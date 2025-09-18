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
#include "ZoneGroup.h"
#include "ConcreteGainActuator.h"
#include "ConcreteMuteActuator.h"
#include "ConcreteSwitchActuator.h"

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

struct ZoneDef
{
    std::string id;           // e.g., zone1757016...
    std::string name;         // Human readable
    std::string controllerId; // controller identifier (parsed but not used)
    ZoneONODef ono;           // nested ONO structure
    std::string gainID;       // gain identifier token
    std::vector<ZoneSourceDef> sources;
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
 * @param baseZoneGroupONo ONO for top container (8000 by default)
 * @return structure containing created objects (already added to hierarchy except top container which caller adds to root) or nullptr members on failure.
 */
BuiltZones BuildZonesFromJson(const std::string &json,
                              ::OcaONo baseZoneGroupONo = static_cast<::OcaONo>(8000));

// Refactored helper steps (exposed for testability)
bool parseJson(const std::string &json, std::vector<ZoneDef> &zonesOut);

// Create all zone-related objects (container + per-zone objects) but DO NOT link them yet.
// Returns an empty BuiltZones (all pointers null/empty) on failure. The objects in the returned
// BuiltZones ARE NOT yet added to any parent except the top container pointer exists.
BuiltZones createZoneObjects(const std::vector<ZoneDef> &zones,
                             ::OcaONo baseZoneGroupONo);

// Build hierarchy: add zone groups to container, actuators to their zone group. Mutates input.
// Any failed add will delete the affected object and skip it.
void buildHierarchy(BuiltZones &zonesModel);

#endif // ZONE_CONFIG_BUILDER_H
