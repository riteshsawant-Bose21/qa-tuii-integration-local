/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteMuteActuator - Concrete implementation of OcaLiteMute
 *
 */

#ifndef CONCRETEMUTEACTUATOR_H
#define CONCRETEMUTEACTUATOR_H

// ---- Include system wide include files ----

// ---- Include local include files ----
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteMute.h>
#include <atomic>
#include <mutex>

// ---- Referenced classes and types ----

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Class Definition ----

/**
 * Concrete implementation of OcaLiteMute actuator.
 * This class provides a real implementation of the mute functionality
 * by implementing the pure virtual SetStateValue method from OcaLiteMute.
 */
class ConcreteMuteActuator : public ::OcaLiteMute
{
public:
    /**
     * Constructor
     *
     * @param[in] objectNumber    The object number of this instance.
     * @param[in] lockable        Indicates whether or not this object is lockable.
     * @param[in] role            The role of this instance.
     * @param[in] ports           The OCA input and output ports.
     * @param[in] gainID          The gain identifier from JSON configuration (required)
     */
    ConcreteMuteActuator(::OcaONo objectNumber,
                         ::OcaBoolean lockable,
                         const ::OcaLiteString &role,
                         const ::OcaLiteList<::OcaLitePort> &ports,
                         const std::string &gainID);

    /**
     * Destructor.
     */
    virtual ~ConcreteMuteActuator();

    /**
     * Handle mute message from Fusion system.
     * This method is used to update the mute state from external Fusion commands
     * without triggering feedback loops.
     *
     * @param[in] muteState  The mute state from Fusion (true = muted, false = unmuted).
     */
    void handleFusionMuteMessage(bool muteState);

protected:
    /**
     * Implementation of pure virtual SetStateValue from OcaLiteMute.
     * This method is called to actually set the mute state in the hardware/software.
     *
     * @param[in] muteState  The mute state to set (OCAMUTESTATE_MUTED or OCAMUTESTATE_UNMUTED).
     * @return              Status of the operation.
     */
    virtual ::OcaLiteStatus SetStateValue(::OcaLiteMuteState muteState);

private:
    /** The gain identifier from JSON configuration */
    std::string m_gainID;

    /** Copy constructor */
    ConcreteMuteActuator(const ConcreteMuteActuator &);
    /** Assignment operator */
    ConcreteMuteActuator &operator=(const ConcreteMuteActuator &);
};

#endif // CONCRETEMUTEACTUATOR_H
