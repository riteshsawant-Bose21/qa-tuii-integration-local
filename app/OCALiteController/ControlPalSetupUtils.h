/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

#ifndef CONTROLPAL_SETUP_UTILS_H_
#define CONTROLPAL_SETUP_UTILS_H_

#include <Proxy/GeneralProxy.h>
#include "OcaServiceDiscovery.h"
#include "../common/FusionProxy.h"

#ifndef STM32H7S7xx
// Helper functions
void DisplayDiscoveredDevices(
         const std::vector<OcaServiceDiscovery::DiscoveredDevice> &devices);

#endif

::OcaBoolean ConnectToDevice(
                     const OcaServiceDiscovery::DiscoveredDevice &device,
                     ::OcaSessionID& sessionId);

void DisconnectFromDevice(::OcaSessionID& sessionId, ::OcaONo networkONo);

::OcaLiteStatus GetControllerConfig(::OcaLiteString& controllerId,
                                    FusionProxy& proxy,
                                    Controller& controllerCfg);

::OcaBoolean AddSubscriptions(Zone& newZone, GeneralProxy& proxy);

ZoneGroup* CreateZoneGroup(Zone& newZone, FusionProxy& proxy,
                                             void *commandQueue);

OcaBoolean ControlPalSetupConnection(::OcaSessionID& sessionId);

::OcaBoolean ControlPalSetupControls(::OcaLiteString& controllerId,
                                        ::GeneralProxy& gen_proxy,
                                        FusionProxy& proxy,
                                        void *commandQueue,
                                        std::vector<::OcaONo>& zoneONo);

void ControlPalTeardownControls(std::vector<::OcaONo>& zoneONo);
#endif // CONTROLPAL_SETUP_UTILS_H_
