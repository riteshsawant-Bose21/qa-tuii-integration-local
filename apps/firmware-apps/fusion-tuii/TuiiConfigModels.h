/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */
#ifndef TUIICONFIGMODELS_H
#define TUIICONFIGMODELS_H

#include <string>
#include <vector>

struct TuiiGainConfig
{
    std::string gainID;
    float minValue;
    float maxValue;
    float defaultGainValue;
    float gainValue;
    bool defaultMuteValue;
    bool muteState;
};

struct TuiiSourceConfig
{
    std::string sourceName;
};

struct TuiiZoneConfig
{
    std::string zoneId;
    std::string zoneName;
    TuiiGainConfig gain;
    int sourceIndex;
    std::vector<TuiiSourceConfig> sources;
};

#endif // TUIICONFIGMODELS_H
