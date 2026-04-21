// This class houses the parsing logic for all the JSON updates coming from the fusion server.
// This class is responsible for parsing external updates.

#pragma once
#include "Models.h"
#include <json/json.h>
#include <stdexcept>
#include "../workers/ZoneGroup.h"
#include "../workers/FusionBlock.h"
#include "../workers/ConcreteGainActuator.h"
#include "../workers/ConcreteMuteActuator.h"
#include "../workers/ConcreteSwitchActuator.h"
#include "../FusionOCAConstants.h"

inline Source parseSource(const Json::Value &v)
{
    Source s;
    s.index = v["index"].asInt();
    s.label = v["label"].asString();
    return s;
}

inline FusionZoneOno parseOno(const Json::Value &v)
{
    FusionZoneOno o;
    o.zone = v["zone"].asInt();
    o.gain = v["gain"].asInt();
    o.mute = v["mute"].asInt();
    o.sourceSelector = v["sourceSelector"].asInt();
    return o;
}

inline GainConfig parseGain(const Json::Value &v)
{
    GainConfig g;
    g.gainID = v["gainID"].asString();
    g.min_value = v["min_value"].asString();
    g.max_value = v["max_value"].asString();
    g.default_gain_value = v["default_gain_value"].asString();
    g.default_mute_value = v["default_mute_value"].asString();
    return g;
}

inline std::shared_ptr<Zone> parseZone(const Json::Value &v)
{
    if (!v.isObject())
        throw std::runtime_error("Zone must be an object");
    auto z = std::make_shared<Zone>();
    z->id = v["id"].asString();
    z->name = v["name"].asString();
    if (v.isMember("ono"))
        z->ono = parseOno(v["ono"]);
    if (v.isMember("gain"))
        z->gain = parseGain(v["gain"]);
    if (v.isMember("sources") && v["sources"].isArray())
    {
        for (const auto &s : v["sources"])
            z->sources.push_back(parseSource(s));
    }
    return z;
}

inline std::shared_ptr<Controller> parseController(const Json::Value &v)
{
    if (!v.isObject())
        throw std::runtime_error("Controller must be an object");
    auto c = std::make_shared<Controller>();
    c->id = v["id"].asString();
    c->name = v["name"].asString();
    if (v.isMember("zoneIds") && v["zoneIds"].isArray())
    {
        for (const auto &z : v["zoneIds"])
            c->zoneIds.push_back(z.asString());
    }
    return c;
}

inline ControlSystemConfig MakeControlSystemModelFromJson(const Json::Value &root)
{
    ControlSystemConfig model;

    // First pass: Parse all zones
    if (root.isMember("zones") && root["zones"].isArray())
    {
        for (const auto &jz : root["zones"])
        {
            model.zones.emplace_back(parseZone(jz));
        }
    }

    // Second pass: Parse controllers and link them to zones
    if (root.isMember("controllers") && root["controllers"].isArray())
    {
        for (const auto &jc : root["controllers"])
        {
            auto controller = parseController(jc);

            // Link zones to controller based on zoneIds
            if (jc.isMember("zoneIds") && jc["zoneIds"].isArray())
            {
                for (const auto &zoneIdJson : jc["zoneIds"])
                {
                    std::string zoneId = zoneIdJson.asString();

                    // Find the zone with matching ID
                    for (const auto &zone : model.zones)
                    {
                        if (zone->id == zoneId)
                        {
                            controller->zones.push_back(zone);
                            break;
                        }
                    }
                }
            }

            model.controllers.emplace_back(controller);
        }
    }

    return model;
}

#ifndef OCA_LITE_CONTROLLER
inline std::unique_ptr<ZoneGroup> MakeZoneGroupFromControlSystemConfig(const ControlSystemConfig &config)
{
    static ::OcaLiteList<::OcaLitePort> s_emptyPorts;

    // Create the top-level zones container
    auto zonesContainer = std::make_unique<ZoneGroup>(
        ROOT_ZONE_CONTAINER_ONO,
        static_cast<::OcaBoolean>(true),
        ::OcaLiteString("Zones"));

    if (!zonesContainer)
        return nullptr;

    for (const auto &zone : config.zones)
    {
        // Create zone group/block using the ONO from the zone's FusionZoneOno
        auto zoneGroup = std::make_unique<ZoneGroup>(
            zone->ono.zone,
            static_cast<::OcaBoolean>(true),
            ::OcaLiteString(zone->name.c_str()),
            static_cast<::OcaONo>(0));

        if (!zoneGroup)
            continue;

        ZoneGroup *zoneGroupRaw = zoneGroup.get();

        // Add zone to the container first
        if (!zonesContainer->AddObject(*zoneGroup))
            continue;

        // Release ownership of zone group - OCA now owns it
        zoneGroup.release();

        // Create Gain Actuator using ONO from zone->ono.gain
        if (zone->ono.gain > 0)
        {
            ::OcaLiteList<::OcaLitePort> gainPorts;

            // Parse gain config values or use defaults
            double minGain = -60.0;
            double maxGain = 20.0;
            if (!zone->gain.min_value.empty())
                minGain = std::stod(zone->gain.min_value);
            if (!zone->gain.max_value.empty())
                maxGain = std::stod(zone->gain.max_value);

            auto gainActuator = std::make_unique<ConcreteGainActuator>(
                zone->ono.gain,
                static_cast<::OcaBoolean>(true),
                ::OcaLiteString((zone->name + " Gain").c_str()),
                gainPorts,
                minGain,
                maxGain,
                zone->gain.gainID);

            gainActuator->handleFusionGainMessage(::OcaDB(std::stod(zone->gain.default_gain_value)));

            if (gainActuator)
            {
                if (zoneGroupRaw->AddObject(*gainActuator))
                    gainActuator.release(); // OCA now owns it
            }
        }

        // Create Mute Actuator using ONO from zone->ono.mute
        if (zone->ono.mute > 0)
        {
            ::OcaLiteList<::OcaLitePort> mutePorts;
            auto muteActuator = std::make_unique<ConcreteMuteActuator>(
                zone->ono.mute,
                static_cast<::OcaBoolean>(true),
                ::OcaLiteString((zone->name + " Mute").c_str()),
                mutePorts,
                zone->gain.gainID);

            muteActuator->handleFusionMuteMessage(zone->gain.default_mute_value == "true" ? true : false);

            if (muteActuator)
            {
                if (zoneGroupRaw->AddObject(*muteActuator))
                    muteActuator.release(); // OCA now owns it
            }
        }

        // Create Source Switch Actuator using ONO from zone->ono.sourceSelector
        if (zone->ono.sourceSelector > 0 && !zone->sources.empty())
        {
            ::OcaLiteList<::OcaLitePort> switchPorts;
            ::OcaLiteList<::OcaLiteString> sourceNames;
            ::OcaLiteList<::OcaBoolean> sourceEnables;

            // Use sequential positions 0, 1, 2... regardless of source.index values
            for (const auto &source : zone->sources)
            {
                sourceNames.Add(::OcaLiteString(source.label.c_str()));
                sourceEnables.Add(static_cast<::OcaBoolean>(true));
            }

            auto switchActuator = std::make_unique<ConcreteSwitchActuator>(
                zone->ono.sourceSelector,
                static_cast<::OcaBoolean>(true),
                ::OcaLiteString((zone->name + " Source Select").c_str()),
                switchPorts,
                static_cast<::OcaUint16>(0),
                static_cast<::OcaUint16>(zone->sources.size() - 1),
                sourceNames,
                sourceEnables,
                zone->id);

            if (switchActuator)
            {
                if (zoneGroupRaw->AddObject(*switchActuator))
                    switchActuator.release(); // OCA now owns it
            }
        }
    }

    return zonesContainer;
}
#endif
