/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Copyright 2024 Bose Professional.
 */

#ifndef _FUSION_IO_H
#define _FUSION_IO_H

#include <linux/types.h>
#include <linux/gpio.h>
#include <linux/i2c.h>
#include <linux/irq.h>
#include <linux/i2c-mux.h>
#include <linux/mutex.h>


#define MAX_STRING          32
#define MAX_I2C_ADDRS       8

#define I2C_ADAPTER 1


/* I2C */
enum i2c_reg_data_op_size {
    I2C_REG_DATA_OP_8BIT,
    I2C_REG_DATA_OP_16BIT
};

#define I2C_REG_DATA_ADDR_NONE 0xff

struct i2c_reg_data {
    u8                        reg_addr;
    enum i2c_reg_data_op_size op_size;
    u16                       data_mask;
};


/* GPIO and commands */
enum endpoint_gpio_type {
    EP_GPIO_TYPE_NONE,
    EP_GPIO_TYPE_VIRT,
    EP_GPIO_TYPE_PHYS,
};

enum endpoint_gpio_export {
    EP_GPIO_NO_EXPORT,
    EP_GPIO_EXPORT
};

enum endpoint_gpio_dir {
    EP_GPIO_DIR_O,
    EP_GPIO_DIR_I,
};

enum endpoint_gpio_val {
    EP_GPIO_VAL_LO,
    EP_GPIO_VAL_HI
};

// represents either
// a. a real physical gpio
// b. a virtual gpio either
//    - connected to a physical gpio
//    - or connected on an io expander
//    - OR a user GPIO that can also be an analog value
struct endpoint_gpio {
    char                        name[MAX_STRING];
    enum endpoint_gpio_type     type;
    enum endpoint_gpio_export   export;

    u8                          num;
    enum endpoint_gpio_dir      dir;
    enum endpoint_gpio_val      default_val;

    bool                        is_irq;
    unsigned int                trigger_type;
    unsigned int                irq_num;

    u8                          ioexp_id;
    u8                          aggregate_id;
    
    bool                        valid;
    u16                         value;

    struct endpoint_gpio        *linked_gpio;
    size_t                      num_aggregate_gpios;
    struct endpoint_gpio        **aggregate_gpios;
    
    struct gpio_desc            *desc;
    struct device_attribute     dev_attr;

    struct base_device          *parent_base_device;
    struct io_card              *parent_io_card;
    struct endpoint             *parent_endpoint;
};

// also serve as index to .cmds list
enum endpoint_cmd_type {
    EP_CMD_TYPE_CFG         = 0,

    /* adc */
    EP_CMD_TYPE_ADC_REGOP   = 1
};

enum endpoint_cmd_export {
    EP_CMD_NO_EXPORT,
    EP_CMD_EXPORT
};

struct endpoint_cmd {
    char                     name[MAX_STRING];
    enum endpoint_cmd_export export;
    enum endpoint_cmd_type   type;

    size_t                   num_i2c_cmds;
    struct i2c_reg_data      *i2c_cmds;

    struct device_attribute  dev_attr;

    struct endpoint          *parent_endpoint;
};


/* endpoint */
enum endpoint_type {
    /* NONE */
    EP_TYPE_NONE = 0,

    /* audio devices */
    // codecs
    EP_TYPE_AUD_START         = EP_TYPE_NONE + 1,
    EP_TYPE_AUD_ADC_TAA5242   = EP_TYPE_AUD_START,
    EP_TYPE_AUD_DAC_TAD5242,
    EP_TYPE_AUD_END,

    // SRCs
    EP_TYPE_SRC_START         = EP_TYPE_AUD_END + 1,
    EP_TYPE_SRC_AK4137        = EP_TYPE_SRC_START,
    EP_TYPE_SRC_END,

    // HDMI
    EP_TYPE_HDMI_START        = EP_TYPE_SRC_END + 1,
    EP_TYPE_HDMI_EP9512T      = EP_TYPE_HDMI_START,
    EP_TYPE_HDMI_END,

    /* non-audio */
    // i2c IO exander
    EP_TYPE_IOEXP_START       = EP_TYPE_HDMI_END + 1,
    EP_TYPE_IOEXP_TCA9535     = EP_TYPE_IOEXP_START,
    EP_TYPE_IOEXP_TCAL6408,
    EP_TYPE_IOEXP_END,

    // ADCs
    EP_TYPE_ADC_START         = EP_TYPE_IOEXP_END + 1,
    EP_TYPE_ADC_ADS7128        = EP_TYPE_ADC_START,
    EP_TYPE_ADC_END,

    // SECURE EEPROM
    EP_TYPE_SEC_EEPROM_START  = EP_TYPE_ADC_END + 1,
    EP_TYPE_SEC_EEPROM_SHA104 = EP_TYPE_SEC_EEPROM_START,                
    EP_TYPE_SEC_EEPROM_END,

    // EEPROM
    EP_TYPE_EEPROM_START      = EP_TYPE_SEC_EEPROM_END + 1,
    EP_TYPE_EEPROM_M24C02     = EP_TYPE_EEPROM_START,
    EP_TYPE_EEPROM_M24C32,            
    EP_TYPE_EEPROM_END,

    // I2C switch
    EP_TYPE_I2CSW_START       = EP_TYPE_EEPROM_END + 1,
    EP_TYPE_I2CSW_TCA9544     = EP_TYPE_I2CSW_START,
    EP_TYPE_I2CSW_END,
};

enum endpoint_export {
    EP_NO_EXPORT,
    EP_EXPORT
};

/* IC register definitions */
enum tcal6408_regs {
    TCAL6408_REG_INPUT_PORT          = 0x00,
    TCAL6408_REG_OUTPUT_PORT         = 0x01,
    TCAL6408_REG_POLARITY_INV        = 0x02,
    TCAL6408_REG_CONFIGURATION       = 0x03,
    TCAL6408_REG_OUTPUT_DR_STR0      = 0x40,
    TCAL6408_REG_OUTPUT_DR_STR1      = 0x41,
    TCAL6408_REG_INPUT_LATCH_REG     = 0x42,
    TCAL6408_REG_PU_PD_ENABLE_REG    = 0x43,
    TCAL6408_REG_PU_PD_SELECTION_REG = 0x44,
    TCAL6408_REG_INT_MASK_REG        = 0x45,
    TCAL6408_REG_INT_STATUS_REG      = 0x46,
    TCAL6408_REG_OUTPUT_PORT_CFG_REG = 0x4f
};

enum tca9535_regs {
    TCA9535_REG_INPUT_PORT0          = 0x00,
    TCA9535_REG_INPUT_PORT1          = 0x01,
    TCA9535_REG_OUTPUT_PORT0         = 0x02,
    TCA9535_REG_OUTPUT_PORT1         = 0x03,
    TCA9535_REG_POLARITY_INV0        = 0x04,
    TCA9535_REG_POLARITY_INV1        = 0x05,
    TCA9535_REG_CONFIGURATION0       = 0x06,
    TCA9535_REG_CONFIGURATION1       = 0x07,
};

enum ak4137_regs {
    AK4137_REG_RST_MUTE   = 0x00,
    AK4137_REG_PCM_CONT0  = 0x01,
    AK4137_REG_PCM_CONT1  = 0x02,
    AK4137_REG_DSDI_CONT  = 0x03,
    AK4137_REG_DSDO_CONT  = 0x04,
    AK4137_REG_DSD_GAIN   = 0x05,
    AK4137_REG_DSD_STATUS = 0x06
};

enum ads7128_regs {
/* ADS7128 requires opcodes before reg address */
#define ADS7128_OPCODE_READ_REG  0x10
#define ADS7128_OPCODE_WRITE_REG 0x08
#define ADS7128_OPCODE_SET_BIT   0x18
#define ADS7128_OPCODE_CLR_BIT   0x20
#define ADS7128_OPCODE_READ_CONTIGUOUS_REG  0x30
    /* 0x00 - 0x0F */
    ADS7128_REG_SYSTEM_STATUS        = 0x00, /* [reset = 0x81] */
    ADS7128_REG_GENERAL_CFG          = 0x01, /* [reset = 0x00] */
    ADS7128_REG_DATA_CFG             = 0x02, /* [reset = 0x00] */
    ADS7128_REG_OSR_CFG              = 0x03, /* [reset = 0x00] */
    ADS7128_REG_OPMODE_CFG           = 0x04, /* [reset = 0x00] */
    ADS7128_REG_PIN_CFG              = 0x05, /* [reset = 0x00] */
    ADS7128_REG_GPIO_CFG             = 0x07, /* [reset = 0x00] */
    ADS7128_REG_GPO_DRIVE_CFG        = 0x09, /* [reset = 0x00] */
    ADS7128_REG_GPO_VALUE            = 0x0B, /* [reset = 0x00] */
    ADS7128_REG_GPI_VALUE            = 0x0D, /* [reset = 0x00] */
    ADS7128_REG_ZCD_BLANKING_CFG     = 0x0F, /* [reset = 0x00] */

    /* 0x10 - 0x1F */
    ADS7128_REG_SEQUENCE_CFG         = 0x10, /* [reset = 0x00] */
    ADS7128_REG_CHANNEL_SEL          = 0x11, /* [reset = 0x00] */
    ADS7128_REG_AUTO_SEQ_CH_SEL      = 0x12, /* [reset = 0x00] */
    ADS7128_REG_ALERT_CH_SEL         = 0x14, /* [reset = 0x00] */
    ADS7128_REG_ALERT_MAP            = 0x16, /* [reset = 0x00] */
    ADS7128_REG_ALERT_PIN_CFG        = 0x17, /* [reset = 0x00] */
    ADS7128_REG_EVENT_FLAG           = 0x18, /* [reset = 0x00] */
    ADS7128_REG_EVENT_HIGH_FLAG      = 0x1A, /* [reset = 0x00] */
    ADS7128_REG_EVENT_LOW_FLAG       = 0x1C, /* [reset = 0x00] */
    ADS7128_REG_EVENT_RGN            = 0x1E, /* [reset = 0x00] */

    /* 0x20 - 0x3F, per-channel thresholds and hysteresis (CH0...CH7) */
    ADS7128_REG_HYSTERESIS_CH0       = 0x20, /* [reset = 0xF0] */
    ADS7128_REG_HIGH_TH_CH0          = 0x21, /* [reset = 0xFF] */
    ADS7128_REG_EVENT_COUNT_CH0      = 0x22, /* [reset = 0x00] */
    ADS7128_REG_LOW_TH_CH0           = 0x23, /* [reset = 0x00] */
    ADS7128_REG_HYSTERESIS_CH1       = 0x24,
    ADS7128_REG_HIGH_TH_CH1          = 0x25,
    ADS7128_REG_EVENT_COUNT_CH1      = 0x26,
    ADS7128_REG_LOW_TH_CH1           = 0x27,
    ADS7128_REG_HYSTERESIS_CH2       = 0x28,
    ADS7128_REG_HIGH_TH_CH2          = 0x29,
    ADS7128_REG_EVENT_COUNT_CH2      = 0x2A,
    ADS7128_REG_LOW_TH_CH2           = 0x2B,
    ADS7128_REG_HYSTERESIS_CH3       = 0x2C,
    ADS7128_REG_HIGH_TH_CH3          = 0x2D,
    ADS7128_REG_EVENT_COUNT_CH3      = 0x2E,
    ADS7128_REG_LOW_TH_CH3           = 0x2F,
    ADS7128_REG_HYSTERESIS_CH4       = 0x30,
    ADS7128_REG_HIGH_TH_CH4          = 0x31,
    ADS7128_REG_EVENT_COUNT_CH4      = 0x32,
    ADS7128_REG_LOW_TH_CH4           = 0x33,
    ADS7128_REG_HYSTERESIS_CH5       = 0x34,
    ADS7128_REG_HIGH_TH_CH5          = 0x35,
    ADS7128_REG_EVENT_COUNT_CH5      = 0x36,
    ADS7128_REG_LOW_TH_CH5           = 0x37,
    ADS7128_REG_HYSTERESIS_CH6       = 0x38,
    ADS7128_REG_HIGH_TH_CH6          = 0x39,
    ADS7128_REG_EVENT_COUNT_CH6      = 0x3A,
    ADS7128_REG_LOW_TH_CH6           = 0x3B,
    ADS7128_REG_HYSTERESIS_CH7       = 0x3C,
    ADS7128_REG_HIGH_TH_CH7          = 0x3D,
    ADS7128_REG_EVENT_COUNT_CH7      = 0x3E,
    ADS7128_REG_LOW_TH_CH7           = 0x3F,

    /* 0x60 - 0x6F, per-channel max registers (CH0...CH7, LSB/MSB) */
    ADS7128_REG_MAX_CH0_LSB          = 0x60,
    ADS7128_REG_MAX_CH0_MSB          = 0x61,
    ADS7128_REG_MAX_CH1_LSB          = 0x62,
    ADS7128_REG_MAX_CH1_MSB          = 0x63,
    ADS7128_REG_MAX_CH2_LSB          = 0x64,
    ADS7128_REG_MAX_CH2_MSB          = 0x65,
    ADS7128_REG_MAX_CH3_LSB          = 0x66,
    ADS7128_REG_MAX_CH3_MSB          = 0x67,
    ADS7128_REG_MAX_CH4_LSB          = 0x68,
    ADS7128_REG_MAX_CH4_MSB          = 0x69,
    ADS7128_REG_MAX_CH5_LSB          = 0x6A,
    ADS7128_REG_MAX_CH5_MSB          = 0x6B,
    ADS7128_REG_MAX_CH6_LSB          = 0x6C,
    ADS7128_REG_MAX_CH6_MSB          = 0x6D,
    ADS7128_REG_MAX_CH7_LSB          = 0x6E,
    ADS7128_REG_MAX_CH7_MSB          = 0x6F,

    /* 0x80 - 0x8F, per-channel min registers (CH0...CH7, LSB/MSB) */
    ADS7128_REG_MIN_CH0_LSB          = 0x80,
    ADS7128_REG_MIN_CH0_MSB          = 0x81,
    ADS7128_REG_MIN_CH1_LSB          = 0x82,
    ADS7128_REG_MIN_CH1_MSB          = 0x83,
    ADS7128_REG_MIN_CH2_LSB          = 0x84,
    ADS7128_REG_MIN_CH2_MSB          = 0x85,
    ADS7128_REG_MIN_CH3_LSB          = 0x86,
    ADS7128_REG_MIN_CH3_MSB          = 0x87,
    ADS7128_REG_MIN_CH4_LSB          = 0x88,
    ADS7128_REG_MIN_CH4_MSB          = 0x89,
    ADS7128_REG_MIN_CH5_LSB          = 0x8A,
    ADS7128_REG_MIN_CH5_MSB          = 0x8B,
    ADS7128_REG_MIN_CH6_LSB          = 0x8C,
    ADS7128_REG_MIN_CH6_MSB          = 0x8D,
    ADS7128_REG_MIN_CH7_LSB          = 0x8E,
    ADS7128_REG_MIN_CH7_MSB          = 0x8F,

    /* 0xA0 - 0xAF, per-channel recent data (CH0...CH7, LSB/MSB) */
    ADS7128_REG_RECENT_CH0_LSB       = 0xA0,
    ADS7128_REG_RECENT_CH0_MSB       = 0xA1,
    ADS7128_REG_RECENT_CH1_LSB       = 0xA2,
    ADS7128_REG_RECENT_CH1_MSB       = 0xA3,
    ADS7128_REG_RECENT_CH2_LSB       = 0xA4,
    ADS7128_REG_RECENT_CH2_MSB       = 0xA5,
    ADS7128_REG_RECENT_CH3_LSB       = 0xA6,
    ADS7128_REG_RECENT_CH3_MSB       = 0xA7,
    ADS7128_REG_RECENT_CH4_LSB       = 0xA8,
    ADS7128_REG_RECENT_CH4_MSB       = 0xA9,
    ADS7128_REG_RECENT_CH5_LSB       = 0xAA,
    ADS7128_REG_RECENT_CH5_MSB       = 0xAB,
    ADS7128_REG_RECENT_CH6_LSB       = 0xAC,
    ADS7128_REG_RECENT_CH6_MSB       = 0xAD,
    ADS7128_REG_RECENT_CH7_LSB       = 0xAE,
    ADS7128_REG_RECENT_CH7_MSB       = 0xAF,

    /* 0xC0 - 0xC2, RMS registers */
    ADS7128_REG_RMS_CFG              = 0xC0,
    ADS7128_REG_RMS_LSB              = 0xC1,
    ADS7128_REG_RMS_MSB              = 0xC2,

    /* 0xC3 - 0xD1, GPO trigger event selects (skipping reserved) */
    ADS7128_REG_GPO0_TRIG_EVENT_SEL  = 0xC3, /* [reset = 0x2] */
    ADS7128_REG_GPO1_TRIG_EVENT_SEL  = 0xC5, /* [reset = 0x2] */
    ADS7128_REG_GPO2_TRIG_EVENT_SEL  = 0xC7, /* [reset = 0x2] */
    ADS7128_REG_GPO3_TRIG_EVENT_SEL  = 0xC9, /* [reset = 0x2] */
    ADS7128_REG_GPO4_TRIG_EVENT_SEL  = 0xCB, /* [reset = 0x2] */
    ADS7128_REG_GPO5_TRIG_EVENT_SEL  = 0xCD, /* [reset = 0x2] */
    ADS7128_REG_GPO6_TRIG_EVENT_SEL  = 0xCF, /* [reset = 0x2] */
    ADS7128_REG_GPO7_TRIG_EVENT_SEL  = 0xD1, /* [reset = 0x2] */

    /* 0xE3 - 0xEB, GPO configuration and values */
    ADS7128_REG_GPO_VALUE_ZCD_CFG_CH0_CH3 = 0xE3, /* [reset = 0x0] */
    ADS7128_REG_GPO_VALUE_ZCD_CFG_CH4_CH7 = 0xE4, /* [reset = 0x0] */
    ADS7128_REG_GPO_ZCD_UPDATE_EN         = 0xE7,      /* [reset = 0x0] */
    ADS7128_REG_GPO_TRIGGER_CFG           = 0xE9,      /* [reset = 0x0] */
    ADS7128_REG_GPO_VALUE_TRIG            = 0xEB       /* [reset = 0x0] */
};

// In fusion_io.h
enum ep9512t_regs {
    EP9512T_REG_VENDOR_ID_0     = 0x00, // Vendor ID (0x17)
    EP9512T_REG_VENDOR_ID_1     = 0x01, // Vendor ID (0x7A)
    EP9512T_REG_DEVICE_ID_0     = 0x02, // Device ID (0x95)
    EP9512T_REG_DEVICE_ID_1     = 0x03, // Device ID (0x12)
    EP9512T_REG_VERSION         = 0x04, // Firmware version
    EP9512T_REG_GENERAL_INFO    = 0x08, // Status (hot plug, etc.)
    EP9512T_REG_CEC_EVENT_FLAG  = 0x09, // CEC event flag
    EP9512T_REG_GENERAL_CTRL    = 0x10, // Power, audio path
    EP9512T_REG_TX_CTRL         = 0x11, // TX on, HDMI mode, mute
    EP9512T_REG_AUDIO_CFG       = 0x12, // Audio input, layout, PCM
    EP9512T_REG_SYSTEM_STATUS   = 0x20, // AUD_OK, LAYOUT
    EP9512T_REG_AUDIO_STATUS    = 0x22, // Audio type, sample freq
    EP9512T_REG_CHAN_STATUS_EARC= 0x23, // Channel status (eARC, 5 bytes)
    EP9512T_REG_ADO_INFOFRAME   = 0x28, // Audio Infoframe (6 bytes)
    EP9512T_REG_EARC_LATENCY    = 0x37, // eARC latency
    EP9512T_REG_EDID            = 0xFF  // EDID 256-byte block
};

struct endpoint {
    char                    name[MAX_STRING];
    enum endpoint_type      type;
    enum endpoint_export    export;
    u8                      ioexp_id;
    unsigned short          i2c_addr;

    u16                     in_ch_bm;
    u16                     out_ch_bm;

    struct i2c_client       *i2c_client;

    size_t                  num_gpios;
    struct endpoint_gpio    *gpios;
    size_t                  num_cmds;
    struct endpoint_cmd     *cmds;

    int                     (*ep_handle_irq)(struct endpoint_gpio *);
    int                     (*ep_configure)(struct endpoint *, struct endpoint_cmd *);
    
    struct base_device      *parent_base_device;
    struct io_card          *parent_io_card;

    struct device           *sysfs_dev;
};


/* eeprom data */
#define ID_DATA_VER_MAJ 0
#define ID_DATA_VER_MIN 1
struct id_data {
    u8      ver_maj;
    u8      ver_min;
    char    model[MAX_STRING];
    char    sn[MAX_STRING];
    u8      type;
};


/* io card */
enum io_card_type {
    /* NONE--terminator */
    IC_TYPE_NONE       = 0,

    /* audio */
    // analog
    IC_TYPE_AN_START   = IC_TYPE_NONE + 1,
    IC_TYPE_AN_IN      = IC_TYPE_AN_START,
    IC_TYPE_AN_OUT,
    IC_TYPE_AN_IN_OUT,
    IC_TYPE_AN_END,

    // digital
    IC_TYPE_HDMI_START = IC_TYPE_AN_END + 1,
    IC_TYPE_HDMI       = IC_TYPE_HDMI_START,
    IC_TYPE_HDMI_END,

    // amplifier
    IC_TYPE_AMP_START = IC_TYPE_HDMI_END + 1,
    IC_TYPE_AMP       = IC_TYPE_AMP_START,
    IC_TYPE_AMP_END,

    /* non-audio */
    IC_TYPE_GPIO_START = IC_TYPE_HDMI_END + 1,
    IC_TYPE_GPIO       = IC_TYPE_GPIO_START,
    IC_TYPE_GPIO_END,

    IC_TYPE_PWR_START = IC_TYPE_GPIO_END + 1,
    IC_TYPE_PWR       = IC_TYPE_PWR_START,
    IC_TYPE_PWR_END
};

struct io_card {
    u8                      num_inputs;
    u8                      num_outputs;
    u8                      slot;        // slot IO arch only

    struct id_data          data;

    struct endpoint         *sec_eeprom;
    
    size_t                  num_eps;
    struct endpoint         *endpoints;
    size_t                  num_gpios;
    struct endpoint_gpio    *gpios;

    struct device           *sysfs_dev; 
};


/* base device */
enum base_device_type {
    BD_TYPE_NONE,

    BD_TYPE_FIXED_IO_START = BD_TYPE_NONE + 1,
    BD_TYPE_FUSION_C0      = BD_TYPE_FIXED_IO_START,
    BD_TYPE_FIXED_IO_END,

    BD_TYPE_SLOT_IO_START  = BD_TYPE_FIXED_IO_END + 1,
    BD_TYPE_SLOT_IO_END,
};

struct base_device {
    bool                    has_slot_io;

    struct id_data          data;

    size_t                  num_eps;
    struct endpoint         *endpoints;
    size_t                  num_gpios;
    struct endpoint_gpio    *gpios;
    size_t                  num_ics;
    struct io_card          *io_cards;

    struct device           *sysfs_dev;
};

// Driver data
struct fusion_io_base_drvdata {
    struct platform_device *pdev;
    struct base_device     *fusion_device;
    struct i2c_adapter     *i2c_adapter;
    struct i2c_mux_core    *muxc;
    bool                   ready;
};


// defined in fusion_io_config.c
extern const enum endpoint_type   default_ep_types[];
extern const struct endpoint      *default_eps[];

extern const enum io_card_type    default_ic_types[];
extern const struct io_card       *default_ics[];

extern const enum base_device_type default_bd_types[];
extern const struct base_device    *default_bds[];


// x_configure callbacks defined in fusion_io_device.c
int ads7128_configure(struct endpoint *, struct endpoint_cmd *);
int tca9544_configure(struct endpoint *, struct endpoint_cmd *);


// x_handle_irq callbacks defined in fusion_io_device.c
int tca9544_handle_irq(struct endpoint_gpio *);
int tcal6408_handle_irq(struct endpoint_gpio *);
int tca9535_handle_irq(struct endpoint_gpio *);
int ads7128_handle_irq(struct endpoint_gpio *);
int ep9512t_handle_irq(struct endpoint_gpio *);

#endif
