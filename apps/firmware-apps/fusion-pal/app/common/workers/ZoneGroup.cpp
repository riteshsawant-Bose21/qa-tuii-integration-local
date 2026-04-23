/*
 *  ZoneGroup.cpp - see header for description.
 */
#include "ZoneGroup.h"

// No additional logic yet; placeholder for future aggregation/event features.
::OcaLitePort ZoneGroup::dummy;

#ifdef OCA_LITE_CONTROLLER
void ZoneGroup::SendValue()
{
    ControllerCmdIntfc setNameCmd;

    setNameCmd.cmd = CTRL_CMD_ZONE_NAME_SET;
    setNameCmd.ono = GetObjectNumber();

    std::string temp;
    temp.assign(m_name.GetString());
    if (temp.size() > (CMD_INTFC_MAX_STRING_LENGTH-1))
    {
        temp.assign(temp,0,(CMD_INTFC_MAX_STRING_LENGTH-1));
    }
    strcpy(setNameCmd.val.char_val, temp.c_str());

    PushToMsgQueue(setNameCmd);
}
#endif
