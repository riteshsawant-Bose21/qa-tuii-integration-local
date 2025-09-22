/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteSwitchActuator - Concrete implementation of OcaLiteSwitch
 */
#ifndef CONCRETESWITCHACTUATOR_H
#define CONCRETESWITCHACTUATOR_H

#include <OCC/ControlClasses/Workers/Actuators/OcaLiteSwitch.h>

/**
 * Concrete implementation of OcaLiteSwitch used for simple source selection.
 * Sources are provided at construction time (position names) and all enabled.
 * Implements the pure virtual mutator methods required by OcaLiteSwitch.
 */
class ConcreteSwitchActuator : public ::OcaLiteSwitch
{
public:
    ConcreteSwitchActuator(::OcaONo objectNumber,
                           ::OcaBoolean lockable,
                           const ::OcaLiteString &role,
                           const ::OcaLiteList<::OcaLitePort> &ports,
                           ::OcaUint16 minPosition,
                           ::OcaUint16 maxPosition,
                           const ::OcaLiteList<::OcaLiteString> &positionNames,
                           const ::OcaLiteList<::OcaBoolean> &positionEnable,
                           const std::string &zoneID);

    virtual ~ConcreteSwitchActuator() {}

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
    
    ConcreteSwitchActuator(const ConcreteSwitchActuator &);
    ConcreteSwitchActuator &operator=(const ConcreteSwitchActuator &);
};

#endif // CONCRETESWITCHACTUATOR_H
