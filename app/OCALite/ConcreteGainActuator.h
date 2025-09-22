/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteGainActuator - Concrete implementation of OcaLiteGain
 *
 */
#ifndef CONCRETEGAINACTUATOR_H
#define CONCRETEGAINACTUATOR_H

// ---- Include system wide include files ----

// ---- Include local include files ----
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteGain.h>

// ---- Referenced classes and types ----

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Class Definition ----
/**
 * Concrete implementation of a gain actuator that actually performs gain adjustment.
 * This class inherits from OcaLiteGain and implements the pure virtual SetGainValue method.
 */
class ConcreteGainActuator : public ::OcaLiteGain
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
    ConcreteGainActuator(::OcaONo objectNumber,
                         ::OcaBoolean lockable,
                         const ::OcaLiteString &role,
                         const ::OcaLiteList<::OcaLitePort> &ports,
                         ::OcaDB minGain,
                         ::OcaDB maxGain,
                         const std::string &gainID);

    /**
     * Destructor.
     */
    virtual ~ConcreteGainActuator() {}

protected:
    /**
     * Set the value of the Gain property. This method performs the actual
     * gain adjustment in the audio processing chain.
     *
     * @param[in]  gain     Input parameter that holds the value of the Gain property in dB.
     * @return Indicates whether the operation succeeded.
     */
    virtual ::OcaLiteStatus SetGainValue(::OcaDB gain) override;

    /**
     * Gets the current value of the Gain property from the actual audio processing.
     *
     * @param[out]  gain    The current value of the Gain property in dB.
     * @return Indicates whether the operation succeeded.
     */
    virtual ::OcaLiteStatus GetGainValue(::OcaDB &gain) const override;

private:
    /** The actual gain value applied to the audio signal */
    mutable ::OcaDB m_actualGain;

    /** The gain identifier from JSON configuration */
    std::string m_gainID;

    /** private copy constructor, no copying of object allowed */
    ConcreteGainActuator(const ConcreteGainActuator &);
    /** private assignment operator, no assignment of object allowed */
    ConcreteGainActuator &operator=(const ConcreteGainActuator &);
};

#endif // CONCRETEGAINACTUATOR_H
