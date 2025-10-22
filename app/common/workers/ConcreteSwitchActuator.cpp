/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteSwitchActuator - Concrete implementation of OcaLiteSwitch
 */

#include "ConcreteSwitchActuator.h"
#include "../FusionAudioBridge.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>

ConcreteSwitchActuator::ConcreteSwitchActuator(::OcaONo objectNumber,
                                               ::OcaBoolean lockable,
                                               const ::OcaLiteString &role,
                                               const ::OcaLiteList<::OcaLitePort> &ports,
                                               ::OcaUint16 minPosition,
                                               ::OcaUint16 maxPosition,
                                               const ::OcaLiteList<::OcaLiteString> &positionNames,
                                               const ::OcaLiteList<::OcaBoolean> &positionEnable,
                                               const std::string &zoneID)
    : ::OcaLiteSwitch(objectNumber, lockable, role, ports, minPosition, maxPosition, positionNames, positionEnable),
      m_zoneID(zoneID),
      m_minPosition(minPosition),
      m_maxPosition(maxPosition)
{
    OCA_LOG_INFO("=== ConcreteSwitchActuator Created ===");
    OCA_LOG_INFO_PARAMS("Object Number: %u", objectNumber);
    OCA_LOG_INFO_PARAMS("Role: %s", role.GetString().c_str());
    OCA_LOG_INFO_PARAMS("Zone ID: %s", m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    OCA_LOG_INFO_PARAMS("Positions: %u - %u", minPosition, maxPosition);
    OCA_LOG_INFO_PARAMS("Number of Position Names: %u", positionNames.GetCount());
}

ConcreteSwitchActuator::~ConcreteSwitchActuator()
{
    // Destructor implementation - ensures vtable is properly generated
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionValue(::OcaUint16 position)
{

    // Set the position value called from some aes70 client
    // This will make an update to Fusion and doesnt update internal state
    // internal state is updated by fusion message handling

    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionValue -> %u (Zone ID: %s)",
                        position, m_zoneID.empty() ? "N/A" : m_zoneID.c_str());

    if (!m_zoneID.empty())
    {
        FusionAudioBridge &bridge = FusionAudioBridge::getInstance();
        if (bridge.isInitialized())
        {
            bridge.sendSourceToFusion(m_zoneID, position);
            OCA_LOG_INFO_PARAMS("[SWITCH] Sent source selection to Fusion: %s = %u",
                                m_zoneID.c_str(), position);
        }
        else
        {
            OCA_LOG_WARNING("[SWITCH] FusionAudioBridge not initialized - source selection not sent to Fusion");
        }
    }
    else
    {
        OCA_LOG_WARNING("[SWITCH] No zone ID configured - source selection not sent to Fusion");
    }

    return OCASTATUS_OK;
}
::OcaLiteStatus ConcreteSwitchActuator::SetPositionNameValue(::OcaUint16 index, const ::OcaLiteString &name)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionNameValue index=%u name=%s (Zone ID: %s)", index, name.GetString().c_str(), m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionNamesValue(const ::OcaLiteList<::OcaLiteString> &names)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionNamesValue count=%u (Zone ID: %s)", names.GetCount(), m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionEnabledValue(::OcaUint16 index, ::OcaBoolean enabled)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionEnabledValue index=%u enabled=%u (Zone ID: %s)", index, enabled, m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionEnabledsValue(const ::OcaLiteList<::OcaBoolean> &enableds)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionEnabledsValue count=%u (Zone ID: %s)", enableds.GetCount(), m_zoneID.empty() ? "N/A" : m_zoneID.c_str());
    return OCASTATUS_OK;
}

void ConcreteSwitchActuator::handleFusionSourceMessage(::OcaUint16 sourceIndex)
{
    try
    {
        OCA_LOG_INFO_PARAMS("[SWITCH] Handling Fusion source message: %u (Zone ID: %s)",
                            sourceIndex, m_zoneID.c_str());

        // Validate source index is within valid range
        if (sourceIndex < m_minPosition || sourceIndex > m_maxPosition)
        {
            OCA_LOG_ERROR_PARAMS("[SWITCH] Invalid source index %u, must be between %u and %u (Zone ID: %s)",
                                 sourceIndex, m_minPosition, m_maxPosition, m_zoneID.c_str());
            return;
        }

        // Set the position value using the base class method
        // This will update the internal state AND notify AES70 clients, but won't send back to Fusion

        ::OcaLiteStatus status = SetPositionFromFusion(sourceIndex);

        if (OCASTATUS_OK == status)
        {
            OCA_LOG_INFO_PARAMS("[SWITCH] ✓ Fusion source selection applied: %u (Zone ID: %s)",
                                sourceIndex, m_zoneID.c_str());
        }
        else
        {
            OCA_LOG_ERROR_PARAMS("[SWITCH] Failed to apply Fusion source selection: %u (Zone ID: %s)",
                                 sourceIndex, m_zoneID.c_str());
        }
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("[SWITCH] Exception in handleFusionSourceMessage: %s", e.what());
    }
}
