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

// Custom Class IDs for AES70 class hierarchy
// Class ID defines the inheritance path: OcaRoot -> OcaManager -> OcaLiteControllerConfigManager
// Format: {OCA_MANAGER_CLASSID, custom_extension_number}
//
// OCA_ROOT_CLASSID = 1 (base class for all OCA objects)
// OCA_MANAGER_CLASSID = {1, 3} (all managers inherit from OcaRoot with manager extension 3)
// Our custom manager = {1, 3, 1516}
//
// So the full class path is 1.3.1516, meaning:
// Level 1: OcaRoot (class ID = 1)
// Level 2: OcaManager (class ID = 1.3)
// Level 3: OcaLiteControllerConfigManager (class ID = 1.3.1516)
//
// The 1516 is an arbitrary number for our custom manager class.
const ::OcaUint16 CONTROLLER_CONFIG_MANAGER_CLASS_ID = static_cast<::OcaUint16>(1516);

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
