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

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "ConcreteGainActuator.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>

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
                                           ::OcaDB maxGain)
    : ::OcaLiteGain(objectNumber, lockable, role, ports, minGain, maxGain),
      m_actualGain(0.0) // Initialize to 0 dB (unity gain)
{
    // Enhanced logging with dynamic information
    OCA_LOG_INFO("=== ConcreteGainActuator Created ===");
    OCA_LOG_INFO_PARAMS("Object Number: %u", objectNumber);
    OCA_LOG_INFO_PARAMS("Role: %s", role.GetString().c_str());
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
    try
    {
        // Simulate setting the gain value in the actual audio processing hardware/software
        // In a real implementation, this would interface with your DSP or audio hardware

        OCA_LOG_INFO_PARAMS("[GAIN] Setting gain to %.2f dB", gain);

        // Convert dB to linear for internal processing (if needed)
        double linearGain = dbToLinear(gain);

        // Here you would typically:
        // 1. Send the gain value to your audio processing hardware/DSP
        // 2. Update internal audio processing parameters
        // 3. Validate that the setting was successful

        // Example hardware interface calls (commented out):
        // audioHardware.setChannelGain(channelId, gain);
        // dspLibrary.updateGainParameter(gain);
        // registerWrite(GAIN_REGISTER, gainToRegisterValue(gain));

        // For this example, we'll just store the value and simulate successful setting
        m_actualGain = gain;

        OCA_LOG_INFO_PARAMS("[GAIN] ✓ Gain successfully set to %.2f dB (linear: %.6f)", gain, linearGain);

        return OCASTATUS_OK;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[GAIN] Error setting gain: %s", e.what());
        return OCASTATUS_PROCESSING_FAILED;
    }
}

::OcaLiteStatus ConcreteGainActuator::GetGainValue(::OcaDB &gain) const
{
    try
    {
        // In a real implementation, this would read the actual gain value from
        // your audio processing hardware/DSP to ensure accuracy

        // Example hardware read calls (commented out):
        // gain = audioHardware.getChannelGain(channelId);
        // gain = registerRead(GAIN_REGISTER_READBACK);

        // For this example, we'll return the stored value
        gain = m_actualGain;

        OCA_LOG_INFO_PARAMS("[GAIN] Getting current gain value: %.2f dB", gain);

        return OCASTATUS_OK;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[GAIN] Error getting gain: %s", e.what());
        return OCASTATUS_PROCESSING_FAILED;
    }
}
