/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  According to AES70-1-2024 standard:
 *  - ONO values 1 through 4095 are reserved for standard Managers and predefined objects
 *  - Custom managers and objects should use values above 4095
 *  - We use the 8000+ range for our custom objects
 */

#ifndef FUSION_OCA_CONSTANTS_H
#define FUSION_OCA_CONSTANTS_H

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

const ::OcaONo OCP_NETWORK_ONO = static_cast<::OcaONo>(9000);

const ::OcaONo CONTROLLER_CONFIG_MANAGER_ONO = static_cast<::OcaONo>(33); // ONO 33 = 3+3 = F -> Fusion ;)

// Custom Object ONOs (must be 4096+ per AES70 standard for device objects)
const ::OcaONo ROOT_ZONE_CONTAINER_ONO = static_cast<::OcaONo>(631965); // again, cryptographic representation of Fusion ;)

const std::string ZONES_JSON_STRING_FOR_DEV = R"(
        {
        "controllers": [
            {
            "id": "ctrl1",
            "name": "Controller 1",
            "zoneIds": [
                "zone1"
            ]
            },
            {
            "id": "ctrl2",
            "name": "Controller 2",
            "zoneIds": [
                "zone2"
                ]
            }
        ],
        "zones": [
            {
            "id": "zone1",
            "name": "Living Room",
            "ono": {
                "zone": 8001,
                "gain": 8002,
                "mute": 8003,
                "sourceSelector": 8004
            },
            "gain": {
                "gainID": "gain1",
                "min_value": "0",
                "max_value": "100",
                "default_gain_value": "50",
                "default_mute_value": "50"
            },
            "sources": [
                { "index": 0, "label": "HDMI 1" },
                { "index": 1, "label": "HDMI 2" },
                { "index": 2, "label": "Bluetooth" }
            ]
            },
            {
            "id": "zone2",
            "name": "Kitchen",
            "gain": {
                "gainID": "gain2",
                "min_value": "0",
                "max_value": "100",
                "default_gain_value": "50",
                "default_mute_value": "50"
            },
            "ono": {
                "zone": 8005,
                "gain": 8006,
                "mute": 8007,
                "sourceSelector": 8008
            },
            "sources": [
                { "index": 0, "label": "Radio" },
                { "index": 1, "label": "Streaming" }
            ]
            },
            {
            "id": "zone3",
            "name": "Bedroom",
            "gain": {
                "gainID": "gain3",
                "min_value": "0",
                "max_value": "100",
                "default_gain_value": "50",
                "default_mute_value": "50"
            },
            "ono": {
                "zone": 8009,
                "gain": 8010,
                "mute": 8011,
                "sourceSelector": 8012
            },
            "sources": [
                { "index": 0, "label": "TV" },
                { "index": 1, "label": "AUX" },
                { "index": 2, "label": "AirPlay" }
            ]
            }
        ]
        }
        )";

const ::OcaONo FUSION_NETWORK_ONO        = static_cast<::OcaONo>(9001);
const ::OcaONo FUSION_CONNECTION_MON_ONO = static_cast<::OcaONo>(9002);

#endif // FUSION_OCA_CONSTANTS_H
