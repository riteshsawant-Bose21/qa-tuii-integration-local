/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteSwitchActuator - Concrete implementation of OcaLiteSwitch
 */

#include "ConcreteSwitchActuator.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>

ConcreteSwitchActuator::ConcreteSwitchActuator(::OcaONo objectNumber,
                                               ::OcaBoolean lockable,
                                               const ::OcaLiteString &role,
                                               const ::OcaLiteList<::OcaLitePort> &ports,
                                               ::OcaUint16 minPosition,
                                               ::OcaUint16 maxPosition,
                                               const ::OcaLiteList<::OcaLiteString> &positionNames,
                                               const ::OcaLiteList<::OcaBoolean> &positionEnable)
    : ::OcaLiteSwitch(objectNumber, lockable, role, ports, minPosition, maxPosition, positionNames, positionEnable),
      m_actualPosition(minPosition)
{
    OCA_LOG_INFO("=== ConcreteSwitchActuator Created ===");
    OCA_LOG_INFO_PARAMS("Object Number: %u", objectNumber);
    OCA_LOG_INFO_PARAMS("Role: %s", role.GetString().c_str());
    OCA_LOG_INFO_PARAMS("Positions: %u - %u", minPosition, maxPosition);
    OCA_LOG_INFO_PARAMS("Number of Position Names: %u", positionNames.GetCount());
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionValue(::OcaUint16 position)
{
    // Here you would apply the source selection to underlying audio routing.
    m_actualPosition = position; // Mirror for potential hardware confirmation.
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionValue -> %u", position);
    return OCASTATUS_OK;
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionNameValue(::OcaUint16 index, const ::OcaLiteString &name)
{
    // Could validate name length or character set here.
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionNameValue index=%u name=%s", index, name.GetString().c_str());
    return OCASTATUS_OK;
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionNamesValue(const ::OcaLiteList<::OcaLiteString> &names)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionNamesValue count=%u", names.GetCount());
    return OCASTATUS_OK;
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionEnabledValue(::OcaUint16 index, ::OcaBoolean enabled)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionEnabledValue index=%u enabled=%u", index, enabled);
    return OCASTATUS_OK;
}

::OcaLiteStatus ConcreteSwitchActuator::SetPositionEnabledsValue(const ::OcaLiteList<::OcaBoolean> &enableds)
{
    OCA_LOG_INFO_PARAMS("[SWITCH] SetPositionEnabledsValue count=%u", enableds.GetCount());
    return OCASTATUS_OK;
}
