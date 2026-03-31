/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

#include <cstdio>
#include <algorithm>
#include <cmath>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <exception>
#include <map>
#include <mutex>
#include <memory>
#include <regex>
#include <string>
#include <thread>
#include <vector>

#include <json/json.h>
#include <spdlog/cfg/env.h>
#include <spdlog/spdlog.h>

#include "FusionTuiiBridge.h"
#include "SerialManager.h"
#include "TuiiConfigModels.h"
#include <observer/observer.h>

static bool g_bSuccess = false;
static std::unique_ptr<UDPValueMonitor> g_udpObserver;
static std::shared_ptr<std::map<std::string, int>> g_objectTracker =
    std::make_shared<std::map<std::string, int>>();

static const char *TUII_ZONE_CONFIG_JSON_STRING_FOR_DEV = R"({
    "touchui_zone_config": {
        "zones": [
            {
                "zoneId": "ZONE_1",
                "zoneName": "Living Room",
                "gain": {
                    "Id": "gain1",
                    "Min": 0,
                    "Max": 100,
                    "DefGain": 50,
                    "DefMute": false
                },
                "sources": [
                    {
                        "Index": 0,
                        "Name": "HDMI 1"
                    },
                    {
                        "Index": 1,
                        "Name": "HDMI 2"
                    },
                    {
                        "Index": 2,
                        "Name": "Bluetooth"
                    }
                ]
            },
            {
                "zoneId": "ZONE_2",
                "zoneName": "Kitchen",
                "gain": {
                    "Id": "gain2",
                    "Min": 0,
                    "Max": 100,
                    "DefGain": 50,
                    "DefMute": false
                },
                "sources": [
                    {
                        "Index": 0,
                        "Name": "Radio"
                    },
                    {
                        "Index": 1,
                        "Name": "Streaming"
                    }
                ]
            },
            {
                "zoneId": "ZONE_3",
                "zoneName": "Bedroom",
                "gain": {
                    "Id": "gain3",
                    "Min": 0,
                    "Max": 100,
                    "DefGain": 50,
                    "DefMute": false
                },
                "sources": [
                    {
                        "Index": 0,
                        "Name": "TV"
                    },
                    {
                        "Index": 1,
                        "Name": "AUX"
                    },
                    {
                        "Index": 2,
                        "Name": "AirPlay"
                    }
                ]
            }
        ]
    }
})";

static const char *TUII_DEVICE_CONFIG_JSON_STRING_FOR_DEV = R"({
    "touchui_device_config": {
        "Id": "DTU001",
        "Serial": "SN12345678",
        "Version": "Version String",
        "Mac": "AA:BB:CC:DD:EE:01",
        "Ip": "192.168.1.100",
        "IpMask": "255.255.255.0",
        "Gateway": "192.168.1.1",
        "Dhcp": false
    }
})";

bool InitializeFusionTUIIBridge(const std::string &serverIP,
                                unsigned int serverPort,
                                const std::vector<TuiiZoneConfig> &zoneConfigs,
                                const Json::Value &deviceConfig);
void HandleTUIIConfigurationUpdate(const Json::Value &newConfig);
void HandleTUIIDeviceConfigurationUpdate(const Json::Value &newConfig);
void HandleTUIIAudioSettingsUpdate(const Json::Value &newSettings);
void ShutdownSerial();
bool ParseZonesArray(const Json::Value &zonesSection,
                     std::map<std::string, int> &objectTracker,
                     std::vector<TuiiZoneConfig> &zoneConfigs);
bool BuildZoneConfigsFromConfig(const Json::Value &configJson,
                                std::map<std::string, int> &objectTracker,
                                std::vector<TuiiZoneConfig> &zoneConfigs);
bool ValidateDeviceConfig(const Json::Value &device, Json::Value &deviceConfigOut);
bool IsValidMacAddress(const std::string &macAddress);
bool IsValidIPv4Address(const std::string &ipAddress);
bool SendJsonPacket(const Json::Value &packet);

namespace {
constexpr int PROTOCOL_ACK_TIMEOUT_MS      = 100;
constexpr int SERIAL_RETRY_INTERVAL_MS     = 1000;
constexpr int NACK_MAX_RETRIES             = 3;
constexpr int NACK_RETRY_DELAY_MS          = 50;

std::mutex              g_protocolMutex;
std::condition_variable g_protocolCv;
std::thread             g_protocolThread;
bool                    g_protocolRunning = false;
bool                    g_protocolStop    = false;
bool                    g_initialSyncDone = false;
std::string             g_serialDevicePath;

bool                    g_readyAckReceived   = false;
enum class ZoneEndWaitResult { none, ack, nack };
ZoneEndWaitResult       g_zoneEndWaitResult  = ZoneEndWaitResult::none;
using NackEvent = std::pair<std::string, int>;
std::deque<NackEvent>    g_pendingNacks;
std::map<std::string, Json::Value> g_lastRealtimePacketByKey;

Json::Value             g_latestDeviceConfig(Json::objectValue);
bool                    g_hasLatestDeviceConfig = false;
bool                    g_pendingDeviceConfig   = false;

std::vector<TuiiZoneConfig> g_latestZoneConfigs;
bool                        g_hasLatestZoneConfigs = false;
bool                        g_pendingZoneConfig    = false;

Json::Value             g_latestAudioSettings(Json::objectValue);
bool                    g_pendingAudioSettings = false;

std::string MakeRealtimeCommandKey(const std::string &action, int zoneIndex);
bool SendRealtimeCommand(const std::string &action,
                         const Json::Value &payload,
                         int zoneIndex = -1);
void ProtocolWorkerLoop();
void StartProtocolWorker();
void StopProtocolWorker();
void QueueDeviceConfigForProtocol(const Json::Value &deviceConfig);
void QueueZoneConfigForProtocol(const std::vector<TuiiZoneConfig> &zoneConfigs);
void QueueAudioSettingsForProtocol(const Json::Value &newSettings);
void HandleSerialProtocolMessage(const char *buf, std::size_t len);
bool WaitForReadyAck();
ZoneEndWaitResult WaitForZoneEndResult();
bool PerformInitializationCycle(Json::Value &deviceSnapshot,
                                std::vector<TuiiZoneConfig> &zoneSnapshot);
bool ApplyQueuedAudioCommands();
bool ProcessPendingNacks();
bool SendNackWithRetry(const std::string &failedAction, int zoneIndex);
void HandleClientSetCommand(const std::string &action, const Json::Value &msg);
}

int main(int argc, const char *argv[])
{
    spdlog::set_level(spdlog::level::info);
    spdlog::cfg::load_env_levels();

    std::string serialDevice;
    if (argc > 1)
    {
        serialDevice = argv[1];
    }
    else
    {
        spdlog::info("Usage: {} <serialDevice> <port> <serverIP>", argv[0]);
        spdlog::warn("No serial device specified - serial I/O will be disabled");
        return -1;
    }

    unsigned int serverPort = 7947;
    if (argc > 2)
    {
        static_cast<void>(sscanf(argv[2], "%u", &serverPort));
    }

    std::string serverIP = "127.0.0.1";
    if (argc > 3)
    {
        serverIP = argv[3];
    }

    Json::Value deviceConfig(Json::objectValue);
    std::vector<TuiiZoneConfig> zoneConfigs;

    const bool hasZoneDevConfig =
        (TUII_ZONE_CONFIG_JSON_STRING_FOR_DEV != nullptr) && (TUII_ZONE_CONFIG_JSON_STRING_FOR_DEV[0] != '\0');
    const bool hasDeviceDevConfig =
        (TUII_DEVICE_CONFIG_JSON_STRING_FOR_DEV != nullptr) && (TUII_DEVICE_CONFIG_JSON_STRING_FOR_DEV[0] != '\0');

    if (hasZoneDevConfig)
    {
        Json::Value zoneConfigJson;
        Json::Reader reader;
        if (!reader.parse(TUII_ZONE_CONFIG_JSON_STRING_FOR_DEV, zoneConfigJson))
        {
            spdlog::error("Failed to parse hardcoded zone JSON: {}", reader.getFormattedErrorMessages());
            return -1;
        }

        if (!BuildZoneConfigsFromConfig(zoneConfigJson, *g_objectTracker, zoneConfigs))
        {
            spdlog::error("Failed to build zone configuration from hardcoded zone JSON");
            return -1;
        }
    }
    else
    {
        g_objectTracker->clear();
        spdlog::warn("TUII_ZONE_CONFIG_JSON_STRING_FOR_DEV is null/empty; skipping startup zone config parsing");
    }

    if (hasDeviceDevConfig)
    {
        Json::Value deviceConfigJson;
        Json::Reader reader;
        if (!reader.parse(TUII_DEVICE_CONFIG_JSON_STRING_FOR_DEV, deviceConfigJson))
        {
            spdlog::error("Failed to parse hardcoded device JSON: {}", reader.getFormattedErrorMessages());
            return -1;
        }

        if (deviceConfigJson.isMember("touchui_device_config") && deviceConfigJson["touchui_device_config"].isObject())
        {
            if (!ValidateDeviceConfig(deviceConfigJson["touchui_device_config"], deviceConfig))
            {
                spdlog::error("Invalid device configuration in startup device JSON; continuing with empty device object");
                deviceConfig = Json::Value(Json::objectValue);
            }
        }
        else
        {
            spdlog::error("Missing touchui_device_config in startup device JSON; continuing with empty device object");
        }
    }
    else
    {
        spdlog::warn("TUII_DEVICE_CONFIG_JSON_STRING_FOR_DEV is null/empty; skipping startup device config parsing");
    }

    g_bSuccess = InitializeFusionTUIIBridge(serverIP, serverPort, zoneConfigs, deviceConfig);
    if (!g_bSuccess)
    {
        spdlog::error("FusionTUIIBridge initialization failed");
        return -1;
    }

    // Initialize serial I/O if a device was provided
    if (!serialDevice.empty())
    {
        {
            std::lock_guard<std::mutex> lock(g_protocolMutex);
            g_serialDevicePath = serialDevice;
        }

        SerialManager &serial = SerialManager::getInstance();
        serial.setReceiveCallback(HandleSerialProtocolMessage);
        if (!serial.initialize(serialDevice))
        {
            spdlog::error("Serial device initialization failed for {}", serialDevice);
            // Non-fatal: protocol worker will retry every second.
        }

        StartProtocolWorker();
        if (deviceConfig.isObject() && !deviceConfig.empty())
        {
            QueueDeviceConfigForProtocol(deviceConfig);
        }
        if (!zoneConfigs.empty())
        {
            QueueZoneConfigForProtocol(zoneConfigs);
        }
    }

    spdlog::info("FusionTUIIManager started successfully");

    // Block until terminated (e.g. SIGINT)
    spdlog::info("Press Enter to exit...");
    std::getchar();

    ShutdownSerial();
    return 0;
}

void ShutdownSerial()
{
    StopProtocolWorker();
    SerialManager::getInstance().shutdown();
}

bool InitializeFusionTUIIBridge(const std::string &serverIP,
                                unsigned int serverPort,
                                const std::vector<TuiiZoneConfig> &zoneConfigs,
                                const Json::Value &deviceConfig)
{
    try
    {
        FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();

        bool success = bridge.initialize(serverIP, serverPort, g_objectTracker, zoneConfigs, deviceConfig);
        if (!success)
        {
            spdlog::error("Failed to initialize FusionTUIIBridge");
            return false;
        }

        if (!g_udpObserver)
        {
            g_udpObserver = std::unique_ptr<UDPValueMonitor>(new UDPValueMonitor(
                serverIP,
                static_cast<int>(serverPort)));

            spdlog::info("UDP Observer started - monitoring from {}:{}", serverIP, serverPort);

            g_udpObserver->watch("touchui_zone_config", [](const std::string &path,
                                                              const Json::Value &oldVal,
                                                              const Json::Value &newVal)
                                 {
                                     spdlog::info("Zone configuration update received at {}", path);
                                     spdlog::debug("Zone configuration update from {} to {}",
                                                   oldVal.toStyledString(),
                                                   newVal.toStyledString());

                                     HandleTUIIConfigurationUpdate(newVal);
                                 });

            g_udpObserver->watch("touchui_device_config", [](const std::string &path,
                                                               const Json::Value &oldVal,
                                                               const Json::Value &newVal)
                                 {
                                     spdlog::info("Device configuration update received at {}", path);
                                     spdlog::debug("Device configuration update from {} to {}",
                                                   oldVal.toStyledString(),
                                                   newVal.toStyledString());

                                     HandleTUIIDeviceConfigurationUpdate(newVal);
                                 });

            g_udpObserver->watch("settings.audio", [](const std::string &path,
                                                      const Json::Value &oldVal,
                                                      const Json::Value &newVal)
                                 {
                                     spdlog::debug("Audio settings update received at {} oldValue: {}, newValue: {}",
                                                   path,
                                                   oldVal.toStyledString(),
                                                   newVal.toStyledString());
                                     HandleTUIIAudioSettingsUpdate(newVal);
                                 });
        }
        else
        {
            spdlog::info("UDP Observer already running - preserved during configuration update");
        }

        spdlog::info("FusionTUIIBridge initialized successfully");
        return true;
    }
    catch (const std::exception &e)
    {
        spdlog::error("Failed to initialize FusionTUIIBridge: {}", e.what());
        return false;
    }
}

bool SendJsonPacket(const Json::Value &packet)
{
    Json::StreamWriterBuilder swb;
    swb["indentation"] = "";
    const std::string serialized = Json::writeString(swb, packet);
    if (serialized.empty())
    {
        spdlog::error("[Protocol] Failed to serialize packet");
        return false;
    }

    if (serialized.size() > 255)
    {
        spdlog::error("[Protocol] Packet too large ({} bytes, max 255): {}",
                      serialized.size(), packet.toStyledString());
        return false;
    }

    SerialManager &serial = SerialManager::getInstance();
    return serial.send(serialized.c_str(), serialized.size());
}

namespace {

bool SendNackWithRetry(const std::string &failedAction, int zoneIndex)
{
    Json::Value nack(Json::objectValue);
    nack["action"] = "nack";
    nack["payload"]["error"] = failedAction;
    nack["payload"]["value"] = zoneIndex;

    for (int attempt = 0; attempt < NACK_MAX_RETRIES; ++attempt)
    {
        if (attempt > 0)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(NACK_RETRY_DELAY_MS));
        }
        if (SendJsonPacket(nack))
        {
            return true;
        }
        spdlog::warn("[Protocol] Failed to send nack({}) zone {} (attempt {}/{})",
                     failedAction, zoneIndex, attempt + 1, NACK_MAX_RETRIES);
    }
    spdlog::error("[Protocol] Exhausted {} retries sending nack({}) zone {}",
                  NACK_MAX_RETRIES, failedAction, zoneIndex);
    return false;
}

void HandleClientSetCommand(const std::string &action, const Json::Value &msg)
{
    if (!msg.isMember("payload") || !msg["payload"].isObject())
    {
        spdlog::warn("[Protocol] {} missing payload object", action);
        SendNackWithRetry(action, -1);
        return;
    }

    const Json::Value &payload = msg["payload"];

    if (!payload.isMember("zone") || !payload["zone"].isInt())
    {
        spdlog::warn("[Protocol] {} missing integer payload.zone", action);
        SendNackWithRetry(action, -1);
        return;
    }
    const int zoneIndex = payload["zone"].asInt();

    // Take a snapshot of shared state under lock before calling bridge methods
    std::map<std::string, int> trackerSnapshot;
    std::vector<TuiiZoneConfig> zoneSnapshot;
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        if (g_objectTracker)
        {
            trackerSnapshot = *g_objectTracker;
        }
        zoneSnapshot = g_latestZoneConfigs;
    }

    if (zoneIndex < 0 || static_cast<std::size_t>(zoneIndex) >= zoneSnapshot.size())
    {
        spdlog::warn("[Protocol] {} zone {} out of range (size={})", action, zoneIndex, zoneSnapshot.size());
        SendNackWithRetry(action, zoneIndex);
        return;
    }

    const TuiiZoneConfig &zone = zoneSnapshot[static_cast<std::size_t>(zoneIndex)];

    FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();
    if (!bridge.isInitialized())
    {
        spdlog::warn("[Protocol] {} bridge not initialized", action);
        SendNackWithRetry(action, zoneIndex);
        return;
    }

    if (action == "setGain")
    {
        if (!payload.isMember("norm") || !payload["norm"].isNumeric())
        {
            spdlog::warn("[Protocol] setGain missing numeric payload.norm");
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        const double norm = payload["norm"].asDouble();
        if (norm < 0.0 || norm > 100.0)
        {
            spdlog::warn("[Protocol] setGain payload.norm {:.4f} out of range [0.0, 100.0]", norm);
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        if (trackerSnapshot.find(zone.gain.gainID) == trackerSnapshot.end())
        {
            spdlog::warn("[Protocol] setGain gainID '{}' not found in object tracker", zone.gain.gainID);
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        const double dBValue = static_cast<double>(zone.gain.minValue)
                               + (norm/100.0) * (static_cast<double>(zone.gain.maxValue)
                                         - static_cast<double>(zone.gain.minValue));
        bridge.sendGainToFusion(zone.gain.gainID, dBValue);
    }
    else if (action == "setMute")
    {
        if (!payload.isMember("state") || !payload["state"].isBool())
        {
            spdlog::warn("[Protocol] setMute missing bool payload.state");
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        if (trackerSnapshot.find(zone.gain.gainID) == trackerSnapshot.end())
        {
            spdlog::warn("[Protocol] setMute gainID '{}' not found in object tracker", zone.gain.gainID);
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        bridge.sendMuteToFusion(zone.gain.gainID, payload["state"].asBool());
    }
    else
    {
        // action == "setSource"
        if (!payload.isMember("index") || !payload["index"].isInt())
        {
            spdlog::warn("[Protocol] setSource missing int payload.index");
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        const int sourceIndex = payload["index"].asInt();
        if (sourceIndex < 0 || static_cast<std::size_t>(sourceIndex) >= zone.sources.size())
        {
            spdlog::warn("[Protocol] setSource index {} out of range (sources={})",
                         sourceIndex, zone.sources.size());
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        if (trackerSnapshot.find(zone.zoneId) == trackerSnapshot.end())
        {
            spdlog::warn("[Protocol] setSource zoneId '{}' not found in object tracker", zone.zoneId);
            SendNackWithRetry(action, zoneIndex);
            return;
        }
        bridge.sendSourceToFusion(zone.zoneId, static_cast<uint16_t>(sourceIndex));
    }
}

void HandleSerialProtocolMessage(const char *buf, std::size_t len)
{
    if (buf == nullptr || len == 0)
    {
        return;
    }

    Json::Value msg;
    Json::CharReaderBuilder rb;
    std::string errs;
    const char *start = buf;
    const char *end   = buf + len;
    std::unique_ptr<Json::CharReader> reader(rb.newCharReader());

    if (!reader->parse(start, end, &msg, &errs))
    {
        spdlog::warn("[Protocol] Failed to parse incoming serial JSON: {}", errs);
        return;
    }

    if (!msg.isObject() || !msg.isMember("action") || !msg["action"].isString())
    {
        spdlog::warn("[Protocol] Incoming serial message missing string action");
        return;
    }

    const std::string action = msg["action"].asString();

    // Route inbound set* commands from TUII Client to Fusion
    if (action == "setGain" || action == "setMute" || action == "setSource")
    {
        HandleClientSetCommand(action, msg);
        return;
    }

    bool sendUnknownNack = false;
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        if (action == "readyAck")
        {
            g_readyAckReceived = true;
        }
        else if (action == "zoneEndAck")
        {
            g_zoneEndWaitResult = ZoneEndWaitResult::ack;
        }
        else if (action == "zoneEndNack")
        {
            g_zoneEndWaitResult = ZoneEndWaitResult::nack;
        }
        else if (action == "nack" && msg.isMember("payload") && msg["payload"].isObject())
        {
            std::string failedAction;
            int failedZone = -1;

            if (msg["payload"].isMember("error") && msg["payload"]["error"].isString())
            {
                failedAction = msg["payload"]["error"].asString();
            }

            if (msg["payload"].isMember("value") && msg["payload"]["value"].isInt())
            {
                failedZone = msg["payload"]["value"].asInt();
            }

            if (!failedAction.empty())
            {
                g_pendingNacks.emplace_back(failedAction, failedZone);
            }
        }
        else
        {
            sendUnknownNack = true;
        }
    }

    if (sendUnknownNack)
    {
        spdlog::warn("[Protocol] Unknown serial action '{}'; sending nack", action);
        SendNackWithRetry(action, -1);
        return;
    }

    g_protocolCv.notify_all();
}

void StartProtocolWorker()
{
    std::lock_guard<std::mutex> lock(g_protocolMutex);
    if (g_protocolRunning)
    {
        return;
    }

    g_protocolStop = false;
    g_protocolRunning = true;
    g_protocolThread = std::thread(ProtocolWorkerLoop);
}

void StopProtocolWorker()
{
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        if (!g_protocolRunning)
        {
            return;
        }
        g_protocolStop = true;
    }

    g_protocolCv.notify_all();

    if (g_protocolThread.joinable())
    {
        g_protocolThread.join();
    }

    std::lock_guard<std::mutex> lock(g_protocolMutex);
    g_protocolRunning = false;
}

void QueueDeviceConfigForProtocol(const Json::Value &deviceConfig)
{
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        g_latestDeviceConfig   = deviceConfig;
        g_hasLatestDeviceConfig = true;
        g_pendingDeviceConfig   = true;
    }
    g_protocolCv.notify_all();
}

void QueueZoneConfigForProtocol(const std::vector<TuiiZoneConfig> &zoneConfigs)
{
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        g_latestZoneConfigs  = zoneConfigs;
        g_hasLatestZoneConfigs = true;
        g_pendingZoneConfig    = true;
    }
    g_protocolCv.notify_all();
}

void QueueAudioSettingsForProtocol(const Json::Value &newSettings)
{
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        g_latestAudioSettings = newSettings;
        g_pendingAudioSettings = true;
    }
    g_protocolCv.notify_all();
}

bool WaitForReadyAck()
{
    std::unique_lock<std::mutex> lock(g_protocolMutex);
    return g_protocolCv.wait_for(
        lock,
        std::chrono::milliseconds(PROTOCOL_ACK_TIMEOUT_MS),
        []() { return g_protocolStop || g_readyAckReceived; }) && g_readyAckReceived;
}

ZoneEndWaitResult WaitForZoneEndResult()
{
    std::unique_lock<std::mutex> lock(g_protocolMutex);
    const bool signaled = g_protocolCv.wait_for(
        lock,
        std::chrono::milliseconds(PROTOCOL_ACK_TIMEOUT_MS),
        []() { return g_protocolStop || g_zoneEndWaitResult != ZoneEndWaitResult::none; });

    if (!signaled)
    {
        return ZoneEndWaitResult::none;
    }

    return g_zoneEndWaitResult;
}

bool PerformInitializationCycle(Json::Value &deviceSnapshot,
                                std::vector<TuiiZoneConfig> &zoneSnapshot)
{
    if (deviceSnapshot.isObject())
    {
        Json::Value identityPacket(Json::objectValue);
        identityPacket["action"] = "identity";
        identityPacket["payload"] = deviceSnapshot;
        if (!SendJsonPacket(identityPacket))
        {
            spdlog::warn("[Protocol] Failed to send identity packet");
            return false;
        }
    }

    for (const auto &zoneConfig : zoneSnapshot)
    {
        Json::Value packet(Json::objectValue);
        Json::Value payload(Json::objectValue);
        Json::Value gain(Json::objectValue);
        Json::Value sources(Json::arrayValue);

        gain["DefGain"] = zoneConfig.gain.defaultGainValue;
        gain["DefMute"] = zoneConfig.gain.defaultMuteValue;

        for (const auto &source : zoneConfig.sources)
        {
            sources.append(source.sourceName);
        }

        payload["Name"]    = zoneConfig.zoneName;
        payload["gain"]    = gain;
        payload["sources"] = sources;
        packet["action"]   = "zone";
        packet["payload"]  = payload;

        if (!SendJsonPacket(packet))
        {
            spdlog::warn("[Protocol] Failed to send zone packet for '{}'", zoneConfig.zoneName);
            return false;
        }
    }

    Json::Value zoneEndPacket(Json::objectValue);
    zoneEndPacket["action"] = "zoneEnd";
    zoneEndPacket["payload"]["zones"] = static_cast<int>(zoneSnapshot.size());
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        g_zoneEndWaitResult = ZoneEndWaitResult::none;
    }
    if (!SendJsonPacket(zoneEndPacket))
    {
        spdlog::warn("[Protocol] Failed to send zoneEnd packet");
        return false;
    }

    const ZoneEndWaitResult zoneEndResult = WaitForZoneEndResult();
    if (zoneEndResult == ZoneEndWaitResult::ack)
    {
        spdlog::info("[Protocol] zoneEnd acknowledged");
        return true;
    }

    if (zoneEndResult == ZoneEndWaitResult::nack)
    {
        spdlog::warn("[Protocol] zoneEndNack received; restarting initialization");
    }
    else
    {
        spdlog::warn("[Protocol] zoneEnd timeout; restarting initialization");
    }
    return false;
}

std::string MakeRealtimeCommandKey(const std::string &action, int zoneIndex)
{
    return action + "|" + std::to_string(zoneIndex);
}

bool SendRealtimeCommand(const std::string &action,
                         const Json::Value &payload,
                         int zoneIndex)
{
    Json::Value packet(Json::objectValue);
    packet["action"] = action;
    packet["payload"] = payload;
    if (zoneIndex >= 0)
    {
        packet["payload"]["zone"] = zoneIndex;
    }

    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        g_lastRealtimePacketByKey[MakeRealtimeCommandKey(action, zoneIndex)] = packet;
    }

    if (!SendJsonPacket(packet))
    {
        spdlog::warn("[Protocol] Failed to send '{}' command", action);
        return false;
    }

    // Do not block waiting for NACK; NACK is handled asynchronously by the worker loop.
    return true;
}

bool ProcessPendingNacks()
{
    std::deque<NackEvent> nacks;
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        nacks.swap(g_pendingNacks);
    }

    for (const auto &nack : nacks)
    {
        const std::string key = MakeRealtimeCommandKey(nack.first, nack.second);
        Json::Value packet;
        {
            std::lock_guard<std::mutex> lock(g_protocolMutex);
            auto it = g_lastRealtimePacketByKey.find(key);
            if (it == g_lastRealtimePacketByKey.end())
            {
                spdlog::warn("[Protocol] Received nack for unknown command '{}' zone {}",
                             nack.first, nack.second);
                continue;
            }
            packet = it->second;
        }

        spdlog::warn("[Protocol] Async nack({}) for zone {} - resending once",
                     nack.first, nack.second);
        if (!SendJsonPacket(packet))
        {
            spdlog::warn("[Protocol] Failed to resend '{}' for zone {}",
                         nack.first, nack.second);
            return false;
        }
    }

    return true;
}

bool ApplyQueuedAudioCommands()
{
    Json::Value audioSnapshot(Json::objectValue);
    std::map<std::string, int> objectTrackerSnapshot;
    std::vector<TuiiZoneConfig> zoneSnapshot;

    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        if (!g_pendingAudioSettings || !g_latestAudioSettings.isObject())
        {
            return true;
        }
        audioSnapshot = g_latestAudioSettings;
        g_pendingAudioSettings = false;
        zoneSnapshot = g_latestZoneConfigs;
        if (g_objectTracker)
        {
            objectTrackerSnapshot = *g_objectTracker;
        }
    }

    for (const auto &settingID : audioSnapshot.getMemberNames())
    {
        const auto zoneIt = objectTrackerSnapshot.find(settingID);
        if (zoneIt == objectTrackerSnapshot.end())
        {
            continue;
        }

        const int zoneIndex = zoneIt->second;
        const Json::Value &settings = audioSnapshot[settingID];
        if (!settings.isObject())
        {
            continue;
        }

        if (settings.isMember("gain") && settings["gain"].isNumeric())
        {
            const double gainValue = settings["gain"].asDouble();

            float minValue = 0.0F;
            float maxValue = 1.0F;
            if (zoneIndex >= 0 && static_cast<std::size_t>(zoneIndex) < zoneSnapshot.size())
            {
                const auto &z = zoneSnapshot[static_cast<std::size_t>(zoneIndex)];
                minValue = z.gain.minValue;
                maxValue = z.gain.maxValue;
            }

            double norm = 0.0;
            const double denom = static_cast<double>(maxValue) - static_cast<double>(minValue);
            if (std::abs(denom) > 1e-9)
            {
                norm = (gainValue - static_cast<double>(minValue)) * 100.0 / denom;
            }

            Json::Value payload(Json::objectValue);
            payload["db"] = gainValue;
            payload["norm"] = norm;
            if (!SendRealtimeCommand("setGain", payload, zoneIndex))
            {
                return false;
            }
        }

        if (settings.isMember("mute") && settings["mute"].isBool())
        {
            Json::Value payload(Json::objectValue);
            payload["state"] = settings["mute"].asBool();
            if (!SendRealtimeCommand("setMute", payload, zoneIndex))
            {
                return false;
            }
        }

        if (settings.isMember("input") && settings["input"].isInt())
        {
            Json::Value payload(Json::objectValue);
            payload["index"] = settings["input"].asInt();
            if (!SendRealtimeCommand("setSource", payload, zoneIndex))
            {
                return false;
            }
        }
    }

    return true;
}

void ProtocolWorkerLoop()
{
    spdlog::info("[Protocol] Worker started");

    while (true)
    {
        {
            std::unique_lock<std::mutex> lock(g_protocolMutex);
            if (g_protocolStop)
            {
                break;
            }
        }

        SerialManager &serial = SerialManager::getInstance();
        if (!serial.isInitialized())
        {
            std::string serialPath;
            {
                std::lock_guard<std::mutex> lock(g_protocolMutex);
                serialPath = g_serialDevicePath;
            }

            if (!serialPath.empty())
            {
                if (serial.initialize(serialPath))
                {
                    serial.setReceiveCallback(HandleSerialProtocolMessage);
                    spdlog::info("[Protocol] Serial reinitialized on {}", serialPath);
                    continue;
                }
            }

            spdlog::warn("[Protocol] Serial unavailable; retrying in {} ms", SERIAL_RETRY_INTERVAL_MS);
            std::this_thread::sleep_for(std::chrono::milliseconds(SERIAL_RETRY_INTERVAL_MS));
            continue;
        }

        while (true)
        {
            Json::Value deviceSnapshot(Json::objectValue);
            std::vector<TuiiZoneConfig> zoneSnapshot;

            {
                std::lock_guard<std::mutex> lock(g_protocolMutex);
                if (g_protocolStop)
                {
                    break;
                }
                if (g_hasLatestDeviceConfig)
                {
                    deviceSnapshot = g_latestDeviceConfig;
                }
                if (g_hasLatestZoneConfigs)
                {
                    zoneSnapshot = g_latestZoneConfigs;
                }
            }

            Json::Value readyPacket(Json::objectValue);
            readyPacket["action"] = "ready";
            {
                std::lock_guard<std::mutex> lock(g_protocolMutex);
                g_readyAckReceived = false;
            }
            if (!SendJsonPacket(readyPacket))
            {
                spdlog::warn("[Protocol] Failed to send ready; retrying in {} ms", SERIAL_RETRY_INTERVAL_MS);
                std::this_thread::sleep_for(std::chrono::milliseconds(SERIAL_RETRY_INTERVAL_MS));
                continue;
            }

            if (!WaitForReadyAck())
            {
                spdlog::warn("[Protocol] readyAck timeout; retrying ready");
                continue;
            }

            if (!PerformInitializationCycle(deviceSnapshot, zoneSnapshot))
            {
                continue;
            }

            {
                std::lock_guard<std::mutex> lock(g_protocolMutex);
                g_initialSyncDone = true;
                g_pendingDeviceConfig = false;
                g_pendingZoneConfig = false;
            }

            while (true)
            {
                if (!ProcessPendingNacks())
                {
                    std::this_thread::sleep_for(std::chrono::milliseconds(SERIAL_RETRY_INTERVAL_MS));
                    break;
                }

                {
                    std::unique_lock<std::mutex> lock(g_protocolMutex);
                    if (g_protocolStop)
                    {
                        break;
                    }
                    if (g_pendingDeviceConfig || g_pendingZoneConfig || g_pendingAudioSettings)
                    {
                        if (g_pendingDeviceConfig || g_pendingZoneConfig)
                        {
                            break;
                        }
                    }
                    g_protocolCv.wait_for(lock, std::chrono::milliseconds(50));
                    if (g_pendingDeviceConfig || g_pendingZoneConfig)
                    {
                        break;
                    }
                }

                if (!ApplyQueuedAudioCommands())
                {
                    std::this_thread::sleep_for(std::chrono::milliseconds(SERIAL_RETRY_INTERVAL_MS));
                    break;
                }
            }

            {
                std::lock_guard<std::mutex> lock(g_protocolMutex);
                if (g_protocolStop)
                {
                    break;
                }
            }
        }

        {
            std::lock_guard<std::mutex> lock(g_protocolMutex);
            if (g_protocolStop)
            {
                break;
            }
        }
    }

    spdlog::info("[Protocol] Worker stopped");
}

} // namespace

bool IsValidMacAddress(const std::string &macAddress)
{
    static const std::regex macPattern("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$");
    return std::regex_match(macAddress, macPattern);
}

bool IsValidIPv4Address(const std::string &ipAddress)
{
    static const std::regex ipv4Pattern("^([0-9]{1,3}\\.){3}[0-9]{1,3}$");
    if (!std::regex_match(ipAddress, ipv4Pattern))
    {
        return false;
    }

    size_t start = 0;
    for (int octet = 0; octet < 4; ++octet)
    {
        size_t dotPos = ipAddress.find('.', start);
        const std::string token = (dotPos == std::string::npos) ? ipAddress.substr(start)
                                                                 : ipAddress.substr(start, dotPos - start);

        if (token.empty())
        {
            return false;
        }

        int value = -1;
        try
        {
            value = std::stoi(token);
        }
        catch (const std::exception &)
        {
            return false;
        }

        if (value < 0 || value > 255)
        {
            return false;
        }

        if (dotPos == std::string::npos)
        {
            start = ipAddress.size();
        }
        else
        {
            start = dotPos + 1;
        }
    }

    return true;
}

bool ValidateDeviceConfig(const Json::Value &device, Json::Value &deviceConfigOut)
{
    if (!device.isObject())
    {
        spdlog::error("Invalid device configuration: expected object");
        return false;
    }

    const char *requiredStringFields[] = {"Id", "Serial", "Version", "Mac", "Ip", "IpMask", "Gateway"};
    for (const char *field : requiredStringFields)
    {
        if (!device.isMember(field) || !device[field].isString() || device[field].asString().empty())
        {
            spdlog::error("Invalid device field '{}': expected non-empty string", field);
            return false;
        }
    }

    if (!device.isMember("Dhcp") || !device["Dhcp"].isBool())
    {
        spdlog::error("Invalid device field 'Dhcp': expected boolean");
        return false;
    }

    if (!IsValidMacAddress(device["Mac"].asString()))
    {
        spdlog::error("Invalid device field 'Mac': expected strict MAC address format XX:XX:XX:XX:XX:XX");
        return false;
    }

    if (!IsValidIPv4Address(device["Ip"].asString()) ||
        !IsValidIPv4Address(device["IpMask"].asString()) ||
        !IsValidIPv4Address(device["Gateway"].asString()))
    {
        spdlog::error("Invalid device IPv4 fields: Ip/IpMask/Gateway must be valid IPv4 addresses");
        return false;
    }

    deviceConfigOut = device;
    return true;
}

bool ParseZonesArray(const Json::Value &zonesSection,
                     std::map<std::string, int> &objectTracker,
                     std::vector<TuiiZoneConfig> &zoneConfigs)
{
    if (!zonesSection.isArray())
    {
        spdlog::error("Invalid zones section: expected array");
        return false;
    }

    objectTracker.clear();
    zoneConfigs.clear();
    zoneConfigs.reserve(zonesSection.size());

    for (Json::ArrayIndex i = 0; i < zonesSection.size(); ++i)
    {
        const Json::Value &zoneJson = zonesSection[i];
        if (!zoneJson.isObject())
        {
            spdlog::error("Invalid zone entry at index {}: expected object", i);
            objectTracker.clear();
            zoneConfigs.clear();
            return false;
        }

        if (!zoneJson.isMember("zoneId") || !zoneJson["zoneId"].isString() ||
            !zoneJson.isMember("zoneName") || !zoneJson["zoneName"].isString() ||
            !zoneJson.isMember("gain") || !zoneJson["gain"].isObject() ||
            !zoneJson.isMember("sources") || !zoneJson["sources"].isArray())
        {
            spdlog::error("Zone at index {} is missing required fields", i);
            objectTracker.clear();
            zoneConfigs.clear();
            return false;
        }

        const Json::Value &gainJson = zoneJson["gain"];
        if (!gainJson.isMember("Id") || !gainJson["Id"].isString() ||
            !gainJson.isMember("Min") || !gainJson["Min"].isNumeric() ||
            !gainJson.isMember("Max") || !gainJson["Max"].isNumeric() ||
            !gainJson.isMember("DefGain") || !gainJson["DefGain"].isNumeric() ||
            !gainJson.isMember("DefMute") || !gainJson["DefMute"].isBool())
        {
            spdlog::error("Zone gain block at index {} is missing required fields", i);
            objectTracker.clear();
            zoneConfigs.clear();
            return false;
        }

        TuiiZoneConfig zoneConfig;
        zoneConfig.zoneId = zoneJson["zoneId"].asString();
        zoneConfig.zoneName = zoneJson["zoneName"].asString();
        zoneConfig.gain.gainID = gainJson["Id"].asString();
        zoneConfig.gain.minValue = gainJson["Min"].asFloat();
        zoneConfig.gain.maxValue = gainJson["Max"].asFloat();
        zoneConfig.gain.defaultGainValue = gainJson["DefGain"].asFloat();
        zoneConfig.gain.gainValue = zoneConfig.gain.defaultGainValue;
        zoneConfig.gain.defaultMuteValue = gainJson["DefMute"].asBool();
        zoneConfig.gain.muteState = zoneConfig.gain.defaultMuteValue;
        zoneConfig.sourceIndex = 0;

        const Json::Value &sourcesJson = zoneJson["sources"];
        zoneConfig.sources.reserve(sourcesJson.size());
        for (Json::ArrayIndex sourceIdx = 0; sourceIdx < sourcesJson.size(); ++sourceIdx)
        {
            const Json::Value &sourceJson = sourcesJson[sourceIdx];
            if (!sourceJson.isObject() ||
                !sourceJson.isMember("Index") || !sourceJson["Index"].isInt() ||
                !sourceJson.isMember("Name") || !sourceJson["Name"].isString())
            {
                spdlog::error("Invalid source at zone index {} source index {}", i, sourceIdx);
                objectTracker.clear();
                zoneConfigs.clear();
                return false;
            }

            TuiiSourceConfig sourceConfig;
            sourceConfig.sourceName = sourceJson["Name"].asString();
            zoneConfig.sources.push_back(sourceConfig);
        }

        if (zoneConfig.sources.empty())
        {
            spdlog::error("Zone {} has no sources", zoneConfig.zoneId);
            objectTracker.clear();
            zoneConfigs.clear();
            return false;
        }

        const int zoneIndex = static_cast<int>(zoneConfigs.size());
        objectTracker[zoneConfig.gain.gainID] = zoneIndex;
        objectTracker[zoneConfig.zoneId] = zoneIndex;
        zoneConfigs.push_back(zoneConfig);
    }

    return true;
}

bool BuildZoneConfigsFromConfig(const Json::Value &configJson,
                                std::map<std::string, int> &objectTracker,
                                std::vector<TuiiZoneConfig> &zoneConfigs)
{
    if (!configJson.isObject() ||
        !configJson.isMember("touchui_zone_config") ||
        !configJson["touchui_zone_config"].isObject())
    {
        spdlog::error("Invalid config: missing touchui_zone_config object");
        objectTracker.clear();
        zoneConfigs.clear();
        return false;
    }

    const Json::Value &zoneConfig = configJson["touchui_zone_config"];
    if (!zoneConfig.isMember("zones"))
    {
        spdlog::error("Invalid config: missing zones section");
        objectTracker.clear();
        zoneConfigs.clear();
        return false;
    }

    return ParseZonesArray(zoneConfig["zones"], objectTracker, zoneConfigs);
}

void HandleTUIIConfigurationUpdate(const Json::Value &newConfig)
{
    if (!newConfig.isObject())
    {
        spdlog::warn("Invalid TUII configuration update - expected JSON object");
        return;
    }

    std::map<std::string, int> rebuiltTracker;
    std::vector<TuiiZoneConfig> rebuiltZoneConfigs;
    FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();

    Json::Value wrappedZoneConfig(Json::objectValue);
    wrappedZoneConfig["touchui_zone_config"] = newConfig;
    if (!BuildZoneConfigsFromConfig(wrappedZoneConfig, rebuiltTracker, rebuiltZoneConfigs))
    {
        spdlog::error("Rejected TUII zone configuration update due to parse/validation failure");
        return;
    }

    auto newTrackerPtr = std::make_shared<std::map<std::string, int>>(std::move(rebuiltTracker));

    if (!bridge.updateZoneConfiguration(newTrackerPtr, rebuiltZoneConfigs))
    {
        spdlog::error("Rejected TUII configuration update because zone update failed");
        return;
    }

    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        g_objectTracker = newTrackerPtr;
    }

    QueueZoneConfigForProtocol(rebuiltZoneConfigs);

    spdlog::info("TUII zone configuration update applied: {} zones, {} keys",
                 rebuiltZoneConfigs.size(), g_objectTracker->size());
    spdlog::info("TUII zone update queued for protocol sync");
}

void HandleTUIIDeviceConfigurationUpdate(const Json::Value &newConfig)
{
    if (!newConfig.isObject())
    {
        spdlog::warn("Invalid TUII device configuration update - expected JSON object");
        return;
    }

    Json::Value validatedDeviceConfig;
    if (!ValidateDeviceConfig(newConfig, validatedDeviceConfig))
    {
        spdlog::error("Rejected TUII device configuration update due to validation failure");
        return;
    }

    FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();
    if (!bridge.updateDeviceConfiguration(validatedDeviceConfig))
    {
        spdlog::error("Rejected TUII device configuration update because device update failed");
        return;
    }

    QueueDeviceConfigForProtocol(validatedDeviceConfig);

    spdlog::info("TUII device configuration update applied");
    spdlog::info("TUII device update queued for protocol sync");
}

void HandleTUIIAudioSettingsUpdate(const Json::Value &newSettings)
{
    spdlog::info("Processing audio settings update for TUII bridge...");

    if (!newSettings.isObject())
    {
        spdlog::warn("Audio settings must be a JSON object - discarding message");
        return;
    }

    FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();
    if (!bridge.isInitialized())
    {
        spdlog::warn("FusionTUIIBridge not initialized - discarding audio update");
        return;
    }

    for (const auto &settingID : newSettings.getMemberNames())
    {
        const Json::Value &settings = newSettings[settingID];
        if (!settings.isObject())
        {
            spdlog::warn("Audio setting for '{}' is not an object - skipping", settingID);
            continue;
        }

        if (settings.isMember("gain") && settings["gain"].isNumeric())
        {
            bridge.handleFusionGainUpdate(settingID, settings["gain"].asDouble());
        }

        if (settings.isMember("mute") && settings["mute"].isBool())
        {
            bridge.handleFusionMuteUpdate(settingID, settings["mute"].asBool());
        }

        if (settings.isMember("input") && settings["input"].isInt())
        {
            uint16_t sourceIndex = static_cast<uint16_t>(settings["input"].asInt());
            bridge.handleFusionSourceUpdate(settingID, sourceIndex);
        }
    }

    QueueAudioSettingsForProtocol(newSettings);

    spdlog::info("Audio settings update processing completed");
}
