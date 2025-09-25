/*
 * ZoneConfigBuilder.h
 * Minimal ad-hoc JSON parser for zone configuration and builder that creates
 * ZoneGroup hierarchy + Gain/Switch objects (Mute folded into Gain responsibility).
 */
#ifndef ZONE_CONFIG_BUILDER_H
#define ZONE_CONFIG_BUILDER_H

#include <string>
#include <vector>
#include <memory>
#include <OCC/ControlDataTypes/OcaLiteBaseDataTypes.h>
#include "CustomONODefinitions.h" // For custom ONO constants
#include "workers/ZoneGroup.h"
#include "workers/ConcreteGainActuator.h"
#include "workers/ConcreteMuteActuator.h"
#include "workers/ConcreteSwitchActuator.h"

struct ZoneSourceDef
{
    unsigned index;
    std::string label;
};

struct ZoneONODef
{
    ::OcaONo zone;
    ::OcaONo gain;
    ::OcaONo mute;
    ::OcaONo sourceSelector;
};

struct Zone
{
    std::string id;     // e.g., zone1757016...
    std::string name;   // Human readable
    ZoneONODef ono;     // nested ONO structure
    std::string gainID; // gain identifier token
    std::vector<ZoneSourceDef> sources;
};

// Controller struct for managing zones
struct Controller
{
    std::string id;                           // controller identifier
    std::string name;                         // human readable controller name
    std::vector<std::shared_ptr<Zone>> zones; // smart pointers to zones managed by this controller
};

// Aggregated per-zone object bundle
struct ZoneObjects
{
    std::unique_ptr<ZoneGroup> group;           // may be null if creation failed
    std::unique_ptr<ConcreteGainActuator> gain; // optional
    std::unique_ptr<ConcreteMuteActuator> mute; // optional
    std::unique_ptr<ConcreteSwitchActuator> sw; // optional
};

struct BuiltZones
{
    std::unique_ptr<ZoneGroup> zonesContainer; // Top level container
    std::vector<ZoneObjects> zones;            // One entry per parsed zone
};

/**
 * Parse the incoming JSON text (very constrained shape) and build zone hierarchy.
 * Current mapping:
 *  - Zone ONOs, Gain ONOs, Mute ONOs, and Source Selector ONOs are specified in the JSON
 *  - Each zone must specify: zoneONO, gainONO, muteONO, sourceSelectorONO
 *
 * @param json   Raw JSON string.
 * @param baseZoneGroupONo ONO for top container (ROOT_ZONE_CONTAINER_ONO by default)
 * @return structure containing created objects (already added to hierarchy except top container which caller adds to root) or nullptr members on failure.
 */
BuiltZones BuildZonesFromJson(const std::string &json,
                              ::OcaONo baseZoneGroupONo = ROOT_ZONE_CONTAINER_ONO);

// Refactored helper steps
bool parseJson(const std::string &json, std::vector<Zone> &zonesOut);

// Create all zone-related objects (container + per-zone objects) but DO NOT link them yet.
// Returns an empty BuiltZones (all pointers null/empty) on failure. The objects in the returned
// BuiltZones ARE NOT yet added to any parent except the top container pointer exists.
BuiltZones createZoneObjects(const std::vector<Zone> &zones,
                             ::OcaONo baseZoneGroupONo);

// Build hierarchy: add zone groups to container, actuators to their zone group. Mutates input.
// Any failed add will delete the affected object and skip it.
void buildHierarchy(BuiltZones &zonesModel);

/**
 * Parse the incoming JSON text and build controller list with associated zones from metadata format.
 * Extracts controller and zone information from the JSON structure with "controllers" object.
 *
 * @param json   Raw JSON string containing controllers and zones in metadata format
 * @return vector of Controller structs with populated zones, empty vector on failure
 */
std::vector<Controller> BuildControllersFromMetadataJson(const std::string &json);

/**
 * Deserialize a single controller from JSON format.
 * Parses a JSON object representing a single controller with its zones and properties.
 *
 * @param json   Raw JSON string containing a single controller object
 * @return vector containing the parsed controller, empty vector on failure
 */
std::vector<Controller> DeserializeControllers(const std::string &json);

/**
 * Serialize a controller to JSON format.
 * Creates a JSON representation of the controller including all its zones and their properties.
 *
 * @param controller The controller to serialize
 * @return JSON string representation of the controller
 */
std::string SerializeControllerToJson(const Controller &controller);

#endif // ZONE_CONFIG_BUILDER_H
