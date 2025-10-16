/*
 *  ZoneGroup.cpp - see header for description.
 */
#include "ZoneGroup.h"

// No additional logic yet; placeholder for future aggregation/event features.
::OcaLiteList<::OcaLitePort> ZoneGroup::s_emptyPorts;

#ifdef OCA_LITE_CONTROLLER
void ZoneGroup::SendValue()
{
    ControllerCmdIntfc setNameCmd;

    setNameCmd.cmd = CTRL_CMD_ZONE_NAME_SET;
    setNameCmd.ono = GetObjectNumber();

    std::string temp;
    temp.assign(m_name.GetString());
    if (temp.size() > 8)
    {
        temp.assign(temp,0,8);
    }
    memcpy(setNameCmd.val.char_val, temp.c_str(), temp.size());

    PushToMsgQueue(setNameCmd);
}
#endif
