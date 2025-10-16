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
#include "HostInterface/CommandInterface/CommandInterface.h"
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
    : ::OcaLiteSwitch(objectNumber, lockable, role, ports, minPosition, maxPosition, positionNames, positionEnable),
      m_zoneID(zoneID), m_zoneONo(zoneONo), m_cmdQueue(cmdQueue)
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
    ControlPal_MsgQueue<ControllerCmdIntfc> *cmdQueue =
                         static_cast<ControlPal_MsgQueue<ControllerCmdIntfc> * >(m_cmdQueue);
    ControllerCmdIntfc setPositionCmd;
    setPositionCmd.cmd = CTRL_CMD_SOURCE_SET;
    setPositionCmd.ono = m_zoneONo; // Zone ONo
    setPositionCmd.val.int_val = static_cast<uint32_t>(position);

    // Call fn. to send Source POSITION value command to UI task
    cmdQueue->push(setPositionCmd);

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
