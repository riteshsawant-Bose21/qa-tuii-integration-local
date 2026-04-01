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

    virtual ~ConcreteSwitchActuator();

    /**
     * @brief Handle source selection messages received from Fusion server and propagate to AES70 clients after updating internal state
     * @param[in] sourceIndex The source index from Fusion server
     */
    void handleFusionSourceMessage(::OcaUint16 sourceIndex);

protected:
    /**
     * @brief Set switch position implementation that forwards AES70 client requests to Fusion server without updating internal state
     * @param[in] position The switch position to set
     * @return Indicates whether the operation succeeded
     */
    virtual ::OcaLiteStatus SetPositionValue(::OcaUint16 position) override;

    // unused methods below - required to implement pure virtuals from base class
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
