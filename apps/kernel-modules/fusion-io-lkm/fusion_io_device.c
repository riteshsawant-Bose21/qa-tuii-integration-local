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

    ret = i2c_transfer(ep->i2c_client->adapter, &msg, 1);
    if (ret < 0)
        return ret;

    return 0;
}

// for i2c switches, we create sub-adapters for each switch channel
static int configure_i2c_mux_adapters(struct endpoint *ep) 
{    
    int (*select)(struct i2c_mux_core *, u32);
    
    int num_adapters = 0;
    int ret;

    switch (ep->type) {
        case EP_TYPE_I2CSW_TCA9544:
            num_adapters = 4;
            select = tca9544_select_chan;
            break;
        default:
            pr_info("Unknown I2C SW type %d\n", ep->type);
            return -EINVAL;
    }

    bd_drvdata->muxc = i2c_mux_alloc(bd_drvdata->i2c_adapter, &bd_drvdata->pdev->dev,          
                                     num_adapters, sizeof(*ep), I2C_MUX_LOCKED, select, NULL);

    if (!bd_drvdata->muxc)
        return -ENOMEM;

    bd_drvdata->muxc->priv = ep;

    for (int i = 0; i < num_adapters; ++i) {
        ret = i2c_mux_add_adapter(bd_drvdata->muxc, 0, i);
        if (ret < 0) {
            dev_err(&bd_drvdata->pdev->dev, "Failed to add mux adapter for channel %d\n", i);
            return ret;
        }
    }

    return 0;
}

// get the i2c client for the endpoint
static int endpoint_get_i2c_client(struct endpoint *ep)
{
    struct i2c_board_info i2c_info;
    struct i2c_client *client;
    struct i2c_adapter *i2c_adapter;
    int ret, tries, delay_ms;
    int id = -ENXIO; /* for logging */

    if (bd_drvdata->muxc != NULL && ep->parent_io_card) {
        i2c_adapter = bd_drvdata->muxc->adapter[ep->parent_io_card->slot];
    } else {
        i2c_adapter = bd_drvdata->i2c_adapter;
    }

    if (!ep || !i2c_adapter) return -EINVAL;
    if (!ep->i2c_addr) {
        dev_err(&bd_drvdata->pdev->dev, "Endpoint %s missing i2c addr\n", ep->name);
        return -EINVAL;
    }
    if (!ep->cmds || ep->cmds->num_msgs == 0 || !ep->cmds->msgs) {
        dev_err(&bd_drvdata->pdev->dev, "Endpoint %s missing i2c commands\n", ep->name);
        return -EINVAL;
    }

    memset(&i2c_info, 0, sizeof(i2c_info));
    strscpy(i2c_info.type, ep->name, sizeof(i2c_info.type));
    i2c_info.addr  = ep->i2c_addr;
    i2c_info.flags = 0;

    client = i2c_new_client_device(i2c_adapter, &i2c_info);
    if (IS_ERR(client)) {
        ret = PTR_ERR(client);
        dev_err(&bd_drvdata->pdev->dev, "Failed new_client %s@0x%02x: %d\n",
                ep->name, ep->i2c_addr, ret);
        return ret;
    }

    /* Probe the device with bounded retries / backoff */
    tries = 7;        /* 1,2,4,8,16,32,64 ms ≈ 127 ms total */
    delay_ms = 1;

    while (tries-- > 0) {
        if (ep->cmds->msgs->reg_addr == ENDPOINT_CMD_MSG_ADDR_NONE)
            id = i2c_smbus_read_byte(client);
        else
            id = i2c_smbus_read_byte_data(client, ep->cmds->msgs->reg_addr);

        if (id >= 0) {
            dev_dbg(&bd_drvdata->pdev->dev,
                    "Discovered endpoint %s at 0x%02x (id=0x%02x)\n",
                    i2c_info.type, client->addr, id & 0xff);
            ep->i2c_client = client;
            return 0;
        }

        /* sleep between attempts; prefer usleep_range for <20ms */
        if (delay_ms < 20)
            usleep_range(delay_ms * 1000, delay_ms * 1000 + 1000);
        else
            msleep(delay_ms);

        if (delay_ms < 64)
            delay_ms <<= 1;
    }

    dev_err(&bd_drvdata->pdev->dev,
            "Endpoint %s at 0x%02x not responding (last err=%d)\n",
            ep->name, ep->i2c_addr, id);

    i2c_unregister_device(client);
    return (id < 0) ? id : -EIO;
}

static int configure_i2c_endpoint(struct endpoint *ep) 
{
    struct i2c_client *client;
    struct endpoint_cmd *cmd;
    struct endpoint_cmd_msg *msg;

    int ret;
    int i;

    if (ep->i2c_addr) {
        cmd = &ep->cmds[EP_CMD_TYPE_CFG];
        if (strcmp(cmd->name, "cmd_config")) {
            return 0;
        }

        // some endpoints have a custom configure func
        if (ep->ep_configure != NULL) {
            return ep->ep_configure(ep, cmd);
        }

        // set up the i2c_client
        endpoint_get_i2c_client(ep);
        if(ep->i2c_client == NULL) {
            dev_err(&bd_drvdata->pdev->dev, "Failed to set i2c client...");
            return -ENODEV;
        }

        client = ep->i2c_client;

        // otherwise use the generic one
        for (i = 0; i < cmd->num_msgs; ++i) {
            msg = &cmd->msgs[i];
            
            // i2c devices with no register table don't need configuring
            if (msg->reg_addr == ENDPOINT_CMD_MSG_ADDR_NONE) {
                break;
            }

            // need to be wary of LE vs BE devices for 16bit ops here...
            // account for this in the device config (i.e. don't do 16bit ops for BE devices)
            if (msg->op_size == ENDPOINT_CMD_MSG_OP_8BIT) {
                ret = i2c_smbus_write_byte_data(client, msg->reg_addr, (u8)msg->data);
            } else if (msg->op_size == ENDPOINT_CMD_MSG_OP_16BIT) {
                ret = i2c_smbus_write_word_data(client, msg->reg_addr, msg->data);
            } else {
                dev_err(&bd_drvdata->pdev->dev, "Unknown register type for register 0x%02x reg_data 0x%04x\n", msg->reg_addr, msg->data);
                return -EINVAL;
            }

            if (ret < 0) {
                dev_err(&bd_drvdata->pdev->dev, "Failed to write register 0x%04x with data 0x%04x to I2C device at 0x%02x\n",
                                                                            msg->reg_addr, msg->data, client->addr);
                return ret;
            }
        }
    }
    
    return 0;
}

// custom configuration callbacks (only for those who need one)
int ads7128_configure(struct endpoint *ep, struct endpoint_cmd *cmd)
{
    struct i2c_msg msg;
    u8 buf[3];

    int ret;
    int i;

    // set up the i2c_client
    endpoint_get_i2c_client(ep);
    if(ep->i2c_client == NULL) {
        dev_err(&bd_drvdata->pdev->dev, "Failed to set i2c client for ads7128...");
        return -ENODEV;
    }

    buf[0] = ADS7128_OPCODE_WRITE_REG;
    msg.addr = ep->i2c_client->addr;
    msg.flags = I2C_SMBUS_WRITE;
    msg.len = 3;
    msg.buf = buf;

    for (i = 0; i < cmd->num_msgs; ++i) {
        buf[1] = cmd->msgs[i].reg_addr;
        buf[2] = cmd->msgs[i].data;

        ret = i2c_transfer(ep->i2c_client->adapter, &msg, 1);
        if (ret < 0) {
            printk(KERN_ERR "ads7128_configure: failed transfer %i\n", i);
            return ret;
        }
    }

    return 0;
}

int tca9544_configure(struct endpoint *ep, struct endpoint_cmd *cmd)
{
    // set up the i2c_client
    endpoint_get_i2c_client(ep);
    if(ep->i2c_client == NULL) {
        dev_err(&bd_drvdata->pdev->dev, "Failed to set i2c client for tca9544...");
        return -ENODEV;
    }

    // configure the mux adapters
    return configure_i2c_mux_adapters(ep);
}

int ep9512t_configure(struct endpoint *ep, struct endpoint_cmd *cmd)
{
    struct i2c_client *client;
    struct endpoint_cmd_msg *msg;

    int ret;
    int i;

    // ep9512t needs extra time on a hard power cycle. 
    msleep(250);

    // set up the i2c_client
    endpoint_get_i2c_client(ep);
    if(ep->i2c_client == NULL) {
        dev_err(&bd_drvdata->pdev->dev, "Failed to set i2c client for ep9512t...");
        return -ENODEV;
    }

    client = ep->i2c_client;

    for (i = 0; i < cmd->num_msgs; ++i) {
        msg = &cmd->msgs[i];

        ret = i2c_smbus_write_byte_data(client, msg->reg_addr, (u8)msg->data);
        if (ret < 0) {
            dev_err(&bd_drvdata->pdev->dev, "Failed to write register 0x%04x with data 0x%04x to EP9512t at 0x%02x\n",
                                                                        msg->reg_addr, msg->data, client->addr);
            return ret;
        }
    }

    return 0;
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
            printk(KERN_DEBUG "handle_irq: calling ep_handle_irq for agg_gpio %s\n", ep_gpio->name);
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

    ret = i2c_transfer(client->adapter, &msg, 1);
    if (ret < 0) {
        printk(KERN_ERR "tca9544_handle_irq: failed transfer\n");
        return ret;
    }

    // last 4 bits are irq mask
    irq_mask = *buf >> 4;
    for (int i = 0; i < 4; ++i) {
        if (irq_mask >> i & 1) {
            if (tca9544->gpios[i].linked_gpio == NULL) {
                printk(KERN_WARNING "tca9544_handle_irq: null linked gpio %s\n", tca9544->gpios[i].name);
                continue;
            }

            handle_irq(tca9544->gpios[i].linked_gpio);
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

    ret = i2c_transfer(client->adapter, msgs, 2);
    if (ret < 0) {
        return ret;
    }

    printk(KERN_DEBUG "tcal6408_handle_irq: rd_buf=0x%02x\n", *rd_buf);

    irq_mask = *rd_buf;

    for (int i = 0; i < 8; ++i) {
        if (irq_mask >> i & 1) {
            if (tcal6408->gpios[i].linked_gpio == NULL) {
                continue;
            }

            handle_irq(tcal6408->gpios[i].linked_gpio);
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

    ret = i2c_transfer(client->adapter, msgs, 2);
    if (ret < 0) {
        printk(KERN_ERR "tca9535_handle_irq: failed transfer\n");
        return ret;
    }

    irq_mask = ((u16)rd_buf[1] << 8) | rd_buf[0];

    // TODO account for different irq trigger_type polarities
    for (int i = 0; i < 8; ++i) {
        if (irq_mask >> i & 1) {
            if (tca9535->gpios[i].is_irq) {
                if (tca9535->gpios[i].linked_gpio == NULL) {
                    continue;
                }
                handle_irq(tca9535->gpios[i].linked_gpio);
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
    ret = i2c_transfer(client->adapter, rd_msgs, 2);
    if (ret < 0) {
        printk(KERN_ERR "ads7128_handle_irq: failed read EVENT_FLAG\n");
        return ret;
    }
    event_mask = *rd_data_buf;

    // nothing to do?
    if (!event_mask) {
        return 0;
    }

    // Read PIN_CFG once for ADC checks
    rd_opcode_buf[1] = ADS7128_REG_PIN_CFG;
    ret = i2c_transfer(client->adapter, rd_msgs, 2);
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

        gpio = &ads7128->gpios[channel];

        // Check ADC interrupt
        if (!(pin_cfg & (1 << channel))) {
            // analog input
            rd_opcode_buf[0] = ADS7128_OPCODE_READ_CONTIGUOUS_REG;
            rd_msgs[1].len = 2;
            rd_opcode_buf[1] = ADS7128_REG_RECENT_CH0_LSB + channel * 2;
            ret = i2c_transfer(client->adapter, rd_msgs, 2);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed read RECENT_CH0_LSB + %d\n", channel * 2);
                continue;
            }

            adc_value = *(u16 *)rd_data_buf; // 12-bit value (i think its 16bit...)
            gpio->value = adc_value;   // Store ADC value

            // Update thresholds (±32)
            new_high = adc_value > 0xffdf ? 0xffff : adc_value + 0x0020 ;
            new_low = adc_value < 0x0020 ? 0 : adc_value - 0x0020;

            if (new_high == 0xffff) {
                new_low = new_high - 0x0040;
            }
            if (new_low == 0) {
                new_high = 0x0040;
            }

            // Use word writes for high and low thresholds
            wr_buf[1] = ADS7128_REG_HIGH_TH_CH0 + channel * 4;
            wr_buf[2] = (u8)(new_high >> 8); // lower 4 bits are in HYSTERESIS_CHx reg
            ret = i2c_transfer(client->adapter, &wr_msg, 1);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed write HIGH_TH_CH0 + %d\n", channel * 4);
                continue;
            }
            wr_buf[1] = ADS7128_REG_LOW_TH_CH0 + channel * 4;
            wr_buf[2] = (u8)(new_low >> 8); // lower 4 bits are in HYSTERESIS_CHx reg
            ret = i2c_transfer(client->adapter, &wr_msg, 1);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed write LOW_TH_CH0 + %d\n", channel * 4);
                continue;
            }
        } else {
            printk(KERN_DEBUG "ads7128_handle_irq: in GPI handling\n");
            // Read GPIO value for input interrupts
            rd_opcode_buf[1] = ADS7128_REG_GPI_VALUE;
            ret = i2c_transfer(client->adapter, rd_msgs, 2);
            if (ret < 0) {
                printk(KERN_ERR "ads7128_handle_irq: failed read GPI_VALUE\n");
                return ret;
            }
            gpi_value = *rd_data_buf;

            printk(KERN_DEBUG "ads7128_handle_irq: rd_data_buf=0x%04x\n", *(u16 *)rd_data_buf);
            printk(KERN_DEBUG "ads7128_handle_irq: gpi_value=0x%02x\n", gpi_value);

            gpio->value = (gpi_value & (1UL << channel)) ? 1 : 0;
        }

        // clear event flag bits
        wr_buf[1] = ADS7128_REG_EVENT_HIGH_FLAG;
        wr_buf[2] = (u8)(1 << channel); // lower 4 bits are in HYSTERESIS_CHx reg
        ret = i2c_transfer(client->adapter, &wr_msg, 1);
        if (ret < 0) {
            printk(KERN_ERR "ads7128_handle_irq: failed write EVENT_HIGH_FLAG ch %d\n", channel);
            continue;
        }
        wr_buf[1] = ADS7128_REG_EVENT_LOW_FLAG;
        ret = i2c_transfer(client->adapter, &wr_msg, 1);
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

static int configure_gpio_interrupt(struct endpoint_gpio *ep_gpio)
{
    int ret;

    ep_gpio->irq_num = gpiod_to_irq(ep_gpio->desc);
    if (ep_gpio->irq_num < 0) {
        dev_err(&bd_drvdata->pdev->dev, "Failed to get IRQ number for GPIO %d\n", ep_gpio->num);
        return -EINVAL;
    }

    // Initialize workqueue if not already done
    if (!fusion_irq_wq) {
        fusion_irq_wq = create_singlethread_workqueue("fusion_irq");
        if (!fusion_irq_wq) {
            dev_err(&bd_drvdata->pdev->dev, "Failed to create workqueue\n");
            return -ENOMEM;
        }
    }

    // Use regular IRQ, defer to workqueue
    ret = request_irq(ep_gpio->irq_num, gpio_irq_handler,
                      ep_gpio->trigger_type | IRQF_ONESHOT,
                      ep_gpio->name, (void *)ep_gpio);
    if (ret) {
        dev_err(&bd_drvdata->pdev->dev, "Failed to request IRQ for GPIO %d\n", ep_gpio->num);
        return ret;
    }

    dev_dbg(&bd_drvdata->pdev->dev, "Configured GPIO %s num %d as interrupt with IRQ number %d\n", ep_gpio->name, ep_gpio->num, ep_gpio->irq_num);
    return 0;
}

static void configure_base_device_references(void)
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

static void configure_io_card_references(struct io_card *ic)
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

// crucial piece of "link_gpio()"
static int set_linked_or_aggregate_gpio(struct endpoint_gpio *ep_gpio, struct endpoint *parent_ep) 
{
    struct endpoint_gpio *parent_gpio;
    
    int i, j;

    for (i = 0; i < parent_ep->num_gpios; ++i) {
        parent_gpio = &parent_ep->gpios[i];

        if (!strcmp(parent_gpio->name, ep_gpio->name)) {
            if (ep_gpio->is_irq == false) {
                if (ep_gpio->aggregate_id != 0) {
                    // first, count how many gpios are aggregated
                    j = i;
                    while (ep_gpio->aggregate_id == parent_gpio->aggregate_id) {
                        parent_gpio = &parent_ep->gpios[j++];
                        if (j > parent_ep->num_gpios) {
                            break;
                        }
                    }

                    // allocate the memory for thos gpios
                    ep_gpio->aggregate_gpios = devm_kzalloc(&bd_drvdata->pdev->dev, sizeof(struct ep_gpio *) * (j - i - 1), GFP_KERNEL);
                    if (ep_gpio->aggregate_gpios == NULL) {
                        dev_err(&bd_drvdata->pdev->dev, "ENOMEM from aggregate gpio alloc in link_gpio!");
                        return -ENOMEM;
                    }

                    // reset the agg gpio and counter
                    parent_gpio = &parent_ep->gpios[i];
                    j = 0;

                    // now assign them
                    while (ep_gpio->aggregate_id == parent_gpio->aggregate_id) {
                        ep_gpio->num = parent_gpio->num;
                        ep_gpio->aggregate_gpios[j++] = parent_gpio;

                        dev_dbg(&bd_drvdata->pdev->dev, "Linking aggregate GPIO %s:%s to GPIO %s:%s\n", ep_gpio->parent_io_card ?
                                                                                            ep_gpio->parent_io_card->data.model :
                                                                                            ep_gpio->parent_endpoint->name,
                                                                                            ep_gpio->name,
                                                                                            parent_gpio->parent_io_card ? 
                                                                                            parent_gpio->parent_io_card->data.model : 
                                                                                            parent_gpio->parent_endpoint->name,
                                                                                            parent_gpio->name);

                        if (++i >= parent_ep->num_gpios) {
                            break;
                        }
                        parent_gpio = &parent_ep->gpios[i];
                    }

                    ep_gpio->num_aggregate_gpios = j; 

                    dev_dbg(&bd_drvdata->pdev->dev, "Successfully linked (%d) aggregate GPIOs to %s:%s\n", j, ep_gpio->parent_io_card ? 
                                                                                                    ep_gpio->parent_io_card->data.model : 
                                                                                                    ep_gpio->parent_endpoint->name,
                                                                                                    ep_gpio->name);
                    return 0;
                } else {
                    // link only with the correct io expander gpio
                    if (!parent_gpio->parent_endpoint || parent_gpio->parent_endpoint->ioexp_id != ep_gpio->ioexp_id) {                                                
                        return -1;
                    }
                    ep_gpio->linked_gpio = parent_gpio;
                    ep_gpio->num = parent_gpio->num;

                    dev_dbg(&bd_drvdata->pdev->dev, "Successfully linked %s:%s to %s:%s\n", ep_gpio->parent_io_card ? 
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
                        parent_gpio->aggregate_gpios = devm_kzalloc(&bd_drvdata->pdev->dev, sizeof(struct ep_gpio *), GFP_KERNEL);
                        if (parent_gpio->aggregate_gpios == NULL) {
                            dev_err(&bd_drvdata->pdev->dev, "ENOMEM from aggregate irq gpio array alloc in link_gpio!");
                            return -ENOMEM;
                        }

                        parent_gpio->num_aggregate_gpios = 1;
                    } else {
                        // get the existing pointer array size
                        size = parent_gpio->num_aggregate_gpios;

                        // resize the pointer array
                        parent_gpio->aggregate_gpios = devm_krealloc(&bd_drvdata->pdev->dev, ep_gpio->aggregate_gpios, sizeof(struct ep_gpio *) * (size + 1), GFP_KERNEL);
                        if (parent_gpio->aggregate_gpios == NULL) {
                            dev_err(&bd_drvdata->pdev->dev, "ENOMEM from aggregate irq gpio realloc in link_gpio!");
                            return -ENOMEM;
                        }

                        parent_gpio->num_aggregate_gpios += 1;
                    }
                    
                    parent_gpio->aggregate_gpios[size - 1] = ep_gpio;

                    dev_dbg(&bd_drvdata->pdev->dev, "Successfully linked aggregate irq %s:%s to %s:%s\n", parent_gpio->parent_io_card ? 
                                                                                                parent_gpio->parent_io_card->data.model : 
                                                                                                parent_gpio->parent_endpoint->name,
                                                                                                parent_gpio->name, ep_gpio->parent_io_card ?
                                                                                                ep_gpio->parent_io_card->data.model :
                                                                                                ep_gpio->parent_endpoint->name,
                                                                                                ep_gpio->name);
                    return 0;
                
                } else {
                    parent_gpio->linked_gpio = ep_gpio;

                    dev_dbg(&bd_drvdata->pdev->dev, "Successfully linked irq %s:%s to %s:%s\n", parent_gpio->parent_io_card ? 
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
// 1. exportable non-irq GPIOs link directly to the io expander pin
// 2. irq GPIOs link up from the physical irq pin to their sources
// 3. for aggregate gpios (links in aggregate_gpios):
// 3a. an exportable non-irq aggregated GPIO links to multiple io expander pins
// 3b. aggregated irq GPIOs are aggregated on an io_card gpio which links up to multiple endpoint gpios; physical gpio links up to the aggregated io_card gpio
// 
// NOTE: before link_gpio is called on any GPIO, ALL LOWER LEVEL GPIO's parent relationships MUST be populated by "configure_x_references()"
static void link_gpio(struct endpoint_gpio *ep_gpio) 
{
    struct base_device *bd = bd_drvdata->fusion_device;
    struct io_card *parent_ic;
    struct endpoint *parent_ep;
    struct endpoint *ep;

    int ret;
    int i;

    // irqs are never exported to sysfs
    // bail if non-irq is not set for export
    if (ep_gpio->is_irq == false && ep_gpio->export == false) {
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

        // just for non-irq IC gpios
        // Never need to search ic gpios. Only want to link to io expander gpio
        if (parent_ic && !ep_gpio->is_irq) {
            // search the ic endpoint gpios
            for (i = 0; i < parent_ic->num_eps; ++i) {
                ep = &parent_ic->endpoints[i];

                // if gpio is on an endpoint, don't search that endpoint's gpios
                if (parent_ep && !strcmp(parent_ep->name, ep->name)) {
                    continue;
                }

                ret = set_linked_or_aggregate_gpio(ep_gpio, ep);
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

            ret = set_linked_or_aggregate_gpio(ep_gpio, ep);
            if (!ret) {
                return;
            }
        }
    } else if (ep_gpio->type == EP_GPIO_TYPE_PHYS) {
        // physical gpios just need a base_device match
        for (i = 0; i < bd->num_gpios; ++i) {
            if (!strcmp(ep_gpio->name, bd->gpios[i].name)) {
                if (ep_gpio->is_irq == false) {
                    dev_dbg(&bd_drvdata->pdev->dev, "Successfully linked phys GPIO %s:%s to %s:%s", ep_gpio->parent_io_card ?
                                                                                        ep_gpio->parent_io_card->data.model :
                                                                                        ep_gpio->parent_endpoint->name,
                                                                                        ep_gpio->name, 
                                                                                        bd->data.model, bd->gpios[i].name);
                    ep_gpio->linked_gpio = &bd->gpios[i];
                } else if (ep_gpio->is_irq == true) {
                    dev_dbg(&bd_drvdata->pdev->dev, "Successfully linked phys GPIO irq %s:%s to %s:%s", bd->data.model, bd->gpios[i].name,
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

    dev_dbg(&bd_drvdata->pdev->dev, "link_gpio: no link for GPIO %s:%s", ep_gpio->parent_io_card ?
                                                                ep_gpio->parent_io_card->data.model :
                                                                ep_gpio->parent_endpoint ?
                                                                ep_gpio->parent_endpoint->name :
                                                                ep_gpio->parent_base_device->data.model,
                                                                ep_gpio->name);
}

static int configure_base_device_gpios(void)
{
    struct base_device *bd = bd_drvdata->fusion_device;
    struct endpoint *ep;
    struct endpoint_gpio *ep_gpio;

    int ret, i, j;

    // first mainboard gpios
    for (i = 0; i < bd->num_gpios; ++i) {
        ep_gpio = &bd->gpios[i];

        if (ep_gpio->type != EP_GPIO_TYPE_PHYS) {
            dev_err(&bd_drvdata->pdev->dev, "Invalid base device GPIO %s\n", ep_gpio->name);
            continue;
        }

        ep_gpio->desc = gpio_to_desc(ep_gpio->num);
        if (!ep_gpio->desc) {
            dev_err(&bd_drvdata->pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
            continue;
        }

        if (ep_gpio->is_irq) {
            ret = gpio_direction_input(ep_gpio->num);
            if (ret) {
                dev_err(&bd_drvdata->pdev->dev, "Failed to setup base device GPIO %s as input\n", ep_gpio->name);
                continue;
            }

            ret = configure_gpio_interrupt(ep_gpio);
            if (ret) {
                dev_err(&bd_drvdata->pdev->dev, "Failed to setup base device GPIO %s as interrupt\n", ep_gpio->name);
                continue;
            }
        } else {
            ret = devm_gpio_request(&bd_drvdata->pdev->dev, ep_gpio->num, ep_gpio->name);
            if (ret) {
                dev_err(&bd_drvdata->pdev->dev, "Failed to request base device GPIO %s\n", ep_gpio->name);
                continue;
            }

            if (ep_gpio->dir == EP_GPIO_DIR_O) {
                ret = gpio_direction_output(ep_gpio->num, ep_gpio->default_val);
            } else if (ep_gpio->dir == EP_GPIO_DIR_I) {
                ret = gpio_direction_input(ep_gpio->num);
            }

            if (ret) {
                dev_err(&bd_drvdata->pdev->dev, "Failed to configure base device GPIO %s direction\n", ep_gpio->name);
                continue;
            }
        }

        dev_dbg(&bd_drvdata->pdev->dev, "Configured base device GPIO %s\n", ep_gpio->name);
        
        ep_gpio->valid = true;
    }

    // then endpoint gpios
    for (i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];

        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            // link gpio before we check the links
            link_gpio(ep_gpio);

            dev_dbg(&bd_drvdata->pdev->dev, "Configuring base device gpio %s:%s", ep->name, ep_gpio->name);

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS && !ep_gpio->is_irq) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&bd_drvdata->pdev->dev, "GPIO desc is NULL for %s\n", ep_gpio->name);
                    continue;
                }
            }

            dev_dbg(&bd_drvdata->pdev->dev, "Configured GPIO %s:%s\n", ep->name, ep_gpio->name);
            
            ep_gpio->valid = true;
        }
    }    

    return 0;
}

// Real GPIO config and io exp configs done in base device
// Just validate and mark valid true
static int configure_io_card_gpios(struct io_card *ic) 
{
    struct endpoint *ep;
    struct endpoint_gpio *ep_gpio;

    int i, j;

    // first io card gpios
    for (i = 0; i < ic->num_gpios; ++i) {
        ep_gpio = &ic->gpios[i];

        link_gpio(ep_gpio);

        if (ep_gpio->type == EP_GPIO_TYPE_PHYS) {
            ep_gpio->desc = ep_gpio->linked_gpio->desc;
            if (!ep_gpio->desc) {
                dev_err(&bd_drvdata->pdev->dev, "GPIO %s:%s descriptor is NULL\n", ic->data.model, ep_gpio->name);
                continue;
            }
        }

        ep_gpio->valid = true;

        dev_dbg(&bd_drvdata->pdev->dev, "Successfully configured GPIO %s:%s\n", ic->data.model, ep_gpio->name);
    }

    // io_card endpoint gpios
    for (i = 0; i < ic->num_eps; ++i) {
        ep = &ic->endpoints[i];

        for (j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];

            link_gpio(ep_gpio);

            if (ep_gpio->ioexp_id > 0) {
                if (!ep_gpio->linked_gpio && !ep_gpio->aggregate_gpios) {
                    dev_err(&bd_drvdata->pdev->dev, "GPIO %s:%s:%s is missing a link to an IO Expander GPIO\n", ic->data.model,
                                                                                                    ep->name,
                                                                                                    ep_gpio->name);
                    continue;
                }
            }

            if (ep_gpio->type == EP_GPIO_TYPE_PHYS) {
                ep_gpio->desc = ep_gpio->linked_gpio->desc;
                if (!ep_gpio->desc) {
                    dev_err(&bd_drvdata->pdev->dev, "GPIO %s:%s:%s descriptor is NULL\n", ic->data.model, ep->name, ep_gpio->name);
                    continue;
                }
            }

            ep_gpio->valid = true;

            dev_dbg(&bd_drvdata->pdev->dev, "Successfully configured GPIO %s:%s:%s\n", ic->data.model, ep->name, ep_gpio->name);
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

static struct base_device *new_default_base_device(enum base_device_type bd_type) 
{
    struct base_device *bd;

    for (int i = 0; default_bd_types[i] != BD_TYPE_NONE; ++i) {
        if (bd_type == default_bd_types[i]) {
            bd = devm_kzalloc(&bd_drvdata->pdev->dev, sizeof(*default_bds[i]), GFP_KERNEL);
            if (bd == NULL) {
                break;
            }

            memcpy(bd, default_bds[i], sizeof(*bd));
            return bd;
        }
    }

    return NULL;
} 

static struct io_card *new_default_io_card(enum io_card_type ic_type) 
{
    struct io_card *ic;

    for (int i = 0; default_ic_types[i] != IC_TYPE_NONE; ++i) {
        if (ic_type == default_ic_types[i]) {
            ic = devm_kzalloc(&bd_drvdata->pdev->dev, sizeof(*default_ics[i]), GFP_KERNEL);
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
// TODO -- only used for lookup of EEPROMs on slot IO card arch devices!
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

        fusion_io_remove_sysfs_io_card(bd_drvdata->pdev, ic);
    }

    cleanup_gpios();
    
    if(bd_drvdata->muxc) {
        i2c_mux_del_adapters(bd_drvdata->muxc);
    }
    if(bd_drvdata->i2c_adapter) {
        i2c_put_adapter(bd_drvdata->i2c_adapter);
    }

    fusion_io_remove_sysfs_base(bd_drvdata->pdev);
}

static int fusion_io_probe(struct platform_device *pdev)
{
    struct base_device  *bd;
    struct io_card      *ic;
    struct endpoint     *ep;
    struct id_data      data;

    struct i2c_adapter  *i2c_adapter;

    bool has_slot_io;
    int i, j;
    int ret;

    // allocate drvdata, but we'll set it up after we know what device we are
    bd_drvdata = devm_kzalloc(&pdev->dev, sizeof(*bd_drvdata), GFP_KERNEL);
    if (!bd_drvdata) {
        return -ENOMEM;
    }

    bd_drvdata->pdev = pdev;


    i2c_adapter = i2c_get_adapter(I2C_ADAPTER);
    if (!i2c_adapter) {
        dev_err(&pdev->dev, "Failed to get I2C adapter %d\n", I2C_ADAPTER);
        return -ENODEV;
    }

    // TODO
    // Read IMX8 ROM for this. hardcode for now
    data.type = BD_TYPE_FUSION_C0;

    if (data.type >= BD_TYPE_FIXED_IO_START && data.type < BD_TYPE_FIXED_IO_END) {
        has_slot_io = false;
    } else {
        has_slot_io = true;
    }
    
    // set up the base_device
    bd = new_default_base_device(data.type);
    if (!bd) {
        dev_err(&pdev->dev, "No base_device static config match found for base_device type %d\n", data.type);
        ret = -EINVAL;
        goto error;
    }

    bd_drvdata->fusion_device = bd;

    // Set the private data 
    platform_set_drvdata(pdev, bd_drvdata);
    
    strcpy(bd->data.sn, data.sn);
    bd_drvdata->i2c_adapter = i2c_adapter;
    dev_info(&pdev->dev, "Found config -- Model: %s, SN: %s", bd->data.model, bd->data.sn);

    // TODO: maybe we can have patches for HW revisions? apply here

    // now configure base device endpoints
    for (i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];

        if (!ep->i2c_addr) {
            continue;
        }

        dev_dbg(&pdev->dev, "Setting i2c client for base device endpoint %s...\n", ep->name);

        // configure i2c device
        ret = configure_i2c_endpoint(ep);
        if (ret) {
            dev_err(&pdev->dev, "Error configuring i2c endpoint %s\n", ep->name);
            goto error;
        }
            
        dev_dbg(&pdev->dev, "Successfully registered endpoint %s!\n", ep->name);
    }

    // set up parent references
    configure_base_device_references();

    // configure GPIOs
    ret = configure_base_device_gpios();
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
    if (has_slot_io == false) {
        /* We are a fixed IO device */
        dev_dbg(&pdev->dev, "Base device is fixed IO\n");

        // for all the io blocks on the device
        for (i = 0; i < bd->num_ics; ++i) {
            ic = &bd->io_cards[i];

            // set up parent references
            configure_io_card_references(ic);

            ic->slot = i;

            // for all the endpoints on that io block
            for (j = 0; j < ic->num_eps; ++j) {
                ep = &ic->endpoints[j];

                if (!ep->i2c_addr) {
                    continue;
                }

                dev_dbg(&pdev->dev, "Setting i2c client for block %s endpoint %s...\n", 
                                      ic->data.model, ep->name);

                // configure i2c device
                ret = configure_i2c_endpoint(ep);
                if (ret) {
                    
                    dev_warn(&pdev->dev, "Failed to configure I2C endpoint %s. Skipping.\n", ep->name);
                    continue; // Skip this endpoint but keep the rest alive
                }

                dev_dbg(&pdev->dev, "Successfully registered endpoint %s!\n", ep->name);
            }

            // configure GPIOs
            ret = configure_io_card_gpios(ic);
            if (ret) {
                goto error;
            }

            // create sysfs entries
            ret = fusion_io_create_sysfs_io_card(pdev, ic);
            if (ret) {
                goto error;
            }

            dev_info(&pdev->dev, "Successfully registered IO block %s!\n", ic->data.model);
        }
    } else if (has_slot_io == true) { /* we are a slot IO device */
        // go through all slots
        for (i = 0; i < bd->num_ics; ++i) {
            ic = &bd->io_cards[i];

            if (ic->data.type != IC_TYPE_NONE) {
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
                endpoint_get_i2c_client(ep);
                
                if (ep->i2c_client) {
                    dev_dbg(&pdev->dev, "Found %s on io-card model %s, slot %d\n", 
                                                                    ep->name, 
                                                                    ic->data.model, 
                                                                    i);
                    break;
                }

                kfree(ep);
            }

            // if it's not there, assume no IO card in this slot
            if (ep == NULL || ep->i2c_client == NULL) {
                dev_dbg(&pdev->dev, "No IO card found on slot %d\n", i);
                ep = NULL;
                continue;
            }

            ret = configure_i2c_endpoint(ep);
            if (ret) {
                dev_err(&pdev->dev, "Error configuring endpoint %s\n", ep->name);
                goto error;
            }

            memset(&data, 0, sizeof(data));

            // Here we can pull device data from secure eeprom. 
            // TODO!!! crypto part, data size, address, etc
            // TODO: probably need read eeprom data commands for different sec eeproms
            // ret = i2c_smbus_read_i2c_block_data(i2c_client, 
            //                                     ep->cmds[EP_CMD_EEPROM_RD_DATA].msgs[0].reg_addr, 
            //                                     sizeof(data), 
            //                                     (char *)&data);

            if (ret < 0) {
                dev_err(&pdev->dev, "Bad I2C read of %s\n", ep->name);
                goto error;
            }

            // TODO need to set an endpoint for sec_eeprom?

            kfree(ep);
            ep = NULL;

            // then, check type against io_card table.
            ic = new_default_io_card(data.type);
            if (!ic) {
                continue;
            }

            // IDEA: maybe we can have patches for HW revisions? apply here

            ic->slot = i;

            // get endpoint i2c clients
            for (j = 0; j < ic->num_eps; ++j) {
                ep = &ic->endpoints[j];

                if (!ep->i2c_addr) {
                    continue;
                }

                dev_dbg(&pdev->dev, "Setting i2c client for card slot %d block %s endpoint %s...\n", 
                                                                ic->slot, ic->data.model, ep->name);
                
                ret = configure_i2c_endpoint(ep);
                if (ret) {
                    goto error;
                }

                dev_dbg(&pdev->dev, "Successfully registered endpoint %s!\n", ep->name);
            }

            configure_io_card_references(ic);

            ret = configure_io_card_gpios(ic);
            if (ret) {
                goto error;
            }

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
