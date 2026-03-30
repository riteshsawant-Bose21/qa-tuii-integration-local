/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : FusionTUIIBridge - Centralized Fusion audio communication
 *
 */
#ifndef FUSIONTUIIBRIDGE_H
#define FUSIONTUIIBRIDGE_H

// ---- Include system wide include files ----
#include <string>
#include <mutex>
#include <memory>
#include <map>
#include <vector>
#include <atomic>
#include <json/json.h>

// ---- Include local include files ----
#include <OCC/ControlDataTypes/OcaLiteWorkerDataTypes.h>
#include <OCC/ControlDataTypes/OcaLiteFrameworkDataTypes.h>
#include "TuiiConfigModels.h"

// ---- Forward declarations ----
class UDPSender;

// ---- Class Definition ----
class FusionTUIIBridge
{
public:
    static FusionTUIIBridge &getInstance();

    bool initialize(const std::string &serverIP,
                    unsigned int serverPort,
                    std::shared_ptr<std::map<std::string, int>> objectTracker,
                    const std::vector<TuiiZoneConfig> &zoneConfigs,
                    const Json::Value &deviceConfig);
    bool updateZoneConfiguration(std::shared_ptr<std::map<std::string, int>> objectTracker,
                                 const std::vector<TuiiZoneConfig> &zoneConfigs);
    bool updateDeviceConfiguration(const Json::Value &deviceConfig);
    Json::Value getDeviceConfig() const;

    void sendGainToFusion(const std::string &gainID, double value);
    void handleFusionGainUpdate(const std::string &gainID, double value);

    void sendMuteToFusion(const std::string &gainID, bool muteState);
    void handleFusionMuteUpdate(const std::string &gainID, bool muteState);

    void sendSourceToFusion(const std::string &zoneID, ::OcaUint16 sourceIndex);
    void handleFusionSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex);

    void shutdown();
    bool isInitialized() const noexcept;

private:
    FusionTUIIBridge();
    ~FusionTUIIBridge() noexcept;

    bool processGainUpdate(const std::string &gainID, double value);
    bool processMuteUpdate(const std::string &gainID, bool muteState);
    bool processSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex);

    std::shared_ptr<const std::map<std::string, int>> getObjectTrackerSnapshot() const;
    bool checkInitialized() const;
    bool sendMessageToFusion(const std::string &jsonMessage);

    static std::string createGainMessage(const std::string &gainID, double value);
    static std::string createMuteMessage(const std::string &gainID, bool muteState);
    static std::string createSourceMessage(const std::string &zoneID, ::OcaUint16 sourceIndex);

    const std::string &findGainZoneConfig(const std::string &gainID) const;
    const std::string &findMuteZoneConfig(const std::string &gainID) const;
    const std::string &findSwitchZoneConfig(const std::string &zoneID) const;
    const TuiiZoneConfig *getZoneConfigFromTracker(const std::string &id) const;

    static constexpr const char *JSON_FIELD_GAIN  = "gain";
    static constexpr const char *JSON_FIELD_MUTE  = "mute";
    static constexpr const char *JSON_FIELD_INPUT = "input";

    std::shared_ptr<const std::map<std::string, int>> m_objectTrackerPtr;
    std::vector<TuiiZoneConfig> m_zoneConfigs;
    Json::Value m_deviceConfig;
    std::atomic<bool> m_initialized;
    mutable std::mutex m_initMutex;

    FusionTUIIBridge(const FusionTUIIBridge &) = delete;
    FusionTUIIBridge &operator=(const FusionTUIIBridge &) = delete;
};

#endif // FUSIONTUIIBRIDGE_H