/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description: Custom Object Number (ONO) definitions for application-specific managers and objects
 *
 *  According to AES70-1-2024 standard:
 *  - ONO values 1 through 4095 are reserved for standard Managers and predefined objects
 *  - Custom managers and objects should use values above 4095
 *  - We use the 8000+ range for our custom objects
 */

#ifndef CUSTOM_ONO_DEFINITIONS_H
#define CUSTOM_ONO_DEFINITIONS_H

#include "../../common/OCALite/OCC/ControlDataTypes/OcaLiteFrameworkDataTypes.h"

// Custom Manager ONOs
// From the standard table:

// 1: OcaDeviceManager
// 2: OcaSecurityManager
// 3: OcaFirmwareManager
// 4: OcaSubscriptionManager
// 5: OcaPowerManager
// 6: OcaNetworkManager
// 7: OcaMediaClockManager
// 8: UNUSED
// 9: OcaAudioProcessingManager
// 10: OcaDeviceTimeManager
// 11: UNUSED
// 12: UNUSED
// 13: OcaDiagnosticManager
// 14: OcaLockManager
// 15-99: UNUSED
// 100: OcaBlock (Root Block)

const ::OcaONo CONTROLLER_CONFIG_MANAGER_ONO = static_cast<::OcaONo>(33); // ONO 33 = 3+3 = F -> Fusion ;)

// Custom Object ONOs (must be 4096+ per AES70 standard for device objects)
const ::OcaONo ROOT_ZONE_CONTAINER_ONO = static_cast<::OcaONo>(631965); // again, cryptographic representation of Fusion ;)

#endif // CUSTOM_ONO_DEFINITIONS_H
