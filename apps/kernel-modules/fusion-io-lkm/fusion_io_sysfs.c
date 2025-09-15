#include <linux/module.h>
#include <linux/slab.h>
#include <linux/sysfs.h>
#include <linux/swab.h>

#include "fusion-io.h"
#include "fusion-io-sysfs.h"

struct class *fusion_io_class;
static struct device *fusion_io_parent_dev;


/* gpio */
// todo aggregate physical gpios?
static ssize_t fusion_io_phys_gpio_show(struct device *dev,
					struct device_attribute *attr,
					char *buf)
{
	struct endpoint_gpio *ep_gpio = container_of(attr, struct endpoint_gpio, dev_attr);
	int value = 0;

	value = gpiod_get_value(ep_gpio->desc);

	return scnprintf(buf, PAGE_SIZE, "%d\n", value);
}

static ssize_t fusion_io_phys_gpio_store(struct device *dev,
					 struct device_attribute *attr,
					 const char *buf, size_t count)
{
	struct endpoint_gpio *ep_gpio = container_of(attr, struct endpoint_gpio, dev_attr);

	unsigned long new_val;
	int ret;

	ret = kstrtoul(buf, 0, &new_val);
	if (ret) {
		return ret;
	}

	gpiod_set_value(ep_gpio->desc, new_val ? 1 : 0);

	return count;
}

// need x_show_gpio for all io expanders x
static int tca9535_show_gpio(struct endpoint *tca9535)
{
	int value;

	value = i2c_smbus_read_word_data(tca9535->i2c_client,
					 TCA9535_REG_OUTPUT_PORT0);
	if (value < 0) {
		return value;
	}

	return (int)value;
}

static int tcal6408_show_gpio(struct endpoint *tcal6408)
{
	int value;

	value = i2c_smbus_read_byte_data(tcal6408->i2c_client,
					 TCAL6408_REG_OUTPUT_PORT);

	return value;
}

static int ads7128_show_gpio(struct endpoint *ads7128, u8 pin_num, bool *is_adc)
{
    int value;
    struct endpoint_gpio *gpio = &ads7128->gpios[pin_num - 1]; // Data pins are first
    struct i2c_client *client = ads7128->i2c_client;
	struct i2c_msg msgs[2];
    u8 rd_opcode_buf[2];
    u8 rd_data_buf[1];
	int ret;

    rd_opcode_buf[0] = ADS7128_OPCODE_READ_REG;
    msgs[0].addr = client->addr;
    msgs[0].flags = I2C_SMBUS_WRITE;
    msgs[0].len = 2;
    msgs[0].buf = rd_opcode_buf;

    rd_data_buf[0] = ADS7128_OPCODE_READ_REG;
    msgs[1].addr = client->addr;
    msgs[1].flags = I2C_SMBUS_READ;
    msgs[1].len = 1;
    msgs[1].buf = rd_data_buf;

    // Read alert status for ADC interrupts
    rd_opcode_buf[1] = ADS7128_REG_PIN_CFG;
    ret = i2c_transfer(client->adapter, msgs, 2);
    if (ret < 0) {
        printk(KERN_ERR "ads7128_configure: failed read EVENT_FLAG\n");
        return ret;
    }

    *is_adc = (*rd_data_buf & (1U << (pin_num - 1))) == 0;

    value = gpio->value; // Directly use cached value

    return value;
}

static ssize_t fusion_io_virt_gpio_show(struct device *dev,
					struct device_attribute *attr,
					char *buf)
{
	struct endpoint_gpio *ep_gpio = container_of(attr, struct endpoint_gpio, dev_attr);
	struct endpoint *ep;

	bool adc_value = false;

	int value = 0;
	u16 mask = 0;

	// create a bitmask for the bits we care about
	// if we have aggregate gpios, we're on an endpoint
	// and we're pointing back to the gpio control device, e.g. io expander
	if (ep_gpio->aggregate_id != 0) {
		struct endpoint_gpio *agg_gpio;

		if (ep_gpio->num_aggregate_gpios == 0 || ep_gpio->aggregate_gpios == NULL) {
			dev_err(dev, "exported ep_gpio %s has aggregate_id %d but no aggregate_gpios!\n", ep_gpio->name, ep_gpio->aggregate_id);
			return -EINVAL;
		}

		for (int i = 0; i < ep_gpio->num_aggregate_gpios; ++i) {
			agg_gpio = ep_gpio->aggregate_gpios[i];

			mask |= 1UL << (agg_gpio->num - 1);
		}
		ep = agg_gpio->parent_endpoint;
		// otherwise we're on the gpio control device, e.g. ADC
	} else {
		mask |= 1U << (ep_gpio->num - 1);
		if (ep_gpio->linked_gpio) {
			ep = ep_gpio->linked_gpio->parent_endpoint;
		} else {
			ep = ep_gpio->parent_endpoint;
		}
	}

	// read the gpio states
	switch (ep->type) {
	case EP_TYPE_IOEXP_TCA9535:
		value = tca9535_show_gpio(ep);
		if (value < 0) {
			dev_err(dev, "tca9535_show_gpio returned err %d", value);
			return value;
		}
		break;
	case EP_TYPE_IOEXP_TCAL6408:
		value = tcal6408_show_gpio(ep);
		if (value < 0) {
			dev_err(dev, "tcal6408_show_gpio returned err %d", value);
			return value;
		}
		break;
	case EP_TYPE_ADC_ADS7128:
		value = ads7128_show_gpio(ep, ep_gpio->num, &adc_value);
		if (value < 0) {
			dev_err(dev, "ads7128_show_gpio returned err %d", value);
			return value;
		}
		break;
	default:
		dev_warn(dev, "Unknown ep type in virt_gpio_show '%d'\n", ep->type);
		return -EINVAL;
	}

	// mask the register value with the bits we care about
	if (!adc_value) {
		value = (u16)value & mask;

		// keep shifting the value down until the first bit we care about is in the 1's place
		for (int i = 0; i < 16; ++i) {
			if (mask & 0x0001) {
				break;
			}

			mask >>= 1;
			value >>= 1;
		}
	}

	return scnprintf(buf, PAGE_SIZE, "%d\n", value);
}

// need x_store_gpio for all io expanders x
static int tca9535_store_gpio(struct endpoint *tca9535, u16 new_value, u16 mask)
{
	int ret;
	u16 old_value;

	ret = i2c_smbus_read_word_data(tca9535->i2c_client,
				       TCA9535_REG_OUTPUT_PORT0);
	if (ret < 0)
		return ret;

	old_value = (u16)ret;
	old_value &= ~mask;

	for (int i = 0; i < 16; ++i) {
		if (new_value == 0) {
			break;
		} else if (mask & 0x0001) {
			break;
		}

		mask >>= 1;
		new_value <<= 1;
	}

	new_value |= old_value;

	ret = i2c_smbus_write_word_data(tca9535->i2c_client,
					TCA9535_REG_OUTPUT_PORT0, new_value);

	return ret;
}

static int tcal6408_store_gpio(struct endpoint *tcal6408, u8 new_value, u8 mask)
{
	int ret;
	u8 old_value;

	ret = i2c_smbus_read_byte_data(tcal6408->i2c_client,
				       TCAL6408_REG_OUTPUT_PORT);
	if (ret < 0)
		return ret;

	old_value = (u8)ret;
	old_value &= ~mask;

	for (int i = 0; i < 8; ++i) {
		if (new_value == 0) {
			break;
		} else if (mask & 0x0001) {
			break;
		}

		mask >>= 1;
		new_value <<= 1;
	}

	new_value |= old_value;

	ret = i2c_smbus_write_byte_data(tcal6408->i2c_client,
					TCAL6408_REG_OUTPUT_PORT, new_value);

	return ret;
}

static ssize_t fusion_io_virt_gpio_store(struct device *dev,
					 struct device_attribute *attr,
					 const char *buf, size_t count)
{
	struct endpoint_gpio *ep_gpio = container_of(attr, struct endpoint_gpio, dev_attr);
	struct endpoint *ep;

	int num_bits;
	int ret;

	unsigned long new_value;
	u16 mask = 0x0000;

	ret = kstrtoul(buf, 0, &new_value);
	if (ret)
		return ret;

	// create a bitmask for the bits we care about
	// if we have linked and aggregate gpios, we're on an endpoint
	// and we're pointing back to the gpio control device, e.g. io expander
	if (ep_gpio->aggregate_id != 0) {
		struct endpoint_gpio *agg_gpio;

		if (ep_gpio->num_aggregate_gpios == 0 || ep_gpio->aggregate_gpios == NULL) {
			dev_err(dev, "exported ep_gpio %s has aggregate_id %d but no aggregate_gpios!\n", ep_gpio->name, 
																							  ep_gpio->aggregate_id);
			return -EINVAL;
		}

		for (int i = 0; i < ep_gpio->num_aggregate_gpios; ++i) {
			agg_gpio = ep_gpio->aggregate_gpios[i];

			mask |= 1UL << (agg_gpio->num - 1);
		}

		ep = agg_gpio->parent_endpoint;

		num_bits = ep_gpio->num_aggregate_gpios;
		// otherwise we're on the gpio control device, e.g. ADC
	} else {
		mask |= 1UL << (ep_gpio->num - 1);

		if (ep_gpio->linked_gpio) {
			ep = ep_gpio->linked_gpio->parent_endpoint;
		} else {
			ep = ep_gpio->parent_endpoint;
		}

		num_bits = 1;
	}

	// if new_value is bigger than max possible val, clamp
    if (new_value >= (1UL << num_bits)) {
        new_value = (1UL << num_bits) - 1;
    }

	switch (ep->type) {
	case EP_TYPE_IOEXP_TCA9535:
		ret = tca9535_store_gpio(ep, new_value, mask);
		if (ret < 0) {
			dev_err(dev, "tca9535_store_gpio returned err %d", ret);
		}
		break;
	case EP_TYPE_IOEXP_TCAL6408:
		ret = tcal6408_store_gpio(ep, new_value, mask);
		if (ret < 0) {
			dev_err(dev, "tcal6408_store_gpio returned err %d", ret);
		}
		break;
	case EP_TYPE_ADC_ADS7128:
		dev_warn(dev, "Control GPOs with ctl_gpiox pins\n");
		break;
	default:
		dev_warn(dev, "Unknown ep type in virt_gpio_store '%d'\n", ep->type);
		return -EINVAL;
	}

	return count;
}

/* command */
static ssize_t ads7128_cmd_regop(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    struct endpoint_cmd *ep_cmd = container_of(attr, struct endpoint_cmd, dev_attr);
    struct endpoint *ep = dev_get_drvdata(dev);
    struct i2c_client *client = ep->i2c_client;
    unsigned int reg_addr, value;
    u8 wr_buf[3];
    u8 rd_opcode_buf[2];
    u8 rd_data_buf[1];
    struct i2c_msg wr_msg = {
        .addr = client->addr,
        .flags = 0,
        .buf = wr_buf,
        .len = 3
    };
    struct i2c_msg rd_msgs[2] = {
        { .addr = client->addr, .flags = 0, .buf = rd_opcode_buf, .len = 2 },
        { .addr = client->addr, .flags = I2C_M_RD, .buf = rd_data_buf, .len = 1 }
    };
    int ret;

    if (!client)
        return -ENODEV;

    // Parse input: "<reg_addr> <value>" for write, "<reg_addr>" for read
    if (sscanf(buf, "%x %x", &reg_addr, &value) == 2) {
        // Write operation
        wr_buf[0] = ADS7128_OPCODE_WRITE_REG; // Opcode 0x08
        wr_buf[1] = reg_addr;
        wr_buf[2] = value;
        ret = i2c_transfer(client->adapter, &wr_msg, 1);
        if (ret < 0)
            return ret;
        ep_cmd->i2c_cmds[0].data_mask = value; // Store for show
    } else if (sscanf(buf, "%x", &reg_addr) == 1) {
        // Read operation
        rd_opcode_buf[0] = ADS7128_OPCODE_READ_REG; // Opcode 0x10
        rd_opcode_buf[1] = reg_addr;
        ret = i2c_transfer(client->adapter, rd_msgs, 2);
        if (ret < 0)
            return ret;
        ep_cmd->i2c_cmds[0].data_mask = rd_data_buf[0]; // Store for show
		printk(KERN_INFO "0x%02x\n", rd_data_buf[0]);
    } else {
        return -EINVAL; // Invalid format
    }

    return count;
}

static ssize_t ads7128_cmd_regop_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct endpoint_cmd *ep_cmd = container_of(attr, struct endpoint_cmd, dev_attr);
    return scnprintf(buf, PAGE_SIZE, "0x%02x\n", ep_cmd->i2c_cmds[0].data_mask);
}

static int fusion_io_create_sysfs_gpio(struct device *parent_dev,
                                       struct endpoint_gpio *ep_gpio)
{
    int ret;

    ep_gpio->dev_attr.attr.name = kasprintf(GFP_KERNEL, "%s", ep_gpio->name);
    if (!ep_gpio->dev_attr.attr.name) {
        return -ENOMEM;
    }

    switch(ep_gpio->type) {
        case EP_GPIO_TYPE_PHYS:
            if (ep_gpio->dir == EP_GPIO_DIR_O) {
                ep_gpio->dev_attr.attr.mode = 0664;
                ep_gpio->dev_attr.show  = fusion_io_phys_gpio_show; 
                ep_gpio->dev_attr.store = fusion_io_phys_gpio_store;
            } else {
                ep_gpio->dev_attr.attr.mode = 0444;
                ep_gpio->dev_attr.show  = fusion_io_phys_gpio_show;
                ep_gpio->dev_attr.store = NULL;
            }
            break;
        case EP_GPIO_TYPE_VIRT:
            ep_gpio->dev_attr.attr.mode = 0664;
            ep_gpio->dev_attr.show  = fusion_io_virt_gpio_show;
            ep_gpio->dev_attr.store = fusion_io_virt_gpio_store;
            break;
        default:
            dev_warn(parent_dev, "Unknown ep_gpio type '%d'\n", ep_gpio->type);
            return -EINVAL;
    }
        
    /* Create the sysfs entry under the endpoint’s kobject */
    ret = device_create_file(parent_dev, &ep_gpio->dev_attr);
    if (ret) {
        kfree(ep_gpio->dev_attr.attr.name);
        ep_gpio->dev_attr.attr.name = NULL;
    }
    return ret;
}

static void fusion_io_remove_sysfs_gpio(struct device *dev, struct endpoint_gpio *ep_gpio)
{
    if (ep_gpio->dev_attr.attr.name) {
        /* Remove the attribute from the same endpoint_dev we added it to */
        device_remove_file(dev, &ep_gpio->dev_attr);

        /* Free the name we allocated with kasprintf() */
        kfree(ep_gpio->dev_attr.attr.name);
        ep_gpio->dev_attr.attr.name = NULL;
    }
}

static void fusion_io_remove_sysfs_gpios(struct device *endpoint_dev, struct endpoint *ep)
{
    int i;

    for (i = 0; i < ep->num_gpios; ++i) {
        struct endpoint_gpio *ep_gpio = &ep->gpios[i];

        if (ep_gpio->dev_attr.attr.name) {
            /* Remove the attribute from the same endpoint_dev we added it to */
            device_remove_file(endpoint_dev, &ep_gpio->dev_attr);

            /* Free the name we allocated with kasprintf() */
            kfree(ep_gpio->dev_attr.attr.name);
            ep_gpio->dev_attr.attr.name = NULL;
        }
    }
}

static int fusion_io_create_sysfs_cmd(struct device *parent_dev, struct endpoint_cmd *ep_cmd)
{
    int ret;

    ep_cmd->dev_attr.attr.name = kasprintf(GFP_KERNEL, "%s", ep_cmd->name);
    if (!ep_cmd->dev_attr.attr.name)
        return -ENOMEM;

    switch(ep_cmd->parent_endpoint->type) {
        case EP_TYPE_ADC_ADS7128:
			switch(ep_cmd->type) {
				case EP_CMD_TYPE_ADC_REGOP:
    				ep_cmd->dev_attr.attr.mode = 0664;
					ep_cmd->dev_attr.show  = ads7128_cmd_regop_show;
					ep_cmd->dev_attr.store = ads7128_cmd_regop;
					break;
				default:
					return -EINVAL;
			}
            break;
        default:
            return -EINVAL;
    }

    /* Create the sysfs entry under the endpoint’s kobject */
    ret = device_create_file(parent_dev, &ep_cmd->dev_attr);
    if (ret) {
        kfree(ep_cmd->dev_attr.attr.name);
        ep_cmd->dev_attr.attr.name = NULL;
    }

    return ret;
}

static void fusion_io_remove_sysfs_cmds(struct device *endpoint_dev, struct endpoint *ep)
{
	struct endpoint_cmd *ep_cmd;

    int i;

    for (i = 0; i < ep->num_cmds; ++i) {
        ep_cmd = &ep->cmds[i];

        if (ep_cmd->dev_attr.attr.name) {
            /* Remove the attribute from the same endpoint_dev we added it to */
            device_remove_file(endpoint_dev, &ep_cmd->dev_attr);

            /* Free the name we allocated with kasprintf() */
            kfree(ep_cmd->dev_attr.attr.name);
            ep_cmd->dev_attr.attr.name = NULL;
        }
    }
}


/* base device */
static ssize_t base_device_model_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct base_device *base_dev = dev_get_drvdata(dev);
    return sprintf(buf, "%s\n", base_dev->data.model);
}

static ssize_t base_device_type_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct base_device *base_dev = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", base_dev->data.type);
}

static ssize_t base_device_sn_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct base_device *base_dev = dev_get_drvdata(dev);
    return sprintf(buf, "%s\n", base_dev->data.sn);
}

static ssize_t endpoint_type_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct endpoint *ep = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", ep->type);
}

static ssize_t endpoint_name_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct endpoint *ep = dev_get_drvdata(dev);
    return sprintf(buf, "%s\n", ep->name);
}

static DEVICE_ATTR_RO(base_device_model);
static DEVICE_ATTR_RO(base_device_type);
static DEVICE_ATTR_RO(base_device_sn);
static DEVICE_ATTR_RO(endpoint_type);
static DEVICE_ATTR_RO(endpoint_name);

static struct attribute *base_device_attrs[] = {
    &dev_attr_base_device_model.attr,
    &dev_attr_base_device_type.attr,
    &dev_attr_base_device_sn.attr,
    NULL,
};

static const struct attribute_group base_device_group = {
    .attrs = base_device_attrs,
};

static struct attribute *endpoint_attrs[] = {
    &dev_attr_endpoint_type.attr,
    &dev_attr_endpoint_name.attr,
    NULL,
};

static const struct attribute_group endpoint_group = {
    .attrs = endpoint_attrs,
};

static void fusion_io_remove_parent_device(void)
{
    if (fusion_io_parent_dev) {
        device_unregister(fusion_io_parent_dev);
        fusion_io_parent_dev = NULL;
    }

    if (fusion_io_class) {
        class_destroy(fusion_io_class);
        fusion_io_class = NULL;
    }
}

int fusion_io_create_sysfs_base(struct platform_device *pdev)
{
    struct fusion_io_base_drvdata *drvdata = platform_get_drvdata(pdev);
    struct base_device *bd = drvdata->fusion_device;
	struct device *endpoint_dev;
	struct endpoint *ep;
	struct endpoint_gpio *ep_gpio;

    int ret;

    fusion_io_class = class_create("bosepro");
    if (IS_ERR(fusion_io_class)) {
        dev_err(&pdev->dev, "Failed to create fusion io class\n");
        return PTR_ERR(fusion_io_class);
    }

    fusion_io_parent_dev = device_create(fusion_io_class, NULL, MKDEV(0, 0), NULL, bd->data.model);
    if (IS_ERR(fusion_io_parent_dev)) {
        dev_err(&pdev->dev, "Failed to create sysfs parent device\n");
        ret = PTR_ERR(fusion_io_parent_dev);
        class_destroy(fusion_io_class);
        fusion_io_class = NULL;
        return ret;
    }

    dev_set_drvdata(fusion_io_parent_dev, bd);

    bd->sysfs_dev = fusion_io_parent_dev;

    ret = sysfs_create_group(&fusion_io_parent_dev->kobj, &base_device_group);
    if (ret) {
        dev_err(&pdev->dev, "Failed to create sysfs group for base device\n");
        device_unregister(fusion_io_parent_dev);
        fusion_io_parent_dev = NULL;
        class_destroy(fusion_io_class);
        fusion_io_class = NULL;
        return ret;
    }

    for (int i = 0; i < bd->num_gpios; ++i) {
        ep_gpio = &bd->gpios[i];

        if (!ep_gpio->valid) {
            dev_dbg(&pdev->dev, "Invalid base GPIO %s in create_sysfs_base\n", ep_gpio->name);
            continue;
        } else if (ep_gpio->export == false) {
            continue;
        }

        ret = fusion_io_create_sysfs_gpio(fusion_io_parent_dev, ep_gpio);
        if (ret) {
            dev_err(fusion_io_parent_dev, "Failed to create sysfs for GPIO %s\n", ep_gpio->name);
            return ret;
        }
    }

    for (int i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];
        
		if (ep->export == false) {
            continue;
        }

        endpoint_dev = device_create(fusion_io_class, fusion_io_parent_dev, MKDEV(0, 0), NULL, "%s", ep->name);
        if (IS_ERR(endpoint_dev)) {
            dev_err(&pdev->dev, "Failed to create endpoint device %s\n", ep->name);
            ret = PTR_ERR(endpoint_dev);
            return ret;
        }

        dev_set_drvdata(endpoint_dev, ep);
        ep->sysfs_dev = endpoint_dev;

        ret = sysfs_create_group(&endpoint_dev->kobj, &endpoint_group);
        if (ret) {
            dev_err(&pdev->dev, "Failed to create sysfs group for endpoint %s\n", ep->name);
            return ret;
        }

        for (int j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];
            
			if (!ep_gpio->valid) {
                dev_dbg(&pdev->dev, "Invalid GPIO %s:%s in create_sysfs_base\n", ep->name, ep_gpio->name);
                continue;
            } else if (ep_gpio->export == false) {
                continue;
            }

            ret = fusion_io_create_sysfs_gpio(endpoint_dev, ep_gpio);
            if (ret) {
                dev_err(endpoint_dev, "Failed to create sysfs for GPIO %s:%s\n", ep->name, ep_gpio->name);
                return ret;
            }

			dev_dbg(&pdev->dev, "Sysfs entry created for GPIO %s:%s\n", ep->name, ep_gpio->name);
        }

		for (int j = 0; j < ep->num_cmds; ++j) {
            struct endpoint_cmd *ep_cmd = &ep->cmds[j];

			if (ep_cmd->export == false) {
                continue;
            } else if (ep_cmd->num_i2c_cmds == 0) {
				dev_err(endpoint_dev, "Can't create sysfs cmd for ep_cmd %s with no i2c_cmds\n", ep_cmd->name);
				continue;
			} else if (ep_cmd->i2c_cmds == NULL) {
				dev_err(endpoint_dev, "BAD ep_cmd %s with num_i2c_cmds but NULL pointer\n", ep_cmd->name);
				continue;
			}

            ret = fusion_io_create_sysfs_cmd(endpoint_dev, ep_cmd);
            if (ret) {
                dev_err(endpoint_dev, "Failed to create sysfs for cmd %s\n", ep_cmd->name);
                return ret;
            }
        }
    }

    dev_dbg(&pdev->dev, "Sysfs entries created for base device\n");
    return 0;
}

void fusion_io_remove_sysfs_base(struct platform_device *pdev)
{
    struct fusion_io_base_drvdata *drvdata = platform_get_drvdata(pdev);
    struct base_device *bd = drvdata->fusion_device;

    for (int i = 0; i < bd->num_gpios; ++i) {
        fusion_io_remove_sysfs_gpio(bd->sysfs_dev, &bd->gpios[i]);
    }

    for (int i = 0; i < bd->num_eps; ++i) {
        struct endpoint *ep = &bd->endpoints[i];
        if (ep->sysfs_dev) {
            fusion_io_remove_sysfs_gpios(ep->sysfs_dev, ep);
            fusion_io_remove_sysfs_cmds(ep->sysfs_dev, ep);

            sysfs_remove_group(&ep->sysfs_dev->kobj, &endpoint_group);
            device_unregister(ep->sysfs_dev);
            ep->sysfs_dev = NULL;
        }
    }

    sysfs_remove_group(&fusion_io_parent_dev->kobj, &base_device_group);
    fusion_io_remove_parent_device();
    dev_info(&pdev->dev, "Sysfs entries removed for base device\n");
}


/* io card */
static ssize_t io_card_model_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct io_card *ic = dev_get_drvdata(dev);
    return sprintf(buf, "%s\n", ic->data.model);
}

static ssize_t io_card_type_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct io_card *ic = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", ic->data.type);
}

static ssize_t io_card_sn_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct io_card *ic = dev_get_drvdata(dev);
    return sprintf(buf, "%s\n", ic->data.sn);
}

static ssize_t io_card_slot_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct io_card *ic = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", ic->slot);
}

static ssize_t io_card_num_inputs_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct io_card *ic = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", ic->num_inputs);  // Assuming `num_inputs` tracks input count
}

static ssize_t io_card_num_outputs_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct io_card *ic = dev_get_drvdata(dev);
    return sprintf(buf, "%d\n", ic->num_outputs);  // Assuming `num_outputs` tracks output count
}

static DEVICE_ATTR_RO(io_card_model);
static DEVICE_ATTR_RO(io_card_type);
static DEVICE_ATTR_RO(io_card_sn);
static DEVICE_ATTR_RO(io_card_slot);
static DEVICE_ATTR_RO(io_card_num_inputs);
static DEVICE_ATTR_RO(io_card_num_outputs);

static struct attribute *io_card_attrs[] = {
    &dev_attr_io_card_model.attr,
    &dev_attr_io_card_type.attr,
    &dev_attr_io_card_sn.attr,
    &dev_attr_io_card_slot.attr,
    NULL,
};

static const struct attribute_group io_card_group = {
    .attrs = io_card_attrs,
};

void fusion_io_remove_sysfs_io_card(struct platform_device *pdev, struct io_card *ic)
{
    for (int i = 0; i < ic->num_gpios; ++i) {
        fusion_io_remove_sysfs_gpio(ic->sysfs_dev, &ic->gpios[i]);
    }

    for (int i = 0; i < ic->num_eps; ++i) {
        struct endpoint *ep = &ic->endpoints[i];
        if (ep->sysfs_dev) {
            /* Remove the per-GPIO attributes from that endpoint device */
            fusion_io_remove_sysfs_gpios(ep->sysfs_dev, ep);
            fusion_io_remove_sysfs_cmds(ep->sysfs_dev, ep);

            sysfs_remove_group(&ep->sysfs_dev->kobj, &endpoint_group);
            device_unregister(ep->sysfs_dev);
            ep->sysfs_dev = NULL;
        }
    }

    if (ic->sysfs_dev != NULL) {
        sysfs_remove_group(&ic->sysfs_dev->kobj, &io_card_group);
        if (ic->num_inputs > 0)
            sysfs_remove_file(&ic->sysfs_dev->kobj, &dev_attr_io_card_num_inputs.attr);
        if (ic->num_outputs > 0)
            sysfs_remove_file(&ic->sysfs_dev->kobj, &dev_attr_io_card_num_outputs.attr);
        device_unregister(ic->sysfs_dev);
        ic->sysfs_dev = NULL;
    }

    dev_info(&pdev->dev, "Sysfs entries removed for IO card %s\n", ic->data.model);
}

int fusion_io_create_sysfs_io_card(struct platform_device *pdev, struct io_card *ic)
{
    struct device *dev;
	struct device *endpoint_dev;
	struct endpoint *ep;
	struct endpoint_gpio *ep_gpio;

    int ret;

    dev = device_create(fusion_io_class, fusion_io_parent_dev, MKDEV(0, 0), NULL, "%s", ic->data.model);
    if (IS_ERR(dev)) {
        return PTR_ERR(dev);
	}

    dev_set_drvdata(dev, ic);
    ic->sysfs_dev = dev;

    ret = sysfs_create_group(&dev->kobj, &io_card_group);
    if (ret) {
        dev_err(dev, "Failed to create sysfs group for IO card\n");
        device_unregister(dev);
        return ret;
    }

    // Conditionally add input attributes if the card has inputs
    if (ic->num_inputs > 0) {
        ret = sysfs_create_file(&dev->kobj, &dev_attr_io_card_num_inputs.attr);
        if (ret) {
            return ret;
		}
    }

    // Conditionally add output attributes if the card has outputs
    if (ic->num_outputs > 0) {
        ret = sysfs_create_file(&dev->kobj, &dev_attr_io_card_num_outputs.attr);
        if (ret) {
            return ret;
		}
    }

	for (int i = 0; i < ic->num_gpios; ++i) {
        ep_gpio = &ic->gpios[i];

        if (!ep_gpio->valid) {
            dev_dbg(&pdev->dev, "Invalid GPIO %s:%s in create_sysfs_io_card\n", ic->data.model, ep_gpio->name);
            continue;
        } else if (ep_gpio->export == false) {
            continue;
        }

        ret = fusion_io_create_sysfs_gpio(dev, ep_gpio);
        if (ret) {
            dev_warn(dev, "Failed to create sysfs for GPIO %s:%s\n", ic->data.model, ep_gpio->name);
            return ret;
        }
    }

    for (int i = 0; i < ic->num_eps; ++i) {
        ep = &ic->endpoints[i];
        
		if (ep->export == false) {
            continue;
        }

        endpoint_dev = device_create(fusion_io_class, dev, MKDEV(0, 0), NULL, "%s", ep->name);
        if (IS_ERR(endpoint_dev)) {
            dev_err(dev, "Failed to create endpoint device %s\n", ep->name);
            ret = PTR_ERR(endpoint_dev);
            return ret;
        }

        dev_set_drvdata(endpoint_dev, ep);
        ep->sysfs_dev = endpoint_dev;

        ret = sysfs_create_group(&endpoint_dev->kobj, &endpoint_group);
        if (ret) {
            dev_err(dev, "Failed to create sysfs group for endpoint %s\n", ep->name);
            return ret;
        }

        for (int j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];
            
			if (!ep_gpio->valid) {
                dev_dbg(endpoint_dev, "Invalid GPIO %s:%s:%s in create_sysfs_io_card\n", ic->data.model, ep->name, ep_gpio->name);
                continue;
            } else if (ep_gpio->export == false) {
                continue;
            }

            ret = fusion_io_create_sysfs_gpio(endpoint_dev, ep_gpio);
            if (ret) {
                dev_err(endpoint_dev, "Failed to create sysfs for GPIO %s:%s:%s\n", ic->data.model, ep->name, ep_gpio->name);
                return ret;
            }
        }

        for (int j = 0; j < ep->num_cmds; ++j) {
            struct endpoint_cmd *ep_cmd = &ep->cmds[j];

			if (ep_cmd->export == false) {
                continue;
            } else if (ep_cmd->num_i2c_cmds == 0) {
				dev_err(endpoint_dev, "Can't create sysfs cmd for ep_cmd %s with no i2c_cmds\n", ep_cmd->name);
				continue;
			} else if (ep_cmd->i2c_cmds == NULL) {
				dev_err(endpoint_dev, "BAD ep_cmd %s with num_i2c_cmds but NULL pointer\n", ep_cmd->name);
				continue;
			}

            ret = fusion_io_create_sysfs_cmd(endpoint_dev, ep_cmd);
            if (ret) {
                dev_err(endpoint_dev, "Failed to create sysfs for cmd %s\n", ep_cmd->name);
                return ret;
            }
        }
    }

    dev_dbg(&pdev->dev, "Sysfs entries created for IO card %s\n", ic->data.model);
    return 0;
}
