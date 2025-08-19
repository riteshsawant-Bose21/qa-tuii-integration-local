/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Copyright 2024 Bose Professional.
 */

#include <linux/module.h>
#include <linux/interrupt.h>
#include <linux/delay.h>
#include <linux/workqueue.h>

#include "fusion-io.h"
#include "fusion-io-sysfs.h"

static struct fusion_io_base_drvdata *bd_drvdata;

// need x_select_chan for all i2c switches
static int tca9544_select_chan(struct i2c_mux_core *muxc, u32 chan_id) 
{
    struct endpoint *ep = i2c_mux_priv(muxc);
    int ret;

    // bit 3 is always high to enable
    u8 regval = (u8)chan_id | 0x04;

    struct i2c_msg msg;
    u8 buf[1] = { regval };

    msg.addr = ep->i2c_client->addr;
    msg.flags = I2C_SMBUS_WRITE;
    msg.len = 1;
    msg.buf = buf;

    ret = __i2c_transfer(ep->i2c_client->adapter, &msg, 1);
    if (ret < 0)
        return ret;

    return 0;
}

// for i2c switches, we create sub-adapters for each switch channel
static int configure_i2c_mux_adapters(struct platform_device *pdev) 
{    
    struct base_device *bd = bd_drvdata->fusion_device;
    struct endpoint *ep;

    int (*select)(struct i2c_mux_core *, u32);
    
    int num_adapters = 0;
    int ret;

    if (bd->i2c_sw == NULL) {
        return -ENODEV;
    }

    ep = bd->i2c_sw;

    switch (ep->type) {
        case EP_TYPE_I2CSW_TCA9544:
            num_adapters = 4;
            select = tca9544_select_chan;
            break;
        default:
            pr_info("Unknown I2C SW type %d\n", ep->type);
            return -EINVAL;
    }

    bd->muxc = i2c_mux_alloc(bd->i2c_adapter,     // parent adapter
                             &pdev->dev,           // parent device
                             num_adapters,        // max_adapters
                             sizeof(*ep->parent_base_device->i2c_sw),  // size of private data
                             0,
                             select,
                             NULL);

    if (!bd->muxc)
        return -ENOMEM;

    bd->muxc->priv = ep;

    for (int i = 0; i < num_adapters; ++i) {
        ret = i2c_mux_add_adapter(bd->muxc, 0, i);
        if (ret < 0) {
            dev_err(&pdev->dev, "Failed to add mux adapter for channel %d\n", i);
            return ret;
        }
    }

    return 0;
}

static int configure_i2c_endpoint(struct platform_device *pdev, struct endpoint *ep) 
{
    struct i2c_client *client;
    struct endpoint_cmd *cmd;
    struct i2c_reg_data *data;

    int ret;
    int i;

    if (ep->has_i2c && ep->i2c_client) {
        client = ep->i2c_client;
        cmd = &ep->cmds[EP_CMD_CONFIG];
        if (strcmp(cmd->name, "cmd_config")) {
            return 0;
        }

        // some endpoints have a custom configure func
        if (ep->ep_configure != NULL) {
            return ep->ep_configure(client, cmd);
        }

        // otherwise use the generic one
        for (i = 0; i < cmd->num_i2c_cmds; ++i) {
            data = &cmd->i2c_cmds[i];
            
            // i2c devices with no register table don't need configuring
            if (data->reg_addr == I2C_REG_DATA_ADDR_NONE) {
                break;
            }

            // need to be wary of LE vs BE devices for 16bit ops here...
            // account for this in the device config (i.e. don't do 16bit ops for BE devices)
            if (data->op_size == I2C_REG_DATA_OP_8BIT) {
                ret = i2c_smbus_write_byte_data(client, data->reg_addr, (u8)data->data_mask);
            } else if (data->op_size == I2C_REG_DATA_OP_16BIT) {
                ret = i2c_smbus_write_word_data(client, data->reg_addr, data->data_mask);
            } else {
                dev_err(&pdev->dev, "Unknown register type for register 0x%02x reg_data 0x%04x\n", data->reg_addr, data->data_mask);
                return -EINVAL;
            }

            if (ret < 0) {
                dev_err(&pdev->dev, "Failed to write register 0x%04x with data 0x%04x to I2C device at 0x%02x\n",
                                                                            data->reg_addr, data->data_mask, client->addr);
                return ret;
            }

            fsleep(10);
        }
    }
    
    return 0;
}

// custom configuration callbacks (only for those who need one)
int ads7128_configure(struct i2c_client *client, struct endpoint_cmd *cmd)
{
    struct i2c_msg msg;
    u8 buf[3];
    int ret;

    buf[0] = ADS7128_OPCODE_WRITE_REG;
    msg.addr = client->addr;
    msg.flags = I2C_SMBUS_WRITE;
    msg.len = 3;
    msg.buf = buf;

    for (int i = 0; i < cmd->num_i2c_cmds; ++i) {
        buf[1] = cmd->i2c_cmds[i].reg_addr;
        buf[2] = cmd->i2c_cmds[i].data_mask;

        ret = __i2c_transfer(client->adapter, &msg, 1);
        if (ret < 0) {
            printk(KERN_ERR "ads7128_configure: failed transfer %i\n", i);
            return ret;
        }
    }

    return 0;
}

// get the i2c client for the endpoint
// TODO: why return the client pointer? just put it in the endpoint i2c_client
static struct i2c_client *endpoint_get_i2c_client(struct platform_device *pdev, struct endpoint *ep, struct i2c_adapter *adapter) 
{
    struct i2c_board_info i2c_info;
    struct i2c_client *client = NULL;

    int i;
    int id;

    for (i = 0; i < MAX_I2C_ADDRS + 1; ++i) {
        if (ep->addr_list[i] == I2C_CLIENT_END) {
            break;
        } else if (ep->cmds == NULL || ep->cmds->num_i2c_cmds == 0 || ep->cmds->i2c_cmds == NULL) {
            dev_err(&pdev->dev, "Endpoint %s is missing i2c commands\n", ep->name);
            break;
        }

        memset(&i2c_info, 0, sizeof(struct i2c_board_info));
        strscpy(i2c_info.type, ep->name, sizeof(i2c_info.type));
        i2c_info.addr = ep->addr_list[i];
        i2c_info.flags = 0;

        client = i2c_new_client_device(adapter, &i2c_info);

        // try the device to see if it exists
        // TODO don't like this so much
        if (!IS_ERR(client)) {
            if (ep->cmds->i2c_cmds->reg_addr == I2C_REG_DATA_ADDR_NONE) {
                id = i2c_smbus_read_byte(client);
            } else {
                id = i2c_smbus_read_byte_data(client, ep->cmds->i2c_cmds->reg_addr);
            }

            if (id < 0) {
                dev_err(&pdev->dev, "Failed to id %s\n", ep->name);
                i2c_unregister_device(client);
                client = NULL;
                continue;
            }
        
            dev_dbg(&pdev->dev, "Discovered endpoint %s at I2C address 0x%x\n", 
                    i2c_info.type, client->addr);

            return client;
        } else {
            dev_err(&pdev->dev, "Failed to get i2c_client for %s\n", ep->name);
        }
    }

    dev_err(&pdev->dev, "Failed to discover endpoint %s\n", ep->name);
    return NULL;
}

// recursively called func to traverse through linked gpios and handle irq.
// i2csw and ioexp endpoints call handle_irq on their gpios, but eventually  
// we land on the endpoint that is the source of the interrupt and handle it
static int handle_irq(struct endpoint_gpio *ep_gpio) 
{
    struct endpoint_gpio *aggregate_gpio;
    int ret = -1;
  
    if (ep_gpio->parent_endpoint) {
        printk(KERN_INFO "handle_irq: calling ep_handle_irq for gpio %s\n", ep_gpio->name);
        ret = ep_gpio->parent_endpoint->ep_handle_irq(ep_gpio);
    } else if (ep_gpio->parent_io_card) {
        for (int i = 0; i < ep_gpio->num_aggregate_gpios; ++i) {
            aggregate_gpio = ep_gpio->aggregate_gpios[i];
            printk(KERN_INFO "handle_irq: calling ep_handle_irq for agg_gpio %s\n", ep_gpio->name);
            ret = aggregate_gpio->parent_endpoint->ep_handle_irq(aggregate_gpio);
            if (ret == 0) {
                break;
            }
        }
    }

    return ret;
}

int tca9544_handle_irq(struct endpoint_gpio *ep_gpio) 
{
    struct endpoint *tca9544 = ep_gpio->parent_endpoint;
    struct i2c_client *client = tca9544->i2c_client;
    struct i2c_msg msg;
    u8 buf[1];
    int ret;
    u8 irq_mask;

    msg.addr = client->addr;
    msg.flags = I2C_SMBUS_READ;
    msg.len = 1;
    msg.buf = buf;

    ret = __i2c_transfer(client->adapter, &msg, 1);
    if (ret < 0) {
        printk(KERN_ERR "tca9544_handle_irq: failed transfer\n");
        return ret;
    }

    // last 4 bits are irq mask
    irq_mask = *buf >> 4;
    for (int i = 0; i < 4; ++i) {
        if (irq_mask >> i & 1) {
            if (tca9544->gpios[i + 1].linked_gpio == NULL) {
                printk(KERN_WARNING "tca9544_handle_irq: null linked gpio %s\n", tca9544->gpios[i + 1].name);
                continue;
            }

            // on i2c switches, gpios[0] is always the interrupt out to device
            handle_irq(tca9544->gpios[i + 1].linked_gpio);
        }
    }

    return 0;
}

int tcal6408_handle_irq(struct endpoint_gpio *ep_gpio)
{
    struct endpoint *tcal6408 = ep_gpio->parent_endpoint;
    struct i2c_client *client = tcal6408->i2c_client;
    struct i2c_msg msgs[2];
    u8 wr_buf[1];
    u8 rd_buf[1];
    int ret;
    u8 irq_mask;

    wr_buf[0] = TCAL6408_REG_INT_STATUS_REG;
    msgs[0].addr = client->addr;
    msgs[0].flags = I2C_SMBUS_WRITE;
    msgs[0].len = 1;
    msgs[0].buf = wr_buf;

    msgs[1].addr = client->addr;
    msgs[1].flags = I2C_SMBUS_READ;
    msgs[1].len = 1;
    msgs[1].buf = rd_buf;

    ret = __i2c_transfer(client->adapter, msgs, 2);
    if (ret < 0) {
        return ret;
    }

    printk(KERN_INFO "tcal6408_handle_irq: rd_buf=0x%02x\n", *rd_buf);

    irq_mask = *rd_buf;

    for (int i = 0; i < 8; ++i) {
        if (irq_mask >> i & 1) {
            if (tcal6408->gpios[i + 1].linked_gpio == NULL) {
                continue;
            }

            // on io expanders, gpios[0] is always the interrupt out to device
            handle_irq(tcal6408->gpios[i + 1].linked_gpio);
        }
    }

    return 0;
}

// TODO verify
int tca9535_handle_irq(struct endpoint_gpio *ep_gpio)
{
    struct endpoint *tca9535 = ep_gpio->parent_endpoint;
    struct i2c_client *client = tca9535->i2c_client;
    struct i2c_msg msgs[2];
    u8 wr_buf[1];
    u8 rd_buf[2];
    int ret;
    u16 irq_mask;

    wr_buf[0] = TCA9535_REG_INPUT_PORT0;
    msgs[0].addr = client->addr;
    msgs[0].flags = 0; // Write
    msgs[0].len = 1;
    msgs[0].buf = wr_buf;

    msgs[1].addr = client->addr;
    msgs[1].flags = I2C_M_RD; // Read
    msgs[1].len = 2;
    msgs[1].buf = rd_buf;

    ret = __i2c_transfer(client->adapter, msgs, 2);
    if (ret < 0) {
        printk(KERN_ERR "tca9535_handle_irq: failed transfer\n");
        return ret;
    }

    irq_mask = ((u16)rd_buf[1] << 8) | rd_buf[0];

    // TODO account for different irq polarities
    for (int i = 0; i < 8; ++i) {
        if (irq_mask >> i & 1) {
            if (tca9535->gpios[i + 1].is_irq) {
                if (tca9535->gpios[i + 1].linked_gpio == NULL) {
                    continue;
                }
                handle_irq(tca9535->gpios[i + 1].linked_gpio);
            }
        }
    }

    return 0;
}

// TODO: verify
int ep9512t_handle_irq(struct endpoint_gpio *ep_gpio)
{
    // struct endpoint *ep9512t = ep_gpio->parent_endpoint;
    // struct endpoint_gpio *gpio;
    // struct i2c_client *client = ep9512t->i2c_client;

    // It appears the possible interrupts could be
    // - hotplug
    // - audio format change (wth???)
    // - audio output stability (extra wtf??)
    //
    // I think i should handle audio stability and a_mute_out here by hw muting outputs! 
    // how the heck would i do that?

    return 0;
}

int ads7128_handle_irq(struct endpoint_gpio *ep_gpio)
{
    struct endpoint *ads7128 = ep_gpio->parent_endpoint;
    struct endpoint_gpio *gpio;
    struct i2c_client *client = ads7128->i2c_client;
    struct i2c_msg wr_msg;
    struct i2c_msg rd_msgs[2];
    u8 wr_buf[3];
    u8 rd_opcode_buf[2];
    u8 rd_data_buf[2];

    u8 event_mask, gpi_value, pin_cfg;
    u16 adc_value;
    u16 new_high, new_low;
    int ret, channel;

    wr_buf[0] = ADS7128_OPCODE_WRITE_REG;
    wr_msg.addr = client->addr;
    wr_msg.flags = I2C_SMBUS_WRITE;
    wr_msg.len = 3;
    wr_msg.buf = wr_buf;

    rd_opcode_buf[0] = ADS7128_OPCODE_READ_REG;
    rd_msgs[0].addr = client->addr;
    rd_msgs[0].flags = I2C_SMBUS_WRITE;
    rd_msgs[0].len = 2;
    rd_msgs[0].buf = rd_opcode_buf;

    rd_msgs[1].addr = client->addr;
    rd_msgs[1].flags = I2C_SMBUS_READ;
    rd_msgs[1].len = 1;
    rd_msgs[1].buf = rd_data_buf;

    // Read alert status for ADC interrupts
    rd_opcode_buf[1] = ADS7128_REG_EVENT_FLAG;
    ret = __i2c_transfer(client->adapter, rd_msgs, 2);
    if (ret < 0) {
        printk(KERN_ERR "ads7128_handle_irq: failed read EVENT_FLAG\n");
        return ret;
    }
    event_mask = *rd_data_buf;

    printk(KERN_INFO "ads7128_handle_irq: event_mask=0x%02x\n", event_mask);

    // nothing to do?
    if (!event_mask) {
        return 0;
    }

    // Read PIN_CFG once for ADC checks
    rd_opcode_buf[1] = ADS7128_REG_PIN_CFG;
    ret = __i2c_transfer(client->adapter, rd_msgs, 2);
    if (ret < 0) {
        printk(KERN_ERR "ads7128_handle_irq: failed read PIN_CFG\n");
        return ret;
    }
    pin_cfg = *rd_data_buf;

    printk(KERN_INFO "ads7128_handle_irq: pin_cfg=0x%02x\n", pin_cfg);

    // Process interrupts for all channels in the mask
    for (channel = 0; channel < 8; channel++) {
        if (!(event_mask & (1 << channel))) {
            continue; // Skip if not in mask
        }

        gpio = &ads7128->gpios[channel + 1];

        // Check ADC interrupt
        if (!(pin_cfg & (1 << channel))) {
            // analog input
            rd_opcode_buf[0] = ADS7128_OPCODE_READ_CONTIGUOUS_REG;
            rd_msgs[1].len = 2;
            rd_opcode_buf[1] = ADS7128_REG_RECENT_CH0_LSB + channel * 2;
            ret = __i2c_transfer(client->adapter, rd_msgs, 2);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed read RECENT_CH0_LSB + %d\n", channel * 2);
                continue;
            }

            adc_value = *(u16 *)rd_data_buf; // 12-bit value (i think its 16bit...)
            gpio->value = adc_value;   // Store ADC value

            printk(KERN_INFO "ads7128_handle_irq: adc_value=0x%04x\n", adc_value);

            // Update thresholds (±32)
            new_high = adc_value > 0xffdf ? 0xffff : adc_value + 0x0020 ;
            new_low = adc_value < 0x0020 ? 0 : adc_value - 0x0020;

            if (new_high == 0xffff) {
                new_low = new_high - 0x0040;
            }
            if (new_low == 0) {
                new_high = 0x0040;
            }

            printk(KERN_INFO "ads7128_handle_irq: new_high=0x%04x, new_low=0x%04x\n", new_high, new_low);

            // Use word writes for high and low thresholds
            wr_buf[1] = ADS7128_REG_HIGH_TH_CH0 + channel * 4;
            wr_buf[2] = (u8)(new_high >> 8); // lower 4 bits are in HYSTERESIS_CHx reg
            ret = __i2c_transfer(client->adapter, &wr_msg, 1);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed write HIGH_TH_CH0 + %d\n", channel * 4);
                continue;
            }
            wr_buf[1] = ADS7128_REG_LOW_TH_CH0 + channel * 4;
            wr_buf[2] = (u8)(new_low >> 8); // lower 4 bits are in HYSTERESIS_CHx reg
            ret = __i2c_transfer(client->adapter, &wr_msg, 1);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed write LOW_TH_CH0 + %d\n", channel * 4);
                continue;
            }
        } else {
            // TODO gpi
            // Read GPIO value for input interrupts
            rd_opcode_buf[1] = ADS7128_REG_GPI_VALUE;
            ret = __i2c_transfer(client->adapter, rd_msgs, 2);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed read GPI_VALUE\n");
                return ret;
            }
            gpi_value = *rd_data_buf;

            printk(KERN_INFO "ads7128_handle_irq: gpi_value=0x%02x\n", gpi_value);
        }

        // clear event flag bits
        wr_buf[1] = ADS7128_REG_EVENT_HIGH_FLAG;
        wr_buf[2] = (u8)(1 << channel); // lower 4 bits are in HYSTERESIS_CHx reg
        ret = __i2c_transfer(client->adapter, &wr_msg, 1);
        if (ret < 0) {
            printk(KERN_ERR "ads7128_handle_irq: failed write EVENT_HIGH_FLAG ch %d\n", channel);
            continue;
        }
        wr_buf[1] = ADS7128_REG_EVENT_LOW_FLAG;
        ret = __i2c_transfer(client->adapter, &wr_msg, 1);
        if (ret < 0) {
            printk(KERN_ERR "ads7128_handle_irq: failed write EVENT_LOW_FLAG ch %d\n", channel);
            continue;
        }
    }

    return 0;
}

// Dedicated workqueue for IRQ handling
static struct workqueue_struct *fusion_irq_wq;

// Work structure for deferred IRQ handling
struct fusion_irq_work {
    struct work_struct work;
    struct endpoint_gpio *irq_gpio;
};

// Workqueue handler
static void handle_irq_work(struct work_struct *work)
{
    struct fusion_irq_work *irq_work = container_of(work, struct fusion_irq_work, work);
    struct endpoint_gpio *irq_gpio = irq_work->irq_gpio;
    int ret;

    // Debug context
    printk(KERN_INFO "handle_irq_work: gpio %s\n", irq_gpio->name);

    ret = handle_irq(irq_gpio);
    if (ret)
        printk(KERN_ERR "handle_irq_work: failed for gpio %s\n", irq_gpio->name);

    kfree(irq_work);
}

// Shared IRQ handler
static irqreturn_t gpio_irq_handler(int irq, void *dev_id)
{
    struct endpoint_gpio *irq_gpio = (struct endpoint_gpio *)dev_id;
    struct fusion_irq_work *irq_work;

    if (bd_drvdata->ready == false || !irq_gpio->linked_gpio) {
        return IRQ_NONE;
    }

    irq_work = kmalloc(sizeof(*irq_work), GFP_ATOMIC);
    if (!irq_work) {
        printk(KERN_ERR "gpio_irq_handler: kmalloc failed\n");
        return IRQ_NONE;
    }

    INIT_WORK(&irq_work->work, handle_irq_work);
    irq_work->irq_gpio = irq_gpio->linked_gpio;
    queue_work(fusion_irq_wq, &irq_work->work);

    return IRQ_HANDLED;
}

static int configure_gpio_interrupt(struct platform_device *pdev, struct endpoint_gpio *ep_gpio)
{
    int ret;

    ep_gpio->irq_num = gpiod_to_irq(ep_gpio->desc);
    if (ep_gpio->irq_num < 0) {
        dev_err(&pdev->dev, "Failed to get IRQ number for GPIO %d\n", ep_gpio->num);
        return -EINVAL;
    }

    // Initialize workqueue if not already done
    if (!fusion_irq_wq) {
        fusion_irq_wq = create_singlethread_workqueue("fusion_irq");
        if (!fusion_irq_wq) {
            dev_err(&pdev->dev, "Failed to create workqueue\n");
            return -ENOMEM;
        }
    }

    // Use regular IRQ, defer to workqueue
    ret = request_irq(ep_gpio->irq_num, gpio_irq_handler,
                      ep_gpio->trigger_type | IRQF_ONESHOT,
                      ep_gpio->name, (void *)ep_gpio);
    if (ret) {
        dev_err(&pdev->dev, "Failed to request IRQ for GPIO %d\n", ep_gpio->num);
        return ret;
    }

    dev_dbg(&pdev->dev, "Configured GPIO %s num %d as interrupt with IRQ number %d\n", ep_gpio->name, ep_gpio->num, ep_gpio->irq_num);
    return 0;
}

static void configure_base_device_references(struct platform_device *pdev)
{
    struct base_device *bd = bd_drvdata->fusion_device;
    struct endpoint *ep;
    struct endpoint_gpio *ep_gpio;
    struct endpoint_cmd *ep_cmd;

    int i, j;

    // mainboard gpios
    for (i = 0; i < bd->num_gpios; ++i) {
        ep_gpio = &bd->gpios[i];
        
        ep_gpio->parent_base_device = bd;
    }

    // endpoints and endpoint gpios
    if (bd->sec_eeprom != NULL) {
        ep = bd->sec_eeprom;
        ep->parent_base_device = bd;
        for (i = 0; i < ep->num_gpios; ++i) {
            ep_gpio = &ep->gpios[i];

            ep_gpio->parent_endpoint = ep;
        }
        for (i = 0; i < ep->num_cmds; ++i) {
            ep_cmd = &ep->cmds[i];

            ep_cmd->parent_endpoint = ep;
        }
    }

    if (bd->data_eeprom != NULL) {
        ep = bd->data_eeprom;

        ep->parent_base_device = bd;

        for (i = 0; i < ep->num_gpios; ++i) {
            ep_gpio = &ep->gpios[i];

            ep_gpio->parent_endpoint = ep;
        }
        for (i = 0; i < ep->num_cmds; ++i) {
            ep_cmd = &ep->cmds[i];

            ep_cmd->parent_endpoint = ep;
        }
    }

    if (bd->i2c_sw != NULL) {
        ep = bd->i2c_sw;

        ep->parent_base_device = bd;

        for (i = 0; i < ep->num_gpios; ++i) {
            ep_gpio = &ep->gpios[i];

            ep_gpio->parent_endpoint = ep;
        }
        for (i = 0; i < ep->num_cmds; ++i) {
            ep_cmd = &ep->cmds[i];

            ep_cmd->parent_endpoint = ep;
        }
    }

    if (bd->pwr_io_exp != NULL) {
        ep = bd->pwr_io_exp;

        ep->parent_base_device = bd;

        for (i = 0; i < ep->num_gpios; ++i) {
            ep_gpio = &ep->gpios[i];

            ep_gpio->parent_endpoint = ep;
        }
        for (i = 0; i < ep->num_cmds; ++i) {
            ep_cmd = &ep->cmds[i];

            ep_cmd->parent_endpoint = ep;
        }
    }

    for (i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];

        ep->parent_base_device = bd;

        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            ep_gpio->parent_endpoint = ep;
        }
        for (j = 0; j < ep->num_cmds; ++j) {
            ep_cmd = &ep->cmds[j];
    
            ep_cmd->parent_endpoint = ep;
        }
    }    
}

static void configure_io_card_references(struct platform_device *pdev, struct io_card *ic)
{
    struct endpoint *ep;
    struct endpoint_gpio *ep_gpio;
    struct endpoint_cmd *ep_cmd;

    int i, j;

    // io_card gpios
    for (i = 0; i < ic->num_gpios; ++i) {
        ep_gpio = &ic->gpios[i];
        
        ep_gpio->parent_io_card = ic;
    }

    // endpoints, endpoint gpios and cmds
    for (i = 0; i < ic->num_eps; ++i) {
        ep = &ic->endpoints[i];

        ep->parent_io_card = ic;

        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            ep_gpio->parent_endpoint = ep;
        }

        for (j = 0; j < ep->num_cmds; ++j) {
            ep_cmd = &ep->cmds[j];

            ep_cmd->parent_endpoint = ep;
        }
    }    
}

// crucial piece of "link_gpio()" below
// operates on "gpios" of either an endpoint or io_card, and determines whter the links should
// be created in "linked_gpio" or "aggregate_gpios"
// rules for non-irq and irq gpios are different but complementary:
// - non-irq gpios point donw from higher levels to lower levels
// - - this is because the high level gpio is exported and points down 
//     to a gpio on an io expander, i2c switch, or base device physical gpio
// - irq gpios point up from lower levels to higher levels
// - - this is because the irq comes from a physical gpio, and we need to 
//     figure out what endpoint gpio it came from
// refer to "levels" described in comment for "link_gpio()"
static int set_linked_or_aggregate_gpio(struct platform_device *pdev, struct endpoint_gpio *ep_gpio, int num_gpios, struct endpoint_gpio *parent_gpios) 
{
    struct endpoint_gpio *parent_gpio;
    
    int i, j;

    for (i = 0; i < num_gpios; ++i) {
        parent_gpio = &parent_gpios[i];

        if (!strcmp(parent_gpio->name, ep_gpio->name)) {
            if (ep_gpio->is_irq == false) {
                if (ep_gpio->aggregate_id != 0) {
                    // first, count how many gpios are aggregated
                    j = i;
                    while (ep_gpio->aggregate_id == parent_gpio->aggregate_id) {
                        parent_gpio = &parent_gpios[j++];
                        if (j > num_gpios) {
                            break;
                        }
                    }

                    // allocate the memory for thos gpios
                    ep_gpio->aggregate_gpios = devm_kzalloc(&pdev->dev, sizeof(struct ep_gpio *) * (j - i - 1), GFP_KERNEL);
                    if (ep_gpio->aggregate_gpios == NULL) {
                        dev_err(&pdev->dev, "ENOMEM from aggregate gpio alloc in link_gpio!");
                        return -ENOMEM;
                    }

                    // reset the agg gpio and counter
                    parent_gpio = &parent_gpios[i];
                    j = 0;

                    // now assign them
                    while (ep_gpio->aggregate_id == parent_gpio->aggregate_id) {
                        ep_gpio->num = parent_gpio->num;
                        ep_gpio->aggregate_gpios[j++] = parent_gpio;

                        dev_dbg(&pdev->dev, "Linking aggregate GPIO %s:%s to GPIO %s:%s\n", ep_gpio->parent_io_card ?
                                                                                            ep_gpio->parent_io_card->data.model :
                                                                                            ep_gpio->parent_endpoint->name,
                                                                                            ep_gpio->name,
                                                                                            parent_gpio->parent_io_card ? 
                                                                                            parent_gpio->parent_io_card->data.model : 
                                                                                            parent_gpio->parent_endpoint->name,
                                                                                            parent_gpio->name);

                        if (++i >= num_gpios) {
                            break;
                        }
                        parent_gpio = &parent_gpios[i];
                    }

                    ep_gpio->num_aggregate_gpios = j; 

                    dev_dbg(&pdev->dev, "Successfully linked (%d) aggregate GPIOs to %s:%s\n", j, ep_gpio->parent_io_card ? 
                                                                                                    ep_gpio->parent_io_card->data.model : 
                                                                                                    ep_gpio->parent_endpoint->name,
                                                                                                    ep_gpio->name);
                    return 0;
                } else {
                    ep_gpio->linked_gpio = parent_gpio;
                    ep_gpio->num = parent_gpio->num;

                    dev_dbg(&pdev->dev, "Successfully linked %s:%s to %s:%s\n", ep_gpio->parent_io_card ? 
                                                                                ep_gpio->parent_io_card->data.model : 
                                                                                ep_gpio->parent_endpoint->name,
                                                                                ep_gpio->name, parent_gpio->parent_io_card ?
                                                                                parent_gpio->parent_io_card->data.model :
                                                                                parent_gpio->parent_endpoint->name,
                                                                                parent_gpio->name);
                    return 0;
                }
            } else if (ep_gpio->is_irq == true) {
                // process of adding aggregate gpios only works off of endpoint irqs
                // ic irqs have aggregate_id too, but they must be phys_gpios pointed to by bd gpios
                if (parent_gpio->aggregate_id != 0 && ep_gpio->parent_endpoint) {
                    int size = 1;
                    // if there are no aggregate gpios yet, kzalloc this one
                    if (parent_gpio->aggregate_gpios == NULL) {
                        // first allocate the list of pointers
                        parent_gpio->aggregate_gpios = devm_kzalloc(&pdev->dev, sizeof(struct ep_gpio *), GFP_KERNEL);
                        if (parent_gpio->aggregate_gpios == NULL) {
                            dev_err(&pdev->dev, "ENOMEM from aggregate irq gpio array alloc in link_gpio!");
                            return -ENOMEM;
                        }

                        parent_gpio->num_aggregate_gpios = 1;
                    } else {
                        // get the existing pointer array size
                        size = parent_gpio->num_aggregate_gpios;

                        // resize the pointer array
                        parent_gpio->aggregate_gpios = devm_krealloc(&pdev->dev, ep_gpio->aggregate_gpios, sizeof(struct ep_gpio *) * (size + 1), GFP_KERNEL);
                        if (parent_gpio->aggregate_gpios == NULL) {
                            dev_err(&pdev->dev, "ENOMEM from aggregate irq gpio realloc in link_gpio!");
                            return -ENOMEM;
                        }

                        parent_gpio->num_aggregate_gpios += 1;
                    }
                    
                    parent_gpio->aggregate_gpios[size - 1] = ep_gpio;

                    dev_dbg(&pdev->dev, "Successfully linked aggregate irq %s:%s to %s:%s\n", parent_gpio->parent_io_card ? 
                                                                                                parent_gpio->parent_io_card->data.model : 
                                                                                                parent_gpio->parent_endpoint->name,
                                                                                                parent_gpio->name, ep_gpio->parent_io_card ?
                                                                                                ep_gpio->parent_io_card->data.model :
                                                                                                ep_gpio->parent_endpoint->name,
                                                                                                ep_gpio->name);
                    return 0;
                
                } else {
                    parent_gpio->linked_gpio = ep_gpio;

                    dev_dbg(&pdev->dev, "Successfully linked irq %s:%s to %s:%s\n", parent_gpio->parent_io_card ? 
                                                                                    parent_gpio->parent_io_card->data.model : 
                                                                                    parent_gpio->parent_endpoint->name,
                                                                                    parent_gpio->name, ep_gpio->parent_io_card ?
                                                                                    ep_gpio->parent_io_card->data.model :
                                                                                    ep_gpio->parent_endpoint->name,
                                                                                    ep_gpio->name);
                    return 0;
                }
            }
        }
    }

    return -1;
}

// Rules for linking GPIOs
// 1. exportable non-irq GPIOs link down to an io expander pin (higher level -> lower level)
// 2. irq GPIOs link up from the physical irq pin to their sources (lower level -> higher level)
// 3. gpios that are linked to do not need to link back 
// 4. for aggregate gpios (links in aggregate_gpios):
// 4a. exportable non-irq aggregated GPIOs link down to multiple io expander pins
// 4b. aggregated irq GPIOs are aggregated on an io_card gpio which links up to multiple endpoint gpios; physical gpio links up to the aggregated io_card gpio
// 5. when linking, only search levels below the gpio to be linked, except search everything for io_card endpoints:
//
// "levels":
// - base_device gpios
// - - base_device endpoints
// - - - base_device endpoint gpios
// - - io_card gpios
// - - - io_card endpoints
// - - - - io_card endpoint gpios
//
// Example 1 - if the gpio to be linked is a base_device gpio, there are no lower levels, so do nothing
// Example 2 - if the gpio to be linked is an io_card gpio, the lower levels to search are base_device gpios and base_device endpoint gpios
// Example 3 - if the gpio to be linked is an io_card endpoint gpio, search everything
// 
// NOTE: before link_gpio is called on any GPIO, ALL LOWER LEVEL GPIO's parent relationships MUST be populated by "configure_x_references()"
static void link_gpio(struct platform_device *pdev, struct endpoint_gpio *ep_gpio) 
{
    struct base_device *bd = bd_drvdata->fusion_device;
    struct io_card *parent_ic;
    struct endpoint *parent_ep;
    struct endpoint *ep;

    int ret;
    int i;

    // irqs are never exported to sysfs
    if (ep_gpio->is_irq == false && ep_gpio->export == EP_GPIO_NO_EXPORT) {
        return;
    }
    
    if (ep_gpio->type == EP_GPIO_TYPE_VIRT) {
        // first get parent ep and ic links
        if (ep_gpio->parent_endpoint) {
            parent_ep = ep_gpio->parent_endpoint;

            // we never export GPIOs on io expanders (and therefore never add a linked_gpio), but irq's on io expanders get linked
            if (parent_ep->ioexp_id > 0 && ep_gpio->is_irq == false) {
                return;
            }

            if (parent_ep->parent_io_card) {
                parent_ic = parent_ep->parent_io_card;
            } else  {
                parent_ic = NULL;
            }
        } else if (ep_gpio->parent_io_card) {
            parent_ic = ep_gpio->parent_io_card;
            parent_ep = NULL;
        } else if (ep_gpio->parent_base_device) {
            // nothing to do -- irq links get set when we find the higher level irq later
            return;
        }

        // if gpio is on an ic endpoint, search the ic AND ic endpoint gpios
        // if gpio is just on ic, and is aggregate, we need to search up into endpoints
        if (parent_ic && (parent_ep || ep_gpio->aggregate_id != 0) && !ep_gpio->is_irq) {
            // search ic gpios
            if (parent_ep) {
                ret = set_linked_or_aggregate_gpio(pdev, ep_gpio, parent_ic->num_gpios, parent_ic->gpios);
                if (!ret) {
                    return;
                }
            }

            // now search the ic endpoint gpios
            for (i = 0; i < parent_ic->num_eps; ++i) {
                ep = &parent_ic->endpoints[i];

                // if gpio is on an endpoint, don't search that endpoint's gpios
                if (parent_ep && !strcmp(parent_ep->name, ep->name)) {
                    continue;
                }

                ret = set_linked_or_aggregate_gpio(pdev, ep_gpio, ep->num_gpios, ep->gpios);
                if (!ret) {
                    return;
                }
            }
        } 

        // If we haven't found link, check base device gpios
        for (i = 0; i < bd->num_eps; ++i) {
            ep = &bd->endpoints[i];
            // don't check if it's the same endpoint ep_gpio is on
            if (parent_ep && !strcmp(parent_ep->name, ep->name)) {
                continue;
            }

            ret = set_linked_or_aggregate_gpio(pdev, ep_gpio, ep->num_gpios, ep->gpios);
            if (!ret) {
                return;
            }
        }
        if (bd->pwr_io_exp != NULL) {
            ep = bd->pwr_io_exp;
            // don't check if it's the same endpoint ep_gpio is on
            if (!(parent_ep && !strcmp(parent_ep->name, ep->name))) {
                ret = set_linked_or_aggregate_gpio(pdev, ep_gpio, ep->num_gpios, ep->gpios);
                if (!ret) {
                    return;
                }
            }
        }
        if (bd->i2c_sw != NULL) {
            ep = bd->i2c_sw;
            // don't check if it's the same endpoint ep_gpio is on
            if (!(parent_ep && !strcmp(parent_ep->name, ep->name))) {
                ret = set_linked_or_aggregate_gpio(pdev, ep_gpio, ep->num_gpios, ep->gpios);
                if (!ret) {
                    return;
                }
            }
        }
    } else if (ep_gpio->type == EP_GPIO_TYPE_PHYS) {
        // physical gpios just need a base_device match
        for (i = 0; i < bd->num_gpios; ++i) {
            if (!strcmp(ep_gpio->name, bd->gpios[i].name)) {
                if (ep_gpio->is_irq == false) {
                    dev_dbg(&pdev->dev, "Successfully linked phys GPIO %s:%s to %s:%s", ep_gpio->parent_io_card ?
                                                                                        ep_gpio->parent_io_card->data.model :
                                                                                        ep_gpio->parent_endpoint->name,
                                                                                        ep_gpio->name, 
                                                                                        bd->data.model, bd->gpios[i].name);
                    ep_gpio->linked_gpio = &bd->gpios[i];
                } else if (ep_gpio->is_irq == true) {
                    dev_dbg(&pdev->dev, "Successfully linked phys GPIO irq %s:%s to %s:%s", bd->data.model, bd->gpios[i].name,
                                                                                            ep_gpio->parent_io_card ?
                                                                                            ep_gpio->parent_io_card->data.model :
                                                                                            ep_gpio->parent_endpoint->name,
                                                                                            ep_gpio->name);
                    bd->gpios[i].linked_gpio = ep_gpio;
                }

                return;
            }
        }
    }

    dev_dbg(&pdev->dev, "link_gpio: no link for GPIO %s:%s", ep_gpio->parent_io_card ?
                                                                ep_gpio->parent_io_card->data.model :
                                                                ep_gpio->parent_endpoint ?
                                                                ep_gpio->parent_endpoint->name :
                                                                ep_gpio->parent_base_device->data.model,
                                                                ep_gpio->name);
}

static int configure_base_device_gpios(struct platform_device *pdev)
{
    struct base_device *bd = bd_drvdata->fusion_device;
    struct endpoint *ep;
    struct endpoint_gpio *ep_gpio;

    int ret, i, j;

    // first mainboard gpios
    for (i = 0; i < bd->num_gpios; ++i) {
        ep_gpio = &bd->gpios[i];

        if (ep_gpio->num == 0xff) {
            dev_err(&pdev->dev, "Invalid base device GPIO %s\n", ep_gpio->name);
            continue;
        }

        ep_gpio->desc = gpio_to_desc(ep_gpio->num);
        if (!ep_gpio->desc) {
            dev_err(&pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
            continue;
        }

        if (ep_gpio->is_irq) {
            ret = gpio_direction_input(ep_gpio->num);
            if (ret) {
                dev_err(&pdev->dev, "Failed to setup base device GPIO %s as input\n", ep_gpio->name);
                continue;
            }

            ret = configure_gpio_interrupt(pdev, ep_gpio);
            if (ret) {
                dev_err(&pdev->dev, "Failed to setup base device GPIO %s as interrupt\n", ep_gpio->name);
                continue;
            }
        } else {
            ret = devm_gpio_request(&pdev->dev, ep_gpio->num, ep_gpio->name);
            if (ret) {
                dev_err(&pdev->dev, "Failed to request base device GPIO %s\n", ep_gpio->name);
                continue;
            }

            if (ep_gpio->dir == EP_GPIO_DIR_O) {
                ret = gpio_direction_output(ep_gpio->num, ep_gpio->default_val);
            } else if (ep_gpio->dir == EP_GPIO_DIR_I) {
                ret = gpio_direction_input(ep_gpio->num);
            }

            if (ret) {
                dev_err(&pdev->dev, "Failed to configure base device GPIO %s direction\n", ep_gpio->name);
                continue;
            }
        }

        dev_dbg(&pdev->dev, "Configured base device GPIO %s\n", ep_gpio->name);
        
        ep_gpio->valid = true;
    }

    if (bd->sec_eeprom) {
        ep = bd->sec_eeprom;
        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            // link gpio before we check the links
            link_gpio(pdev, ep_gpio);

            dev_dbg(&pdev->dev, "Configuring base device gpio %s:%s", ep->name, ep_gpio->name);

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS && !ep_gpio->is_irq) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
                    continue;
                }
            }

            dev_dbg(&pdev->dev, "Configured base device GPIO %s:%s\n", ep->name, ep_gpio->name);
            
            ep_gpio->valid = true;
        }
    }

    if (bd->data_eeprom) {
        ep = bd->data_eeprom;
        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            // link gpio before we check the links
            link_gpio(pdev, ep_gpio);

            dev_dbg(&pdev->dev, "Configuring base device gpio %s:%s", ep->name, ep_gpio->name);

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS && !ep_gpio->is_irq) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
                    continue;
                }
            }

            dev_dbg(&pdev->dev, "Configured base device GPIO %s:%s\n", ep->name, ep_gpio->name);
            
            ep_gpio->valid = true;
        }
    }

    if (bd->i2c_sw) {
        ep = bd->i2c_sw;
        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            // link gpio before we check the links
            link_gpio(pdev, ep_gpio);

            dev_dbg(&pdev->dev, "Configuring base device gpio %s:%s", ep->name, ep_gpio->name);

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS && !ep_gpio->is_irq) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
                    continue;
                }
            }

            dev_dbg(&pdev->dev, "Configured base device GPIO %s:%s\n", ep->name, ep_gpio->name);
            
            ep_gpio->valid = true;
        }
    }

    if (bd->pwr_io_exp) {
        ep = bd->pwr_io_exp;
        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            // link gpio before we check the links
            link_gpio(pdev, ep_gpio);

            dev_dbg(&pdev->dev, "Configuring base device gpio %s:%s", ep->name, ep_gpio->name);

            if (ep_gpio->ioexp_id != ep->ioexp_id) {
                dev_err(&pdev->dev, "GPIO %s:%s doesn't have matching ioexp_id (%d/%d)\n", ep->name, 
                                                                                            ep_gpio->name, 
                                                                                            ep_gpio->ioexp_id, 
                                                                                            ep->ioexp_id);
                continue;
            }

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS && !ep_gpio->is_irq) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
                    continue;
                }
            }

            dev_dbg(&pdev->dev, "Configured base device GPIO %s:%s\n", ep->name, ep_gpio->name);
            
            ep_gpio->valid = true;
        }
    }

    // then endpoint gpios
    for (i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];

        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            // link gpio before we check the links
            link_gpio(pdev, ep_gpio);

            dev_dbg(&pdev->dev, "Configuring base device gpio %s:%s", ep->name, ep_gpio->name);

            if (ep->type >= EP_TYPE_IOEXP_START && ep->type < EP_TYPE_IOEXP_END) {
                if (ep_gpio->ioexp_id != ep->ioexp_id) {
                    dev_err(&pdev->dev, "GPIO %s:%s doesn't have matching ioexp_id (%d/%d)\n", ep->name, 
                                                                                                ep_gpio->name, 
                                                                                                ep_gpio->ioexp_id, 
                                                                                                ep->ioexp_id);
                    continue;
                }
            }

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS && !ep_gpio->is_irq) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
                    continue;
                }
            }

            dev_dbg(&pdev->dev, "Configured GPIO %s:%s\n", ep->name, ep_gpio->name);
            
            ep_gpio->valid = true;
        }
    }    

    return 0;
}

// Real GPIO config and io exp configs done in base device
// Just validate and mark valid true
static int configure_io_card_gpios(struct platform_device *pdev, struct io_card *ic) 
{
    struct endpoint *ep;
    struct endpoint_gpio *ep_gpio;

    int i, j;

    // first io card gpios
    for (i = 0; i < ic->num_gpios; ++i) {
        ep_gpio = &ic->gpios[i];

        link_gpio(pdev, ep_gpio);

        if (ep_gpio->type == EP_GPIO_TYPE_PHYS) {
            ep_gpio->desc = ep_gpio->linked_gpio->desc;
            if (!ep_gpio->desc) {
                dev_err(&pdev->dev, "GPIO %s:%s descriptor is NULL\n", ic->data.model, ep_gpio->name);
                continue;
            }
        }

        ep_gpio->valid = true;

        dev_dbg(&pdev->dev, "Successfully configured GPIO %s:%s\n", ic->data.model, ep_gpio->name);
    }

    // io_card endpoint gpios
    for (i = 0; i < ic->num_eps; ++i) {
        ep = &ic->endpoints[i];

        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            link_gpio(pdev, ep_gpio);

            if (ep->type >= EP_TYPE_IOEXP_START && ep->type < EP_TYPE_IOEXP_END) {
                if (ep_gpio->ioexp_id != ep->ioexp_id) {
                    dev_err(&pdev->dev, "GPIO %s:%s:%s doesn't have matching ioexp_id (%d/%d)\n", ic->data.model,
                                                                                                ep->name,
                                                                                                ep_gpio->name,  
                                                                                                ep_gpio->ioexp_id, 
                                                                                                ep->ioexp_id);
                    continue;
                }
            } else if (ep_gpio->ioexp_id > 0) {
                if (!ep_gpio->linked_gpio && !ep_gpio->aggregate_gpios) {
                    dev_err(&pdev->dev, "GPIO %s:%s:%s is missing a link to an IO Expander GPIO\n", ic->data.model,
                                                                                                    ep->name,
                                                                                                    ep_gpio->name);
                    continue;
                }
            }

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&pdev->dev, "GPIO %s:%s:%s descriptor is NULL\n", ic->data.model, ep->name, ep_gpio->name);
                    continue;
                }
            }

            ep_gpio->valid = true;

            dev_dbg(&pdev->dev, "Successfully configured GPIO %s:%s:%s\n", ic->data.model, ep->name, ep_gpio->name);
        }
    }
    
    return 0;
}

// only care about base device (real) gpios
static void cleanup_gpios(void) 
{
    struct base_device *bd = bd_drvdata->fusion_device;
    struct endpoint_gpio *ep_gpio;

    int i;

    for (i = 0; i < bd->num_gpios; ++i) {
        ep_gpio = &bd->gpios[i];
        
        if (!ep_gpio->valid) {
            continue;
        }

        if (ep_gpio->desc) {
            if (ep_gpio->is_irq) {
                free_irq(ep_gpio->irq_num, (void *)ep_gpio);
            }
            gpiod_put(ep_gpio->desc);
        }
    }
}

static struct base_device *new_default_base_device(struct platform_device *pdev, enum base_device_type bd_type) 
{
    struct base_device *bd;

    for (int i = 0; default_bd_types[i] != BD_TYPE_NONE; ++i) {
        if (bd_type == default_bd_types[i]) {
            bd = devm_kzalloc(&pdev->dev, sizeof(*default_bds[i]), GFP_KERNEL);
            if (bd == NULL) {
                break;
            }

            memcpy(bd, default_bds[i], sizeof(*bd));
            return bd;
        }
    }

    return NULL;
} 

static struct io_card *new_default_io_card(struct platform_device *pdev, enum io_card_type ic_type) 
{
    struct io_card *ic;

    for (int i = 0; default_ic_types[i] != IC_TYPE_NONE; ++i) {
        if (ic_type == default_ic_types[i]) {
            ic = devm_kzalloc(&pdev->dev, sizeof(*default_ics[i]), GFP_KERNEL);
            if (ic == NULL) {
                break;
            }

            memcpy(ic, default_ics[i], sizeof(*ic));
            return ic;
        }
    }

    return NULL;
} 

// get the default endpoint for an endpoint type
// ONLY USE FOR TEMPORARY ENDPOINTS! Returned ptr must be freed
static struct endpoint *new_default_endpoint(enum endpoint_type ep_type) 
{
    struct endpoint *ep;

    for (int i = 0; default_ep_types[i] != EP_TYPE_NONE; ++i) {
        if (ep_type == default_ep_types[i]) {
            if (default_eps[i] == NULL) {
                printk(KERN_WARNING "new_default_endpoint: no default ep for type %d\n", ep_type);
                return NULL;
            }
            
            ep = kzalloc(sizeof(*default_eps[i]), GFP_KERNEL);
            if (ep == NULL) {
                break;
            }

            memcpy(ep, default_eps[i], sizeof(*ep));
            return ep;
        }
    }

    return NULL;
}

static void fusion_io_remove(struct platform_device *pdev)
{
    struct base_device *bd = bd_drvdata->fusion_device;
    struct endpoint *ep;
    struct io_card *ic;

    int i, j;

    if (bd == NULL) {
        return;
    }

    // clear base device endpoint i2c clients
    if (bd->sec_eeprom != NULL && bd->sec_eeprom->i2c_client) {
        i2c_unregister_device(bd->sec_eeprom->i2c_client);
    }
    if (bd->data_eeprom != NULL && bd->data_eeprom->i2c_client) {
        i2c_unregister_device(bd->data_eeprom->i2c_client);
    }
    if (bd->i2c_sw != NULL && bd->i2c_sw->i2c_client) {
        i2c_unregister_device(bd->i2c_sw->i2c_client);
    }
    if (bd->pwr_io_exp != NULL && bd->pwr_io_exp->i2c_client) {
        i2c_unregister_device(bd->pwr_io_exp->i2c_client);
    }
    for (i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];

        if (ep->i2c_client) {
            i2c_unregister_device(ep->i2c_client);
            ep->i2c_client = NULL;  // Clear pointer to prevent reuse
        }
    }

    // clear io card i2c clients and sysfs entries
    for (i = 0; i < bd->num_ics; ++i) {
        ic = &bd->io_cards[i];
        
        // Unregister I2C clients for each endpoint
        for (j = 0; j < ic->num_eps; ++j) {
            ep = &ic->endpoints[j];

            if (ep->i2c_client) {
                i2c_unregister_device(ep->i2c_client);
                ep->i2c_client = NULL;  // Clear pointer to prevent reuse
            }
        }

        fusion_io_remove_sysfs_io_card(pdev, ic);
    }

    cleanup_gpios();
    
    if(bd->muxc) {
        i2c_mux_del_adapters(bd->muxc);
    }
    if(bd->i2c_adapter) {
        i2c_put_adapter(bd->i2c_adapter);
    }

    fusion_io_remove_sysfs_base(pdev);
}

static int fusion_io_probe(struct platform_device *pdev)
{
    struct base_device  *bd;
    struct io_card      *ic;
    struct endpoint     *ep;
    struct i2c_client   *i2c_client;
    struct i2c_adapter  *i2c_adapter;
    struct eeprom_data  data;

    int i, j;
    int ret;


    // allocate drvdata, but we'll set it up after we know what device we are
    bd_drvdata = devm_kzalloc(&pdev->dev, sizeof(*bd_drvdata), GFP_KERNEL);
    if (!bd_drvdata) {
        return -ENOMEM;
    }


    i2c_adapter = i2c_get_adapter(I2C_ADAPTER);
    if (!i2c_adapter) {
        dev_err(&pdev->dev, "Failed to get I2C adapter %d\n", I2C_ADAPTER);
        return -ENODEV;
    }

    // First, find secure eeprom. This is the only IC we have to discover from scratch
    for (i = EP_TYPE_SEC_EEPROM_START; i < EP_TYPE_SEC_EEPROM_END; ++i) {
        ep = new_default_endpoint(i);
        if (ep == NULL) {
            // only possible due to failed zalloc or memcpy
            dev_err(&pdev->dev, "Couldn't get default endpoint for type %d\n", i);
            return -ENOMEM;
        }

        i2c_client = endpoint_get_i2c_client(pdev, ep, i2c_adapter);

        if (i2c_client) {
            break;
        }

        kfree(ep);
    }

    if (i2c_client) {
        ep->i2c_client = i2c_client;
 
        // TODO: configure secure eeprom first time, then use?
        // ret = configure_i2c_endpoint(pdev, ep);
        // if (ret) {
        //     dev_err(&pdev->dev, "Error configuring endpoint %s\n", ep->name);
        //     goto error;
        // }
        
        // Here we can pull device data from secure eeprom.
        // i = i2c_smbus_read_i2c_block_data(i2c_client, 
        //                                   ep->cmds[EP_CMD_EEPROM_RD_DATA].i2c_cmds[0].reg_addr, 
        //                                   sizeof(data), 
        //                                   (char *)&data);

        // if (i < 0) {
        //     dev_err(&pdev->dev, "Bad I2C read of %s\n", ep->name);
        //     goto error;
        // }
    } else {
        // TODO this is really an error! For var proto it's not
        // dev_err(&pdev->dev, "Error getting i2c client for secure eeprom\n");
        dev_dbg(&pdev->dev, "No secure eeprom found on mainboard\n");

        // ret = -ENODEV;
        // goto error;
    }

    ep = NULL;
    data.type = BD_TYPE_FUSION_C0;
    
    // set up the base_device
    bd = new_default_base_device(pdev, data.type);
    if (!bd) {
        dev_err(&pdev->dev, "No base_device static config match found for base_device type %d\n", data.type);
        ret = -EINVAL;
        goto error;
    }

    bd_drvdata->fusion_device = bd;

    // Set the private data 
    platform_set_drvdata(pdev, bd_drvdata);
    
    strcpy(bd->data.sn, data.sn);
    bd->i2c_adapter = i2c_adapter;

    // now copy sec_eeprom endpoint into base_device
    if (ep) {
        bd->sec_eeprom->i2c_client = ep->i2c_client;
        kfree(ep);
        ep = NULL;
    }

    dev_info(&pdev->dev, "Found config -- Model: %s, SN: %s", bd->data.model, bd->data.sn);

    // IDEA: maybe we can have patches for HW revisions? apply here

    // Now look for data eeprom. I'm thinking we don't end up usng it :)
    if (bd->data_eeprom != NULL) {
        ep = bd->data_eeprom;
        i2c_client = endpoint_get_i2c_client(pdev, ep, bd->i2c_adapter);

        if (i2c_client) {
            ep->i2c_client = i2c_client;

            // ret = configure_i2c_endpoint(pdev, ep);
            // if (ret) {
            //     goto error;
            // }
        } else {
            dev_err(&pdev->dev, "Error getting i2c client for %s\n", ep->name);
            ret = -ENODEV;
            goto error;
        }
    } else {
        dev_dbg(&pdev->dev, "No data eeprom found on mainboard\n");
    }
    

    // i2c switch
    if (bd->i2c_sw != NULL) {
        ep = bd->i2c_sw;
        i2c_client = endpoint_get_i2c_client(pdev, ep, bd->i2c_adapter);

        if (i2c_client) {
            ep->i2c_client = i2c_client;

            ret = configure_i2c_endpoint(pdev, ep);
            if (ret) {
                goto error;
            }

            // configure the mux adapters
            ret = configure_i2c_mux_adapters(pdev);
            if (ret){
                goto error;
            }
        } else {
            dev_err(&pdev->dev, "Error getting i2c client for %s\n", ep->name);
            ret = -ENODEV;
            goto error;
        }
    } else {
        dev_dbg(&pdev->dev, "No i2c switch on mainboard\n");
    }

    // next find pwr ctrl io expander
    if (bd->pwr_io_exp != NULL) {
        ep = bd->pwr_io_exp;
        i2c_client = endpoint_get_i2c_client(pdev, ep, bd->i2c_adapter);

        if (i2c_client) {
            ep->i2c_client = i2c_client;

            ret = configure_i2c_endpoint(pdev, ep);
            if (ret) {
                goto error;
            }
        } else {
            dev_err(&pdev->dev, "Error getting i2c client for %s\n", ep->name);
            ret = -ENODEV;
            goto error;
        }
    } else {
        dev_dbg(&pdev->dev, "No power io expander on mainboard\n");
    }

    // now configure other base device endpoints
    for (i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];

        if (!ep->has_i2c) {
            continue;
        }

        dev_dbg(&pdev->dev, "Setting i2c client for base device endpoint %s...\n", ep->name);

        // set up the i2c_client
        ep->i2c_client = endpoint_get_i2c_client(pdev, ep, bd->i2c_adapter);

        if (ep->i2c_client == NULL) {
            dev_dbg(&pdev->dev, "Failed to set i2c client...");
            ret = -ENODEV;
            goto error;
        }

        // configure i2c device
        ret = configure_i2c_endpoint(pdev, ep);
        if (ret) {
            dev_err(&pdev->dev, "Error configuring i2c endpoint %s\n", ep->name);
            goto error;
        }
            
        dev_dbg(&pdev->dev, "Successfully registered endpoint %s!\n", ep->name);
        break;
    }

    // set up parent references
    configure_base_device_references(pdev);

    // configure GPIOs
    ret = configure_base_device_gpios(pdev);
    if (ret) {
        dev_err(&pdev->dev, "Error configuring base device gpios!\n");
        goto error;
    }

    // export sysfs for base device
    ret = fusion_io_create_sysfs_base(pdev);
    if (ret) {
        dev_err(&pdev->dev, "Error creating base device sysfs!\n");
        goto error;
    }
   
    // Base device ready!
    //
    // if we're an IO card device, we scan for EEPROMs
    // otherwise, we scan the known HW
    if (bd->has_slot_io == false) {
        /* We are a fixed IO device */
        dev_dbg(&pdev->dev, "Base device is fixed IO\n");

        // for all the io blocks on the device
        for (i = 0; i < bd->num_ics; ++i) {
            ic = &bd->io_cards[i];

            // set up parent references
            configure_io_card_references(pdev, ic);

            // for all the endpoints on that io block
            for (j = 0; j < ic->num_eps; ++j) {
                ep = &ic->endpoints[j];

                if (ep->has_i2c == false) {
                    continue;
                }

                dev_dbg(&pdev->dev, "Setting i2c client for block %s endpoint %s...\n", 
                                      ic->data.model, ep->name);

                // set up the i2c_client
                if (bd->i2c_sw != NULL && ep->parent_io_card && ep->parent_io_card->i2c_sw_channel != 0) {
                    i2c_adapter = bd->muxc->adapter[ep->parent_io_card->i2c_sw_channel - 1];
                } else {
                    i2c_adapter = bd->i2c_adapter;
                }
                ep->i2c_client = endpoint_get_i2c_client(pdev, ep, i2c_adapter);

                if(ep->i2c_client == NULL) {
                    dev_err(&pdev->dev, "Failed to set i2c client...");
                    ret = -ENODEV;
                    goto error;
                }

                // configure i2c device
                ret = configure_i2c_endpoint(pdev, ep);
                if (ret) {
                    goto error;
                }

                dev_dbg(&pdev->dev, "Successfully registered endpoint %s!\n", ep->name);
            }

            // configure GPIOs
            ret = configure_io_card_gpios(pdev, ic);
            if (ret) {
                goto error;
            }

            // create sysfs entries
            ret = fusion_io_create_sysfs_io_card(pdev, ic);
            if (ret) {
                goto error;
            }

            dev_info(&pdev->dev, "Successfully registered IO card %d model %s!\n", i, ic->data.model);
        }
    } else if (bd->has_slot_io == true) { /* we are a slot IO device */
        // go through all slots
        for (i = 0; i < bd->num_ics; ++i) {
            ic = &bd->io_cards[i];

            if (ic->data.type != IC_TYPE_UNKNOWN) {
                continue;
            }

            // First, find secure eeprom. This is the only IC we have to discover from scratch
            for (j = EP_TYPE_SEC_EEPROM_START; j < EP_TYPE_SEC_EEPROM_END; ++j) {
                ep = new_default_endpoint(j);
                if (ep == NULL) {
                    dev_err(&pdev->dev, "Couldn't get default endpoint for type %d\n", j);
                    continue;
                }

                ep->parent_io_card = ic;
                
                // get adapter (should always be mux adapter for slot)
                if (bd->i2c_sw != NULL) {
                    i2c_adapter = bd->muxc->adapter[i];
                } else {
                    i2c_adapter = bd->i2c_adapter;
                }
                i2c_client = endpoint_get_i2c_client(pdev, ep, i2c_adapter);
                
                if (i2c_client) {
                    dev_dbg(&pdev->dev, "Found %s on io-card model %s, slot %d\n", 
                                                                    ep->name, 
                                                                    ic->data.model, 
                                                                    ic->slot);
                    break;
                }

                kfree(ep);
            }

            // if it's not there, assume no IO card in this slot
            if (i2c_client == NULL) {
                dev_dbg(&pdev->dev, "No IO card found on slot %d\n", i);
                ep = NULL;
                continue;
            }

            ep->i2c_client = i2c_client;

            ret = configure_i2c_endpoint(pdev, ep);
            if (ret) {
                dev_err(&pdev->dev, "Error configuring endpoint %s\n", ep->name);
                goto error;
            }

            memset(&data, 0, sizeof(data));

            // Here we can pull device data from secure eeprom. 
            // TODO!!! crypto part, data size, address, etc
            // TODO: probably need read eeprom data commands for different sec eeproms
            ret = i2c_smbus_read_i2c_block_data(i2c_client, 
                                                ep->cmds[EP_CMD_EEPROM_RD_DATA].i2c_cmds[0].reg_addr, 
                                                sizeof(data), 
                                                (char *)&data);

            if (ret < 0) {
                dev_err(&pdev->dev, "Bad I2C read of %s\n", ep->name);
                goto error;
            }

            kfree(ep);
            ep = NULL;

            // then, check type against io_card table.
            ic = new_default_io_card(pdev, data.type);
            if (!ic) {
                continue;
            }

            // IDEA: maybe we can have patches for HW revisions? apply here

            // set io cards slot number
            ic->slot = i;
            if (bd->i2c_sw != NULL) {
                ic->i2c_sw_channel = i + 1;
            }

            // get endpoint i2c clients
            for (j = 0; j < ic->num_eps; ++j) {
                ep = &ic->endpoints[j];

                if (ep->has_i2c == false) {
                    continue;
                }

                dev_dbg(&pdev->dev, "Setting i2c client for card slot %d block %s endpoint %s...\n", 
                                                                ic->slot, ic->data.model, ep->name);

                // set up the i2c_client
                // get adapter (should always be mux adapter for slot)
                if (bd->i2c_sw != NULL) {
                    i2c_adapter = bd->muxc->adapter[i];
                } else {
                    i2c_adapter = bd->i2c_adapter;
                }
                ep->i2c_client = endpoint_get_i2c_client(pdev, ep, i2c_adapter);

                if(ep->i2c_client == NULL) {
                    dev_err(&pdev->dev, "Failed to set i2c client...");
                    ret = -ENODEV;
                    goto error;
                }

                // do configuring of endpoint default configure command here?
                // setup_configure_ep_cmd(&ep->cmds[EP_CMD_CONFIG]);
                
                ret = configure_i2c_endpoint(pdev, ep);
                if (ret) {
                    goto error;
                }

                dev_dbg(&pdev->dev, "Successfully registered endpoint %s!\n", ep->name);
            }

            // set up parent references
            configure_io_card_references(pdev, ic);

            // configure GPIOs
            ret = configure_io_card_gpios(pdev, ic);
            if (ret) {
                goto error;
            }

            // create sysfs entries
            ret = fusion_io_create_sysfs_io_card(pdev, ic);
            if (ret) {
                goto error;
            }

            dev_info(&pdev->dev, "Successfully registered IO card %d model %s!\n", i, ic->data.model);
        }
    }

    bd_drvdata->ready = true;

    dev_info(&pdev->dev, "Successfully registered fusion device %s!\n", bd->data.model);

error:
    return ret;
}

static struct platform_driver fusion_io_driver = {
    .driver = {
        .name = "fusion-io",
    },
    .probe = fusion_io_probe,
    .remove = fusion_io_remove,
};

// Define the release function for the platform device
static void fusion_io_device_release(struct device *dev)
{
    pr_info("fusion-io: Device release called\n");
}

// Update the platform device to include the release function
static struct platform_device fusion_io_device = {
    .name = "fusion-io",
    .id = -1,
    .dev = {
        .release = fusion_io_device_release,
    },
};

static int __init fusion_io_init(void)
{
    int ret;

    // Register the platform device
    ret = platform_device_register(&fusion_io_device);
    if (ret) {
        pr_err("fusion-io: Failed to register device\n");
        return ret;
    }

    // Register the platform driver
    ret = platform_driver_register(&fusion_io_driver);
    if (ret) {
        pr_err("fusion-io: Failed to register driver\n");
        platform_device_unregister(&fusion_io_device);
        return ret;
    }

    pr_info("fusion-io: Initialization successful\n");
    return 0;
}

static void __exit fusion_io_exit(void)
{
    pr_info("fusion-io: Exiting driver\n");

    platform_driver_unregister(&fusion_io_driver);
    platform_device_unregister(&fusion_io_device);

    pr_info("fusion-io: Driver exit completed\n");
}


module_init(fusion_io_init);
module_exit(fusion_io_exit);

MODULE_AUTHOR("Nathan Mark");
MODULE_DESCRIPTION("Fusion IO Driver");
MODULE_LICENSE("GPL");
