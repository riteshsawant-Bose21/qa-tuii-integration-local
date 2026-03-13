/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
* Copyright 2024 Bose Professional.
*/

#include "fusion-io.h"

#define SI5351B_I2C_BUS 0
#define SI5351B_SEQ_DELAY_MS 2000

#define SI5351B_ENDPOINT_INIT {                 \
    .name = "ep_clk_si5351b",                  \
    .type = EP_TYPE_CLK_SI5351B,               \
    .use_i2c_bus_override = true,              \
    .i2c_bus = SI5351B_I2C_BUS,                \
    .i2c_addr = 0x60,                          \
}

#define SI5351B_NUM_MSGS 71

#define SI5351B_CONFIG_MSGS { .reg_addr = 0x03, .data = 0xFF }, \
    { .reg_addr = 0x10, .data = 0x80 }, \
    { .reg_addr = 0x11, .data = 0x80 }, \
    { .reg_addr = 0x12, .data = 0x80 }, \
    { .reg_addr = 0x13, .data = 0x80 }, \
    { .reg_addr = 0x14, .data = 0x80 }, \
    { .reg_addr = 0x15, .data = 0x80 }, \
    { .reg_addr = 0x16, .data = 0x80 }, \
    { .reg_addr = 0x17, .data = 0x80 }, \
    { .reg_addr = 0x02, .data = 0x33 }, \
    { .reg_addr = 0x04, .data = 0x10 }, \
    { .reg_addr = 0x07, .data = 0x01 }, \
    { .reg_addr = 0x0F, .data = 0x00 }, \
    { .reg_addr = 0x10, .data = 0x8C }, \
    { .reg_addr = 0x11, .data = 0x2F }, \
    { .reg_addr = 0x12, .data = 0x2F }, \
    { .reg_addr = 0x13, .data = 0x8C }, \
    { .reg_addr = 0x14, .data = 0x8C }, \
    { .reg_addr = 0x15, .data = 0x2F }, \
    { .reg_addr = 0x16, .data = 0x8C }, \
    { .reg_addr = 0x17, .data = 0x2F }, \
    { .reg_addr = 0x22, .data = 0x42 }, \
    { .reg_addr = 0x23, .data = 0x40 }, \
    { .reg_addr = 0x24, .data = 0x00 }, \
    { .reg_addr = 0x25, .data = 0x10 }, \
    { .reg_addr = 0x26, .data = 0x00 }, \
    { .reg_addr = 0x27, .data = 0xF0 }, \
    { .reg_addr = 0x28, .data = 0x00 }, \
    { .reg_addr = 0x29, .data = 0x00 }, \
    { .reg_addr = 0x32, .data = 0x00 }, \
    { .reg_addr = 0x33, .data = 0x80 }, \
    { .reg_addr = 0x34, .data = 0x00 }, \
    { .reg_addr = 0x35, .data = 0x22 }, \
    { .reg_addr = 0x36, .data = 0x9F }, \
    { .reg_addr = 0x37, .data = 0x00 }, \
    { .reg_addr = 0x38, .data = 0x00 }, \
    { .reg_addr = 0x39, .data = 0x00 }, \
    { .reg_addr = 0x3A, .data = 0x00 }, \
    { .reg_addr = 0x3B, .data = 0x08 }, \
    { .reg_addr = 0x3C, .data = 0x42 }, \
    { .reg_addr = 0x3D, .data = 0x47 }, \
    { .reg_addr = 0x3E, .data = 0xF0 }, \
    { .reg_addr = 0x3F, .data = 0x00 }, \
    { .reg_addr = 0x40, .data = 0x00 }, \
    { .reg_addr = 0x41, .data = 0x00 }, \
    { .reg_addr = 0x52, .data = 0x01 }, \
    { .reg_addr = 0x53, .data = 0x00 }, \
    { .reg_addr = 0x54, .data = 0x00 }, \
    { .reg_addr = 0x55, .data = 0x10 }, \
    { .reg_addr = 0x56, .data = 0x4F }, \
    { .reg_addr = 0x57, .data = 0x00 }, \
    { .reg_addr = 0x58, .data = 0x00 }, \
    { .reg_addr = 0x59, .data = 0x80 }, \
    { .reg_addr = 0x5A, .data = 0x00 }, \
    { .reg_addr = 0x5B, .data = 0x5A }, \
    { .reg_addr = 0x95, .data = 0x00 }, \
    { .reg_addr = 0x96, .data = 0x00 }, \
    { .reg_addr = 0x97, .data = 0x00 }, \
    { .reg_addr = 0x98, .data = 0x00 }, \
    { .reg_addr = 0x99, .data = 0x00 }, \
    { .reg_addr = 0x9A, .data = 0x00 }, \
    { .reg_addr = 0x9B, .data = 0x00 }, \
    { .reg_addr = 0xA2, .data = 0x40 }, \
    { .reg_addr = 0xA3, .data = 0x9C }, \
    { .reg_addr = 0xA4, .data = 0x00 }, \
    { .reg_addr = 0xA6, .data = 0xE3 }, \
    { .reg_addr = 0xA7, .data = 0xE3 }, \
    { .reg_addr = 0xAA, .data = 0xE7 }, \
    { .reg_addr = 0xB7, .data = 0x12 }, \
    { .reg_addr = 0xB1, .data = 0xAC }, \
    { .reg_addr = 0x03, .data = 0x00 }


// TODO
// This stuff is for endpoint and IO card lookup
/* IO card slot arch ONLY */
const enum endpoint_type default_ep_types[] = {
    EP_TYPE_NONE
};

const struct endpoint *default_eps[] = {
};

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

const struct base_device bd_fusion_powersmart = {
    .data = {
        .model = "powersmart",
        .sn = "tbd",
        .type = BD_TYPE_FUSION_POWERSMART
    },
    .num_eps = 1,
    .endpoints = (struct endpoint[]) {
        SI5351B_ENDPOINT_INIT
    },
    .num_gpios = 8,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_GPIO1_IO1",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 1 // GPIO1_IO1
        },
        {
            .name = "gpio_GPIO1_IO5",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 5 // GPIO1_IO5
        },
        {
            .name = "gpio_GPIO1_IO6",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 6 // GPIO1_IO6
        },
        {
            .name = "gpio_GPIO1_IO7",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 7 // GPIO1_IO7
        },
        {
            .name = "gpio_amp_mute",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 10 // GPIO1_IO10
        },
        {
            .name = "gpio_amp_net_wake",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 11, // GPIO1_IO11
            .dir = EP_GPIO_DIR_I
        },
        {
            .name = "GPIO1_IO14",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 14 // GPIO1_IO14
        },
        {
            .name = "gpio_uv_warn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 129, // GPIO5_IO5
            .dir = EP_GPIO_DIR_I
        }
    },
    .cfg_seq = {
        .num_pwrup_cmds = 1,
        .pwrup_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "si5351b_config",
                .parent_ep_name = "ep_clk_si5351b",
                .num_msgs = SI5351B_NUM_MSGS,
                .msgs = (struct endpoint_cmd_msg[]) {
                    SI5351B_CONFIG_MSGS
                },
                .seq_delay_ms = SI5351B_SEQ_DELAY_MS
            }
        }
    }
};

const struct base_device bd_fusion_c1_evk = {
    .data = {
        .model = "c1-evk",
        .sn = "tbd",
        .type = BD_TYPE_FUSION_C1_EVK
    },
    .num_eps = 1,
    .endpoints = (struct endpoint[]) {
        SI5351B_ENDPOINT_INIT
    },
    .num_gpios = 8,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_GPIO1_IO5",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 5 // GPIO1_IO5
        },
        {
            .name = "gpio_GPIO1_IO6",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 6 // GPIO1_IO6
        },
        {
            .name = "gpio_GPIO1_IO7",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 7 // GPIO1_IO7
        },
        {
            .name = "gpio_amp_rstn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 8, // GPIO1_IO8
            .default_val = EP_GPIO_VAL_HI
        },
        {
            .name = "gpio_amp_mute",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 10 // GPIO1_IO10
        },
        {
            .name = "gpio_amp_net_wake",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 11 // GPIO1_IO11
        },
        {
            .name = "GPIO1_IO14",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 14 // GPIO1_IO14
        },
        {
            .name = "gpio_uv_warn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 129, // GPIO5_IO5
            .dir = EP_GPIO_DIR_I
        }
    },
    .cfg_seq = {
        .num_pwrup_cmds = 1,
        .pwrup_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "si5351b_config",
                .parent_ep_name = "ep_clk_si5351b",
                .num_msgs = SI5351B_NUM_MSGS,
                .msgs = (struct endpoint_cmd_msg[]) {
                    SI5351B_CONFIG_MSGS
                },
                .seq_delay_ms = SI5351B_SEQ_DELAY_MS
            }
        }
    }
};

const struct base_device bd_fusion_fm6 = {
    .data = {
        .model = "fm6",
        .sn = "tbd",
        .type = BD_TYPE_FUSION_FM6
    },
    .uv_mute_sw = {
        .enabled = true,
        .uv_warn_gpio_name = "gpio_uv_warn",
        .dac_mute_gpio_name = "gpio_dac_mute",
    },
    .num_gpios = 4,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_a_mute_out",
            .type = EP_GPIO_TYPE_PHYS,
            .num = 5, // GPIO1_IO5
            .dir = EP_GPIO_DIR_I
        },
        // {
        //     .name = "gpio_tca9544_int",
        //     .type = EP_GPIO_TYPE_PHYS,
        //     .is_irq = true,
        //     .num = 6, // GPIO1_IO6
        //     .trigger_type = IRQ_TYPE_LEVEL_LOW
        // },
        {
            .name = "gpio_ui_rstn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 7, // GPIO1_IO7
            .default_val = EP_GPIO_VAL_HI
        },
        {
            .name = "gpio_ui_boot0",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 8 // GPIO1_IO8
        },
        {
            .name = "gpio_uv_warn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 129, // GPIO5_IO5
            .dir = EP_GPIO_DIR_I,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING
        }
    },
    .num_eps = 3,
    .endpoints = (struct endpoint[]) {
        {
            .name = "ep_i2csw_tca9544",
            .type = EP_TYPE_I2CSW_TCA9544,
            .i2c_addr = 0x70,
            .ep_handle_irq = tca9544_handle_irq,
            .ep_configure = tca9544_configure,
            .num_gpios = 4,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_ana_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .num = 1,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_hmcu_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .num = 2,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_gpio_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .num = 3,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_tca9544_int",
                    .type = EP_GPIO_TYPE_PHYS,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_LEVEL_LOW
                }
            }
        },
        {
            .type = EP_TYPE_IOEXP_TCAL6408,
            .name = "ep_ioexp_tcal6408",
            .ioexp_id = 1,
            .i2c_addr = 0x20,
            .ep_handle_irq = tcal6408_handle_irq,
            .num_gpios = 6,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_ana_3v3_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 1
                },
                {
                    .name = "gpio_gpio_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 2
                },
                {
                    .name = "gpio_hdmi_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 3
                },
                {
                    .name = "gpio_hdmi_5v_en",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 4
                },
                {
                    .name = "gpio_hdmi_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 5
                },
                {
                    .name = "gpio_tcal6408_int",
                    .type = EP_GPIO_TYPE_PHYS,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_LEVEL_LOW
                }
            }
        },
        SI5351B_ENDPOINT_INIT
    },
    .num_ics = 3,
    .io_cards = (struct io_card[]) {
        {
            .data = {
                .model = "block_ana",
                .sn = "n/a",
                .type = IC_TYPE_AN_IN_OUT
            },
            .sw_port = 1,
            .num_inputs = 6,
            .num_outputs = 4,
            .num_gpios = 3,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_ana_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .aggregate_id = 6,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_ana_3v3_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_ana_15v_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 3
                }
            },
            .num_eps = 7,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep_ioexp_tca9535-0",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .ioexp_id = 2,
                    .i2c_addr = 0x21,
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 17,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch3_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 1,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch3_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 2,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch3_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 3,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch3_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 4,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch4_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 5,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 6,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 7,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 8,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch5_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 9,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch5_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 10,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch5_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 11,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch5_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 12,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch6_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 13,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_gain_ch6_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 14,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_gain_ch6_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 15,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_gain_ch6_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 16,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ana_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 6,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    }
                },
                {
                    .name = "ep_ioexp_tca9535-1",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .ioexp_id = 3,
                    .i2c_addr = 0x22,
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 7,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_php_en_ch3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 1
                        },
                        {
                            .name = "gpio_php_en_ch4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 2
                        },
                        {
                            .name = "gpio_php_en_ch5",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 3
                        },
                        {
                            .name = "gpio_php_en_ch6",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 4
                        },
                        {
                            .name = "gpio_ana_15v_psw",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 5
                        },
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 6
                        },
                        {
                            .name = "gpio_ana_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 6,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    }
                },
                {
                    .name = "ep_aud_in_chs-12",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = true,
                    .in_ch_bm = 0x0003,
                    .num_gpios = 0,
                    .gpios = NULL
                },
                {
                    .name = "ep_aud_in_chs-34",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = true,
                    .in_ch_bm = 0x000c,
                    .num_gpios = 4,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch3_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 1,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 2,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_php_en_ch3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        },
                        {
                            .name = "gpio_php_en_ch4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                },
                {
                    .name = "ep_aud_in_chs-56",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = true,
                    .in_ch_bm = 0x0030,
                    .num_gpios = 4,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch5_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 3,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_gain_ch6_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 4,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_php_en_ch5",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        },
                        {
                            .name = "gpio_php_en_ch6",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                },
                {
                    .name = "ep_aud_out_chs-12",
                    .type = EP_TYPE_AUD_DAC_TAD5242,
                    .export = true,
                    .out_ch_bm = 0x0003,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                },
                {
                    .name = "ep_aud_out_chs-34",
                    .type = EP_TYPE_AUD_DAC_TAD5242,
                    .export = true,
                    .out_ch_bm = 0x000c,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                }
            }
        },
        {
            .data = {
                .model = "block_hdmi",
                .sn = "n/a",
                .type = IC_TYPE_HDMI
            },
            .sw_port = 2,
            .num_gpios = 4,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_hdmi_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_hdmi_5v_en",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_hdmi_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_a_mute_out",
                    .type = EP_GPIO_TYPE_PHYS,
                    .export = true,
                    //.is_irq = true
                }
            },
            .num_eps = 2,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep_src_ak4137",
                    .type = EP_TYPE_SRC_AK4137,
                    .export = true,
                    .i2c_addr = 0x13,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_hdmi_reset",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 1
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_REGOP,
                            .export = true
                        }
                    }
                },
                {
                    .name = "ep_hdmi_ep9512t",
                    .type = EP_TYPE_HDMI_EP9512T,
                    .export = true,
                    .i2c_addr = 0x3c,
                    .ep_handle_irq = ep9512t_handle_irq,
                    .ep_configure = ep9512t_configure,
                    .num_gpios = 3,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            // not sure exactly, but export for reading
                            .name = "gpio_a_mute_out",
                            .type = EP_GPIO_TYPE_PHYS,
                            .export = true,
                            //.is_irq = true
                        },
                        {
                            .name = "gpio_hmcu_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        },
                        {
                            .name = "gpio_hdmi_reset",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 1
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_REGOP,
                            .export = true
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
            .sw_port = 3,
            .num_gpios = 7,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_gpio_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .aggregate_id = 7,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_gpio_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_ctrl0_gpio0",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 1,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio1",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 2,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio2",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 3,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio3",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 4,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio4",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 5,
                    .ioexp_id = 4
                }
            },
            .num_eps = 2,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep_ioexp_tca9535-2",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .ioexp_id = 4,
                    .i2c_addr = 0x23,
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 16,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_ctrl0_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 1,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_ctrl1_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 2,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_ctrl2_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 3,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_ctrl0_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 4,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_ctrl1_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 5,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_ctrl2_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 6,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_ctrl0_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 7,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_ctrl1_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 8,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_ctrl2_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 9,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_ctrl0_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 10,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ctrl1_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 11,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ctrl2_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 12,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ctrl0_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 13,
                            .aggregate_id = 5
                        },
                        {
                            .name = "gpio_ctrl1_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 14,
                            .aggregate_id = 5
                        },
                        {
                            .name = "gpio_ctrl2_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 15,
                            .aggregate_id = 5
                        },
                        {
                            .name = "gpio_gpio_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 7,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    }
                },
                {
                    .name = "ep_adc_ads7128",
                    .type = EP_TYPE_ADC_ADS7128,
                    .export = true,
                    .i2c_addr = 0x14,
                    .ep_handle_irq = ads7128_handle_irq,
                    .ep_configure  = ads7128_configure,
                    .num_gpios = 7,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_adc_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 1,
                        },
                        {
                            .name = "gpio_adc_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 2
                        },
                        {
                            .name = "gpio_adc_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 3
                        },
                        {
                            .name = "gpio_adc_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 4
                        },
                        {
                            .name = "gpio_adc_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 5
                        },
                        {
                            .name = "gpio_adc_test",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 6
                        },
                        {
                            .name = "gpio_gpio_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 7,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_REGOP,
                            .export = true
                        }
                    }
                }
            }
        }
    },
    .cfg_seq = {
        .num_pwrup_cmds = 10,
        .pwrup_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "tca9544_config",
                .parent_ep_name = "ep_i2csw_tca9544"
            },
            {
                .name = "tcal6408_config",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 7,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCAL6408_REG_POLARITY_INV,        .data = 0x00 },
                    { .reg_addr = TCAL6408_REG_OUTPUT_DR_STR0,      .data = 0xff }, // full strength
                    { .reg_addr = TCAL6408_REG_OUTPUT_DR_STR1,      .data = 0xff }, // full strength
                    { .reg_addr = TCAL6408_REG_INT_MASK_REG,        .data = 0xff }, // all disabled
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT_CFG_REG, .data = 0x00 }, // push-pull
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT,         .data = 0x00 }, // default low
                    { .reg_addr = TCAL6408_REG_CONFIGURATION,       .data = 0x00 }, // all output
                }
            },
            {
                .name = "ana_3v3_psw",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x01 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "si5351b_config",
                .parent_ep_name = "ep_clk_si5351b",
                .num_msgs = SI5351B_NUM_MSGS,
                .msgs = (struct endpoint_cmd_msg[]) {
                    SI5351B_CONFIG_MSGS
                },
                .seq_delay_ms = SI5351B_SEQ_DELAY_MS
            },
            {
                .name = "ana_15v_psw",
                .parent_ep_name = "ep_ioexp_tca9535-1",
                .num_msgs = 2,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0,   .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0010 },
                    { .reg_addr = TCA9535_REG_CONFIGURATION0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "hdmi_psw",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x05 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "hdmi_reset",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x15 }
                }
            },
            {
                .name = "gpio_psw",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x17 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "tca9535-2_config",
                .parent_ep_name = "ep_ioexp_tca9535-2",
                .num_msgs = 2,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0,   .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x36db }, // default Hi-Z
                    { .reg_addr = TCA9535_REG_CONFIGURATION0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 }
                }
            },
            {
                .name = "ads7128_config",
                .parent_ep_name = "ep_adc_ads7128",
                .num_msgs = 13,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = ADS7128_REG_SYSTEM_STATUS,   .data = 0x01 }, // clear BOR
                    { .reg_addr = ADS7128_REG_AUTO_SEQ_CH_SEL, .data = 0x3F }, // AUTO_SEQ_CHSEL 0-5
                    { .reg_addr = ADS7128_REG_SEQUENCE_CFG,    .data = 0x01 }, // SEQ_MODE auto
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH0,     .data = 0x01 }, // DWC high thresholds
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH1,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH2,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH3,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH4,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_ALERT_CH_SEL,    .data = 0x3f }, // alerts on all chs
                    { .reg_addr = ADS7128_REG_OPMODE_CFG,      .data = 0x3d }, // CONV_MODE autonomous, OSC_SEL lp, CLK_DIV 3072us
                    { .reg_addr = ADS7128_REG_OSR_CFG,         .data = 0x03 }, // OSR 8 samples
                    { .reg_addr = ADS7128_REG_GENERAL_CFG,     .data = 0x30 }, // STAT_EN, DWC_EN
                    { .reg_addr = ADS7128_REG_SEQUENCE_CFG,    .data = 0x11 }  // SEQ_START 
                }
            }
        },
        .num_cfg_cmds = 3,
        .cfg_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "tca9535-0_config",
                .parent_ep_name = "ep_ioexp_tca9535-0",
                .num_msgs = 2,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0,   .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 },
                    { .reg_addr = TCA9535_REG_CONFIGURATION0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 }
                }
            },
            {
                .name = "ak4137_config",
                .parent_ep_name = "ep_src_ak4137",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = AK4137_REG_PCM_CONT0, .data = 0x13 } // input format i2s
                }
            },
            {
                .name = "ep9512t_config",
                .parent_ep_name = "ep_hdmi_ep9512t",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) {
                    // from tests, this turns on arc and 5v en
                    // also, prevents tv from going black for a second.
                    { .reg_addr  = EP9512T_REG_AUDIO_CFG,    .data = 0x01 }  // A_IN = 01 (I2S)
                }
            }
        },
        .num_post_cfg_cmds = 1,
        .post_cfg_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "dac_mute",
                .parent_ep_name = "ep_ioexp_tca9535-1",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0030 } 
                }
            }
        }
    }
};

const struct base_device bd_fusion_fm8y = {
    .data = {
        .model = "fm8y",
        .sn = "tbd",
        .type = BD_TYPE_FUSION_FM8Y
    },
    .uv_mute_sw = {
        .enabled = true,
        .uv_warn_gpio_name = "gpio_uv_warn",
        .dac_mute_gpio_name = "gpio_dac_mute",
    },
    .num_gpios = 4,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_a_mute_out",
            .type = EP_GPIO_TYPE_PHYS,
            .num = 5, // GPIO1_IO5
            .dir = EP_GPIO_DIR_I
        },
        // {
        //     .name = "gpio_tca9544_int",
        //     .type = EP_GPIO_TYPE_PHYS,
        //     .is_irq = true,
        //     .num = 6, // GPIO1_IO6
        //     .trigger_type = IRQ_TYPE_LEVEL_LOW
        // },
        {
            .name = "gpio_ui_rstn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 7, // GPIO1_IO7
            .default_val = EP_GPIO_VAL_HI
        },
        {
            .name = "gpio_ui_boot0",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 8 // GPIO1_IO8
        },
        {
            .name = "gpio_uv_warn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 129, // GPIO5_IO5
            .dir = EP_GPIO_DIR_I,
            .is_irq = true,
            .trigger_type = IRQ_TYPE_EDGE_FALLING
        }
    },
    .num_eps = 3,
    .endpoints = (struct endpoint[]) {
        {
            .name = "ep_i2csw_tca9544",
            .type = EP_TYPE_I2CSW_TCA9544,
            .i2c_addr = 0x70,
            .ep_handle_irq = tca9544_handle_irq,
            .ep_configure = tca9544_configure,
            .num_gpios = 4,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_ana_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .num = 1,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_hmcu_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .num = 2,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_gpio_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .num = 3,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_tca9544_int",
                    .type = EP_GPIO_TYPE_PHYS,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                }
            }
        },
        {
            .type = EP_TYPE_IOEXP_TCAL6408,
            .name = "ep_ioexp_tcal6408",
            .ioexp_id = 1,
            .i2c_addr = 0x20,
            .ep_handle_irq = tcal6408_handle_irq,
            .num_gpios = 6,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_ana_3v3_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 1
                },
                {
                    .name = "gpio_gpio_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 2
                },
                {
                    .name = "gpio_hdmi_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 3
                },
                {
                    .name = "gpio_hdmi_5v_en",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 4
                },
                {
                    .name = "gpio_hdmi_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .num = 5
                },
                {
                    .name = "gpio_tcal6408_int",
                    .type = EP_GPIO_TYPE_PHYS,
                    .is_irq = true,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                }
            }
        },
        SI5351B_ENDPOINT_INIT
    },
    .num_ics = 3,
    .io_cards = (struct io_card[]) {
        {
            .data = {
                .model = "block_ana",
                .sn = "n/a",
                .type = IC_TYPE_AN_IN_OUT
            },
            .sw_port = 1,
            .num_inputs = 6,
            .num_outputs = 4,
            .num_gpios = 3,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_ana_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .aggregate_id = 6,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_ana_3v3_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_ana_15v_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 3
                }
            },
            .num_eps = 7,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep_ioexp_tca9535-0",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .ioexp_id = 2,
                    .i2c_addr = 0x21,
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 17,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch3_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 1,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch3_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 2,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch3_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 3,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch3_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 4,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_gain_ch4_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 5,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 6,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 7,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 8,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_gain_ch5_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 9,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch5_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 10,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch5_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 11,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch5_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 12,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_gain_ch6_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 13,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_gain_ch6_1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 14,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_gain_ch6_2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 15,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_gain_ch6_3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 16,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ana_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 6,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    }
                },
                {
                    .name = "ep_ioexp_tca9535-1",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .ioexp_id = 3,
                    .i2c_addr = 0x22,
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 7,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_php_en_ch3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 1
                        },
                        {
                            .name = "gpio_php_en_ch4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 2
                        },
                        {
                            .name = "gpio_php_en_ch5",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 3
                        },
                        {
                            .name = "gpio_php_en_ch6",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 4
                        },
                        {
                            .name = "gpio_ana_15v_psw",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 5
                        },
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 6
                        },
                        {
                            .name = "gpio_ana_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 6,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    }
                },
                {
                    .name = "ep_aud_in_chs-12",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = true,
                    .in_ch_bm = 0x0003,
                    .num_gpios = 0,
                    .gpios = NULL
                },
                {
                    .name = "ep_aud_in_chs-34",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = true,
                    .in_ch_bm = 0x000c,
                    .num_gpios = 4,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch3_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 1,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_gain_ch4_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 2,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_php_en_ch3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        },
                        {
                            .name = "gpio_php_en_ch4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                },
                {
                    .name = "ep_aud_in_chs-56",
                    .type = EP_TYPE_AUD_ADC_TAA5242,
                    .export = true,
                    .in_ch_bm = 0x0030,
                    .num_gpios = 4,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_gain_ch5_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 3,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_gain_ch6_0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .aggregate_id = 4,
                            .ioexp_id = 2
                        },
                        {
                            .name = "gpio_php_en_ch5",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        },
                        {
                            .name = "gpio_php_en_ch6",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                },
                {
                    .name = "ep_aud_out_chs-12",
                    .type = EP_TYPE_AUD_DAC_TAD5242,
                    .export = true,
                    .out_ch_bm = 0x0003,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                },
                {
                    .name = "ep_aud_out_chs-34",
                    .type = EP_TYPE_AUD_DAC_TAD5242,
                    .export = true,
                    .out_ch_bm = 0x000c,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_dac_mute",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 3
                        }
                    }
                }
            }
        },
        {
            .data = {
                .model = "block_hdmi",
                .sn = "n/a",
                .type = IC_TYPE_HDMI
            },
            .sw_port = 2,
            .num_gpios = 4,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_hdmi_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_hdmi_5v_en",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_hdmi_reset",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_a_mute_out",
                    .type = EP_GPIO_TYPE_PHYS,
                    .export = true,
                    //.is_irq = true
                }
            },
            .num_eps = 2,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep_src_ak4137",
                    .type = EP_TYPE_SRC_AK4137,
                    .export = true,
                    .i2c_addr = 0x13,
                    .num_gpios = 1,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_hdmi_reset",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 1
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_REGOP,
                            .export = true
                        }
                    }
                },
                {
                    .name = "ep_hdmi_ep9512t",
                    .type = EP_TYPE_HDMI_EP9512T,
                    .export = true,
                    .i2c_addr = 0x3c,
                    .ep_handle_irq = ep9512t_handle_irq,
                    .ep_configure = ep9512t_configure,
                    .num_gpios = 3,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            // not sure exactly, but export for reading
                            .name = "gpio_a_mute_out",
                            .type = EP_GPIO_TYPE_PHYS,
                            .export = true,
                            //.is_irq = true
                        },
                        {
                            .name = "gpio_hmcu_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        },
                        {
                            .name = "gpio_hdmi_reset",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .ioexp_id = 1
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_REGOP,
                            .export = true
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
            .sw_port = 3,
            .num_gpios = 7,
            .gpios = (struct endpoint_gpio[]) {
                {
                    .name = "gpio_gpio_int",
                    .type = EP_GPIO_TYPE_VIRT,
                    .is_irq = true,
                    .aggregate_id = 7,
                    .trigger_type = IRQ_TYPE_EDGE_FALLING
                },
                {
                    .name = "gpio_gpio_psw",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .ioexp_id = 1
                },
                {
                    .name = "gpio_ctrl0_gpio0",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 1,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio1",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 2,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio2",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 3,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio3",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 4,
                    .ioexp_id = 4
                },
                {
                    .name = "gpio_ctrl0_gpio4",
                    .type = EP_GPIO_TYPE_VIRT,
                    .export = true,
                    .aggregate_id = 5,
                    .ioexp_id = 4
                }
            },
            .num_eps = 2,
            .endpoints = (struct endpoint[]) {
                {
                    .name = "ep_ioexp_tca9535-2",
                    .type = EP_TYPE_IOEXP_TCA9535,
                    .ioexp_id = 4,
                    .i2c_addr = 0x23,
                    .ep_handle_irq = tca9535_handle_irq,
                    .num_gpios = 16,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_ctrl0_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 1,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_ctrl1_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 2,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_ctrl2_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 3,
                            .aggregate_id = 1
                        },
                        {
                            .name = "gpio_ctrl0_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 4,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_ctrl1_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 5,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_ctrl2_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 6,
                            .aggregate_id = 2
                        },
                        {
                            .name = "gpio_ctrl0_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 7,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_ctrl1_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 8,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_ctrl2_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 9,
                            .aggregate_id = 3
                        },
                        {
                            .name = "gpio_ctrl0_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 10,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ctrl1_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 11,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ctrl2_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 12,
                            .aggregate_id = 4
                        },
                        {
                            .name = "gpio_ctrl0_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 13,
                            .aggregate_id = 5
                        },
                        {
                            .name = "gpio_ctrl1_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 14,
                            .aggregate_id = 5
                        },
                        {
                            .name = "gpio_ctrl2_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .num = 15,
                            .aggregate_id = 5
                        },
                        {
                            .name = "gpio_gpio_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 7,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    }
                },
                {
                    .name = "ep_adc_ads7128",
                    .type = EP_TYPE_ADC_ADS7128,
                    .export = true,
                    .i2c_addr = 0x14,
                    .ep_handle_irq = ads7128_handle_irq,
                    .ep_configure  = ads7128_configure,
                    .num_gpios = 7,
                    .gpios = (struct endpoint_gpio[]) {
                        {
                            .name = "gpio_adc_gpio0",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 1,
                        },
                        {
                            .name = "gpio_adc_gpio1",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 2
                        },
                        {
                            .name = "gpio_adc_gpio2",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 3
                        },
                        {
                            .name = "gpio_adc_gpio3",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 4
                        },
                        {
                            .name = "gpio_adc_gpio4",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 5
                        },
                        {
                            .name = "gpio_adc_test",
                            .type = EP_GPIO_TYPE_VIRT,
                            .export = true,
                            .num = 6
                        },
                        {
                            .name = "gpio_gpio_int",
                            .type = EP_GPIO_TYPE_VIRT,
                            .is_irq = true,
                            .aggregate_id = 7,
                            .trigger_type = IRQ_TYPE_EDGE_FALLING
                        }
                    },
                    .num_cmds = 1,
                    .cmds = (struct endpoint_cmd[]) {
                        {
                            .name = "cmd_regop",
                            .type = EP_CMD_TYPE_REGOP,
                            .export = true
                        }
                    }
                }
            }
        }
    },
    .cfg_seq = {
        .num_pwrup_cmds = 10,
        .pwrup_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "tca9544_config",
                .parent_ep_name = "ep_i2csw_tca9544"
            },
            {
                .name = "tcal6408_config",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 7,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCAL6408_REG_POLARITY_INV,        .data = 0x00 },
                    { .reg_addr = TCAL6408_REG_OUTPUT_DR_STR0,      .data = 0xff }, // full strength
                    { .reg_addr = TCAL6408_REG_OUTPUT_DR_STR1,      .data = 0xff }, // full strength
                    { .reg_addr = TCAL6408_REG_INT_MASK_REG,        .data = 0xff }, // all disabled
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT_CFG_REG, .data = 0x00 }, // push-pull
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT,         .data = 0x00 }, // default low
                    { .reg_addr = TCAL6408_REG_CONFIGURATION,       .data = 0x00 }, // all output
                }
            },
            {
                .name = "ana_3v3_psw",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x01 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "si5351b_config",
                .parent_ep_name = "ep_clk_si5351b",
                .num_msgs = SI5351B_NUM_MSGS,
                .msgs = (struct endpoint_cmd_msg[]) {
                    SI5351B_CONFIG_MSGS
                },
                .seq_delay_ms = SI5351B_SEQ_DELAY_MS
            },
            {
                .name = "ana_15v_psw",
                .parent_ep_name = "ep_ioexp_tca9535-1",
                .num_msgs = 2,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0,   .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0010 },
                    { .reg_addr = TCA9535_REG_CONFIGURATION0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "hdmi_psw",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x05 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "hdmi_reset",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x15 }
                }
            },
            {
                .name = "gpio_psw",
                .parent_ep_name = "ep_ioexp_tcal6408",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCAL6408_REG_OUTPUT_PORT, .data = 0x17 }
                },
                .seq_delay_ms = 25
            },
            {
                .name = "tca9535-2_config",
                .parent_ep_name = "ep_ioexp_tca9535-2",
                .num_msgs = 2,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0,   .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x36db }, // default Hi-Z
                    { .reg_addr = TCA9535_REG_CONFIGURATION0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 }
                }
            },
            {
                .name = "ads7128_config",
                .parent_ep_name = "ep_adc_ads7128",
                .num_msgs = 13,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = ADS7128_REG_SYSTEM_STATUS,   .data = 0x01 }, // clear BOR
                    { .reg_addr = ADS7128_REG_AUTO_SEQ_CH_SEL, .data = 0x3F }, // AUTO_SEQ_CHSEL 0-5
                    { .reg_addr = ADS7128_REG_SEQUENCE_CFG,    .data = 0x01 }, // SEQ_MODE auto
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH0,     .data = 0x01 }, // DWC high thresholds
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH1,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH2,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH3,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_HIGH_TH_CH4,     .data = 0x01 },
                    { .reg_addr = ADS7128_REG_ALERT_CH_SEL,    .data = 0x3f }, // alerts on all chs
                    { .reg_addr = ADS7128_REG_OPMODE_CFG,      .data = 0x3d }, // CONV_MODE autonomous, OSC_SEL lp, CLK_DIV 3072us
                    { .reg_addr = ADS7128_REG_OSR_CFG,         .data = 0x03 }, // OSR 8 samples
                    { .reg_addr = ADS7128_REG_GENERAL_CFG,     .data = 0x30 }, // STAT_EN, DWC_EN
                    { .reg_addr = ADS7128_REG_SEQUENCE_CFG,    .data = 0x11 }  // SEQ_START 
                }
            }
        },
        .num_cfg_cmds = 3,
        .cfg_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "tca9535-0_config",
                .parent_ep_name = "ep_ioexp_tca9535-0",
                .num_msgs = 2,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0,   .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 },
                    { .reg_addr = TCA9535_REG_CONFIGURATION0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0000 }
                }
            },
            {
                .name = "ak4137_config",
                .parent_ep_name = "ep_src_ak4137",
                .num_msgs = 2,
                .msgs = (struct endpoint_cmd_msg[]) {
                    { .reg_addr = AK4137_REG_PCM_CONT0, .data = 0x13 }, // input format i2s
                    { .reg_addr = AK4137_REG_PCM_CONT1, .data = 0x10 }  // sdo clocked on rising edge of bclk
                }
            },
            {
                .name = "ep9512t_config",
                .parent_ep_name = "ep_hdmi_ep9512t",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) {
                    // from tests, this turns on arc and 5v en
                    // also, prevents tv from going black for a second.
                    { .reg_addr  = EP9512T_REG_AUDIO_CFG,    .data = 0x01 }  // A_IN = 01 (I2S)
                }
            }
        },
        .num_post_cfg_cmds = 1,
        .post_cfg_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "dac_mute",
                .parent_ep_name = "ep_ioexp_tca9535-1",
                .num_msgs = 1,
                .msgs = (struct endpoint_cmd_msg[]) { 
                    { .reg_addr = TCA9535_REG_OUTPUT_PORT0, .op_size = ENDPOINT_CMD_MSG_OP_16BIT, .data = 0x0030 } 
                }
            }
        }
    }
};

const struct base_device bd_fusion_xlr_pal = {
    .data = {
        .model = "xlr-pal",
        .sn = "tbd",
        .type = BD_TYPE_FUSION_XLR_PAL
    },
    .num_eps = 1,
    .endpoints = (struct endpoint[]) {
        SI5351B_ENDPOINT_INIT
    },
    .num_gpios = 3,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_XLR_SW",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .dir = EP_GPIO_DIR_I,
            .num = 5 // GPIO1_IO5
        },
        {
            .name = "gpio_TRS_SW",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .dir = EP_GPIO_DIR_I,
            .num = 6 // GPIO1_IO6
        },
        {
            .name = "gpio_PWR_SW1",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .num = 123 // GPIO1_IO6
        }
    },
    .cfg_seq = {
        .num_pwrup_cmds = 1,
        .pwrup_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "si5351b_config",
                .parent_ep_name = "ep_clk_si5351b",
                .num_msgs = SI5351B_NUM_MSGS,
                .msgs = (struct endpoint_cmd_msg[]) {
                    SI5351B_CONFIG_MSGS
                },
                .seq_delay_ms = SI5351B_SEQ_DELAY_MS
            }
        }
    }
};

const struct base_device bd_fusion_blue_pal = {
    .data = {
        .model = "blue-pal",
        .sn = "tbd",
        .type = BD_TYPE_FUSION_BLUE_PAL
    },
    .num_eps = 1,
    .endpoints = (struct endpoint[]) {
        SI5351B_ENDPOINT_INIT
    },
    .num_gpios = 1,
    .gpios = (struct endpoint_gpio[]) {
        {
            .name = "gpio_BT_SWn",
            .type = EP_GPIO_TYPE_PHYS,
            .export = true,
            .dir = EP_GPIO_DIR_I,
            .num = 5 // GPIO1_IO5
        }
    },
    .cfg_seq = {
        .num_pwrup_cmds = 1,
        .pwrup_cmds = (struct config_sequence_cmd[]) {
            {
                .name = "si5351b_config",
                .parent_ep_name = "ep_clk_si5351b",
                .num_msgs = SI5351B_NUM_MSGS,
                .msgs = (struct endpoint_cmd_msg[]) {
                    SI5351B_CONFIG_MSGS
                },
                .seq_delay_ms = SI5351B_SEQ_DELAY_MS
            }
        }
    }
};

const enum base_device_type default_bd_types[] = {
    BD_TYPE_FUSION_POWERSMART,
    BD_TYPE_FUSION_C1_EVK,
    BD_TYPE_FUSION_FM6,
    BD_TYPE_FUSION_FM8Y,
    BD_TYPE_FUSION_XLR_PAL,
    BD_TYPE_FUSION_BLUE_PAL,
    BD_TYPE_NONE
};

const struct base_device *default_bds[] = {
    &bd_fusion_powersmart,
    &bd_fusion_c1_evk,
    &bd_fusion_fm6,
    &bd_fusion_fm8y,
    &bd_fusion_xlr_pal,
    &bd_fusion_blue_pal
};
