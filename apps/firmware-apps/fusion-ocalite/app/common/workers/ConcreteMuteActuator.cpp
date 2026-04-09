/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteMuteActuator - Concrete implementation of OcaLiteMute
 *
 */

// ---- Include local include files ----
#include "ConcreteMuteActuator.h"
#include "../FusionAudioBridge.h"
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

ConcreteMuteActuator::~ConcreteMuteActuator()
{
    // Destructor implementation - ensures vtable is properly generated
}

::OcaLiteStatus ConcreteMuteActuator::SetStateValue(::OcaLiteMuteState muteState)
{

    // Set the mute state value called from some aes70 client
    // This will make an update to Fusion and doesnt update internal state
    // internal state is updated by fusion message handling

    try
    {

        OCA_LOG_INFO_PARAMS("[MUTE] Setting mute state to %s (Gain ID: %s)",
                            muteStateToString(muteState), m_gainID.empty() ? "N/A" : m_gainID.c_str());

        if (!m_gainID.empty())
        {
            FusionAudioBridge &bridge = FusionAudioBridge::getInstance();
            if (bridge.isInitialized())
            {
                bool muteStateBool = (muteState == OCAMUTESTATE_MUTED);
                bridge.sendMuteToFusion(m_gainID, muteStateBool);
                OCA_LOG_INFO_PARAMS("[MUTE] Sent mute state to Fusion: %s = %s",
                                    m_gainID.c_str(), muteStateBool ? "MUTED" : "UNMUTED");
            }
            else
            {
                OCA_LOG_WARNING("[MUTE] FusionAudioBridge not initialized - mute state not sent to Fusion");
            }
        }
        else
        {
            OCA_LOG_WARNING("[MUTE] No gain ID configured - mute state not sent to Fusion");
        }
        return OCASTATUS_OK;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[MUTE] Error setting mute state: %s", e.what());
        return OCASTATUS_PROCESSING_FAILED;
    }
}

void ConcreteMuteActuator::handleFusionMuteMessage(bool muteState)
{
    try
    {
        ::OcaLiteMuteState ocaState = muteState ? OCAMUTESTATE_MUTED : OCAMUTESTATE_UNMUTED;

        OCA_LOG_INFO_PARAMS("[MUTE] Handling Fusion mute message: %s (Gain ID: %s)",
                            muteState ? "MUTED" : "UNMUTED", m_gainID.c_str());

        // Set the mute value using the base class method
        // This will update the internal state AND notify AES70 clients, but won't send back to Fusion

        ::OcaLiteStatus status = SetStateFromFusion(ocaState);

        if (OCASTATUS_OK == status)
        {
            OCA_LOG_INFO_PARAMS("[MUTE] ✓ Fusion mute state applied: %s (Gain ID: %s)",
                                muteState ? "MUTED" : "UNMUTED", m_gainID.c_str());
        }
        else
        {
            OCA_LOG_ERROR_PARAMS("[MUTE] Failed to apply Fusion mute state: %s (Gain ID: %s)",
                                 muteState ? "MUTED" : "UNMUTED", m_gainID.c_str());
        }
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[MUTE] Exception in handleFusionMuteMessage: %s", e.what());
    }
}
