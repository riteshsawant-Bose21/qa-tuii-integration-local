/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteMuteActuator - Concrete implementation of OcaLiteMute
 *
 */

// ---- Include system wide include files ----
#include <iostream>

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "ConcreteMuteActuator.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>

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

ConcreteMuteActuator::ConcreteMuteActuator(::OcaONo objectNumber,
                                           ::OcaBoolean lockable,
                                           const ::OcaLiteString &role,
                                           const ::OcaLiteList<::OcaLitePort> &ports,
                                           const std::string &gainID)
    : ::OcaLiteMute(objectNumber, lockable, role, ports),
      m_actualMuteState(OCAMUTESTATE_UNMUTED), // Initialize to unmuted
      m_gainID(gainID)
{
    // Enhanced logging with dynamic information
    OCA_LOG_INFO("=== ConcreteMuteActuator Created ===");
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

::OcaLiteStatus ConcreteMuteActuator::SetStateValue(::OcaLiteMuteState muteState)
{
    try
    {
        // Simulate setting the mute state in the actual audio processing hardware/software
        // In a real implementation, this would interface with your DSP or audio hardware

        OCA_LOG_INFO_PARAMS("[MUTE] Setting mute state to %s (Gain ID: %s)",
                            muteStateToString(muteState), m_gainID.empty() ? "N/A" : m_gainID.c_str());

        // Here you would typically:
        // 1. Send the mute command to your audio processing hardware/DSP
        // 2. Update internal audio processing parameters
        // 3. Validate that the setting was successful

        // Example hardware interface calls (commented out):
        // audioHardware.setChannelMute(channelId, muteState == OCAMUTESTATE_MUTED);
        // dspLibrary.updateMuteParameter(muteState);
        // registerWrite(MUTE_REGISTER, muteState == OCAMUTESTATE_MUTED ? 1 : 0);

        // For this example, we'll just store the value and simulate successful setting
        m_actualMuteState = muteState;

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

::OcaLiteStatus ConcreteMuteActuator::GetStateValue(::OcaLiteMuteState &muteState) const
{
    try
    {
        // In a real implementation, this would read the actual mute state from
        // your audio processing hardware/DSP to ensure accuracy

        // Example hardware read calls (commented out):
        // bool isMuted = audioHardware.getChannelMute(channelId);
        // muteState = isMuted ? OCAMUTESTATE_MUTED : OCAMUTESTATE_UNMUTED;
        // int muteRegValue = registerRead(MUTE_REGISTER_READBACK);
        // muteState = (muteRegValue == 1) ? OCAMUTESTATE_MUTED : OCAMUTESTATE_UNMUTED;

        // For this example, we'll return the stored value
        muteState = m_actualMuteState;

        OCA_LOG_INFO_PARAMS("[MUTE] Getting current mute state: %s (Gain ID: %s)", muteStateToString(muteState), m_gainID.empty() ? "N/A" : m_gainID.c_str());

        return OCASTATUS_OK;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[MUTE] Error getting mute state: %s", e.what());
        return OCASTATUS_PROCESSING_FAILED;
    }
}
