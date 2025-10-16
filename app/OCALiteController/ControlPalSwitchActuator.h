/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ControlPalSwitchActuator - ControlPal implementation of OcaLiteSwitch
 */
#ifndef CONTROLPAL_SWITCHACTUATOR_H
#define CONTROLPAL_SWITCHACTUATOR_H

#include <OCC/ControlClasses/Workers/Actuators/OcaLiteSwitch.h>
#include "HostInterface/CommandInterface/CommandInterface.h"
#include "ControlPalMsgInterface.h"

/**
 * ControlPal implementation of OcaLiteSwitch used for simple source selection.
 * Sources are provided at construction time (position names) and all enabled.
 * Implements the pure virtual mutator methods required by OcaLiteSwitch.
 */
class ControlPalSwitchActuator : public ::OcaLiteSwitch,
                                 public ControlPalMsgInterface<ControllerCmdIntfc>
{
public:
    ControlPalSwitchActuator(::OcaONo objectNumber,
                           ::OcaBoolean lockable,
                           const ::OcaLiteString &role,
                           const ::OcaLiteList<::OcaLitePort> &ports,
                           ::OcaUint16 minPosition,
                           ::OcaUint16 maxPosition,
                           const ::OcaLiteList<::OcaLiteString> &positionNames,
                           const ::OcaLiteList<::OcaBoolean> &positionEnable,
                           const std::string &zoneID,
                           const ::OcaONo zoneONo,
                           void *commandQue);

    virtual ~ControlPalSwitchActuator() {}

    ::OcaONo GetZoneONo()
    {
        return m_zoneONo;
    }

    void SendValue();

protected:
    // Store selected position internally (base also keeps its own). We mirror for potential future hardware logic.
    virtual ::OcaLiteStatus SetPositionValue(::OcaUint16 position) override;
    virtual ::OcaLiteStatus SetPositionNameValue(::OcaUint16 index, const ::OcaLiteString &name) override;
    virtual ::OcaLiteStatus SetPositionNamesValue(const ::OcaLiteList<::OcaLiteString> &names) override;
    virtual ::OcaLiteStatus SetPositionEnabledValue(::OcaUint16 index, ::OcaBoolean enabled) override;
    virtual ::OcaLiteStatus SetPositionEnabledsValue(const ::OcaLiteList<::OcaBoolean> &enableds) override;

private:
    /** The zone identifier from JSON configuration */
    std::string m_zoneID;
    
    // ONo of the ZoneBlock
    ::OcaONo    m_zoneONo;

    ControlPalSwitchActuator(const ControlPalSwitchActuator &);
    ControlPalSwitchActuator &operator=(const ControlPalSwitchActuator &);
};

#endif // CONTROLPAL_SWITCHACTUATOR_H
