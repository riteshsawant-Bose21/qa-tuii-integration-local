#ifndef _COMMANDINTERFACE_H
#define _COMMANDINTERFACE_H

typedef enum commands  : uint32_t
{
    CTRL_CMD_MIN       = 0,
    CTRL_CMD_ZONE_NAME_SET,    // "name" (max 12 chars)
    CTRL_CMD_SOURCE_COUNT_SET, // <uint32>
    CTRL_CMD_SOURCE_1_SET,     // "name" (max 12 chars)
    CTRL_CMD_SOURCE_2_SET,     // "name" (max 12 chars)
    CTRL_CMD_SOURCE_3_SET,     // "name" (max 12 chars)
    CTRL_CMD_SOURCE_4_SET,     // "name" (max 12 chars)
    CTRL_CMD_SOURCE_5_SET,     // "name" (max 12 chars)
    CTRL_CMD_GAIN_GET,         // none
    CTRL_CMD_MUTE_GET,         // none
    CTRL_CMD_SOURCE_GET,       // <uint32> (Current position) 
    CTRL_CMD_GAIN_SET,         // <uint32>
    CTRL_CMD_MUTE_SET,         // <uint32> (state)
    CTRL_CMD_SOURCE_SET,       // <uint32> (New Position) 
    CTRL_CMD_WINK_SET,         // <uint32> (on/off)
    CTRL_CMD_REV_WINK_SET,     // <uint32> (on/off)
    CTRL_CMD_MAX
} ControlerCmds;

typedef struct CmdIntfc 
{
    // ThreadX message queue has a max size of 
    ControlerCmds cmd;
    union value {
        uint32_t  int_val;
        float     flt_val;
        uint8_t   char_val[12];
    }val;
} ControllerCmdIntfc;

#endif
