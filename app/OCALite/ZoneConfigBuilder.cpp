#include "ZoneConfigBuilder.h"
#include <cstring>
#include <cstdio>

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

static bool parseZones(const std::string &json, std::vector<ZoneDef> &out)
{
    const char *p = json.c_str();
    const char *zonesKey = strstr(p, "\"zones\"");
    if (!zonesKey)
        return false;
    const char *arrStart = strchr(zonesKey, '[');
    if (!arrStart)
        return false;
    ++arrStart;
    while (*arrStart)
    {
        while (*arrStart && (*arrStart == ' ' || *arrStart == '\n' || *arrStart == '{' || *arrStart == ','))
        {
            if (*arrStart == '{')
            {
                ++arrStart;
                break;
            }
            ++arrStart;
        }
        if (!*arrStart)
            break;
        ZoneDef z;
        bool haveId = false, haveName = false;
        bool done = false;
        while (*arrStart && !done)
        {
            if (*arrStart == '"')
            {
                const char *keyStart = ++arrStart;
                while (*arrStart && *arrStart != '"')
                    ++arrStart;
                if (!*arrStart)
                    return false;
                std::string key(keyStart, arrStart - keyStart);
                ++arrStart;
                while (*arrStart && *arrStart != ':')
                    ++arrStart;
                if (!*arrStart)
                    return false;
                ++arrStart;
                while (*arrStart == ' ')
                    ++arrStart;
                if (key == "id" || key == "name" || key == "gainID")
                {
                    if (*arrStart == '"')
                    {
                        ++arrStart;
                        const char *valStart = arrStart;
                        while (*arrStart && *arrStart != '"')
                            ++arrStart;
                        if (!*arrStart)
                            return false;
                        std::string val(valStart, arrStart - valStart);
                        ++arrStart;
                        val = trim(val);
                        if (key == "id")
                        {
                            z.id = val;
                            haveId = true;
                        }
                        else if (key == "name")
                        {
                            z.name = val;
                            haveName = true;
                        }
                        else
                        {
                            z.gainID = val;
                        }
                    }
                }
                else if (key == "sources")
                {
                    while (*arrStart && *arrStart != '[')
                        ++arrStart;
                    if (!*arrStart)
                        return false;
                    ++arrStart;
                    while (*arrStart)
                    {
                        while (*arrStart && (*arrStart == ' ' || *arrStart == '\n' || *arrStart == '{' || *arrStart == ','))
                        {
                            if (*arrStart == '{')
                            {
                                ++arrStart;
                                break;
                            }
                            ++arrStart;
                        }
                        if (!*arrStart)
                            break;
                        if (*arrStart == ']')
                        {
                            ++arrStart;
                            break;
                        }
                        ZoneSourceDef s;
                        bool haveIdx = false, haveLabel = false;
                        bool sourceDone = false;
                        while (*arrStart && !sourceDone)
                        {
                            if (*arrStart == '"')
                            {
                                const char *sk = ++arrStart;
                                while (*arrStart && *arrStart != '"')
                                    ++arrStart;
                                if (!*arrStart)
                                    return false;
                                std::string skey(sk, arrStart - sk);
                                ++arrStart;
                                while (*arrStart && *arrStart != ':')
                                    ++arrStart;
                                if (!*arrStart)
                                    return false;
                                ++arrStart;
                                while (*arrStart == ' ')
                                    ++arrStart;
                                if (skey == "index")
                                {
                                    unsigned idx = static_cast<unsigned>(strtoul(arrStart, nullptr, 10));
                                    s.index = idx;
                                    haveIdx = true;
                                }
                                else if (skey == "label")
                                {
                                    if (*arrStart == '"')
                                    {
                                        ++arrStart;
                                        const char *sv = arrStart;
                                        while (*arrStart && *arrStart != '"')
                                            ++arrStart;
                                        if (!*arrStart)
                                            return false;
                                        s.label.assign(sv, arrStart - sv);
                                        ++arrStart;
                                        haveLabel = true;
                                    }
                                }
                            }
                            if (*arrStart == '}')
                            {
                                ++arrStart;
                                sourceDone = true;
                            }
                            else
                                ++arrStart;
                        }
                        if (haveIdx)
                        {
                            if (!haveLabel)
                                s.label = "";
                            z.sources.push_back(s);
                        }
                        while (*arrStart && (*arrStart == ' ' || *arrStart == '\n'))
                            ++arrStart;
                        if (*arrStart == ']')
                        {
                            ++arrStart;
                            break;
                        }
                    }
                }
            }
            if (*arrStart == '}')
            {
                ++arrStart;
                done = true;
                break;
            }
            ++arrStart;
        }
        if (haveId && haveName)
            out.push_back(z);
        while (*arrStart && (*arrStart == ' ' || *arrStart == '\n'))
            ++arrStart;
        if (*arrStart == ']')
            break;
    }
    return !out.empty();
}

BuiltZones BuildZonesFromJson(const std::string &json, ::OcaONo baseZoneGroupONo, ::OcaONo firstZoneONo)
{
    BuiltZones result{};
    std::vector<ZoneDef> zones;
    if (!parseZones(json, zones))
    {
        printf("[ZoneConfig] Failed to parse any zones from JSON\n");
        return result;
    }

    // Create top container
    result.zonesContainer = new ZoneGroup(baseZoneGroupONo, static_cast<::OcaBoolean>(true), ::OcaLiteString("Zone"));

    ::OcaONo zoneONo = firstZoneONo;
    // Base ONOs for first zone's actuators (match existing requirement to reuse 4096, 4098)
    const ::OcaONo BASE_GAIN_ONO_FIRST = static_cast<::OcaONo>(4096);
    const ::OcaONo BASE_MUTE_ONO_FIRST = static_cast<::OcaONo>(4097);
    const ::OcaONo BASE_SWITCH_ONO_FIRST = static_cast<::OcaONo>(4098);
    // Offsets for subsequent zones (simple scheme: add zone index * 100)
    const ::OcaONo GAIN_ZONE_STRIDE = static_cast<::OcaONo>(100);
    const ::OcaONo MUTE_ZONE_STRIDE = static_cast<::OcaONo>(100);
    const ::OcaONo SWITCH_ZONE_STRIDE = static_cast<::OcaONo>(100);

    for (size_t i = 0; i < zones.size(); ++i, ++zoneONo)
    {
        ZoneGroup *zg = new ZoneGroup(zoneONo, static_cast<::OcaBoolean>(true), ::OcaLiteString(zones[i].name.c_str()));
        if (!(zg && result.zonesContainer && result.zonesContainer->AddObject(*zg)))
        {
            delete zg; // failed to add
            continue;
        }
        result.zoneGroups.push_back(zg);

        // Determine ONOs for this zone's actuators
        ::OcaONo gainONo = (i == 0) ? BASE_GAIN_ONO_FIRST : static_cast<::OcaONo>(BASE_GAIN_ONO_FIRST + (i * GAIN_ZONE_STRIDE));
        ::OcaONo muteONo = (i == 0) ? BASE_MUTE_ONO_FIRST : static_cast<::OcaONo>(BASE_MUTE_ONO_FIRST + (i * MUTE_ZONE_STRIDE));
        ::OcaONo switchONo = (i == 0) ? BASE_SWITCH_ONO_FIRST : static_cast<::OcaONo>(BASE_SWITCH_ONO_FIRST + (i * SWITCH_ZONE_STRIDE));

        // Build Gain (folding mute semantics into this for future; for now just gain actuator)
        ::OcaLiteList<::OcaLitePort> gainPorts; // empty ports for now
        ConcreteGainActuator *gain = new ConcreteGainActuator(
            gainONo,
            static_cast<::OcaBoolean>(true),
            ::OcaLiteString((zones[i].name + " Gain").c_str()),
            gainPorts,
            -60.0,
            20.0);
        if (gain && zg->AddObject(*gain))
        {
            result.gains.push_back(gain);
            printf("[ZoneConfig] Added Gain ONo %u to zone '%s'\n", static_cast<unsigned>(gainONo), zones[i].name.c_str());
        }
        else
        {
            delete gain;
        }

        // Mute actuator (same role naming as gain) - using separate ONO.
        ::OcaLiteList<::OcaLitePort> mutePorts; // empty ports for now
        ConcreteMuteActuator *mute = new ConcreteMuteActuator(
            muteONo,
            static_cast<::OcaBoolean>(true),
            ::OcaLiteString((zones[i].name + " Gain").c_str()), // same role as gain per requirement
            mutePorts);
        if (mute && zg->AddObject(*mute))
        {
            result.mutes.push_back(mute);
            printf("[ZoneConfig] Added Mute ONo %u to zone '%s'\n", static_cast<unsigned>(muteONo), zones[i].name.c_str());
        }
        else
        {
            delete mute;
        }

        // Switch creation from sources
        if (!zones[i].sources.empty())
        {
            unsigned minPos = zones[i].sources.front().index;
            unsigned maxPos = zones[i].sources.front().index;
            for (const auto &s : zones[i].sources)
            {
                if (s.index < minPos)
                    minPos = s.index;
                if (s.index > maxPos)
                    maxPos = s.index;
            }
            ::OcaLiteList<::OcaLiteString> names;
            ::OcaLiteList<::OcaBoolean> enables;
            for (unsigned pos = minPos; pos <= maxPos; ++pos)
            {
                names.Add(::OcaLiteString(""));
                enables.Add(static_cast<::OcaBoolean>(true));
            }
            for (const auto &s : zones[i].sources)
            {
                if (s.index >= minPos && s.index <= maxPos)
                {
                    names.RemovePosition(s.index - minPos);
                    names.Insert(s.index - minPos, ::OcaLiteString(s.label.c_str()));
                }
            }
            ::OcaLiteList<::OcaLitePort> switchPorts;
            ConcreteSwitchActuator *sw = new ConcreteSwitchActuator(
                switchONo,
                static_cast<::OcaBoolean>(true),
                ::OcaLiteString("Source Select"),
                switchPorts,
                static_cast<::OcaUint16>(minPos),
                static_cast<::OcaUint16>(maxPos),
                names,
                enables);
            if (sw && zg->AddObject(*sw))
            {
                result.switches.push_back(sw);
                printf("[ZoneConfig] Added Switch ONo %u with %u sources to zone '%s'\n", static_cast<unsigned>(switchONo), names.GetCount(), zones[i].name.c_str());
            }
            else
            {
                delete sw;
            }
        }
    }

    return result;
}
