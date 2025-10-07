// Model.hpp
#pragma once
#include <memory>
#include <string>
#include <vector>
#include "../workers/ConcreteGainActuator.h"
#include "../workers/ConcreteMuteActuator.h"
#include "../workers/ConcreteSwitchActuator.h"
#include "../workers/FusionBlock.h"
#include "../workers/ZoneGroup.h"

struct Source
{
    int index{};
    std::string label;
};

struct FusionZoneOno
{
    int zone{};
    int gain{};
    int mute{};
    int sourceSelector{};
};

struct GainConfig
{
    std::string gainID;
    std::string min_value;
    std::string max_value;
    std::string default_gain_value;
    std::string default_mute_value;
};

struct Zone
{
    std::string id;
    std::string name;
    FusionZoneOno ono;
    GainConfig gain;
    std::vector<Source> sources;
};

struct Controller
{
    std::string id;
    std::string name;
    std::vector<std::string> zoneIds;
    std::vector<std::shared_ptr<Zone>> zones;
};

class ControlSystemConfig
{
public:
    std::vector<std::shared_ptr<Controller>> controllers;
    std::vector<std::shared_ptr<Zone>> zones;

    // // Convenience lookups (linear for simplicity)
    // Controller *findControllerById(const std::string &cid) const
    // {
    //     for (const auto &c : controllers)
    //         if (c->id == cid)
    //             return c.get();
    //     return nullptr;
    // }
    // Zone *findZoneById(const std::string &zid) const
    // {
    //     for (const auto &z : zones)
    //         if (z->id == zid)
    //             return z.get();
    //     return nullptr;
    // }

    // Disallow copy; allow move
    ControlSystemConfig() = default;
    ControlSystemConfig(const ControlSystemConfig &) = delete;
    ControlSystemConfig &operator=(const ControlSystemConfig &) = delete;
    ControlSystemConfig(ControlSystemConfig &&) noexcept = default;
    ControlSystemConfig &operator=(ControlSystemConfig &&) noexcept = default;
};

struct ZoneOCAObjects
{
    std::unique_ptr<FusionBlock> group;         // may be null if creation failed
    std::unique_ptr<ConcreteGainActuator> gain; // optional
    std::unique_ptr<ConcreteMuteActuator> mute; // optional
    std::unique_ptr<ConcreteSwitchActuator> sw; // optional
};

struct BuiltZones
{
    std::unique_ptr<ZoneGroup> zonesContainer; // Top level container
    std::vector<ZoneOCAObjects> zones;         // One entry per parsed zone
};