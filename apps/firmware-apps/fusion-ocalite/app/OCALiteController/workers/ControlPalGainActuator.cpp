/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ControlPalGainActuator - ControlPal implementation of OcaLiteGain
 *
 */

// ---- Include system wide include files ----
#include <iostream>
#include <cmath>

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "ControlPalGainActuator.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
#include "../PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#else
#include "../PlatformInterface/stm32/OcaPlatformSTM32.h"
#endif
#include "../ControlPalOcaUtils.h"

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

ControlPalGainActuator::ControlPalGainActuator(::OcaONo objectNumber,
                                           ::OcaBoolean lockable,
                                           const ::OcaLiteString &role,
                                           const ::OcaLiteList<::OcaLitePort> &ports,
                                           ::OcaDB minGain,
                                           ::OcaDB maxGain,
                                           const std::string &gainID,
                                           ::OcaONo zoneONo,
                                           void *cmdQueue)
    : ::OcaLiteGain(objectNumber, lockable, role, ports, minGain, maxGain),
      ControlPalMsgInterface(cmdQueue),
      m_gainID(gainID), m_zoneONo(zoneONo),
      m_lastGainSet(GAIN_UPDATE_SENTINEL), m_lastUIGainSet(50.0), m_gainSetCount(0)
{
    // Enhanced logging with dynamic information
    OCA_LOG_INFO("=== ControlPalGainActuator Created ===");
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

::OcaLiteStatus ControlPalGainActuator::SetGainValue(::OcaDB gain)
{
    try
    {
        OCA_LOG_INFO_PARAMS("[GAIN] Setting gain to %.2f dB (Gain ID: %s)",
                gain, m_gainID.empty() ? "N/A" : m_gainID.c_str());

        // Convert dB to linear for internal processing (if needed)
        double linearGain = dbToLinear(gain);

        // Call fn. to send GAIN value command to frontend task
        if ((m_gainSetCount == 0) || (m_lastGainSet == GAIN_UPDATE_SENTINEL))
        {
            SendValue();
        }
        else
        {
            if (GAIN_VALUE_ROUND(gain) == LastGainGet())
            {
                // All gain notifications received, reset LastGain
                m_lastGainSet = GAIN_UPDATE_SENTINEL;
            }

            m_gainSetCount--;
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

void ControlPalGainActuator::SendValue()
{
    ::OcaDB gainVal, minVal, maxVal;
    ControllerCmdIntfc setGainCmd;

    GetGain(gainVal, minVal, maxVal);

    m_lastUIGainSet = gainVal;

    setGainCmd.cmd = CTRL_CMD_GAIN_SET;
    setGainCmd.ono = m_zoneONo;
    setGainCmd.val.flt_val = gainVal;

    PushToMsgQueue(setGainCmd);
}

void ControlPalGainActuator::SendConfiguration()
{
    ::OcaDB gainVal, minVal, maxVal;
    ControllerCmdIntfc setGainCmd;

    GetGain(gainVal, minVal, maxVal);

    setGainCmd.cmd = CTRL_CMD_GAIN_MIN_VAL;
    setGainCmd.ono = m_zoneONo;
    setGainCmd.val.flt_val = minVal;
    PushToMsgQueue(setGainCmd);

    setGainCmd.cmd = CTRL_CMD_GAIN_MAX_VAL;
    setGainCmd.ono = m_zoneONo;
    setGainCmd.val.flt_val = maxVal;
    PushToMsgQueue(setGainCmd);
}

