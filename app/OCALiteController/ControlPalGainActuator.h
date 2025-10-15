/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ControlPalGainActuator - ControlPal implementation of OcaLiteGain
 *
 */
#ifndef CONTROLPAL_GAINACTUATOR_H
#define CONTROLPAL_GAINACTUATOR_H

// ---- Include system wide include files ----

// ---- Include local include files ----
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteGain.h>

// ---- Referenced classes and types ----

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Class Definition ----
/**
 * ControlPal implementation of a gain actuator that actually performs gain adjustment.
 * This class inherits from OcaLiteGain and implements the pure virtual SetGainValue method.
 */
class ControlPalGainActuator : public ::OcaLiteGain
{
public:
    /**
     * Constructor
     *
     * @param[in]  objectNumber Object number of this instance.
     * @param[in]  lockable     Indicates whether or not the object is lockable.
     * @param[in]  role         The role of this instance.
     * @param[in]  ports        The OCA input and output ports.
     * @param[in]  minGain      Lower limit of the gain in dB
     * @param[in]  maxGain      Upper limit of the gain in dB
     * @param[in]  gainID       The gain identifier from JSON configuration (required)
     */
    ControlPalGainActuator(::OcaONo objectNumber,
                         ::OcaBoolean lockable,
                         const ::OcaLiteString &role,
                         const ::OcaLiteList<::OcaLitePort> &ports,
                         ::OcaDB minGain,
                         ::OcaDB maxGain,
                         const std::string &gainID);

    /**
     * Destructor.
     */
    virtual ~ControlPalGainActuator() {}

protected:
    /**
     * Set the value of the Gain property. This method performs the actual
     * gain adjustment in the audio processing chain.
     *
     * @param[in]  gain     Input parameter that holds the value of the Gain property in dB.
     * @return Indicates whether the operation succeeded.
     */
    virtual ::OcaLiteStatus SetGainValue(::OcaDB gain) override;

private:
    /** The gain identifier from JSON configuration */
    std::string m_gainID;

    /** private copy constructor, no copying of object allowed */
    ControlPalGainActuator(const ControlPalGainActuator &);
    /** private assignment operator, no assignment of object allowed */
    ControlPalGainActuator &operator=(const ControlPalGainActuator &);
};

#endif // CONTROLPAL_GAINACTUATOR_H
