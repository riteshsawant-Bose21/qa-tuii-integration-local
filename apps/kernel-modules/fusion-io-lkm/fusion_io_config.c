/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
* Copyright 2024 Bose Professional.
*/

#include "fusion-io.h"


// Default endpoints
const struct endpoint ep_aud_adc_taa5242 = {
    .type = EP_TYPE_AUD_ADC_TAA5242,
    .name = "aud-adc-taa5242",
    .addr_list = (unsigned short[]) { I2C_CLIENT_END },
    .num_gpios = 0,
    .gpios = NULL,  // No GPIOs, so explicitly NULL
    .num_cmds = 0,
    .cmds = NULL    // No commands, so explicitly NULL
};

const struct endpoint ep_aud_dac_tad5242 = {
    .type = EP_TYPE_AUD_DAC_TAD5242,
    .name = "aud-dac-tad5242",
    .addr_list = (unsigned short[]) { I2C_CLIENT_END },
    .num_gpios = 0,
    .gpios = NULL,
    .num_cmds = 0,
    .cmds = NULL
};

const struct endpoint ep_src_ak4137 = {
    .type = EP_TYPE_SRC_AK4137,
    .name = "src-ak4137",
    .addr_list = (unsigned short[]) { I2C_CLIENT_END },
    .num_gpios = 1,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_reset",
            .dir = EP_GPIO_DIR_O,
            .default_val = EP_GPIO_VAL_HI
        }
    },
    .num_cmds = 0,
    .cmds = NULL
};

const struct endpoint ep_hdmi_ep9512t = {
    .type = EP_TYPE_HDMI_EP9512T,
    .name = "hdmi-ep9512t",
    .addr_list = (unsigned short[]) { 0x3c, I2C_CLIENT_END },
    .num_gpios = 2,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_reset",
            .dir = EP_GPIO_DIR_O,
            .default_val = EP_GPIO_VAL_HI
        },
        {
            .name = "gpio_int",
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        }
    },
    .num_cmds = 0,
    .cmds = NULL
};

const struct endpoint ep_ioexp_tca9535 = {
    .type = EP_TYPE_IOEXP_TCA9535,
    .name = "ioexp-tca9535",
    .addr_list = (unsigned short[]) { 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, I2C_CLIENT_END },
    .num_gpios = 17,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_p00",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p01",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p02",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p03",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p04",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p05",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p06",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p07",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p10",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p11",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p12",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p13",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p14",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p15",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p16",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p17",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_int",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        }
    },
    .num_cmds = 0,
    .cmds = NULL
};

const struct endpoint ep_ioexp_tcal6408 = {
    .type = EP_TYPE_IOEXP_TCAL6408,
    .name = "ioexp-tcal6408",
    .addr_list = (unsigned short[]) { 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, I2C_CLIENT_END },
    .num_gpios = 9,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_p0",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p1",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p2",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p3",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p4",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p5",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p6",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_p7",
            .num = 0xff,
            .dir = EP_GPIO_DIR_I,
            .default_val = EP_GPIO_VAL_LO
        },
        {
            .name = "gpio_int",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        }
    },
    .num_cmds = 0,
    .cmds = NULL
};

const struct endpoint ep_adc_ads7128 = {
    .type = EP_TYPE_ADC_ADS7128,
    .name = "adc-ads7128",
    .addr_list = (unsigned short[]) { 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, I2C_CLIENT_END },
    .num_gpios = 1,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_int",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        }
    },
    .num_cmds = 0,
    .cmds = NULL
};

const struct endpoint ep_sec_eeprom_sha104 = {
    .name = "eeprom-sha104",
    .type = EP_TYPE_SEC_EEPROM_SHA104,
    .export = EP_EXPORT,
    .has_i2c = true,
    .addr_list = (unsigned short[]) { 0x41, I2C_CLIENT_END },
    .num_gpios = 0,
    .gpios = NULL,
    .num_cmds = 3,
    .cmds = (struct endpoint_cmd[]) {
        {
            .name = "cmd_config",
            .type = EP_CMD_TYPE_CFG,
            .export = EP_CMD_NO_EXPORT,
            .num_i2c_cmds = 1,
            .i2c_cmds = (struct i2c_reg_data[]) {
                {
                    .reg_addr = 0x00,
                    .op_size = I2C_REG_DATA_OP_16BIT,
                    .data_mask = 0xffff
                }
            }
        },
        {
            .name = "cmd_read_all",
            .type = EP_CMD_TYPE_EEPROM_RD,
            .export = EP_CMD_EXPORT,
            .num_i2c_cmds = 1,
            .i2c_cmds = (struct i2c_reg_data[]) {
                {
                    .reg_addr = 0x00,
                    .op_size = I2C_REG_DATA_OP_16BIT,
                    .data_mask = 0xffff
                }
            }
        },
        {
            .name = "cmd_write",
            .type = EP_CMD_TYPE_EEPROM_WR,
            .export = EP_CMD_EXPORT,
            .num_i2c_cmds = 1,
            .i2c_cmds = (struct i2c_reg_data[]) {
                {
                    .reg_addr = 0x00,
                    .op_size = I2C_REG_DATA_OP_16BIT,
                    .data_mask = 0xffff
                }
            }
        }
    }
};

const struct endpoint ep_eeprom_m24c32 = {
    .type = EP_TYPE_EEPROM_M24C32,
    .name = "eeprom-m24c02",  // Note: Name mismatch with type, should be "eeprom-m24c32"?
    .addr_list = (unsigned short[]) { 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, I2C_CLIENT_END },
    .num_gpios = 1,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_wc",
            .num = 0xff,
            .dir = EP_GPIO_DIR_O,
            .default_val = EP_GPIO_VAL_HI
        }
    },
    .num_cmds = 0,
    .cmds = NULL
};

const struct endpoint ep_i2csw_tca9544 = {
    .type = EP_TYPE_I2CSW_TCA9544,
    .name = "i2csw-tca9544",
    .addr_list = (unsigned short[]) { 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, I2C_CLIENT_END },
    .num_gpios = 5,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_int",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_int0",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_int1",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_int2",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_int3",
            .num = 0xff,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        }
    },
    .num_cmds = 0,
    .cmds = NULL
};

const enum endpoint_type default_ep_types[] = {
    EP_TYPE_AUD_ADC_TAA5242,
    EP_TYPE_AUD_DAC_TAD5242,
    EP_TYPE_SRC_AK4137,
    EP_TYPE_HDMI_EP9512T,
    EP_TYPE_IOEXP_TCA9535,
    EP_TYPE_IOEXP_TCAL6408,
    EP_TYPE_ADC_ADS7128,
    EP_TYPE_SEC_EEPROM_SHA104,
    EP_TYPE_EEPROM_M24C32,
    EP_TYPE_I2CSW_TCA9544,
    EP_TYPE_NONE
};

const struct endpoint *default_eps[] = {
    &ep_aud_adc_taa5242,
    &ep_aud_dac_tad5242,
    &ep_src_ak4137,
    &ep_hdmi_ep9512t,
    &ep_ioexp_tca9535,
    &ep_ioexp_tcal6408,
    &ep_adc_ads7128,
    &ep_sec_eeprom_sha104,
    &ep_eeprom_m24c32,
    &ep_i2csw_tca9544
};

// Default IO cards
const struct io_card ic_empty = {
    .data = {
        .type = IC_TYPE_NONE
    }
};

const struct io_card ic_unknown = {
    .data = {
        .type = IC_TYPE_UNKNOWN
    }
};

const enum io_card_type default_ic_types[] = {
    IC_TYPE_NONE
};

const struct io_card *default_ics[] = {
    &ic_empty
};

// Default base devices
const struct base_device bd_empty = {
    .data = {
        .type = BD_TYPE_NONE
    }
};

const struct base_device bd_fusion_var_proto = {
    .data = {
        .model = "fusion-var_proto1",
        .type = BD_TYPE_FUSION_VAR_PROTO,
        .ver_maj = EEPROM_DATA_VER_MAJ,
        .ver_min = EEPROM_DATA_VER_MIN
    },
    .has_slot_io = false,
    .num_gpios = 1,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_phantom_pwr",
            .num = 6,
            .type = EP_GPIO_TYPE_PHYS,
            .export = EP_GPIO_NO_EXPORT,
            .dir = EP_GPIO_DIR_O,
            .default_val = EP_GPIO_VAL_LO,
            .valid = false
        }
    },
    .num_eps = 0,
    .endpoints = NULL,
    .sec_eeprom = NULL,
    .data_eeprom = NULL,
    .i2c_sw = NULL,
    .pwr_io_exp = NULL,
    .num_ics = 1,
    .io_cards = (struct io_card[]) {
        {
            .data = {
                .model = "ana_block",
                .type = IC_TYPE_AN_IN_OUT,
                .ver_maj = EEPROM_DATA_VER_MAJ,
                .ver_min = EEPROM_DATA_VER_MIN
            },
            .slot = 0,
            .num_inputs = 1,
            .num_outputs = 1,
            .num_gpios = 0,
            .gpios = NULL,
            .num_eps = 1,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "aud_cod_wm8904",
                    .type = EP_TYPE_AUD_COD_WM8904,
                    .export = EP_EXPORT,
                    .has_i2c = true,
                    .addr_list = (unsigned short[]) { 0x1a, I2C_CLIENT_END },
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_phantom_pwr",
                            .type = EP_GPIO_TYPE_PHYS,
                            .export = EP_GPIO_EXPORT,
                            .dir = EP_GPIO_DIR_I,
                            .valid = true
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_config",
                            .type = EP_CMD_TYPE_CFG,
                            .export = EP_CMD_NO_EXPORT,
                            .num_i2c_cmds = 1,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                {
                                    .reg_addr = 0x00,
                                    .op_size  = I2C_REG_DATA_OP_16BIT,
                                    .data_mask = 0xff
                                }
                            }
                        }
                    }
                }
            }
        }
    }
};

const struct base_device bd_fusion_c0 = {
    .data = {
        .model = "fusion-c0",
        .sn = "tbd",
        .type = BD_TYPE_FUSION_C0
    },
    .has_slot_io = false,
    .num_gpios = 5,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_i2c4_int",
            .type = EP_GPIO_TYPE_PHYS,
            .export = EP_GPIO_NO_EXPORT,
            .num = 11,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_tca9544_int",
            .type = EP_GPIO_TYPE_PHYS,
            .export = EP_GPIO_NO_EXPORT,
            .num = 12,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_tcal6408_int",
            .type = EP_GPIO_TYPE_PHYS,
            .export = EP_GPIO_NO_EXPORT,
            .num = 13,
            .ioexp_id = 1,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_a_mute_out",
            .type = EP_GPIO_TYPE_PHYS,
            .export = EP_GPIO_NO_EXPORT,
            .num = 47,
            //.is_irq = true,
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "gpio_gpio2_16",
            .type = EP_GPIO_TYPE_PHYS,
            .export = EP_GPIO_EXPORT,
            .num = 48,
            .dir = EP_GPIO_DIR_O,
            .default_val = EP_GPIO_VAL_LO
        }
    },
    .sec_eeprom = (struct endpoint[]) {
        {
            .name = "ep-eeprom-sha104",
            .type = EP_TYPE_SEC_EEPROM_SHA104,
            .export = EP_EXPORT,
            .has_i2c = true,
            .addr_list = (unsigned short[]) { 0x41, I2C_CLIENT_END },
            .num_gpios = 0,
            .gpios = NULL,
            .num_cmds = 3,
            .cmds = (struct endpoint_cmd[]) {
                {
                    .name = "cmd_config",
                    .type = EP_CMD_TYPE_CFG,
                    .export = EP_CMD_NO_EXPORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr = 0x00,
                            .op_size = I2C_REG_DATA_OP_16BIT,
                            .data_mask = 0xffff
                        }
                    }
                },
                {
                    .name = "cmd_read_all",
                    .type = EP_CMD_TYPE_EEPROM_RD,
                    .export = EP_CMD_EXPORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr = 0x00,
                            .op_size = I2C_REG_DATA_OP_16BIT,
                            .data_mask = 0xffff
                        }
                    }
                },
                {
                    .name = "cmd_write",
                    .type = EP_CMD_TYPE_EEPROM_WR,
                    .export = EP_CMD_EXPORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr = 0x00,
                            .op_size = I2C_REG_DATA_OP_16BIT,
                            .data_mask = 0xffff
                        }
                    }
                }
            }
        }
    },
    .data_eeprom = (struct endpoint[]) {
        {
            .name = "ep-eeprom-m24c02",
            .type = EP_TYPE_EEPROM_M24C32,
            .export = EP_EXPORT,
            .has_i2c = true,
            .addr_list = (unsigned short[]) { 0x50, I2C_CLIENT_END },
            .num_gpios = 1,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_wc",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .dir = EP_GPIO_DIR_I
                }
            },
            .num_cmds = 3,
            .cmds = (struct endpoint_cmd[]) {
                {
                    .name = "cmd_config",
                    .type = EP_CMD_TYPE_CFG,
                    .export = EP_CMD_NO_EXPORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr = 0x00,
                            .op_size = I2C_REG_DATA_OP_16BIT,
                            .data_mask = 0xffff
                        }
                    }
                },
                {
                    .name = "cmd_read_all",
                    .type = EP_CMD_TYPE_EEPROM_RD,
                    .export = EP_CMD_EXPORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr = 0x00,
                            .op_size = I2C_REG_DATA_OP_16BIT,
                            .data_mask = 0xffff
                        }
                    }
                },
                {
                    .name = "cmd_write",
                    .type = EP_CMD_TYPE_EEPROM_WR,
                    .export = EP_CMD_EXPORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr = 0x00,
                            .op_size = I2C_REG_DATA_OP_16BIT,
                            .data_mask = 0xffff
                        }
                    }
                }
            }
        }
    },
    .i2c_sw = (struct endpoint[]) {
        {
            .name = "ep-i2csw-tca9544",
            .type = EP_TYPE_I2CSW_TCA9544,
            .export = EP_NO_EXPORT,
            .has_i2c = true,
            .addr_list = (unsigned short[]) { 0x70, I2C_CLIENT_END },
            .ep_handle_irq = tca9544_handle_irq,
            .num_gpios = 5,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_tca9544_int",
                    .type = EP_GPIO_TYPE_PHYS,
                    .export = EP_GPIO_NO_EXPORT,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_O
                },
                {
                    .name = "gpio_ana_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 1,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_I
                },
                {
                    .name = "gpio_hmcu_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 2,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_I
                },
                {
                    .name = "gpio_gpio_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 3,
                    .aggregate_id = 7,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_I
                },
                {
                    .name = "gpio_amp_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 4,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_I
                }
            },
            .num_cmds = 1,
            .cmds = (struct endpoint_cmd[]) {
                {
                    .name         = "cmd_discover",
                    .type         = EP_CMD_TYPE_I2CSW_SET_PORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr  = I2C_REG_DATA_ADDR_NONE
                        }
                    }
                }
            }
        }
    },
    .pwr_io_exp = (struct endpoint[]) {
        {
            .type = EP_TYPE_IOEXP_TCAL6408,
            .name = "ep-ioexp-tcal6408",
            .export = EP_NO_EXPORT,
            .has_i2c = true,
            .ioexp_id = 1,
            .addr_list = (unsigned short[]) { 0x20, I2C_CLIENT_END },
            .ep_handle_irq = tcal6408_handle_irq,
            .num_gpios = 9,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_tcal6408_int",
                    .type = EP_GPIO_TYPE_PHYS,
                    .export = EP_GPIO_NO_EXPORT,
                    .ioexp_id = 1,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_O
                },
                {
                    .name = "gpio_ana_3v3_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 1,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                },
                {
                    .name = "gpio_gpio_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 2,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                },
                {
                    .name = "gpio_hdmi_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 3,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                },
                {
                    .name = "gpio_hdmi_5v_en",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 4,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                },
                {
                    .name = "gpio_hdmi_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 5,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                },
                {
                    .name = "gpio_amp_stby",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 6,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                },
                {
                    .name = "gpio_amp_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 7,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                },
                {
                    .name = "gpio_ui_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .num = 8,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_HI
                }
            },
            .num_cmds = 1,
            .cmds = (struct endpoint_cmd[]) {
                {
                    .name = "cmd_config",
                    .type = EP_CMD_TYPE_CFG,
                    .export = EP_CMD_NO_EXPORT,
                    .num_i2c_cmds = 7,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        {
                            .reg_addr = TCAL6408_REG_POLARITY_INV,
                            .op_size = I2C_REG_DATA_OP_8BIT,
                            .data_mask = 0x00
                        },
                        {
                            .reg_addr = TCAL6408_REG_CONFIGURATION,
                            .op_size = I2C_REG_DATA_OP_8BIT,
                            .data_mask = 0x00  // all output
                        },
                        {
                            .reg_addr = TCAL6408_REG_OUTPUT_DR_STR0,
                            .op_size = I2C_REG_DATA_OP_8BIT,
                            .data_mask = 0xff  // full strength
                        },
                        {
                            .reg_addr = TCAL6408_REG_OUTPUT_DR_STR1,
                            .op_size = I2C_REG_DATA_OP_8BIT,
                            .data_mask = 0xff  // full strength
                        },
                        {
                            .reg_addr = TCAL6408_REG_INT_MASK_REG,
                            .op_size = I2C_REG_DATA_OP_8BIT,
                            .data_mask = 0xff  // all disabled
                        },
                        {
                            .reg_addr = TCAL6408_REG_OUTPUT_PORT_CFG_REG,
                            .op_size = I2C_REG_DATA_OP_8BIT,
                            .data_mask = 0x00  // push-pull
                        },
                        {
                            .reg_addr = TCAL6408_REG_OUTPUT_PORT,
                            .op_size = I2C_REG_DATA_OP_8BIT,
                            .data_mask = 0xff
                        }
                    }
                }
            }
        }
    },
    .num_eps = 0,
    .endpoints = NULL,
    .num_ics = 4,
    .io_cards = (struct io_card[]) {
        {
            .data = {
                .model = "block_ana",
                .sn = "n/a",
                .type = IC_TYPE_AN_IN_OUT
            },
            .slot = 0,
            .num_inputs = 6,
            .num_outputs = 4,
            .i2c_sw_channel = 1,
            .num_gpios = 2,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_ana_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .aggregate_id = 6,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_O
                },
                {
                    .name = "gpio_ana_3v3_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_I
                }
            },
            .num_eps = 7,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep-ioexp-tca9535-0",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .export = EP_NO_EXPORT,
                    .has_i2c = true,
                    .ioexp_id = 2,
                    .addr_list = (unsigned short[]) { 0x21, I2C_CLIENT_END },
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 17,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_ana_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .ioexp_id = 2,
                            .aggregate_id = 6,
                            .is_irq = true,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING,
                            .dir = EP_GPIO_DIR_O
                        },
                        {
                            .name = "gpio_gain_ch3_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 1,
                            .aggregate_id = 1,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch3_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 2,
                            .aggregate_id = 1,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch3_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 3,
                            .aggregate_id = 1,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch3_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 4,
                            .aggregate_id = 1,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch4_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 5,
                            .aggregate_id = 2,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch4_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 6,
                            .aggregate_id = 2,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch4_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 7,
                            .aggregate_id = 2,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch4_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 8,
                            .aggregate_id = 2,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch5_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 9,
                            .aggregate_id = 3,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch5_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 10,
                            .aggregate_id = 3,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch5_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 11,
                            .aggregate_id = 3,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch5_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 12,
                            .aggregate_id = 3,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch6_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 13,
                            .aggregate_id = 4,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch6_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 14,
                            .aggregate_id = 4,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch6_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 15,
                            .aggregate_id = 4,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch6_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 16,
                            .aggregate_id = 4,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_config",
                            .type = EP_CMD_TYPE_CFG,
                            .export = EP_CMD_NO_EXPORT,
                            .num_i2c_cmds = 2,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                {
                                    .reg_addr = TCA9535_REG_OUTPUT_PORT0,
                                    .op_size = I2C_REG_DATA_OP_16BIT,
                                    .data_mask = 0x0000
                                },
                                {
                                    .reg_addr = TCA9535_REG_CONFIGURATION0,
                                    .op_size = I2C_REG_DATA_OP_16BIT,
                                    .data_mask = 0x0000  // all outputs
                                }
                            }
                        }
                    }
                },
                {
                    .name = "ep-ioexp-tca9535-1",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .export = EP_NO_EXPORT,
                    .has_i2c = true,
                    .ioexp_id = 3,
                    .addr_list = (unsigned short[]) { 0x22, I2C_CLIENT_END },
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 7,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_ana_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .ioexp_id = 3,
                            .aggregate_id = 6,
                            .is_irq = true,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING,
                            .dir = EP_GPIO_DIR_O
                        },
                        {
                            .name = "gpio_php_en_ch3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 1,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_php_en_ch4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 2,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_php_en_ch5",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 3,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_php_en_ch6",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 4,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ana_15v_psw",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 5,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_HI
                        },
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 6,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_HI
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_config",
                            .type = EP_CMD_TYPE_CFG,
                            .export = EP_CMD_NO_EXPORT,
                            .num_i2c_cmds = 2,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                {
                                    .reg_addr = TCA9535_REG_OUTPUT_PORT0,
                                    .op_size = I2C_REG_DATA_OP_16BIT,
                                    .data_mask = 0x0010  // 15v_psw high
                                },
                                {
                                    .reg_addr = TCA9535_REG_CONFIGURATION0,
                                    .op_size = I2C_REG_DATA_OP_16BIT,
                                    .data_mask = 0x0030  // / 15v_psw & dac_mute high
                                }
                            }
                        }
                    }
                },
                {
                    .name = "ep-aud-in-chs-12",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = EP_EXPORT,
                    .has_i2c = false,
                    .in_ch_bm = 0x0003,
                    .num_gpios = 0,
                    .gpios = NULL,
                    .num_cmds = 0,
                    .cmds = NULL
                },
                {
                    .name = "ep-aud-in-chs-34",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = EP_EXPORT,
                    .has_i2c = false,
                    .in_ch_bm = 0x000c,
                    .num_gpios = 4,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch3_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .aggregate_id = 1,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_I
                        },
                        {
                            .name = "gpio_gain_ch4_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .aggregate_id = 2,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_I
                        },
                        {
                            .name = "gpio_php_en_ch3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_php_en_ch4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        }
                    },
                    .num_cmds = 0,
                    .cmds = NULL
                },
                {
                    .name = "ep-aud-in-chs-56",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = EP_EXPORT,
                    .has_i2c = false,
                    .in_ch_bm = 0x0030,
                    .num_gpios = 4,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch5_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .aggregate_id = 3,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_gain_ch6_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .aggregate_id = 4,
                            .ioexp_id = 2,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_php_en_ch5",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_php_en_ch6",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        }
                    },
                    .num_cmds = 0,
                    .cmds = NULL
                },
                {
                    .name = "ep-aud-out-chs-12",
                    .type = EP_TYPE_AUD_DAC_TAD5242,
                    .export = EP_EXPORT,
                    .has_i2c = false,
                    .out_ch_bm = 0x0003,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_I
                        }
                    },
                    .num_cmds = 0,
                    .cmds = NULL
                },
                {
                    .name = "ep-aud-out-chs-34",
                    .type = EP_TYPE_AUD_DAC_TAD5242,
                    .export = EP_EXPORT,
                    .has_i2c = false,
                    .out_ch_bm = 0x000c,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 3,
                            .dir = EP_GPIO_DIR_I
                        }
                    },
                    .num_cmds = 0,
                    .cmds = NULL
                },
            },
            .sec_eeprom = NULL,
            .data_eeprom = NULL
        },
        {
            .data = {
                .model = "block_hdmi",
                .sn = "n/a",
                .type = IC_TYPE_HDMI
            },
            .slot = 1,
            .i2c_sw_channel = 2,
            .num_gpios = 3,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_hdmi_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_I
                },
                {
                    .name = "gpio_hdmi_5v_en",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_I
                },
                {
                    .name = "gpio_hdmi_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_I
                }
            },
            .num_eps = 2,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep-src-ak4137",
                    .type = EP_TYPE_SRC_AK4137,
                    .export = EP_EXPORT,
                    .has_i2c = true,
                    .addr_list = (unsigned short[]) { 0x13, I2C_CLIENT_END },
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_hdmi_reset",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 1,
                            .dir = EP_GPIO_DIR_I
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_config",
                            .type = EP_CMD_TYPE_CFG,
                            .export = EP_CMD_NO_EXPORT,
                            .num_i2c_cmds = 1,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                {
                                    .reg_addr = AK4137_REG_PCM_CONT0,
                                    .op_size = I2C_REG_DATA_OP_8BIT,
                                    .data_mask = 0x13   //32 or 16bit, I2S justified
                                }
                            }
                        }
                    }
                },
                {
                    .name = "ep-hdmi-ep9512t",
                    .type = EP_TYPE_HDMI_EP9512T,
                    .export = EP_NO_EXPORT,
                    .has_i2c = true,
                    .addr_list = (unsigned short[]) { 0x3c, I2C_CLIENT_END },
                    .ep_handle_irq = ep9512t_handle_irq,
                    .num_gpios = 3,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_a_mute_out",
                            .type = EP_GPIO_TYPE_PHYS,
                            .export = EP_GPIO_EXPORT,
                            //.is_irq = true,
                            .dir = EP_GPIO_DIR_O
                        },
                        {
                            .name = "gpio_hmcu_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .is_irq = true,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING,
                            .dir = EP_GPIO_DIR_O
                        },
                        {
                            .name = "gpio_hdmi_reset",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .ioexp_id = 1,
                            .is_irq = false,
                            .dir = EP_GPIO_DIR_I,
                            .default_val = EP_GPIO_VAL_HI
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_config",
                            .type = EP_CMD_TYPE_CFG,
                            .export = EP_CMD_NO_EXPORT,
                            .num_i2c_cmds = 3,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                {
                                    .reg_addr  = EP9512T_REG_GENERAL_CTRL, // 0x10
                                    .op_size   = I2C_REG_DATA_OP_8BIT,
                                    // ARC_EN = 1, Audio_Path = 1, others 0
                                    // This is the default setting for EP9512T      
                                    .data_mask = 0x21                
                                },
                                {
                                    .reg_addr  = EP9512T_REG_TX_CTRL,    // 0x11
                                    .op_size   = I2C_REG_DATA_OP_8BIT,
                                    .data_mask = 0x00                  // All zero, clear all bits
                                    
                                },
                                {
                                    .reg_addr  = EP9512T_REG_AUDIO_CFG,  // 0x12
                                    .op_size   = I2C_REG_DATA_OP_8BIT,
                                    .data_mask = 0x01                  //  A_IN = 01 (I2S), others 0
                                }
                            }
                        }
                    }
                }
            }
        },
        {
            .data = {
                .model = "block_gpio",
                .sn = "n/a",
                .type = IC_TYPE_GPIO
            },
            .slot = 2,
            .i2c_sw_channel = 3,
            .num_gpios = 7,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_gpio_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .is_irq = true,
                    .aggregate_id = 7,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING,
                    .dir = EP_GPIO_DIR_O
                },
                {
                    .name = "gpio_gpio_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_LO
                },
                {
                    .name = "gpio_ctrl0_gpio0",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .aggregate_id = 1,
                    .ioexp_id = 4,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_LO
                },
                {
                    .name = "gpio_ctrl0_gpio1",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .aggregate_id = 2,
                    .ioexp_id = 4,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_LO
                },
                {
                    .name = "gpio_ctrl0_gpio2",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .aggregate_id = 3,
                    .ioexp_id = 4,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_LO
                },
                {
                    .name = "gpio_ctrl0_gpio3",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .aggregate_id = 4,
                    .ioexp_id = 4,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_LO
                },
                {
                    .name = "gpio_ctrl0_gpio4",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .aggregate_id = 5,
                    .ioexp_id = 4,
                    .dir = EP_GPIO_DIR_O,
                    .default_val = EP_GPIO_VAL_LO
                }
            },
            .num_eps = 2,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep-ioexp-tca9535-2",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .export = EP_NO_EXPORT,
                    .has_i2c = true,
                    .ioexp_id = 4,
                    .addr_list = (unsigned short[]) { 0x23, I2C_CLIENT_END },
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 11,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gpio_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .is_irq = true,
                            .aggregate_id = 7,
                            .ioexp_id = 4,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING,
                            .dir = EP_GPIO_DIR_O
                        },
                        {
                            .name = "gpio_ctrl0_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 1,
                            .aggregate_id = 1,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl1_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 2,
                            .aggregate_id = 1,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl0_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 3,
                            .aggregate_id = 2,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl1_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 4,
                            .aggregate_id = 2,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl0_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 5,
                            .aggregate_id = 3,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl1_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 6,
                            .aggregate_id = 3,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl0_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 7,
                            .aggregate_id = 4,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl1_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 8,
                            .aggregate_id = 4,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl0_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 9,
                            .aggregate_id = 5,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        },
                        {
                            .name = "gpio_ctrl1_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .num = 10,
                            .aggregate_id = 5,
                            .ioexp_id = 4,
                            .dir = EP_GPIO_DIR_O,
                            .default_val = EP_GPIO_VAL_LO
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        [EP_CMD_CONFIG] = {
                            .name = "cmd_config",
                            .type = EP_CMD_TYPE_CFG,
                            .export = EP_CMD_NO_EXPORT,
                            .num_i2c_cmds = 2,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                {
                                    .reg_addr = TCA9535_REG_OUTPUT_PORT0,
                                    .op_size = I2C_REG_DATA_OP_16BIT,
                                    .data_mask = 0x03ff
                                },
                                {
                                    .reg_addr = TCA9535_REG_CONFIGURATION0,
                                    .op_size = I2C_REG_DATA_OP_16BIT,
                                    .data_mask = 0xfc00  // all outputs
                                }
                            }
                        }
                    }
                },
                {
                    .name = "ep-adc-ads7128",
                    .type = EP_TYPE_ADC_ADS7128,
                    .export = EP_EXPORT,
                    .has_i2c = true,
                    .addr_list = (unsigned short[]) { 0x14, I2C_CLIENT_END },
                    .ep_handle_irq = ads7128_handle_irq,
                    .ep_configure  = ads7128_configure,
                    .num_gpios = 7,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gpio_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_NO_EXPORT,
                            .is_irq = true,
                            .aggregate_id = 7,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING,
                            .dir = EP_GPIO_DIR_O
                        },
                        {
                            .name = "gpio_adc_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .num = 1,
                            .dir = EP_GPIO_DIR_IO
                        },
                        {
                            .name = "gpio_adc_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .num = 2,
                            .dir = EP_GPIO_DIR_IO
                        },
                        {
                            .name = "gpio_adc_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .num = 3,
                            .dir = EP_GPIO_DIR_IO
                        },
                        {
                            .name = "gpio_adc_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .num = 4,
                            .dir = EP_GPIO_DIR_IO
                        },
                        {
                            .name = "gpio_adc_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .num = 5,
                            .dir = EP_GPIO_DIR_IO
                        },
                        {
                            .name = "gpio_adc_test",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = EP_GPIO_EXPORT,
                            .num = 6,
                            .dir = EP_GPIO_DIR_I
                        }
                    },
                    .num_cmds = 2,
                    .cmds = (struct endpoint_cmd[]) {
                        [EP_CMD_CONFIG] = {
                            .name = "cmd_config",
                            .type = EP_CMD_TYPE_CFG,
                            .export = EP_CMD_NO_EXPORT,
                            .num_i2c_cmds = 13,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                { .reg_addr = ADS7128_REG_OSR_CFG, .op_size = I2C_REG_DATA_OP_8BIT, .data_mask = 0x03 },         // OSR 8 samples
                                { .reg_addr = ADS7128_REG_OPMODE_CFG, .op_size = I2C_REG_DATA_OP_8BIT, .data_mask = 0x3d },      // CONV_MODE autonomous, OSC_SEL lp, CLK_DIV 3072us
                                { .reg_addr = ADS7128_REG_AUTO_SEQ_CH_SEL, .op_size = I2C_REG_DATA_OP_8BIT, .data_mask = 0x3F }, // AUTO_SEQ_CHSEL all used 
                                { .reg_addr = ADS7128_REG_GENERAL_CFG, .op_size = I2C_REG_DATA_OP_8BIT, .data_mask = 0x14 },     // DWC_EN, CH_RST
                                { .reg_addr = ADS7128_REG_SEQUENCE_CFG, .op_size = I2C_REG_DATA_OP_8BIT, .data_mask = 0x11 },    // SEQ_MODE auto, SEQ_START
                                { .reg_addr = ADS7128_REG_GENERAL_CFG, .op_size = I2C_REG_DATA_OP_8BIT, .data_mask = 0x08 }      // CONVST
                            }
                        },
                        [EP_CMD_ADS7128_REGOP] = {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_ADC_REGOP,
                            .export = EP_CMD_EXPORT,
                            .num_i2c_cmds = 1,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                { .reg_addr = ADS7128_REG_EVENT_FLAG, .op_size = I2C_REG_DATA_OP_8BIT, .data_mask = 0x00 } // dummy
                            }
                        }
                    }
                }
            }
        },
        {
            .data = {
                .model = "block_amp",
                .sn = "n/a",
                .type = IC_TYPE_AMP
            },
            .slot = 3,
            .i2c_sw_channel = 4,
            .num_gpios = 3,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_amp_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_NO_EXPORT,
                    .dir = EP_GPIO_DIR_O,
                    .is_irq = true
                },
                {
                    .name = "gpio_amp_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_I
                },
                {
                    .name = "gpio_amp_stby",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 1,
                    .dir = EP_GPIO_DIR_I
                }
            },
            .num_eps = 0,
            .endpoints = NULL,
            .sec_eeprom = NULL,
            .data_eeprom = NULL
        }
    }
};

const enum base_device_type default_bd_types[] = {
    BD_TYPE_FUSION_VAR_PROTO,
    BD_TYPE_FUSION_C0,
    BD_TYPE_NONE
};

const struct base_device *default_bds[] = {
    &bd_fusion_var_proto,
    &bd_fusion_c0
};
