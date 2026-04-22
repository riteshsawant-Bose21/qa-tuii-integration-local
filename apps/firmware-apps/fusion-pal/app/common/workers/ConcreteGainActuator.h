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
    virtual ~ConcreteGainActuator();

    /**
     * @brief Handle gain update messages received from Fusion server and propagate to AES70 clients after updating internal state
     * @param gainValue The gain value in dB received from Fusion server
     */
    void handleFusionGainMessage(::OcaDB gainValue);

protected:
    /**
     * @brief Set gain value implementation that forwards AES70 client requests to Fusion server without updating internal state
     * @param[in] gain The gain value in dB to set
     * @return Indicates whether the operation succeeded
     */
    virtual ::OcaLiteStatus SetGainValue(::OcaDB gain) override;

private:
    /** The gain identifier from JSON configuration */
    std::string m_gainID;

    /** private copy constructor, no copying of object allowed */
    ConcreteGainActuator(const ConcreteGainActuator &);
    /** private assignment operator, no assignment of object allowed */
    ConcreteGainActuator &operator=(const ConcreteGainActuator &);
};

#endif // CONCRETEGAINACTUATOR_H
