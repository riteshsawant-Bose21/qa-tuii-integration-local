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

// Internal legacy parser implementation (now used by public parseJson wrapper)
static bool parseZonesInternal(const std::string &json, std::vector<ZoneDef> &out)
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

// Public wrapper for tests / external usage
bool parseJson(const std::string &json, std::vector<ZoneDef> &zonesOut)
{
    zonesOut.clear();
    return parseZonesInternal(json, zonesOut);
}

struct ONOScheme
{
    ::OcaONo baseGain{static_cast<::OcaONo>(4096)};
    ::OcaONo baseMute{static_cast<::OcaONo>(4097)};
    ::OcaONo baseSwitch{static_cast<::OcaONo>(4098)};
    ::OcaONo strideGain{static_cast<::OcaONo>(100)};
    ::OcaONo strideMute{static_cast<::OcaONo>(100)};
    ::OcaONo strideSwitch{static_cast<::OcaONo>(100)};
};

// Helper to compute actuator ONOs for a zone index
static void computeONOs(size_t zoneIndex, const ONOScheme &scheme,
                        ::OcaONo &gainONo, ::OcaONo &muteONo, ::OcaONo &switchONo)
{
    if (zoneIndex == 0)
    {
        gainONo = scheme.baseGain;
        muteONo = scheme.baseMute;
        switchONo = scheme.baseSwitch;
    }
    else
    {
        gainONo = static_cast<::OcaONo>(scheme.baseGain + (zoneIndex * scheme.strideGain));
        muteONo = static_cast<::OcaONo>(scheme.baseMute + (zoneIndex * scheme.strideMute));
        switchONo = static_cast<::OcaONo>(scheme.baseSwitch + (zoneIndex * scheme.strideSwitch));
    }
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
                             ::OcaONo baseZoneGroupONo,
                             ::OcaONo firstZoneONo)
{
    BuiltZones model{};
    model.zonesContainer = new ZoneGroup(baseZoneGroupONo, static_cast<::OcaBoolean>(true), ::OcaLiteString("Zone"));
    if (!model.zonesContainer)
        return model;

    ONOScheme scheme; // could be parameterized later
    ::OcaONo zoneONo = firstZoneONo;
    model.zones.reserve(zoneDefs.size());
    for (size_t i = 0; i < zoneDefs.size(); ++i, ++zoneONo)
    {
        ZoneObjects zb;
        zb.group = new ZoneGroup(zoneONo, static_cast<::OcaBoolean>(true), ::OcaLiteString(zoneDefs[i].name.c_str()));
        if (!zb.group)
        {
            model.zones.push_back(zb);
            continue;
        }

        ::OcaONo gainONo, muteONo, switchONo;
        computeONOs(i, scheme, gainONo, muteONo, switchONo);

        // Gain
        ::OcaLiteList<::OcaLitePort> gainPorts;
        zb.gain = new ConcreteGainActuator(gainONo, static_cast<::OcaBoolean>(true), ::OcaLiteString((zoneDefs[i].name + " Gain").c_str()), gainPorts, -60.0, 20.0);
        if (!zb.gain)
        {
            model.zones.push_back(zb);
            continue;
        }

        // Mute
        ::OcaLiteList<::OcaLitePort> mutePorts;
        zb.mute = new ConcreteMuteActuator(muteONo, static_cast<::OcaBoolean>(true), ::OcaLiteString((zoneDefs[i].name + " Mute").c_str()), mutePorts);

        // Switch
        if (!zoneDefs[i].sources.empty())
        {
            unsigned minPos = 0, maxPos = 0;
            ::OcaLiteList<::OcaLiteString> names;
            ::OcaLiteList<::OcaBoolean> enables;
            buildSwitchLists(zoneDefs[i].sources, minPos, maxPos, names, enables);
            ::OcaLiteList<::OcaLitePort> switchPorts;
            zb.sw = new ConcreteSwitchActuator(
                switchONo,
                static_cast<::OcaBoolean>(true),
                ::OcaLiteString("Source Select"),
                switchPorts,
                static_cast<::OcaUint16>(minPos),
                static_cast<::OcaUint16>(maxPos),
                names,
                enables);
        }
        model.zones.push_back(zb);
    }
    return model;
}

void buildHierarchy(BuiltZones &zonesModel)
{
    if (!zonesModel.zonesContainer)
        return;
    for (auto &zb : zonesModel.zones)
    {
        if (zb.group)
        {
            if (!zonesModel.zonesContainer->AddObject(*zb.group))
            {
                delete zb.group;
                zb.group = nullptr;
                continue;
            }
            if (zb.gain)
            {
                if (!zb.group->AddObject(*zb.gain))
                {
                    delete zb.gain;
                    zb.gain = nullptr;
                }
            }
            if (zb.mute)
            {
                if (!zb.group->AddObject(*zb.mute))
                {
                    delete zb.mute;
                    zb.mute = nullptr;
                }
            }
            if (zb.sw)
            {
                if (!zb.group->AddObject(*zb.sw))
                {
                    delete zb.sw;
                    zb.sw = nullptr;
                }
            }
        }
    }
}

BuiltZones BuildZonesFromJson(const std::string &json, ::OcaONo baseZoneGroupONo, ::OcaONo firstZoneONo)
{
    BuiltZones empty{};
    std::vector<ZoneDef> zones;
    if (!parseJson(json, zones))
    {
        printf("[ZoneConfig] Failed to parse any zones from JSON\n");
        return empty;
    }
    BuiltZones model = createZoneObjects(zones, baseZoneGroupONo, firstZoneONo);
    buildHierarchy(model);
    return model;
}
