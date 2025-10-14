/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteGainActuator - Concrete implementation of OcaLiteGain
 *
 */

// ---- Include system wide include files ----
#include <iostream>
#include <cmath>
#include <string>
#include <sstream>
#include <mutex>

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "ConcreteGainActuator.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include "../FusionAudioBridge.h"

// ---- Helper types and constants ----

// ---- Helper functions ----

/**
 * Convert dB to linear gain
 */
inline double dbToLinear(double db)
{
    return pow(10.0, db / 20.0);
}

/**
 * Convert linear gain to dB
 */
inline double linearToDb(double linear)
{
    return 20.0 * log10(linear);
}

// ---- Local data ----

// ---- Class Implementation ----

ConcreteGainActuator::ConcreteGainActuator(::OcaONo objectNumber,
                                           ::OcaBoolean lockable,
                                           const ::OcaLiteString &role,
                                           const ::OcaLiteList<::OcaLitePort> &ports,
                                           ::OcaDB minGain,
                                           ::OcaDB maxGain,
                                           const std::string &gainID)
    : ::OcaLiteGain(objectNumber, lockable, role, ports, minGain, maxGain),
      m_gainID(gainID),
      m_processingFusionUpdate(false)
{
    // Enhanced logging with dynamic information
    OCA_LOG_INFO("=== ConcreteGainActuator Created ===");
    OCA_LOG_INFO_PARAMS("Object Number: %u", objectNumber);
    OCA_LOG_INFO_PARAMS("Role: %s", role.GetString().c_str());
    OCA_LOG_INFO_PARAMS("Gain ID: %s", m_gainID.empty() ? "N/A" : m_gainID.c_str());
    OCA_LOG_INFO_PARAMS("Gain Range: %.2f dB to %.2f dB", minGain, maxGain);
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

::OcaLiteStatus ConcreteGainActuator::SetGainValue(::OcaDB gain)
{
    return SetGainValue(gain, "aes70");
}

::OcaLiteStatus ConcreteGainActuator::SetGainValue(::OcaDB gain, const std::string &source)
{
    try
    {
        // Simulate setting the gain value in the actual audio processing hardware/software
        // In a real implementation, this would interface with your DSP or audio hardware

        OCA_LOG_INFO_PARAMS("[GAIN] SetGainValue called with %.2f dB (Gain ID: %s, Source: %s)",
                            gain, m_gainID.empty() ? "N/A" : m_gainID.c_str(), source.c_str());

        // Convert dB to linear for internal processing (if needed)
        double linearGain = dbToLinear(gain);

        // Send to Fusion server via FusionAudioBridge (only if source is "aes70" and not processing Fusion update)
        if (!m_processingFusionUpdate && source == "aes70")
        {
            FusionAudioBridge &bridge = FusionAudioBridge::getInstance();
            if (bridge.isInitialized())
            {
                bridge.sendGainToFusion(m_gainID, gain, source);
                OCA_LOG_INFO_PARAMS("[GAIN] Sent gain update to FusionAudioBridge (source: %s)", source.c_str());
            }
            else
            {
                OCA_LOG_WARNING("[GAIN] FusionAudioBridge not initialized, skipping Fusion communication");
            }
        }
        else if (m_processingFusionUpdate)
        {
            OCA_LOG_INFO_PARAMS("[GAIN] Skipping Fusion send for gain update from Fusion (gain ID: %s)", m_gainID.c_str());
        }
        else
        {
            OCA_LOG_INFO_PARAMS("[GAIN] Skipping Fusion send for gain update (source: %s, gain ID: %s)", source.c_str(), m_gainID.c_str());
        }

        OCA_LOG_INFO_PARAMS("[GAIN] ✓ Gain successfully set to %.2f dB (linear: %.6f) (Gain ID: %s)",
                            gain, linearGain, m_gainID.empty() ? "N/A" : m_gainID.c_str());

        return OCASTATUS_OK;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[GAIN] Error setting gain: %s", e.what());
        return OCASTATUS_PROCESSING_FAILED;
    }
}
void ConcreteGainActuator::handleFusionGainMessage(::OcaDB gainValue)
{
    try
    {
        OCA_LOG_INFO_PARAMS("ConcreteGainActuator[%s]: handleFusionGainMessage called with %.2f dB",
                            m_gainID.c_str(), gainValue);

        // Get current gain limits from base class
        ::OcaDB currentGain, minGain, maxGain;
        ::OcaLiteStatus status = GetGain(currentGain, minGain, maxGain);

        if (status != OCASTATUS_OK)
        {
            OCA_LOG_ERROR_PARAMS("ConcreteGainActuator[%s]: Failed to get gain limits", m_gainID.c_str());
            return;
        }

        // Clamp the gain value to valid range
        ::OcaDB clampedGain = gainValue;
        if (gainValue < minGain)
        {
            clampedGain = minGain;
            OCA_LOG_INFO_PARAMS("ConcreteGainActuator[%s]: Clamping gain %.2f to minimum %.2f dB",
                                m_gainID.c_str(), gainValue, minGain);
        }
        else if (gainValue > maxGain)
        {
            clampedGain = maxGain;
            OCA_LOG_INFO_PARAMS("ConcreteGainActuator[%s]: Clamping gain %.2f to maximum %.2f dB",
                                m_gainID.c_str(), gainValue, maxGain);
        }

        // Set the gain value using the base class method with Fusion flag set
        // This will update the internal state AND notify AES70 clients, but won't send back to Fusion
        {
            std::lock_guard<std::mutex> lock(m_gainMutex);
            m_processingFusionUpdate = true;
        }

        OCA_LOG_INFO_PARAMS("ConcreteGainActuator[%s]: About to call SetGain(%.2f) with Fusion flag", m_gainID.c_str(), clampedGain);
        status = SetGain(clampedGain);

        {
            std::lock_guard<std::mutex> lock(m_gainMutex);
            m_processingFusionUpdate = false;
        }

        OCA_LOG_INFO_PARAMS("ConcreteGainActuator[%s]: SetGain returned with status %d", m_gainID.c_str(), static_cast<int>(status));

        if (status == OCASTATUS_OK)
        {
            OCA_LOG_INFO_PARAMS("ConcreteGainActuator[%s]: Successfully updated gain to %.2f dB from Fusion message",
                                m_gainID.c_str(), clampedGain);
        }
        else
        {
            OCA_LOG_ERROR_PARAMS("ConcreteGainActuator[%s]: Failed to set gain to %.2f dB (status: %d)",
                                 m_gainID.c_str(), clampedGain, static_cast<int>(status));
        }
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("ConcreteGainActuator[%s]: Error handling Fusion gain message: %s",
                             m_gainID.c_str(), e.what());
    }
}