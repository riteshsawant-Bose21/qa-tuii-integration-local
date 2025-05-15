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
int tca9535_show_gpio(struct endpoint *tca9535)
{
	int value;

	value = i2c_smbus_read_word_data(tca9535->i2c_client,
					 TCA9535_REG_OUTPUT_PORT0);
	if (value < 0) {
		return value;
	}

	return (int)__swab16((u16)value);
}

int tcal6408_show_gpio(struct endpoint *tcal6408)
{
	int value;

	value = i2c_smbus_read_byte_data(tcal6408->i2c_client,
					 TCAL6408_REG_OUTPUT_PORT);

	return value;
}

int ads7128_show_gpio(struct endpoint *ads7128, u8 pin_num, bool *is_adc)
{
    int value;
    struct endpoint_gpio *gpio = &ads7128->gpios[pin_num]; // Index 1-7 matches pin_num

    value = i2c_smbus_read_byte_data(ads7128->i2c_client, ADS7128_REG_PIN_CFG);
    if (value < 0) {
		return value;
	}

    *is_adc = (value & (1U << (pin_num - 1))) != 0;

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
	u16 mask = 0x0000;

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
		mask |= 1UL << (ep_gpio->num - 1);
		ep = ep_gpio->linked_gpio->parent_endpoint;
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
int tca9535_store_gpio(struct endpoint *tca9535, u16 new_value, u16 mask)
{
	int ret;
	u16 old_value;

	ret = i2c_smbus_read_word_data(tca9535->i2c_client,
				       TCA9535_REG_OUTPUT_PORT0);
	if (ret < 0)
		return ret;

	old_value = __swab16((u16)ret);
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
	new_value = __swab16(new_value);

	ret = i2c_smbus_write_word_data(tca9535->i2c_client,
					TCA9535_REG_OUTPUT_PORT0, new_value);

	return ret;
}

int tcal6408_store_gpio(struct endpoint *tcal6408, u8 new_value, u8 mask)
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

int ads7128_store_gpio(struct endpoint *ads7128, u8 new_value, u8 mask)
{
    int ret;
    u8 old_value, channel;

    // Read current GPO_VALUE from hardware
    ret = i2c_smbus_read_byte_data(ads7128->i2c_client, ADS7128_REG_GPO_VALUE);
    if (ret < 0) return ret;
    old_value = (u8)ret;

    // Update the single bit specified by mask
    if (new_value) {
        old_value |= mask;  // Set the bit
    } else {
        old_value &= ~mask; // Clear the bit
    }

    // Write back to hardware
    ret = i2c_smbus_write_byte_data(ads7128->i2c_client, ADS7128_REG_GPO_VALUE, old_value);
    if (ret < 0) return ret;

    // Update the cached value for the specific GPIO
    channel = __ffs(mask); // Find the bit position (0-7)
    ads7128->gpios[channel + 1].value = new_value & 1; // Update only this GPIO’s value

    return 0;
}

static ssize_t fusion_io_virt_gpio_store(struct device *dev,
					 struct device_attribute *attr,
					 const char *buf, size_t count)
{
	struct endpoint_gpio *ep_gpio =
		container_of(attr, struct endpoint_gpio, dev_attr);
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
			dev_err(dev, "exported ep_gpio %s has aggregate_id %d but no aggregate_gpios!\n", ep_gpio->name, ep_gpio->aggregate_id);
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

		ep = ep_gpio->linked_gpio->parent_endpoint;

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
		ret = ads7128_store_gpio(ep, new_value, mask);
		if (ret < 0) {
			dev_err(dev, "ads7128_store_gpio returned err %d", ret);
		}
		break;
	default:
		dev_warn(dev, "Unknown ep type in virt_gpio_store '%d'\n", ep->type);
		return -EINVAL;
	}

	return count;
}

/* command */
static ssize_t fusion_io_cmd_reg_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct endpoint_cmd *ep_cmd = container_of(attr, struct endpoint_cmd, dev_attr);
	struct endpoint *ep = dev_get_drvdata(dev);
	struct i2c_client *client = ep->i2c_client;
	int value;
	u16 data;

	if (!client) {
		return -ENODEV;
	}

	if (ep_cmd->i2c_cmds[0].reg_addr == I2C_REG_DATA_ADDR_NONE) {
		if (ep_cmd->i2c_cmds[0].op_size == I2C_REG_DATA_OP_8BIT) {
			value = i2c_smbus_read_byte(client);
			if (value < 0) {
				return value;
			}

			data = (u8)value;
		} else {
			return -EINVAL;
		}
	} else {
		if (ep_cmd->i2c_cmds[0].op_size == I2C_REG_DATA_OP_8BIT) {
			value = i2c_smbus_read_byte_data(client, ep_cmd->i2c_cmds[0].reg_addr);
			if (value < 0) {
				return value;
			}

			data = (u8)value;
		} else if (ep_cmd->i2c_cmds[0].op_size == I2C_REG_DATA_OP_16BIT) {
			value = i2c_smbus_read_word_data(client, ep_cmd->i2c_cmds[0].reg_addr);
			if (value < 0) {
				return value;
			}

			data = __swab16((u16)value);
		} else {
			return -EINVAL;
		}
	}

	return scnprintf(buf, PAGE_SIZE, "%04x\n", data);
}

static ssize_t fusion_io_cmd_bool_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct endpoint_cmd *ep_cmd = container_of(attr, struct endpoint_cmd, dev_attr);
	struct endpoint *ep = dev_get_drvdata(dev);
	struct i2c_client *client = ep->i2c_client;
	int value;
	u16 data;

	if (!client) {
		return -ENODEV;
	}

	if (ep_cmd->i2c_cmds[0].reg_addr == I2C_REG_DATA_ADDR_NONE) {
		if (ep_cmd->i2c_cmds[0].op_size == I2C_REG_DATA_OP_8BIT) {
			value = i2c_smbus_read_byte(client);
			if (value < 0) {
				return value;
			}

			data = (u8)value;
		} else {
			return -EINVAL;
		}
	} else {
		if (ep_cmd->i2c_cmds[0].op_size == I2C_REG_DATA_OP_8BIT) {
			value = i2c_smbus_read_byte_data(
				client, ep_cmd->i2c_cmds[0].reg_addr);
			if (value < 0) {
				return value;
			}

			data = (u8)value;
		} else if (ep_cmd->i2c_cmds[0].op_size ==
			   I2C_REG_DATA_OP_16BIT) {
			value = i2c_smbus_read_word_data(
				client, ep_cmd->i2c_cmds[0].reg_addr);
			if (value < 0) {
				return value;
			}

			data = __swab16((u16)value);
		} else {
			return -EINVAL;
		}
	}

	data &= ep_cmd->i2c_cmds[0].data_mask;

	return scnprintf(buf, PAGE_SIZE, "%u\n", !!data);
}

static ssize_t fusion_io_cmd_bool_store(struct device *dev,
					struct device_attribute *attr,
					const char *buf, size_t count)
{
	struct endpoint_cmd *ep_cmd =
		container_of(attr, struct endpoint_cmd, dev_attr);
	struct endpoint *ep = dev_get_drvdata(dev);
	struct i2c_client *client = ep->i2c_client;

	u8 og_val;
	u16 data_mask;
	unsigned long on_off;
	int ret;

	if (!client)
		return -ENODEV;

	ret = kstrtoul(buf, 0, &on_off);
	if (ret)
		return ret;

	// Suppose each state is in ep_cmd->i2c_cmds[on_off], so we need at least 2 entries
	if (on_off > 1) {
		dev_warn(dev, "Invalid bool state: %lu\n", on_off);
		return -EINVAL;
	}

	// Now pick the i2c_reg_data for this state
	for (int i = 0; i < ep_cmd->num_i2c_cmds; ++i) {
		struct i2c_reg_data *rd = &ep_cmd->i2c_cmds[i];

		data_mask = on_off ? rd->data_mask : ~rd->data_mask;

		if (rd->op_size == I2C_REG_DATA_OP_8BIT) {
			ret = i2c_smbus_read_byte_data(client, rd->reg_addr);
			if (ret < 0) {
				return ret;
			}

			og_val = (u8)ret;
			data_mask = on_off ? (u8)data_mask | og_val :
					     (u8)data_mask & og_val;
			ret = i2c_smbus_write_byte_data(client, rd->reg_addr,
							(u8)data_mask);
		} else if (rd->op_size == I2C_REG_DATA_OP_16BIT) {
			ret = i2c_smbus_read_word_data(client, rd->reg_addr);
			if (ret < 0)
				return ret;

			og_val = __swab16((u16)ret);
			data_mask = on_off ? data_mask | og_val :
					     data_mask & og_val;
			ret = i2c_smbus_write_word_data(client, rd->reg_addr,
							__swab16(data_mask));
		} else {
			dev_err(dev, "Unknown op_size: %d\n", rd->op_size);
			return -EINVAL;
		}
	}

	if (ret < 0)
		return ret;

	return count;
}

static ssize_t fusion_io_cmd_reg_store(struct device *dev,
				       struct device_attribute *attr,
				       const char *buf, size_t count)
{
	struct endpoint_cmd *ep_cmd =
		container_of(attr, struct endpoint_cmd, dev_attr);
	struct endpoint *ep = dev_get_drvdata(dev);
	struct i2c_client *client = ep->i2c_client;
	int ret;

	if (!client)
		return -ENODEV;

	for (int i = 0; i < ep_cmd->num_i2c_cmds; ++i) {
		struct i2c_reg_data *rd = &ep_cmd->i2c_cmds[i];

		if (rd->op_size == I2C_REG_DATA_OP_8BIT) {
			ret = i2c_smbus_write_byte_data(client, rd->reg_addr,
							(u8)rd->data_mask);
		} else if (rd->op_size == I2C_REG_DATA_OP_16BIT) {
			ret = i2c_smbus_write_word_data(
				client, rd->reg_addr, __swab16(rd->data_mask));
		} else {
			dev_err(dev, "Unknown op_size: %d\n", rd->op_size);
			return -EINVAL;
		}
		if (ret < 0)
			return ret;
	}

	return count;
}

static int fusion_io_create_sysfs_gpio(struct device *parent_dev,
                                       struct endpoint_gpio *ep_gpio)
{
    int ret;

    ep_gpio->dev_attr.attr.name = kasprintf(GFP_KERNEL, "%s", ep_gpio->name);
    if (!ep_gpio->dev_attr.attr.name) {
        return -ENOMEM;
    }

    /* Permissions: read/write by owner */
    ep_gpio->dev_attr.attr.mode = 0664;

    switch(ep_gpio->type) {
        case EP_GPIO_TYPE_PHYS:
            ep_gpio->dev_attr.show  = fusion_io_phys_gpio_show;
            ep_gpio->dev_attr.store = fusion_io_phys_gpio_store;
            break;
        case EP_GPIO_TYPE_VIRT:
            // check that the gpio has a linked gpio
            if (ep_gpio->linked_gpio == NULL && ep_gpio->aggregate_gpios == NULL) {
                dev_err(parent_dev, "Virtual gpio %s does not have linked/aggregate gpio(s).\n", ep_gpio->name);
                return -EINVAL;
            }

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

static ssize_t ads7128_cmd_config_pins_store(struct device *dev, struct device_attribute *attr,
                                             const char *buf, size_t count)
{
    struct endpoint_cmd *ep_cmd = container_of(attr, struct endpoint_cmd, dev_attr);
    struct endpoint *ep = dev_get_drvdata(dev);
    struct i2c_client *client = ep->i2c_client;
    unsigned long bitmap;
    int ret, channel;

    if (!client) return -ENODEV;

    ret = kstrtoul(buf, 0, &bitmap);
    if (ret) return ret;
    if (bitmap > 0xFF) return -EINVAL; // 8-bit max

    if (strcmp(ep_cmd->name, "configure_analog_pins") == 0) {
        // Set PIN_CFG to configure pins as analog
        ret = i2c_smbus_write_byte_data(client, ADS7128_REG_PIN_CFG, (u8)bitmap);
        if (ret < 0) return ret;

        // Ensure ADC is enabled (optional redundancy if cmd_config ran)
        ret = i2c_smbus_read_byte_data(client, ADS7128_REG_GENERAL_CFG);
        if (ret < 0) return ret;
        u8 gen_cfg = (u8)ret;
        if (!(gen_cfg & 0x01)) { // CNVST bit
            gen_cfg |= 0x01;
            ret = i2c_smbus_write_byte_data(client, ADS7128_REG_GENERAL_CFG, gen_cfg);
            if (ret < 0) return ret;
        }

        // Update gpio->dir for analog pins
        for (channel = 0; channel < 8; channel++) {
            if (bitmap & (1 << channel)) {
                ep->gpios[channel + 1].dir = EP_GPIO_DIR_I; // Analog input
            }
        }
    } else {
        // Read current GPIO_CFG
        ret = i2c_smbus_read_byte_data(client, ADS7128_REG_GPIO_CFG);
        if (ret < 0) return ret;
        u8 gpio_cfg = (u8)ret;

        if (strcmp(ep_cmd->name, "configure_gpo_pins") == 0) {
            gpio_cfg |= (u8)bitmap; // Set bits to 1 for GPO
            ret = i2c_smbus_write_byte_data(client, ADS7128_REG_GPIO_CFG, gpio_cfg);
            if (ret < 0) return ret;
            for (channel = 0; channel < 8; channel++) {
                if (bitmap & (1 << channel)) {
                    ep->gpios[channel + 1].dir = EP_GPIO_DIR_O;
                }
            }
        } else if (strcmp(ep_cmd->name, "configure_gpi_pins") == 0) {
            gpio_cfg &= ~(u8)bitmap; // Clear bits to 0 for GPI
            ret = i2c_smbus_write_byte_data(client, ADS7128_REG_GPIO_CFG, gpio_cfg);
            if (ret < 0) return ret;
            for (channel = 0; channel < 8; channel++) {
                if (bitmap & (1 << channel)) {
                    ep->gpios[channel + 1].dir = EP_GPIO_DIR_I;
                }
            }
        }
    }

    return count;
}

static int fusion_io_create_sysfs_cmd(struct device *parent_dev, struct endpoint_cmd *ep_cmd)
{
    int ret;

    ep_cmd->dev_attr.attr.name = kasprintf(GFP_KERNEL, "%s", ep_cmd->name);
    if (!ep_cmd->dev_attr.attr.name)
        return -ENOMEM;

    /* Permissions: read/write by owner */
    ep_cmd->dev_attr.attr.mode = 0664;

    switch(ep_cmd->parent_endpoint->type) {
        case EP_TYPE_ADC_ADS7128:
			switch(ep_cmd->type) {
				case EP_CMD_TYPE_ADC_GET_IRQS:
					ep_cmd->dev_attr.show  = fusion_io_cmd_reg_show;
					ep_cmd->dev_attr.store = NULL;
					break;
				case EP_CMD_TYPE_ADC_CFG_ANA_PINS:
				case EP_CMD_TYPE_ADC_CFG_GPI_PINS:
				case EP_CMD_TYPE_ADC_CFG_GPO_PINS:
					ep_cmd->dev_attr.show  = NULL;
            		ep_cmd->dev_attr.store = ads7128_cmd_config_pins_store;
					break;
				default:
					return -EINVAL;
			}
            break;
		case EP_TYPE_SEC_EEPROM_SHA104:
			switch(ep_cmd->type) {
				case EP_CMD_TYPE_EEPROM_WR:
					break;
				case EP_CMD_TYPE_EEPROM_RD:
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

void fusion_io_remove_parent_device(void)
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

    fusion_io_class = class_create(THIS_MODULE, "bosepro");
    if (IS_ERR(fusion_io_class)) {
        dev_err(&pdev->dev, "Failed to create fusion io class\n");
        return PTR_ERR(fusion_io_class);
    }

    fusion_io_parent_dev = device_create(fusion_io_class, NULL, MKDEV(0, 0), NULL, "fusion-io");
    if (IS_ERR(fusion_io_parent_dev)) {
        dev_err(&pdev->dev, "Failed to create sysfs parent device\n");
        ret = PTR_ERR(fusion_io_parent_dev);
        class_destroy(fusion_io_class);
        fusion_io_class = NULL;
        return ret;
    }

    dev_set_drvdata(fusion_io_parent_dev, bd);

    drvdata->sysfs_dev = fusion_io_parent_dev;

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
            dev_info(&pdev->dev, "Invalid base GPIO %s in create_sysfs_base\n", ep_gpio->name);
            continue;
        } else if (ep_gpio->export == EP_GPIO_NO_EXPORT) {
            continue;
        }

        ret = fusion_io_create_sysfs_gpio(fusion_io_parent_dev, ep_gpio);
        if (ret) {
            dev_err(fusion_io_parent_dev, "Failed to create sysfs for GPIO %s\n", ep_gpio->name);
            return ret;
        }
    }

	drvdata->endpoint_sysfs_devs = devm_kzalloc(&pdev->dev, sizeof(struct device *) * bd->num_eps, GFP_KERNEL);

    for (int i = 0; i < bd->num_eps; ++i) {
        ep = &bd->endpoints[i];
        
		if (ep->export == EP_NO_EXPORT) {
            continue;
        }

        endpoint_dev = device_create(fusion_io_class, fusion_io_parent_dev, MKDEV(0, 0), NULL, "endpoint%d", i);
        if (IS_ERR(endpoint_dev)) {
            dev_err(&pdev->dev, "Failed to create endpoint device %d\n", i);
            ret = PTR_ERR(endpoint_dev);
            return ret;
        }

        dev_set_drvdata(endpoint_dev, ep);
        drvdata->endpoint_sysfs_devs[i] = endpoint_dev;

        ret = sysfs_create_group(&endpoint_dev->kobj, &endpoint_group);
        if (ret) {
            dev_err(&pdev->dev, "Failed to create sysfs group for endpoint %d\n", i);
            return ret;
        }

        for (int j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];
            
			if (!ep_gpio->valid) {
                dev_info(&pdev->dev, "Invalid base GPIO %s in create_sysfs\n", ep_gpio->name);
                continue;
            } else if (ep_gpio->export == EP_GPIO_NO_EXPORT) {
                continue;
            }

            ret = fusion_io_create_sysfs_gpio(endpoint_dev, ep_gpio);
            if (ret) {
                dev_err(endpoint_dev, "Failed to create sysfs for GPIO %s\n", ep_gpio->name);
                return ret;
            }

			dev_info(&pdev->dev, "Sysfs entry created for GPIO %s\n", ep_gpio->name);
        }

		for (int j = 0; j < ep->num_cmds; ++j) {
            struct endpoint_cmd *ep_cmd = &ep->cmds[j];

			if (ep_cmd->export == EP_CMD_NO_EXPORT) {
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

    dev_info(&pdev->dev, "Sysfs entries created for base device\n");
    return 0;
}

void fusion_io_remove_sysfs_base(struct platform_device *pdev)
{
    struct fusion_io_base_drvdata *drvdata = platform_get_drvdata(pdev);
    struct base_device *bd = drvdata->fusion_device;

    for (int i = 0; i < bd->num_gpios; ++i) {
        fusion_io_remove_sysfs_gpio(drvdata->sysfs_dev, &bd->gpios[i]);
    }

	if (drvdata->endpoint_sysfs_devs != NULL) {
		for (int i = 0; i < bd->num_eps; ++i) {
			if (drvdata->endpoint_sysfs_devs[i]) {
				fusion_io_remove_sysfs_gpios(drvdata->endpoint_sysfs_devs[i], &bd->endpoints[i]);
				fusion_io_remove_sysfs_cmds(drvdata->endpoint_sysfs_devs[i], &bd->endpoints[i]);

				sysfs_remove_group(&drvdata->endpoint_sysfs_devs[i]->kobj, &endpoint_group);
				device_unregister(drvdata->endpoint_sysfs_devs[i]);
				drvdata->endpoint_sysfs_devs[i] = NULL;
			}
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

	if (ic->endpoint_sysfs_devs != NULL) {
		for (int i = 0; i < ic->num_eps; ++i) {
			if (ic->endpoint_sysfs_devs[i]) {
				/* Remove the per-GPIO attributes from that endpoint device */
				fusion_io_remove_sysfs_gpios(ic->endpoint_sysfs_devs[i], &ic->endpoints[i]);
				fusion_io_remove_sysfs_cmds(ic->endpoint_sysfs_devs[i], &ic->endpoints[i]);

				sysfs_remove_group(&ic->endpoint_sysfs_devs[i]->kobj, &endpoint_group);
				device_unregister(ic->endpoint_sysfs_devs[i]);
				ic->endpoint_sysfs_devs[i] = NULL;
			}
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

    dev_info(&pdev->dev, "Sysfs entries removed for IO card %s in slot %d\n", ic->data.model, ic->slot);
}

int fusion_io_create_sysfs_io_card(struct platform_device *pdev, struct io_card *ic)
{
    struct device *dev;
	struct device *endpoint_dev;
	struct endpoint *ep;
	struct endpoint_gpio *ep_gpio;

    int ret;

    dev = device_create(fusion_io_class, fusion_io_parent_dev, MKDEV(0, 0), NULL, "io_card%d", ic->slot);
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

	ic->endpoint_sysfs_devs = devm_kzalloc(&pdev->dev, sizeof(struct device *) * ic->num_eps, GFP_KERNEL);

    for (int i = 0; i < ic->num_eps; ++i) {
        ep = &ic->endpoints[i];
        
		if (ep->export == EP_NO_EXPORT) {
            continue;
        }

        endpoint_dev = device_create(fusion_io_class, dev, MKDEV(0, 0), NULL, "endpoint%d", i);
        if (IS_ERR(endpoint_dev)) {
            dev_err(dev, "Failed to create endpoint device %d\n", i);
            ret = PTR_ERR(endpoint_dev);
            return ret;
        }

        dev_set_drvdata(endpoint_dev, ep);
        ic->endpoint_sysfs_devs[i] = endpoint_dev;

        ret = sysfs_create_group(&endpoint_dev->kobj, &endpoint_group);
        if (ret) {
            dev_err(dev, "Failed to create sysfs group for endpoint %d\n", i);
            return ret;
        }

        for (int j = 0; j < ep->num_gpios; ++j) {
            ep_gpio = &ep->gpios[j];
            
			if (!ep_gpio->valid) {
                dev_info(endpoint_dev, "Invalid base GPIO %s in create_sysfs\n", ep_gpio->name);
                continue;
            } else if (ep_gpio->export == EP_GPIO_NO_EXPORT) {
                continue;
            }

            ret = fusion_io_create_sysfs_gpio(endpoint_dev, ep_gpio);
            if (ret) {
                dev_err(endpoint_dev, "Failed to create sysfs for GPIO %s\n", ep_gpio->name);
                return ret;
            }
        }

        for (int j = 0; j < ep->num_cmds; ++j) {
            struct endpoint_cmd *ep_cmd = &ep->cmds[j];

			if (ep_cmd->export == EP_CMD_NO_EXPORT) {
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

    dev_info(&pdev->dev, "Sysfs entries created for IO card in slot %d\n", ic->slot);
    return 0;
}
