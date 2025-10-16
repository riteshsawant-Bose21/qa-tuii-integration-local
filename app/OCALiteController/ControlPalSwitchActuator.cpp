/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ControlPalSwitchActuator - ControlPal implementation of OcaLiteSwitch
 */

#include "ControlPalSwitchActuator.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include "PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#include "ControlPalOcaUtils.h"

ControlPalSwitchActuator::ControlPalSwitchActuator(::OcaONo objectNumber,
                                               ::OcaBoolean lockable,
                                               const ::OcaLiteString &role,
                                               const ::OcaLiteList<::OcaLitePort> &ports,
                                               ::OcaUint16 minPosition,
                                               ::OcaUint16 maxPosition,
                                               const ::OcaLiteList<::OcaLiteString> &positionNames,
                                               const ::OcaLiteList<::OcaBoolean> &positionEnable,
                                               const std::string &zoneID,
                                               const ::OcaONo zoneONo,
                                               void *cmdQueue)
    : ::OcaLiteSwitch(objectNumber, lockable, role, ports,
                      minPosition, maxPosition, positionNames, positionEnable),
      ControlPalMsgInterface(cmdQueue),
      m_zoneID(zoneID), m_zoneONo(zoneONo)
{
    OCA_LOG_INFO("=== ControlPalSwitchActuator Created ===");
    OCA_LOG_INFO_PARAMS("Object Number: %u", objectNumber);
    OCA_LOG_INFO_PARAMS("Role: %s", role.GetString().c_str());
    OCA_LOG_INFO_PARAMS("Zone ID: %s", m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    OCA_LOG_INFO_PARAMS("Positions: %u - %u", minPosition, maxPosition);
    OCA_LOG_INFO_PARAMS("Number of Position Names: %u", positionNames.GetCount());
}

::OcaLiteStatus ControlPalSwitchActuator::SetPositionValue(::OcaUint16 position)
{
    // Call fn. to send Source POSITION value command to UI task
    SendValue();

    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionValue -> %u (Zone ID: %s)", position, m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ControlPalSwitchActuator::SetPositionNameValue(::OcaUint16 index, const ::OcaLiteString &name)
{
    // Could validate name length or character set here.
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionNameValue index=%u name=%s (Zone ID: %s)", index, name.GetString().c_str(), m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ControlPalSwitchActuator::SetPositionNamesValue(const ::OcaLiteList<::OcaLiteString> &names)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionNamesValue count=%u (Zone ID: %s)", names.GetCount(), m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ControlPalSwitchActuator::SetPositionEnabledValue(::OcaUint16 index, ::OcaBoolean enabled)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionEnabledValue index=%u enabled=%u (Zone ID: %s)", index, enabled, m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ControlPalSwitchActuator::SetPositionEnabledsValue(const ::OcaLiteList<::OcaBoolean> &enableds)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionEnabledsValue count=%u (Zone ID: %s)", enableds.GetCount(), m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

void ControlPalSwitchActuator::SendValue()
{
    ::OcaUint16 posVal, minVal, maxVal;
    ControllerCmdIntfc setPositionCmd;

    GetPosition( posVal, minVal, maxVal);

    setPositionCmd.cmd = CTRL_CMD_SOURCE_SET;
    setPositionCmd.ono = m_zoneONo; // Zone ONo
    setPositionCmd.val.int_val = static_cast<uint32_t>(posVal);

    PushToMsgQueue(setPositionCmd);
}

void ControlPalSwitchActuator::SendConfigurationValue()
{
    {
        ::OcaUint16 posVal, minVal, maxVal;
        ControllerCmdIntfc setPositionCmd;

        GetPosition( posVal, minVal, maxVal);

        // Send # positions
        setPositionCmd.cmd = CTRL_CMD_SOURCE_COUNT_SET;
        setPositionCmd.ono = m_zoneONo; // Zone ONo
        setPositionCmd.val.int_val = static_cast<uint32_t>(maxVal - minVal + 1);
        PushToMsgQueue(setPositionCmd);
    }

    // Send names
    {
        ::OcaLiteList<::OcaLiteString> names;
        ControllerCmdIntfc setPositionCmd;

        GetPositionNamesValue(names);
        int8_t posCount = names.GetCount();

        // Only a max. of 5 positions supported
        if (posCount > 5)
        {
            posCount = 5;
        }

        // Position-1
        setPositionCmd.cmd = CTRL_CMD_SOURCE_1_SET;
        setPositionCmd.ono = m_zoneONo; // Zone ONo
        std::string temp;
        temp.assign((names.GetItem(0).GetString()));
        if (temp.size() > 8)
        {
            temp.assign(temp,0,8);
        }
        memcpy(setPositionCmd.val.char_val, temp.c_str(), temp.size());
        PushToMsgQueue(setPositionCmd);

        // Position-2
        if (--posCount > 0)
        {
            setPositionCmd.cmd = CTRL_CMD_SOURCE_2_SET;
            setPositionCmd.ono = m_zoneONo; // Zone ONo
            temp.assign((names.GetItem(1).GetString()));
            if (temp.size() > 8)
            {
                temp.assign(temp,0,8);
            }
            memcpy(setPositionCmd.val.char_val, temp.c_str(), temp.size());
            PushToMsgQueue(setPositionCmd);
        }

        // Position-3
        if (--posCount > 0)
        {
            setPositionCmd.cmd = CTRL_CMD_SOURCE_3_SET;
            setPositionCmd.ono = m_zoneONo; // Zone ONo
            temp.assign((names.GetItem(2).GetString()));
            if (temp.size() > 8)
            {
                temp.assign(temp,0,8);
            }
            memcpy(setPositionCmd.val.char_val, temp.c_str(), temp.size());
            PushToMsgQueue(setPositionCmd);
        }

        // Position-4
        if (--posCount > 0)
        {
            setPositionCmd.cmd = CTRL_CMD_SOURCE_4_SET;
            setPositionCmd.ono = m_zoneONo; // Zone ONo
            temp.assign((names.GetItem(3).GetString()));
            if (temp.size() > 8)
            {
                temp.assign(temp,0,8);
            }
            memcpy(setPositionCmd.val.char_val, temp.c_str(), temp.size());
            PushToMsgQueue(setPositionCmd);
        }

        // Position-5
        if (--posCount > 0)
        {
            setPositionCmd.cmd = CTRL_CMD_SOURCE_5_SET;
            setPositionCmd.ono = m_zoneONo; // Zone ONo
            temp.assign((names.GetItem(4).GetString()));
            if (temp.size() > 8)
            {
                temp.assign(temp,0,8);
            }
            memcpy(setPositionCmd.val.char_val, temp.c_str(), temp.size());
            PushToMsgQueue(setPositionCmd);
        }
    }
}

