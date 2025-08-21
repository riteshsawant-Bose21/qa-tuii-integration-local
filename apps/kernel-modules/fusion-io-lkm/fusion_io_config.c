/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
* Copyright 2024 Bose Professional.
*/

#include "fusion-io.h"

const struct endpoint ep_sec_eeprom_sha104 = {
    .name = "eeprom_sha104",
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
    .name = "eeprom_m24c02",  // Note: Name mismatch with type, should be "eeprom_m24c32"?
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
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    &ep_sec_eeprom_sha104,
    &ep_eeprom_m24c32,
    NULL
};

// Default IO cards
const struct io_card ic_empty = {
    .data = {
        .type = IC_TYPE_NONE
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

const struct base_device bd_fusion_c0 = {
    .data = {
        .model = "fusion_c0",
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
        },
        {
            .name = "gpio_pwr_goodn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = EP_GPIO_EXPORT,
            .num = 52,
            .dir = EP_GPIO_DIR_I
        }
    },
    .sec_eeprom = (struct endpoint[]) {
        {
            .name = "ep_eeprom_sha104",
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
            .name = "ep_eeprom_m24c02",
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
            .name = "ep_i2csw_tca9544",
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
                    .name = "cmd_config",
                    .type = EP_CMD_TYPE_CFG,
                    .export = EP_CMD_NO_EXPORT,
                    .num_i2c_cmds = 1,
                    .i2c_cmds = (struct i2c_reg_data[]) {
                        { .reg_addr = I2C_REG_DATA_ADDR_NONE }
                    }
                }
            }
        }
    },
    .pwr_io_exp = (struct endpoint[]) {
        {
            .type = EP_TYPE_IOEXP_TCAL6408,
            .name = "ep_ioexp_tcal6408",
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
                        { .reg_addr = TCAL6408_REG_POLARITY_INV,        .data_mask = 0x00 },
                        { .reg_addr = TCAL6408_REG_CONFIGURATION,       .data_mask = 0x00 }, // all output
                        { .reg_addr = TCAL6408_REG_OUTPUT_DR_STR0,      .data_mask = 0xff }, // full strength
                        { .reg_addr = TCAL6408_REG_OUTPUT_DR_STR1,      .data_mask = 0xff }, // full strength
                        { .reg_addr = TCAL6408_REG_INT_MASK_REG,        .data_mask = 0xff }, // all disabled
                        { .reg_addr = TCAL6408_REG_OUTPUT_PORT_CFG_REG, .data_mask = 0x00 }, // push-pull
                        { .reg_addr = TCAL6408_REG_OUTPUT_PORT,         .data_mask = 0xff }  // All on
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
            .num_gpios = 3,
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
                },
                {
                    .name = "gpio_ana_15v_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = EP_GPIO_EXPORT,
                    .ioexp_id = 3,
                    .dir = EP_GPIO_DIR_I
                }
            },
            .num_eps = 7,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep_ioexp_tca9535-0",
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
                    .name = "ep_ioexp_tca9535-1",
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
                                    .data_mask = 0x0030 // 15v_psw and dac_mute  
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
                    .name = "ep_aud_in_chs-12",
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
                    .name = "ep_aud_in_chs-34",
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
                    .name = "ep_aud_in_chs-56",
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
                    .name = "ep_aud_out_chs-12",
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
                    .name = "ep_aud_out_chs-34",
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
                    .name = "ep_src_ak4137",
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
                                { .reg_addr = AK4137_REG_PCM_CONT0, .data_mask = 0x13 }
                            }
                        }
                    }
                },
                {
                    .name = "ep_hdmi_ep9512t",
                    .type = EP_TYPE_HDMI_EP9512T,
                    .export = EP_NO_EXPORT,
                    .has_i2c = false,
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
                                { .reg_addr  = EP9512T_REG_GENERAL_CTRL, .data_mask = 0x40 }, // Power = 0, Audio_Path = 1, others 0
                                { .reg_addr  = EP9512T_REG_TX_CTRL,      .data_mask = 0xE0 }, // TX_ON = 1, TX_HDMI = 1, TX_5V = 1, A_MUTE = 0
                                { .reg_addr  = EP9512T_REG_AUDIO_CFG,    .data_mask = 0x41 }  // ARC_DIS = 1, A_IN = 01 (I2S), LAYOUT = 0, N_PCM = 0
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
                    .name = "ep_ioexp_tca9535-2",
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
                    .name = "ep_adc_ads7128",
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
                                { .reg_addr = ADS7128_REG_SYSTEM_STATUS,   .data_mask = 0x01 }, // clear BOR
                                { .reg_addr = ADS7128_REG_AUTO_SEQ_CH_SEL, .data_mask = 0x3F }, // AUTO_SEQ_CHSEL 0-5
                                { .reg_addr = ADS7128_REG_SEQUENCE_CFG,    .data_mask = 0x01 }, // SEQ_MODE auto
                                { .reg_addr = ADS7128_REG_HIGH_TH_CH0,     .data_mask = 0x01 }, // DWC high thresholds
                                { .reg_addr = ADS7128_REG_HIGH_TH_CH1,     .data_mask = 0x01 },
                                { .reg_addr = ADS7128_REG_HIGH_TH_CH2,     .data_mask = 0x01 },
                                { .reg_addr = ADS7128_REG_HIGH_TH_CH3,     .data_mask = 0x01 },
                                { .reg_addr = ADS7128_REG_HIGH_TH_CH4,     .data_mask = 0x01 },
                                { .reg_addr = ADS7128_REG_ALERT_CH_SEL,    .data_mask = 0x3f }, // alerts on all chs
                                { .reg_addr = ADS7128_REG_OPMODE_CFG,      .data_mask = 0x3d }, // CONV_MODE autonomous, OSC_SEL lp, CLK_DIV 3072us
                                { .reg_addr = ADS7128_REG_OSR_CFG,         .data_mask = 0x03 }, // OSR 8 samples
                                { .reg_addr = ADS7128_REG_GENERAL_CFG,     .data_mask = 0x30 }, // STAT_EN, DWC_EN
                                { .reg_addr = ADS7128_REG_SEQUENCE_CFG,    .data_mask = 0x11 }  // SEQ_START 
                            }
                        },
                        [EP_CMD_ADS7128_REGOP] = {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_ADC_REGOP,
                            .export = EP_CMD_EXPORT,
                            .num_i2c_cmds = 1,
                            .i2c_cmds = (struct i2c_reg_data[]) {
                                { .reg_addr = I2C_REG_DATA_ADDR_NONE }
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
    BD_TYPE_FUSION_C0,
    BD_TYPE_NONE
};

const struct base_device *default_bds[] = {
    &bd_fusion_c0
};
