/*
 * ZoneConfigBuilder.h
 * Minimal ad-hoc JSON parser for zone configuration and builder that creates
 * ZoneGroup hierarchy + Gain/Switch objects (Mute folded into Gain responsibility).
 */
#ifndef ZONE_CONFIG_BUILDER_H
#define ZONE_CONFIG_BUILDER_H

#include <string>
#include <vector>
#include "ZoneGroup.h"
#include "ConcreteGainActuator.h"
#include "ConcreteMuteActuator.h"
#include "ConcreteSwitchActuator.h"

struct ZoneSourceDef
{
    unsigned index;
    std::string label;
};

struct ZoneDef
{
    std::string id;     // e.g., zone1757016...
    std::string name;   // Human readable
    std::string gainID; // gain identifier token (not used yet to lookup anything)
    std::vector<ZoneSourceDef> sources;
};

struct BuiltZones
{
    ZoneGroup *zonesContainer;                      // ONO 5000
    std::vector<ZoneGroup *> zoneGroups;            // inner zones (e.g., ONO 5001, 5002,...)
    std::vector<ConcreteGainActuator *> gains;      // created gain objects (ONO fixed currently)
    std::vector<ConcreteMuteActuator *> mutes;      // created mute objects
    std::vector<ConcreteSwitchActuator *> switches; // created switch objects
};

/**
 * Parse the incoming JSON text (very constrained shape) and build zone hierarchy.
 * Current mapping assumptions:
 *  - First zone gets existing ONOs 4096 (gain) and 4098 (switch).
 *  - We DO NOT create mute separately (folded into gain per spec note; existing mute left untouched for now).
 *  - Additional zones (if present) will allocate new ONOs offset from base (experimental, may be revised).
 *
 * @param json   Raw JSON string.
 * @param baseZoneGroupONo ONO for top container (5000)
 * @param firstZoneONo ONO for first inner zone (5001)
 * @return structure containing created objects (already added to hierarchy except top container which caller adds to root) or nullptr members on failure.
 */
BuiltZones BuildZonesFromJson(const std::string &json,
                              ::OcaONo baseZoneGroupONo = static_cast<::OcaONo>(5000),
                              ::OcaONo firstZoneONo = static_cast<::OcaONo>(5001));

#endif // ZONE_CONFIG_BUILDER_H
