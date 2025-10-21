/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALiteController.cpp : Defines the entry point for the OCA Controller application.
//

#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include <OCC/ControlDataTypes/OcaLiteClassIdentification.h>
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteBooleanActuator.h>
#include <OCP.1/Ocp1LiteConnectParameters.h>
#include <StandardLib/StandardLib.h>
#include <unistd.h>

#ifndef CONTROL_PAL_CONNECTION_MGR_H_
#define CONTROL_PAL_CONNECTION_MGR_H_

class ControlPalConnectionMonitor :
            public ::OcaLiteBooleanActuator,
            public ::OcaLiteCommandHandler::IConnectionLostDelegate
{
    public:

        ControlPalConnectionMonitor(::OcaONo objectNumber) :
            ::OcaLiteBooleanActuator(
                    objectNumber, static_cast<::OcaBoolean> (true),
                    static_cast<const ::OcaLiteString>("ConnectionMonitor"),
                    mgr_ports),
            ::OcaLiteCommandHandler::IConnectionLostDelegate()
        {
        }

        virtual ::OcaLiteStatus SetSettingValue(::OcaBoolean setting)
        {
            (void) setting;

            // Do Nothing
            return OCASTATUS_OK;
        }

        virtual void OnConnectionLost(::OcaSessionID sessionID)
        {
            (void) sessionID;

            // Signal connection Lost
            SetSetting(static_cast<::OcaBoolean>(false));
        }

    private:
        const ::OcaLiteList< ::OcaLitePort> mgr_ports;
};
#endif // CONTROL_PAL_CONNECTION_MGR_H_
