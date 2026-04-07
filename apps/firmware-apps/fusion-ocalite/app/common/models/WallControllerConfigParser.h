// This file contains parsing functions for all the JSON updates for and to the wall controller.
// It also includes parsing logic for the zones.

#pragma once

#include "Models.h"
#include <json/json.h>
#include <memory>
#include <stdexcept>
#include <string>

inline std::string WallControllerToJsonString(const Controller &controller)
{
    Json::Value root;

    // Basic controller info
    root["id"] = controller.id;
    root["name"] = controller.name;

    // Zone IDs array
    Json::Value zoneIds(Json::arrayValue);
    for (const auto &zoneId : controller.zoneIds)
    {
        zoneIds.append(zoneId);
    }
    root["zoneIds"] = zoneIds;

    // Zones array (full zone objects)
    Json::Value zones(Json::arrayValue);
    for (const auto &zone : controller.zones)
    {
        Json::Value zoneObj;
        zoneObj["id"] = zone->id;
        zoneObj["name"] = zone->name;

        // ONO object
        Json::Value ono;
        ono["zone"] = zone->ono.zone;
        ono["gain"] = zone->ono.gain;
        ono["mute"] = zone->ono.mute;
        ono["sourceSelector"] = zone->ono.sourceSelector;
        zoneObj["ono"] = ono;

        // Gain config
        Json::Value gain;
        gain["gainID"] = zone->gain.gainID;
        gain["min_value"] = zone->gain.min_value;
        gain["max_value"] = zone->gain.max_value;
        gain["default_gain_value"] = zone->gain.default_gain_value;
        gain["default_mute_value"] = zone->gain.default_mute_value;
        zoneObj["gain"] = gain;

        // Sources array
        Json::Value sources(Json::arrayValue);
        for (const auto &source : zone->sources)
        {
            Json::Value sourceObj;
            sourceObj["index"] = source.index;
            sourceObj["label"] = source.label;
            sources.append(sourceObj);
        }
        zoneObj["sources"] = sources;

        zones.append(zoneObj);
    }
    root["zones"] = zones;

    // Convert to string with pretty printing
    Json::StreamWriterBuilder builder;
    builder["indentation"] = "  ";
    return Json::writeString(builder, root);
}

inline std::shared_ptr<Controller> JsonStringToWallController(const std::string &jsonString)
{
    Json::Value root;
    Json::Reader reader;

    if (!reader.parse(jsonString, root))
    {
        OCA_LOG_ERROR_PARAMS("Failed to parse JSON: %s", reader.getFormattedErrorMessages());
        return NULL;
    }

    if (!root.isObject())
    {
        OCA_LOG_ERROR("JSON root must be an object");
        return NULL;
    }

    auto controller = std::make_shared<Controller>();

    // Parse basic controller info
    if (root.isMember("id") && root["id"].isString())
    {
        controller->id = root["id"].asString();
    }

    if (root.isMember("name") && root["name"].isString())
    {
        controller->name = root["name"].asString();
    }

    // Parse zone IDs array
    if (root.isMember("zoneIds") && root["zoneIds"].isArray())
    {
        for (const auto &zoneIdJson : root["zoneIds"])
        {
            if (zoneIdJson.isString())
            {
                controller->zoneIds.push_back(zoneIdJson.asString());
            }
        }
    }

    // Parse zones array (full zone objects)
    if (root.isMember("zones") && root["zones"].isArray())
    {
        for (const auto &zoneJson : root["zones"])
        {
            if (!zoneJson.isObject())
                continue;

            auto zone = std::make_shared<Zone>();

            // Basic zone info
            if (zoneJson.isMember("id") && zoneJson["id"].isString())
            {
                zone->id = zoneJson["id"].asString();
            }

            if (zoneJson.isMember("name") && zoneJson["name"].isString())
            {
                zone->name = zoneJson["name"].asString();
            }

            // Parse ONO object
            if (zoneJson.isMember("ono") && zoneJson["ono"].isObject())
            {
                const auto &onoJson = zoneJson["ono"];
                if (onoJson.isMember("zone") && onoJson["zone"].isInt())
                    zone->ono.zone = onoJson["zone"].asInt();
                if (onoJson.isMember("gain") && onoJson["gain"].isInt())
                    zone->ono.gain = onoJson["gain"].asInt();
                if (onoJson.isMember("mute") && onoJson["mute"].isInt())
                    zone->ono.mute = onoJson["mute"].asInt();
                if (onoJson.isMember("sourceSelector") && onoJson["sourceSelector"].isInt())
                    zone->ono.sourceSelector = onoJson["sourceSelector"].asInt();
            }

            // Parse gain config
            if (zoneJson.isMember("gain") && zoneJson["gain"].isObject())
            {
                const auto &gainJson = zoneJson["gain"];
                if (gainJson.isMember("gainID") && gainJson["gainID"].isString())
                    zone->gain.gainID = gainJson["gainID"].asString();
                if (gainJson.isMember("min_value") && gainJson["min_value"].isString())
                    zone->gain.min_value = gainJson["min_value"].asString();
                if (gainJson.isMember("max_value") && gainJson["max_value"].isString())
                    zone->gain.max_value = gainJson["max_value"].asString();
                if (gainJson.isMember("default_gain_value") && gainJson["default_gain_value"].isString())
                    zone->gain.default_gain_value = gainJson["default_gain_value"].asString();
                if (gainJson.isMember("default_mute_value") && gainJson["default_mute_value"].isString())
                    zone->gain.default_mute_value = gainJson["default_mute_value"].asString();
            }

            // Parse sources array
            if (zoneJson.isMember("sources") && zoneJson["sources"].isArray())
            {
                for (const auto &sourceJson : zoneJson["sources"])
                {
                    if (!sourceJson.isObject())
                        continue;

                    Source source;
                    if (sourceJson.isMember("index") && sourceJson["index"].isInt())
                        source.index = sourceJson["index"].asInt();
                    if (sourceJson.isMember("label") && sourceJson["label"].isString())
                        source.label = sourceJson["label"].asString();

                    zone->sources.push_back(source);
                }
            }

            controller->zones.push_back(zone);
        }
    }

    return controller;
}
