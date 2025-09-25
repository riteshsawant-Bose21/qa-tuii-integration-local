#include "ZoneConfigBuilder.h"
#include <cstring>
#include <cstdio>
#include <cerrno>
#include <limits>
#include <cctype>
#include <map>
#include <memory>

// Helper trim of simple quotes/spaces
static std::string trim(const std::string &s)
{
    size_t b = 0;
    while (b < s.size() && (s[b] == ' ' || s[b] == '\n' || s[b] == '\t' || s[b] == '\r' || s[b] == '"'))
        ++b;
    size_t e = s.size();
    while (e > b && (s[e - 1] == ' ' || s[e - 1] == '\n' || s[e - 1] == '\t' || s[e - 1] == '\r' || s[e - 1] == '"'))
        --e;
    return s.substr(b, e - b);
}

// Helper function to parse a numeric value from JSON
static bool parseNumber(const char *&p, ::OcaONo &result)
{
    errno = 0;
    char *endPtr = nullptr;
    unsigned long val = std::strtoul(p, &endPtr, 10);

    if (endPtr == p)
        return false; // No digits
    if (errno == ERANGE || val > std::numeric_limits<::OcaONo>::max())
        return false; // out of range
    if (!(*endPtr == ' ' || *endPtr == '\n' || *endPtr == '\r' || *endPtr == '\t' ||
          *endPtr == ',' || *endPtr == '}' || *endPtr == '"'))
        return false; // Invalid delimiter

    result = static_cast<::OcaONo>(val);
    p = endPtr;
    return true;
}

// Helper function to parse a string value from JSON
static bool parseString(const char *&p, std::string &result)
{
    if (*p != '"')
        return false;
    ++p;

    const char *start = p;
    while (*p && *p != '"')
        ++p;
    if (!*p)
        return false;

    result.assign(start, p - start);
    ++p;
    return true;
}

// Helper function to skip whitespace
static void skipWhitespace(const char *&p)
{
    while (*p && (*p == ' ' || *p == '\n' || *p == '\t' || *p == '\r'))
        ++p;
}

// Helper function to find and parse the zones object
static bool parseZonesObject(const char *json, std::vector<Zone> &zones)
{
    const char *p = json;

    // Find "zones": pattern (not just "zones" which could be inside "zoneIds")
    const char *zonesKey = strstr(p, "\"zones\":");
    if (!zonesKey)
        return false;

    p = zonesKey + 8; // Skip "zones":
    skipWhitespace(p);
    skipWhitespace(p);

    if (*p != '{')
        return false;
    ++p;
    skipWhitespace(p);

    // Parse each zone in the zones object
    while (*p && *p != '}')
    {
        // Skip comma if not first zone
        if (*p == ',')
        {
            ++p;
            skipWhitespace(p);
        }

        if (*p == '}')
            break;

        // Parse zone key (zone ID)
        std::string zoneKey;
        if (!parseString(p, zoneKey))
            return false;

        skipWhitespace(p);
        if (*p != ':')
            return false;
        ++p;
        skipWhitespace(p);

        if (*p != '{')
            return false;
        ++p;
        skipWhitespace(p);

        // Parse zone object
        Zone zone;
        zone.id = zoneKey;

        bool hasName = false, hasGainID = false, hasOno = false;

        while (*p && *p != '}')
        {
            if (*p == ',')
            {
                ++p;
                skipWhitespace(p);
            }

            if (*p == '}')
                break;

            // Parse property key
            std::string propKey;
            if (!parseString(p, propKey))
                return false;

            skipWhitespace(p);
            if (*p != ':')
                return false;
            ++p;
            skipWhitespace(p);

            if (propKey == "id")
            {
                std::string id;
                if (!parseString(p, id))
                    return false;
                // zone.id already set from key, could validate they match
            }
            else if (propKey == "name")
            {
                if (!parseString(p, zone.name))
                    return false;
                hasName = true;
            }
            else if (propKey == "gainID")
            {
                if (!parseString(p, zone.gainID))
                    return false;
                hasGainID = true;
            }
            else if (propKey == "ono")
            {
                if (*p != '{')
                    return false;
                ++p;
                skipWhitespace(p);

                bool hasZone = false, hasGain = false, hasMute = false, hasSourceSelector = false;

                while (*p && *p != '}')
                {
                    if (*p == ',')
                    {
                        ++p;
                        skipWhitespace(p);
                    }

                    if (*p == '}')
                        break;

                    std::string onoKey;
                    if (!parseString(p, onoKey))
                        return false;

                    skipWhitespace(p);
                    if (*p != ':')
                        return false;
                    ++p;
                    skipWhitespace(p);

                    if (onoKey == "zone")
                    {
                        if (!parseNumber(p, zone.ono.zone))
                            return false;
                        hasZone = true;
                    }
                    else if (onoKey == "gain")
                    {
                        if (!parseNumber(p, zone.ono.gain))
                            return false;
                        hasGain = true;
                    }
                    else if (onoKey == "mute")
                    {
                        if (!parseNumber(p, zone.ono.mute))
                            return false;
                        hasMute = true;
                    }
                    else if (onoKey == "sourceSelector")
                    {
                        if (!parseNumber(p, zone.ono.sourceSelector))
                            return false;
                        hasSourceSelector = true;
                    }
                    else
                    {
                        // Skip unknown ONO property
                        while (*p && *p != ',' && *p != '}')
                            ++p;
                    }

                    skipWhitespace(p);
                }

                if (*p != '}')
                    return false;
                ++p;

                if (hasZone && hasGain && hasMute && hasSourceSelector)
                {
                    hasOno = true;
                }
            }
            else if (propKey == "sources")
            {
                if (*p != '[')
                    return false;
                ++p;
                skipWhitespace(p);

                while (*p && *p != ']')
                {
                    if (*p == ',')
                    {
                        ++p;
                        skipWhitespace(p);
                    }

                    if (*p == ']')
                        break;

                    if (*p != '{')
                        return false;
                    ++p;
                    skipWhitespace(p);

                    ZoneSourceDef source;
                    bool hasIndex = false, hasLabel = false;

                    while (*p && *p != '}')
                    {
                        if (*p == ',')
                        {
                            ++p;
                            skipWhitespace(p);
                        }

                        if (*p == '}')
                            break;

                        std::string srcKey;
                        if (!parseString(p, srcKey))
                            return false;

                        skipWhitespace(p);
                        if (*p != ':')
                            return false;
                        ++p;
                        skipWhitespace(p);

                        if (srcKey == "index")
                        {
                            // Parse numeric index value directly (not as string)
                            ::OcaONo indexVal;
                            if (!parseNumber(p, indexVal))
                                return false;
                            source.index = static_cast<unsigned>(indexVal);
                            hasIndex = true;
                        }
                        else if (srcKey == "label")
                        {
                            if (!parseString(p, source.label))
                                return false;
                            hasLabel = true;
                        }
                        else
                        {
                            // Skip unknown source property
                            if (*p == '"')
                            {
                                std::string dummy;
                                parseString(p, dummy);
                            }
                            else
                            {
                                while (*p && *p != ',' && *p != '}')
                                    ++p;
                            }
                        }

                        skipWhitespace(p);
                    }

                    if (*p != '}')
                        return false;
                    ++p;

                    if (hasIndex)
                    {
                        if (!hasLabel)
                            source.label = "";
                        zone.sources.push_back(source);
                    }

                    skipWhitespace(p);
                }

                if (*p != ']')
                    return false;
                ++p;
            }
            else
            {
                // Skip unknown property
                if (*p == '"')
                {
                    std::string dummy;
                    parseString(p, dummy);
                }
                else if (*p == '{' || *p == '[')
                {
                    // Skip complex objects/arrays
                    char openChar = *p;
                    char closeChar = (openChar == '{') ? '}' : ']';
                    int depth = 1;
                    ++p;

                    while (*p && depth > 0)
                    {
                        if (*p == openChar)
                            depth++;
                        else if (*p == closeChar)
                            depth--;
                        ++p;
                    }
                }
                else
                {
                    while (*p && *p != ',' && *p != '}')
                        ++p;
                }
            }

            skipWhitespace(p);
        }

        if (*p != '}')
            return false;
        ++p;

        // Validate required fields
        if (hasName && hasGainID && hasOno)
        {
            zones.push_back(zone);
        }

        skipWhitespace(p);
    }

    return !zones.empty();
}

// Internal parser implementation for new JSON structure
static bool parseZonesInternal(const std::string &json, std::vector<Zone> &out)
{
    return parseZonesObject(json.c_str(), out);
} // Public wrapper for tests / external usage
bool parseJson(const std::string &json, std::vector<Zone> &zonesOut)
{
    zonesOut.clear();
    return parseZonesInternal(json, zonesOut);
}

// Build lists for switch names/enables
static void buildSwitchLists(const std::vector<ZoneSourceDef> &sources,
                             unsigned &minPos, unsigned &maxPos,
                             ::OcaLiteList<::OcaLiteString> &names,
                             ::OcaLiteList<::OcaBoolean> &enables)
{
    if (sources.empty())
        return;
    minPos = maxPos = sources.front().index;
    for (const auto &s : sources)
    {
        if (s.index < minPos)
            minPos = s.index;
        if (s.index > maxPos)
            maxPos = s.index;
    }
    for (unsigned pos = minPos; pos <= maxPos; ++pos)
    {
        names.Add(::OcaLiteString(""));
        enables.Add(static_cast<::OcaBoolean>(true));
    }
    for (const auto &s : sources)
    {
        if (s.index >= minPos && s.index <= maxPos)
        {
            ::OcaUint16 offset = static_cast<::OcaUint16>(s.index - minPos);
            if (offset < names.GetCount())
            {
                names.GetItem(offset) = ::OcaLiteString(s.label.c_str());
            }
        }
    }
}

BuiltZones createZoneObjects(const std::vector<Zone> &zoneDefs,
                             ::OcaONo baseZoneGroupONo)
{
    BuiltZones model{};
    model.zonesContainer.reset(new ZoneGroup(baseZoneGroupONo, static_cast<::OcaBoolean>(true), ::OcaLiteString("Zone")));
    if (!model.zonesContainer)
        return model;

    model.zones.reserve(zoneDefs.size());
    for (size_t i = 0; i < zoneDefs.size(); ++i)
    {
        const Zone &zoneDef = zoneDefs[i];
        ZoneObjects zb;
        zb.group.reset(new ZoneGroup(zoneDef.ono.zone, static_cast<::OcaBoolean>(true), ::OcaLiteString(zoneDef.name.c_str())));
        if (!zb.group)
        {
            model.zones.push_back(std::move(zb));
            continue;
        }

        // Use ONOs from nested structure
        ::OcaONo gainONo = zoneDef.ono.gain;
        ::OcaONo muteONo = zoneDef.ono.mute;
        ::OcaONo switchONo = zoneDef.ono.sourceSelector;

        // Gain
        ::OcaLiteList<::OcaLitePort> gainPorts;
        zb.gain.reset(new ConcreteGainActuator(gainONo, static_cast<::OcaBoolean>(true), ::OcaLiteString((zoneDef.name + " Gain").c_str()), gainPorts, -60.0, 20.0, zoneDef.gainID));
        if (!zb.gain)
        {
            model.zones.push_back(std::move(zb));
            continue;
        }

        // Mute
        ::OcaLiteList<::OcaLitePort> mutePorts;
        zb.mute.reset(new ConcreteMuteActuator(muteONo, static_cast<::OcaBoolean>(true), ::OcaLiteString((zoneDef.name + " Mute").c_str()), mutePorts, zoneDef.gainID));

        // Switch
        if (!zoneDef.sources.empty())
        {
            unsigned minPos = 0, maxPos = 0;
            ::OcaLiteList<::OcaLiteString> names;
            ::OcaLiteList<::OcaBoolean> enables;
            buildSwitchLists(zoneDef.sources, minPos, maxPos, names, enables);
            ::OcaLiteList<::OcaLitePort> switchPorts;
            zb.sw.reset(new ConcreteSwitchActuator(
                switchONo,
                static_cast<::OcaBoolean>(true),
                ::OcaLiteString("Source Select"),
                switchPorts,
                static_cast<::OcaUint16>(minPos),
                static_cast<::OcaUint16>(maxPos),
                names,
                enables,
                zoneDef.id));
        }
        model.zones.push_back(std::move(zb));
    }
    return model;
}

void buildHierarchy(BuiltZones &zonesModel)
{
    if (!zonesModel.zonesContainer)
        return;
    for (auto &zb : zonesModel.zones)
    {
        if (!zb.group)
            continue;
        ZoneGroup *groupRaw = zb.group.get();
        if (!zonesModel.zonesContainer->AddObject(*groupRaw))
        {
            zb.group.reset();
            continue;
        }

        // Add children before releasing group (need raw pointer intact)
        if (zb.gain)
        {
            if (!groupRaw->AddObject(*zb.gain))
            {
                zb.gain.reset();
            }
            else
            {
                zb.gain.release();
            }
        }
        if (zb.mute)
        {
            if (!groupRaw->AddObject(*zb.mute))
            {
                zb.mute.reset();
            }
            else
            {
                zb.mute.release();
            }
        }
        if (zb.sw)
        {
            if (!groupRaw->AddObject(*zb.sw))
            {
                zb.sw.reset();
            }
            else
            {
                zb.sw.release();
            }
        }
        // Release ownership of group last (OCA now owns it)
        zb.group.release();
    }
}

BuiltZones BuildZonesFromJson(const std::string &json, ::OcaONo baseZoneGroupONo)
{
    BuiltZones empty{};
    std::vector<Zone> zones;
    if (!parseJson(json, zones))
    {
        OCA_LOG_ERROR("[ZoneConfig] Failed to parse any zones from JSON\n");
        return empty;
    }
    BuiltZones model = createZoneObjects(zones, baseZoneGroupONo);
    buildHierarchy(model);
    return model;
}

std::vector<Controller> BuildControllersFromMetadataJson(const std::string &json)
{
    std::vector<Controller> controllers;

    // First, parse all zones
    std::vector<Zone> allZones;
    if (!parseJson(json, allZones))
    {
        return controllers; // empty vector on parse failure
    }

    // Create a map for quick zone lookup by ID
    std::map<std::string, std::shared_ptr<Zone>> zoneMap;
    for (const auto &zone : allZones)
    {
        zoneMap[zone.id] = std::make_shared<Zone>(zone);
    }

    // Parse controllers section
    const char *controllersStart = strstr(json.c_str(), "\"controllers\"");
    if (!controllersStart)
    {
        return controllers; // No controllers section found
    }

    const char *objStart = strchr(controllersStart, '{');
    if (!objStart)
    {
        return controllers;
    }

    const char *p = objStart + 1;
    skipWhitespace(p);

    while (*p && *p != '}')
    {
        // Skip comma if not first controller
        if (*p == ',')
        {
            ++p;
            skipWhitespace(p);
        }

        if (*p == '}')
            break;

        // Parse controller key (controller ID)
        std::string controllerKey;
        if (!parseString(p, controllerKey))
        {
            ++p;
            continue;
        }

        skipWhitespace(p);
        if (*p != ':')
        {
            ++p;
            continue;
        }
        ++p;
        skipWhitespace(p);

        if (*p != '{')
        {
            ++p;
            continue;
        }

        // Find the end of this controller object
        const char *controllerObjStart = p;
        const char *objEnd = p + 1;
        int braceCount = 1;
        while (*objEnd && braceCount > 0)
        {
            if (*objEnd == '{')
                braceCount++;
            else if (*objEnd == '}')
                braceCount--;
            objEnd++;
        }

        if (braceCount != 0)
            break; // malformed JSON

        // Parse controller object
        Controller controller;
        controller.id = controllerKey; // Use the key as the controller ID

        // Parse the controller object properties
        const char *innerP = controllerObjStart + 1;
        skipWhitespace(innerP);

        while (*innerP && *innerP != '}')
        {
            if (*innerP == ',')
            {
                ++innerP;
                skipWhitespace(innerP);
            }

            if (*innerP == '}')
                break;

            // Parse property key
            std::string propKey;
            if (!parseString(innerP, propKey))
                break;

            skipWhitespace(innerP);
            if (*innerP != ':')
                break;
            ++innerP;
            skipWhitespace(innerP);

            if (propKey == "id")
            {
                // Skip the id property (we already have it from the key)
                std::string dummy;
                if (*innerP == '"')
                {
                    parseString(innerP, dummy);
                }
            }
            else if (propKey == "name")
            {
                if (*innerP == '"')
                {
                    parseString(innerP, controller.name);
                }
            }
            else if (propKey == "zoneIds")
            {
                if (*innerP == '[')
                {
                    ++innerP;
                    skipWhitespace(innerP);

                    while (*innerP && *innerP != ']')
                    {
                        if (*innerP == ',')
                        {
                            ++innerP;
                            skipWhitespace(innerP);
                        }

                        if (*innerP == ']')
                            break;

                        std::string zoneId;
                        if (*innerP == '"' && parseString(innerP, zoneId))
                        {
                            // Find the zone with this ID and add it to the controller
                            auto zoneIt = zoneMap.find(zoneId);
                            if (zoneIt != zoneMap.end())
                            {
                                controller.zones.push_back(zoneIt->second);
                            }
                        }

                        skipWhitespace(innerP);
                    }

                    if (*innerP == ']')
                        ++innerP;
                }
            }
            else
            {
                // Skip unknown property
                if (*innerP == '"')
                {
                    std::string dummy;
                    parseString(innerP, dummy);
                }
                else if (*innerP == '[' || *innerP == '{')
                {
                    // Skip complex objects/arrays
                    char openChar = *innerP;
                    char closeChar = (openChar == '{') ? '}' : ']';
                    int depth = 1;
                    ++innerP;

                    while (*innerP && depth > 0)
                    {
                        if (*innerP == openChar)
                            depth++;
                        else if (*innerP == closeChar)
                            depth--;
                        ++innerP;
                    }
                }
                else
                {
                    while (*innerP && *innerP != ',' && *innerP != '}')
                        ++innerP;
                }
            }

            skipWhitespace(innerP);
        }

        if (!controller.id.empty())
        {
            controllers.push_back(controller);
        }

        p = objEnd;
        skipWhitespace(p);
    }

    return controllers;
}

std::vector<Controller> DeserializeControllers(const std::string &json)
{
    std::vector<Controller> controllers;

    if (json.empty())
    {
        return controllers;
    }

    const char *p = json.c_str();
    skipWhitespace(p);

    if (*p != '{')
    {
        return controllers; // Not a valid JSON object
    }

    ++p; // Skip opening brace
    skipWhitespace(p);

    Controller controller;

    while (*p && *p != '}')
    {
        if (*p == ',')
        {
            ++p;
            skipWhitespace(p);
        }

        if (*p == '}')
            break;

        // Parse property key
        std::string propKey;
        if (!parseString(p, propKey))
            break;

        skipWhitespace(p);
        if (*p != ':')
            break;
        ++p;
        skipWhitespace(p);

        if (propKey == "id")
        {
            if (*p == '"')
            {
                parseString(p, controller.id);
            }
        }
        else if (propKey == "name")
        {
            if (*p == '"')
            {
                parseString(p, controller.name);
            }
        }
        else if (propKey == "zones")
        {
            if (*p == '[')
            {
                ++p;
                skipWhitespace(p);

                while (*p && *p != ']')
                {
                    if (*p == ',')
                    {
                        ++p;
                        skipWhitespace(p);
                    }

                    if (*p == ']')
                        break;

                    if (*p == '{')
                    {
                        // Parse zone object
                        auto zone = std::make_shared<Zone>();

                        const char *zoneStart = p;
                        ++p; // Skip opening brace
                        skipWhitespace(p);

                        while (*p && *p != '}')
                        {
                            if (*p == ',')
                            {
                                ++p;
                                skipWhitespace(p);
                            }

                            if (*p == '}')
                                break;

                            std::string zoneKey;
                            if (!parseString(p, zoneKey))
                                break;

                            skipWhitespace(p);
                            if (*p != ':')
                                break;
                            ++p;
                            skipWhitespace(p);

                            if (zoneKey == "id")
                            {
                                if (*p == '"')
                                {
                                    parseString(p, zone->id);
                                }
                            }
                            else if (zoneKey == "name")
                            {
                                if (*p == '"')
                                {
                                    parseString(p, zone->name);
                                }
                            }
                            else if (zoneKey == "gainID")
                            {
                                if (*p == '"')
                                {
                                    parseString(p, zone->gainID);
                                }
                            }
                            else if (zoneKey == "ono")
                            {
                                if (*p == '{')
                                {
                                    ++p;
                                    skipWhitespace(p);

                                    while (*p && *p != '}')
                                    {
                                        if (*p == ',')
                                        {
                                            ++p;
                                            skipWhitespace(p);
                                        }

                                        if (*p == '}')
                                            break;

                                        std::string onoKey;
                                        if (!parseString(p, onoKey))
                                            break;

                                        skipWhitespace(p);
                                        if (*p != ':')
                                            break;
                                        ++p;
                                        skipWhitespace(p);

                                        ::OcaONo onoValue;
                                        if (parseNumber(p, onoValue))
                                        {
                                            if (onoKey == "zone")
                                                zone->ono.zone = onoValue;
                                            else if (onoKey == "gain")
                                                zone->ono.gain = onoValue;
                                            else if (onoKey == "mute")
                                                zone->ono.mute = onoValue;
                                            else if (onoKey == "sourceSelector")
                                                zone->ono.sourceSelector = onoValue;
                                        }

                                        skipWhitespace(p);
                                    }

                                    if (*p == '}')
                                        ++p;
                                }
                            }
                            else if (zoneKey == "sources")
                            {
                                if (*p == '[')
                                {
                                    ++p;
                                    skipWhitespace(p);

                                    while (*p && *p != ']')
                                    {
                                        if (*p == ',')
                                        {
                                            ++p;
                                            skipWhitespace(p);
                                        }

                                        if (*p == ']')
                                            break;

                                        if (*p == '{')
                                        {
                                            ZoneSourceDef source;
                                            ++p;
                                            skipWhitespace(p);

                                            while (*p && *p != '}')
                                            {
                                                if (*p == ',')
                                                {
                                                    ++p;
                                                    skipWhitespace(p);
                                                }

                                                if (*p == '}')
                                                    break;

                                                std::string sourceKey;
                                                if (!parseString(p, sourceKey))
                                                    break;

                                                skipWhitespace(p);
                                                if (*p != ':')
                                                    break;
                                                ++p;
                                                skipWhitespace(p);

                                                if (sourceKey == "index")
                                                {
                                                    ::OcaONo indexValue;
                                                    if (parseNumber(p, indexValue))
                                                    {
                                                        source.index = static_cast<unsigned int>(indexValue);
                                                    }
                                                }
                                                else if (sourceKey == "label")
                                                {
                                                    if (*p == '"')
                                                    {
                                                        parseString(p, source.label);
                                                    }
                                                }

                                                skipWhitespace(p);
                                            }

                                            if (*p == '}')
                                                ++p;

                                            zone->sources.push_back(source);
                                        }

                                        skipWhitespace(p);
                                    }

                                    if (*p == ']')
                                        ++p;
                                }
                            }
                            else
                            {
                                // Skip unknown property
                                if (*p == '"')
                                {
                                    std::string dummy;
                                    parseString(p, dummy);
                                }
                                else if (*p == '[' || *p == '{')
                                {
                                    // Skip complex objects/arrays
                                    char openChar = *p;
                                    char closeChar = (openChar == '{') ? '}' : ']';
                                    int depth = 1;
                                    ++p;

                                    while (*p && depth > 0)
                                    {
                                        if (*p == openChar)
                                            depth++;
                                        else if (*p == closeChar)
                                            depth--;
                                        ++p;
                                    }
                                }
                                else
                                {
                                    while (*p && *p != ',' && *p != '}')
                                        ++p;
                                }
                            }

                            skipWhitespace(p);
                        }

                        if (*p == '}')
                            ++p;

                        controller.zones.push_back(zone);
                    }

                    skipWhitespace(p);
                }

                if (*p == ']')
                    ++p;
            }
        }
        else
        {
            // Skip unknown property
            if (*p == '"')
            {
                std::string dummy;
                parseString(p, dummy);
            }
            else if (*p == '[' || *p == '{')
            {
                // Skip complex objects/arrays
                char openChar = *p;
                char closeChar = (openChar == '{') ? '}' : ']';
                int depth = 1;
                ++p;

                while (*p && depth > 0)
                {
                    if (*p == openChar)
                        depth++;
                    else if (*p == closeChar)
                        depth--;
                    ++p;
                }
            }
            else
            {
                while (*p && *p != ',' && *p != '}')
                    ++p;
            }
        }

        skipWhitespace(p);
    }

    if (!controller.id.empty())
    {
        controllers.push_back(controller);
    }

    return controllers;
}

std::string SerializeControllerToJson(const Controller &controller)
{
    std::string json;

    // Calculate approximate JSON size to reduce string reallocations
    size_t estimatedSize = 100; // Base overhead for controller structure: {"id":"","name":"","zones":[]}
    estimatedSize += controller.id.length() + controller.name.length();

    for (const auto &zone : controller.zones)
    {
        estimatedSize += 150; // Base zone structure overhead: {"id":"","name":"","ono":{...},"gainID":"","sources":[]}
        estimatedSize += zone->id.length() + zone->name.length() + zone->gainID.length();
        estimatedSize += 80; // ONO numbers: "zone":9101,"gain":9102,"mute":9103,"sourceSelector":9104

        for (const auto &source : zone->sources)
        {
            estimatedSize += 50; // Source structure: {"index":0,"label":""}
            estimatedSize += source.label.length();
        }
    }

    // Add 20% buffer for safety
    estimatedSize = static_cast<size_t>(estimatedSize * 1.2);
    json.reserve(estimatedSize);

    json += '{';
    json += "\"id\":\"" + controller.id + "\",";
    json += "\"name\":\"" + controller.name + "\",";
    json += "\"zones\":[";

    for (size_t i = 0; i < controller.zones.size(); ++i)
    {
        const auto &zone = controller.zones[i];
        json += '{';
        json += "\"id\":\"" + zone->id + "\",";
        json += "\"name\":\"" + zone->name + "\",";
        json += "\"ono\":{";
        json += "\"zone\":" + std::to_string(static_cast<long long>(zone->ono.zone)) + ",";
        json += "\"gain\":" + std::to_string(static_cast<long long>(zone->ono.gain)) + ",";
        json += "\"mute\":" + std::to_string(static_cast<long long>(zone->ono.mute)) + ",";
        json += "\"sourceSelector\":" + std::to_string(static_cast<long long>(zone->ono.sourceSelector)) + "},";
        json += "\"gainID\":\"" + zone->gainID + "\",";
        json += "\"sources\":[";

        for (size_t j = 0; j < zone->sources.size(); ++j)
        {
            const auto &source = zone->sources[j];
            json += '{';
            json += "\"index\":" + std::to_string(static_cast<unsigned long long>(source.index)) + ",";
            json += "\"label\":\"" + source.label + "\"";
            json += '}';
            if (j + 1 < zone->sources.size())
            {
                json += ',';
            }
        }
        json += "]}";

        if (i + 1 < controller.zones.size())
        {
            json += ',';
        }
    }
    json += "]}";

    return json;
}
