#include "ZoneConfigBuilder.h"
#include <cstring>
#include <cstdio>
#include <cerrno>
#include <limits>
#include <cctype>

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
static bool parseZonesObject(const char *json, std::vector<ZoneDef> &zones)
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
        ZoneDef zone;
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
            else if (propKey == "controllerId")
            {
                if (!parseString(p, zone.controllerId))
                    return false;
                // Parsed but not used as per requirements
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
static bool parseZonesInternal(const std::string &json, std::vector<ZoneDef> &out)
{
    return parseZonesObject(json.c_str(), out);
} // Public wrapper for tests / external usage
bool parseJson(const std::string &json, std::vector<ZoneDef> &zonesOut)
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

BuiltZones createZoneObjects(const std::vector<ZoneDef> &zoneDefs,
                             ::OcaONo baseZoneGroupONo)
{
    BuiltZones model{};
    model.zonesContainer.reset(new ZoneGroup(baseZoneGroupONo, static_cast<::OcaBoolean>(true), ::OcaLiteString("Zone")));
    if (!model.zonesContainer)
        return model;

    model.zones.reserve(zoneDefs.size());
    for (size_t i = 0; i < zoneDefs.size(); ++i)
    {
        const ZoneDef &zoneDef = zoneDefs[i];
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
    std::vector<ZoneDef> zones;
    if (!parseJson(json, zones))
    {
        OCA_LOG_ERROR("[ZoneConfig] Failed to parse any zones from JSON\n");
        return empty;
    }
    BuiltZones model = createZoneObjects(zones, baseZoneGroupONo);
    buildHierarchy(model);
    return model;
}
