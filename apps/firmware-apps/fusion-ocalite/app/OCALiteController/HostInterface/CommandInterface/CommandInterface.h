#ifndef _COMMANDINTERFACE_H
#define _COMMANDINTERFACE_H

#define CMD_INTFC_MUTE_STATE_MUTED    1
#define CMD_INTFC_MUTE_STATE_UNMUTED  2
#define CMD_INTFC_MAX_STRING_LENGTH   12

typedef enum commands  : uint32_t
{
    CTRL_CMD_MIN       = 0,
    CTRL_CMD_ZONE_CFG_START,   // Initial configuration START string (site name)
    CTRL_CMD_ZONE_CFG_END,     // Initial configuration END
    CTRL_CMD_ZONE_NAME_SET,    // "name" (max CMD_INTFC_MAX_STRING_LENGTH chars)
    CTRL_CMD_SOURCE_COUNT_SET, // <uint32>
    CTRL_CMD_SOURCE_1_SET,     // "name" (CMD_INTFC_MAX_STRING_LENGTH chars)
    CTRL_CMD_SOURCE_2_SET,     // "name" (CMD_INTFC_MAX_STRING_LENGTH chars)
    CTRL_CMD_SOURCE_3_SET,     // "name" (CMD_INTFC_MAX_STRING_LENGTH chars)
    CTRL_CMD_SOURCE_4_SET,     // "name" (CMD_INTFC_MAX_STRING_LENGTH chars)
    CTRL_CMD_SOURCE_5_SET,     // "name" (CMD_INTFC_MAX_STRING_LENGTH chars)
    CTRL_CMD_GAIN_MIN_VAL,     // <float>
    CTRL_CMD_GAIN_MAX_VAL,     // <float>
    CTRL_CMD_GAIN_GET,         // none
    CTRL_CMD_MUTE_GET,         // none
    CTRL_CMD_SOURCE_GET,       // <uint32> (Current position) 
    CTRL_CMD_GAIN_SET,         // <float>, delta value (+x incr., -x decr.)
    CTRL_CMD_MUTE_SET,         // <uint32> (state=1/2)
    CTRL_CMD_SOURCE_SET,       // <uint32> (New Position) 
    // Sideband  Commands start here
    CTRL_CMD_WINK_SET,         // <uint32> (on/off)
    CTRL_CMD_REV_WINK_SET,     // <uint32> (on/off)
    CTRL_CMD_MAX
} ControlerCmds;

typedef struct CmdIntfc 
{
    // ThreadX message queue has a max size of 
    ControlerCmds cmd;
    uint32_t      ono;
    union value {
        uint32_t  int_val;
        float     flt_val;
        char      char_val[CMD_INTFC_MAX_STRING_LENGTH];
    }val;
} ControllerCmdIntfc;

#endif
