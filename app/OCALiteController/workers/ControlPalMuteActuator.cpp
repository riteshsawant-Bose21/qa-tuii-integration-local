/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ControlPalMuteActuator - ControlPal implementation of OcaLiteMute
 *
 */

// ---- Include system wide include files ----
#include <iostream>

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "ControlPalMuteActuator.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include "../PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#include "../ControlPalOcaUtils.h"

// ---- Helper types and constants ----

// ---- Helper functions ----

/**
 * Convert mute state to human-readable string
 */
inline const char *muteStateToString(::OcaLiteMuteState state)
{
    switch (state)
    {
    case OCAMUTESTATE_MUTED:
        return "MUTED";
    case OCAMUTESTATE_UNMUTED:
        return "UNMUTED";
    default:
        return "UNKNOWN";
    }
}

// ---- Local data ----

// ---- Class Implementation ----

ControlPalMuteActuator::ControlPalMuteActuator(::OcaONo objectNumber,
                                           ::OcaBoolean lockable,
                                           const ::OcaLiteString &role,
                                           const ::OcaLiteList<::OcaLitePort> &ports,
                                           const std::string &gainID,
                                           const ::OcaONo zoneONo,
                                           void *cmdQueue)
    : ::OcaLiteMute(objectNumber, lockable, role, ports),
      ControlPalMsgInterface(cmdQueue),
      m_gainID(gainID), m_zoneONo(zoneONo)
{
    // Enhanced logging with dynamic information
    OCA_LOG_INFO("=== ControlPalMuteActuator Created ===");
    OCA_LOG_INFO_PARAMS("Object Number: %u", objectNumber);
    OCA_LOG_INFO_PARAMS("Role: %s", role.GetString().c_str());
    OCA_LOG_INFO_PARAMS("Gain ID: %s", m_gainID.empty() ? "N/A" : m_gainID.c_str());
    OCA_LOG_INFO_PARAMS("Initial State: %s", muteStateToString(OCAMUTESTATE_UNMUTED));
    OCA_LOG_INFO_PARAMS("Number of Ports: %u", ports.GetCount());

    // Display port information
    for (::OcaUint16 i = 0; i < ports.GetCount(); i++)
    {
        const ::OcaLitePort &port = ports.GetItem(i);
        std::string direction = (port.GetID().GetMode() == OCAPORTMODE_INPUT) ? "INPUT" : "OUTPUT";
        OCA_LOG_INFO_PARAMS("  Port %u: %s (%s #%u)",
                            (i + 1),
                            port.GetName().GetString().c_str(),
                            direction.c_str(),
                            port.GetID().GetIndex());
    }
    OCA_LOG_INFO("====================================");
}

::OcaLiteStatus ControlPalMuteActuator::SetStateValue(::OcaLiteMuteState muteState)
{
    try
    {
        OCA_LOG_INFO_PARAMS("[MUTE] Setting mute state to %s (Gain ID: %s)",
                            muteStateToString(muteState), m_gainID.empty() ? "N/A" : m_gainID.c_str());

        // Call fn. to send MUTE value command to UI task
        SendValue();

        OCA_LOG_INFO_PARAMS("[MUTE] ✓ Mute state successfully set to %s (Gain ID: %s)",
                            muteStateToString(muteState), m_gainID.empty() ? "N/A" : m_gainID.c_str());

        return OCASTATUS_OK;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[MUTE] Error setting mute state: %s", e.what());
        return OCASTATUS_PROCESSING_FAILED;
    }
}

void ControlPalMuteActuator::SendValue()
{
    ControllerCmdIntfc setMuteCmd;
    OcaLiteMuteState muteState;

    GetState(muteState);

    setMuteCmd.cmd = CTRL_CMD_MUTE_SET;
    setMuteCmd.ono = m_zoneONo; //Zone Ono
    setMuteCmd.val.int_val = static_cast<uint32_t>(muteState);

    PushToMsgQueue(setMuteCmd);
}
