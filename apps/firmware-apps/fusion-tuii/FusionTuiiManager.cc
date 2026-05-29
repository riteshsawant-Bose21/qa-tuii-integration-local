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
#include <atomic>
#include <csignal>

#include <json/json.h>
#include <spdlog/cfg/env.h>
#include <spdlog/spdlog.h>

#include "FusionTuiiBridge.h"
#include "SerialManager.h"
#include "TuiiConfigModels.h"
#include "LocalConfig.h"

#include <observer/observer.h>


#include <future>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/write.hpp>

#ifndef ENABLE_QA_PROXY
#define ENABLE_QA_PROXY 1
#endif

static bool g_bSuccess = false;
static std::unique_ptr<UDPValueMonitor> g_udpObserver;

static const char *TUII_ZONE_CONFIG_JSON_STRING_FOR_DEV = NULL;
#if 0
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
#endif

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
                                const std::map<std::string, int> &objectTracker,
                                const std::vector<TuiiZoneConfig> &zoneConfigs,
                                const Json::Value &deviceConfig);
#if ENABLE_QA_PROXY
enum class QaTxPriority
{
    UiHigh,
    QaLow
};

struct QaTxCommand
{
    std::string serialized;
    QaTxPriority priority = QaTxPriority::UiHigh;
    bool holdUntilRuntime = false;
    std::shared_ptr<std::promise<bool>> completion;
};
#endif




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

#if ENABLE_QA_PROXY
// ========================= QA_PROXY_BEGIN =========================
// Isolated QA integration layer.

std::mutex              g_qaTxMutex;
std::condition_variable g_qaTxCv;
std::thread             g_qaTxThread;
bool                    g_qaTxRunning = false;
bool                    g_qaTxStop = false;
std::deque<QaTxCommand> g_qaUiQueue;
std::deque<QaTxCommand> g_qaLowQueue;

std::thread             g_qaTcpThread;
bool                    g_qaTcpRunning = false;
bool                    g_qaTcpStop = false;
constexpr uint16_t      QA_PROXY_TCP_PORT = 9000;

using QaSocketPtr = std::shared_ptr<boost::asio::ip::tcp::socket>;
std::mutex g_qaPendingMutex;
std::map<std::string, QaSocketPtr> g_qaPendingById;
std::deque<std::string> g_qaPendingOrder;

bool SerializeJsonCompact(const Json::Value &msg, std::string &out);
bool SerializeJsonForUart(const Json::Value &msg, std::string &out);
bool SendSerializedToSerial(const std::string &serialized);
bool EnqueueQaTx(const Json::Value &packet, QaTxPriority priority, bool holdUntilRuntime, bool waitForCompletion);
bool SendJsonPacketSync(const Json::Value &packet);
bool SendJsonPacketAsyncQa(const Json::Value &packet);

void QaArbitratorLoop();
void StartQaArbitrator();
void StopQaArbitrator();

void QaTcpListenerLoop();
void StartQaTcpListener();
void StopQaTcpListener();
void HandleQaClient(const QaSocketPtr &socket);

bool QaWriteJsonLine(const QaSocketPtr &socket, const Json::Value &msg);
void QaDropPendingForSocket(const QaSocketPtr &socket);
void QaRouteResponseToClient(const Json::Value &msg);

// ========================== QA_PROXY_END ==========================
#endif

namespace {
constexpr int PROTOCOL_ACK_TIMEOUT_MS      = 1000;
constexpr int SERIAL_RETRY_INTERVAL_MS     = 10000;
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
void QueueZoneConfigForProtocol();
void QueueAudioSettingsForProtocol(const Json::Value &newSettings);
void HandleSerialProtocolMessage(const char *buf, std::size_t len);
bool WaitForReadyAck();
ZoneEndWaitResult WaitForZoneEndResult();
bool SetInitialBrightness();
bool PerformInitializationCycle(Json::Value &deviceSnapshot,
                                std::vector<TuiiZoneConfig> &zoneSnapshot);
bool ApplyQueuedAudioCommands();
bool ProcessPendingNacks();
bool SendNackWithRetry(const std::string &failedAction, int zoneIndex);
void HandleClientSetCommand(const std::string &action, const Json::Value &msg);
}

namespace {

static std::atomic<bool> g_shutdownRequested{false};

extern "C" void OnSignal(int signo)
{
    (void)signo;
    g_shutdownRequested.store(true, std::memory_order_relaxed);
}

static void InstallSignalHandlers()
{
    std::signal(SIGINT,  OnSignal);
    std::signal(SIGTERM, OnSignal);
}

} // namespace

int main(int argc, const char *argv[])
{
    InstallSignalHandlers();

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
    std::map<std::string, int> objectTracker;

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

        if (!BuildZoneConfigsFromConfig(zoneConfigJson, objectTracker, zoneConfigs))
        {
            spdlog::error("Failed to build zone configuration from hardcoded zone JSON");
            return -1;
        }
    }
    else
    {
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

    g_bSuccess = InitializeFusionTUIIBridge(serverIP, serverPort, objectTracker, zoneConfigs, deviceConfig);
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
#if ENABLE_QA_PROXY
    StartQaArbitrator();
    StartQaTcpListener();
#endif

        StartProtocolWorker();
        if (deviceConfig.isObject() && !deviceConfig.empty())
        {
            QueueDeviceConfigForProtocol(deviceConfig);
        }
        if (!zoneConfigs.empty())
        {
            QueueZoneConfigForProtocol();
        }
    }

    spdlog::info("FusionTUIIManager started successfully");

    spdlog::info("Running. Send SIGINT (Ctrl+C) or SIGTERM to exit.");

    while (!g_shutdownRequested.load(std::memory_order_relaxed))
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    ShutdownSerial();
    return 0;
}

void ShutdownSerial()
{
    StopProtocolWorker();
#if ENABLE_QA_PROXY
    StopQaTcpListener();
    StopQaArbitrator();
#endif
    SerialManager::getInstance().shutdown();
}

#if ENABLE_QA_PROXY
bool QaWriteJsonLine(const QaSocketPtr &socket, const Json::Value &msg)
{
    if (!socket) return false;
    std::string s;
    if (!SerializeJsonCompact(msg, s)) return false;
    s.push_back('\n');
    boost::system::error_code ec;
    boost::asio::write(*socket, boost::asio::buffer(s), ec);
    return !ec;
}

void QaDropPendingForSocket(const QaSocketPtr &socket)
{
    std::lock_guard<std::mutex> lock(g_qaPendingMutex);

    for (auto it = g_qaPendingById.begin(); it != g_qaPendingById.end(); )
    {
        if (it->second == socket)
        {
            const std::string id = it->first;
            it = g_qaPendingById.erase(it);

            g_qaPendingOrder.erase(
                std::remove(g_qaPendingOrder.begin(), g_qaPendingOrder.end(), id),
                g_qaPendingOrder.end());
        }
        else
        {
            ++it;
        }
    }
}

void QaRouteResponseToClient(const Json::Value &msg)
{
    QaSocketPtr sock;

    {
        std::lock_guard<std::mutex> lock(g_qaPendingMutex);

        // Preferred path: explicit id correlation.
        if (msg.isMember("id") && msg["id"].isString())
        {
            const std::string id = msg["id"].asString();
            auto it = g_qaPendingById.find(id);
            if (it == g_qaPendingById.end()) return;

            sock = it->second;
            g_qaPendingById.erase(it);

            g_qaPendingOrder.erase(
                std::remove(g_qaPendingOrder.begin(), g_qaPendingOrder.end(), id),
                g_qaPendingOrder.end());
        }
        else
        {
            // Fallback path: no id from STM32, use oldest pending request.
            while (!g_qaPendingOrder.empty())
            {
                const std::string oldestId = g_qaPendingOrder.front();
                g_qaPendingOrder.pop_front();

                auto it = g_qaPendingById.find(oldestId);
                if (it == g_qaPendingById.end())
                {
                    continue; // stale queue entry
                }

                sock = it->second;
                g_qaPendingById.erase(it);
                break;
            }

            if (!sock) return;
        }
    }

    QaWriteJsonLine(sock, msg);
}


void HandleQaClient(const QaSocketPtr &socket)
{
    if (!socket) return;

    boost::system::error_code ec;
    socket->non_blocking(true, ec);
    if (ec) return;

    std::string pending;
    char buf[1024];

    while (true)
    {
        {
            std::lock_guard<std::mutex> lock(g_qaPendingMutex);
            if (g_qaTcpStop) break;
        }

        std::size_t n = socket->read_some(boost::asio::buffer(buf, sizeof(buf)), ec);
        if (ec == boost::asio::error::would_block || ec == boost::asio::error::try_again)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
            continue;
        }
        if (ec) break;

        pending.append(buf, n);

        while (true)
        {
            const std::size_t pos = pending.find('\n');
            if (pos == std::string::npos) break;

            std::string line = pending.substr(0, pos);
            pending.erase(0, pos + 1);

            while (!line.empty() && (line.back() == '\r' || line.back() == '\n')) line.pop_back();
            if (line.empty()) continue;

            Json::Value req;
            Json::CharReaderBuilder rb;
            std::string errs;
            std::unique_ptr<Json::CharReader> reader(rb.newCharReader());
            if (!reader->parse(line.data(), line.data() + line.size(), &req, &errs)) continue;
            if (!req.isObject() || !req.isMember("action") || !req["action"].isString()) continue;

const std::string actionIn = req["action"].asString();

Json::Value toSerial(Json::objectValue);

if (actionIn == "qa_invoke")
{
    if (!req.isMember("api") || !req["api"].isString()) continue;

    toSerial["action"] = req["api"].asString();

    if (req.isMember("params") && req["params"].isObject())
    {
        toSerial["payload"] = req["params"];
    }
    else
    {
        toSerial["payload"] = Json::Value(Json::objectValue);
    }
}
else
{
    // Raw passthrough mode: python sends direct serial-style JSON.
    toSerial = req;
}

if (!toSerial.isObject() || !toSerial.isMember("action") || !toSerial["action"].isString()) continue;

spdlog::info(
    "[QA_GATE_B_TX_PREP] toSerial_action={} has_payload={}",
    toSerial["action"].asString(),
    toSerial.isMember("payload")
);


std::string id;
if (req.isMember("id") && req["id"].isString() && !req["id"].asString().empty())
{
    id = req["id"].asString();
}
else
{
    id = "qa-auto-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count());
}

spdlog::info(
    "[QA_GATE_B_RX] actionIn={} has_id={} id={}",
    actionIn,
    (req.isMember("id") && req["id"].isString()),
    id
);

{
    std::lock_guard<std::mutex> lock(g_qaPendingMutex);

    g_qaPendingOrder.erase(
        std::remove(g_qaPendingOrder.begin(), g_qaPendingOrder.end(), id),
        g_qaPendingOrder.end());

    g_qaPendingById[id] = socket;
    g_qaPendingOrder.push_back(id);
}

const bool qaSendOk = SendJsonPacketAsyncQa(toSerial);
spdlog::info("[QA_GATE_B_TX_ENQUEUE] ok={}", qaSendOk);

if (!qaSendOk)
{
    std::lock_guard<std::mutex> lock(g_qaPendingMutex);
    g_qaPendingById.erase(id);
    g_qaPendingOrder.erase(
        std::remove(g_qaPendingOrder.begin(), g_qaPendingOrder.end(), id),
        g_qaPendingOrder.end());
}
        }
    }

    QaDropPendingForSocket(socket);
    socket->shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);
    socket->close(ec);
}

void QaTcpListenerLoop()
{
    using boost::asio::ip::tcp;

    boost::asio::io_context io;
    tcp::acceptor acceptor(io);
    boost::system::error_code ec;
    tcp::endpoint ep(tcp::v4(), QA_PROXY_TCP_PORT);

    acceptor.open(ep.protocol(), ec);
    if (ec) return;
    acceptor.set_option(tcp::acceptor::reuse_address(true), ec);
    acceptor.bind(ep, ec);
    if (ec) return;
    acceptor.listen(boost::asio::socket_base::max_listen_connections, ec);
    if (ec) return;
    acceptor.non_blocking(true, ec);

    while (true)
    {
        {
            std::lock_guard<std::mutex> lock(g_qaPendingMutex);
            if (g_qaTcpStop) break;
        }

        QaSocketPtr socket = std::make_shared<tcp::socket>(io);
        acceptor.accept(*socket, ec);

        if (ec == boost::asio::error::would_block || ec == boost::asio::error::try_again)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
            continue;
        }
        if (ec)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            continue;
        }

        HandleQaClient(socket);
    }
}

void StartQaTcpListener()
{
    std::lock_guard<std::mutex> lock(g_qaPendingMutex);
    if (g_qaTcpRunning) return;
    g_qaTcpStop = false;
    g_qaTcpRunning = true;
    g_qaTcpThread = std::thread(QaTcpListenerLoop);
}

void StopQaTcpListener()
{
    {
        std::lock_guard<std::mutex> lock(g_qaPendingMutex);
        if (!g_qaTcpRunning) return;
        g_qaTcpStop = true;
    }
    if (g_qaTcpThread.joinable()) g_qaTcpThread.join();
    std::lock_guard<std::mutex> lock(g_qaPendingMutex);
    g_qaTcpRunning = false;
}
#endif



bool InitializeFusionTUIIBridge(const std::string &serverIP,
                                unsigned int serverPort,
                                const std::map<std::string, int> &objectTracker,
                                const std::vector<TuiiZoneConfig> &zoneConfigs,
                                const Json::Value &deviceConfig)
{
    try
    {
        FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();

        bool success = bridge.initialize(serverIP, serverPort, objectTracker, zoneConfigs, deviceConfig);
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

#if ENABLE_QA_PROXY
bool SerializeJsonCompact(const Json::Value &msg, std::string &out)
{
    Json::StreamWriterBuilder swb;
    swb["indentation"] = "";
    out = Json::writeString(swb, msg);
    if (out.empty())
    {
        spdlog::error("[QA_PROXY] JSON serialize failed");
        return false;
    }
    return true;
}

bool SerializeJsonForUart(const Json::Value &msg, std::string &out)
{
    if (!SerializeJsonCompact(msg, out))
    {
        return false;
    }
    if (out.size() > 255)
    {
        spdlog::error("[QA_PROXY] UART payload too large ({} > 255)", out.size());
        return false;
    }
    return true;
}

bool SendSerializedToSerial(const std::string &serialized)
{
    SerialManager &serial = SerialManager::getInstance();
    if (!serial.isInitialized())
    {
        spdlog::warn("[QA_PROXY] Serial not initialized");
        return false;
    }
    return serial.send(serialized.c_str(), serialized.size());
}

bool EnqueueQaTx(const Json::Value &packet, QaTxPriority priority, bool holdUntilRuntime, bool waitForCompletion)
{
    std::string serialized;
    if (!SerializeJsonForUart(packet, serialized))
    {
        return false;
    }

    QaTxCommand cmd;
    cmd.serialized = std::move(serialized);
    cmd.priority = priority;
    cmd.holdUntilRuntime = holdUntilRuntime;

    std::future<bool> f;
    if (waitForCompletion)
    {
        cmd.completion = std::make_shared<std::promise<bool>>();
        f = cmd.completion->get_future();
    }

    {
        std::lock_guard<std::mutex> lock(g_qaTxMutex);
        if (priority == QaTxPriority::UiHigh)
        {
            g_qaUiQueue.push_back(std::move(cmd));
        }
        else
        {
            g_qaLowQueue.push_back(std::move(cmd));
        }
    }
    g_qaTxCv.notify_all();

    if (waitForCompletion)
    {
        return f.get();
    }
    return true;
}

bool SendJsonPacketSync(const Json::Value &packet)
{
    return EnqueueQaTx(packet, QaTxPriority::UiHigh, false, true);
}

bool SendJsonPacketAsyncQa(const Json::Value &packet)
{
    return EnqueueQaTx(packet, QaTxPriority::UiHigh, false, false);}

bool SendJsonPacket(const Json::Value &packet)
{
    return SendJsonPacketSync(packet);
}
#else
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
#endif

#if ENABLE_QA_PROXY
void QaArbitratorLoop()
{
    spdlog::info("[QA_PROXY] Arbitrator started");

    while (true)
    {
        QaTxCommand cmd;
        bool hasCmd = false;

        {
            std::unique_lock<std::mutex> lock(g_qaTxMutex);
            g_qaTxCv.wait_for(lock, std::chrono::milliseconds(50), []() {
                return g_qaTxStop || !g_qaUiQueue.empty() || !g_qaLowQueue.empty();
            });

            if (g_qaTxStop)
            {
                break;
            }

            if (!g_qaUiQueue.empty())
            {
                cmd = std::move(g_qaUiQueue.front());
                g_qaUiQueue.pop_front();
                hasCmd = true;
            }
            else if (!g_qaLowQueue.empty())
            {
                bool runtimeReady = false;
                {
                    std::lock_guard<std::mutex> pLock(g_protocolMutex);
                    runtimeReady = g_initialSyncDone;
                }

                if (runtimeReady)
                {
                    cmd = std::move(g_qaLowQueue.front());
                    g_qaLowQueue.pop_front();
                    hasCmd = true;
                }
            }
        }

        if (!hasCmd)
        {
            continue;
        }

        const bool ok = SendSerializedToSerial(cmd.serialized);
        if (cmd.completion)
        {
            cmd.completion->set_value(ok);
        }
    }

    spdlog::info("[QA_PROXY] Arbitrator stopped");
}

void StartQaArbitrator()
{
    std::lock_guard<std::mutex> lock(g_qaTxMutex);
    if (g_qaTxRunning) return;
    g_qaTxStop = false;
    g_qaTxRunning = true;
    g_qaTxThread = std::thread(QaArbitratorLoop);
}

void StopQaArbitrator()
{
    {
        std::lock_guard<std::mutex> lock(g_qaTxMutex);
        if (!g_qaTxRunning) return;
        g_qaTxStop = true;
    }
    g_qaTxCv.notify_all();
    if (g_qaTxThread.joinable()) g_qaTxThread.join();
    std::lock_guard<std::mutex> lock(g_qaTxMutex);
    g_qaTxRunning = false;
}
#endif

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

    FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();
    if (!bridge.isInitialized())
    {
        spdlog::warn("[Protocol] {} bridge not initialized", action);
        SendNackWithRetry(action, -1);
        return;
    }

    if (action == "setBrightness")
    {
        if (!payload.isMember("value") || !payload["value"].isInt())
        {
            spdlog::warn("[Protocol] setBrightness missing int payload.value");
            return;
        }

        const int brightness = payload["value"].asInt();
        auto localConfig = LocalConfig::getInstance();
        localConfig->setBrightness(brightness);

        return;
    }

    if (!payload.isMember("zone") || !payload["zone"].isInt())
    {
        spdlog::warn("[Protocol] {} missing integer payload.zone", action);
        SendNackWithRetry(action, -1);
        return;
    }
    const int zoneIndex = payload["zone"].asInt();

    // Take a snapshot from the central store in the bridge
    std::map<std::string, int> trackerSnapshot = bridge.getObjectTrackerSnapshot();
    std::vector<TuiiZoneConfig> zoneSnapshot = bridge.getZoneConfigsSnapshot();

    if (zoneIndex < 0 || static_cast<std::size_t>(zoneIndex) >= zoneSnapshot.size())
    {
        spdlog::warn("[Protocol] {} zone {} out of range (size={})", action, zoneIndex, zoneSnapshot.size());
        SendNackWithRetry(action, zoneIndex);
        return;
    }

    const TuiiZoneConfig &zone = zoneSnapshot[static_cast<std::size_t>(zoneIndex)];

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
        bridge.handleFusionGainUpdate(zone.gain.gainID, dBValue);
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

        const bool muteState = payload["state"].asBool();
        bridge.sendMuteToFusion(zone.gain.gainID, muteState);
        bridge.handleFusionMuteUpdate(zone.gain.gainID, muteState);
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

        bridge.sendSourceToFusion(zone.zoneId, static_cast<uint16_t>(sourceIndex+1));
        bridge.handleFusionSourceUpdate(zone.zoneId, static_cast<uint16_t>(sourceIndex+1));
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
    #if ENABLE_QA_PROXY
// Mirror serial response to pending QA TCP request as well.
QaRouteResponseToClient(msg);
#endif
    

    // Route inbound set* commands from TUII Client to Fusion
    if (action == "setGain" || action == "setMute" || action == "setSource" || action == "setBrightness")
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
        spdlog::warn("[Protocol] Unknown serial action '{}';", action);
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

void QueueZoneConfigForProtocol()
{
    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        g_pendingZoneConfig    = true;
    }
    g_protocolCv.notify_all();
    spdlog::info("[QueueZoneConfigForProtocol] Queued");
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

bool checkForZoneEndNack()
{
    std::unique_lock<std::mutex> lock(g_protocolMutex);
    bool nackStatus = false;

    if (g_zoneEndWaitResult == ZoneEndWaitResult::nack)
    {
        g_zoneEndWaitResult = ZoneEndWaitResult::none;
        nackStatus = true;
    }

    return nackStatus;
}

ZoneEndWaitResult WaitForZoneEndResult()
{
    std::unique_lock<std::mutex> lock(g_protocolMutex);
    bool signaled = false;

    do {
        signaled = g_protocolCv.wait_for(
                lock,
                std::chrono::milliseconds(PROTOCOL_ACK_TIMEOUT_MS),
                []() { return g_protocolStop || g_zoneEndWaitResult != ZoneEndWaitResult::none; });
    } while (!signaled);

    return g_zoneEndWaitResult;
}

bool SetInitialBrightness()
{
    Json::Value packet(Json::objectValue);
    packet["action"] = "setBrightness";

    Json::Value payload(Json::objectValue);
    auto brightness = LocalConfig::getInstance()->getBrightness();
    payload["value"] = brightness;
    packet["payload"] = payload;

    if (!SendJsonPacket(packet))
    {
        spdlog::warn("[Protocol] Failed to send initial brightness '{}'", brightness);
        return false;
    }
    spdlog::info("[Protocol] Sent intial brightness packet '{}'", brightness);

    return true;
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
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    std::size_t zoneIndex = 0;
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

        payload["Index"]   = zoneIndex++;
        payload["Name"]    = zoneConfig.zoneName;
        payload["Gain"]    = gain;
        payload["sources"] = sources;
        packet["action"]   = "zone";
        packet["payload"]  = payload;

        if (!SendJsonPacket(packet))
        {
            spdlog::warn("[Protocol] Failed to send zone packet for '{}'", zoneConfig.zoneName);
            return false;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        if (checkForZoneEndNack())
        {
            // zoneEndNack received, restart
            return false;
        }
    }

    if (zoneIndex > 0)
    {
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
            //return true;
        }
        else if (zoneEndResult == ZoneEndWaitResult::nack)
        {
            spdlog::warn("[Protocol] zoneEndNack received; restarting initialization");
            return false;
        }
        else
        {
            spdlog::warn("[Protocol] zoneEnd timeout; restarting initialization");
            return false;
        }

        int updZoneIdx = 0;
        for (const auto &zoneConfig : zoneSnapshot)
        {
            if (zoneConfig.gain.defaultGainValue != zoneConfig.gain.gainValue)
            {
                double norm = 0.0;
                const double denom = static_cast<double>(zoneConfig.gain.maxValue) - static_cast<double>(zoneConfig.gain.minValue);

                spdlog::info("Starting Gain update");

                if (std::abs(denom) > 1e-9)
                {
                    norm = (zoneConfig.gain.gainValue - static_cast<double>(zoneConfig.gain.minValue)) * 100.0 / denom;
                }
                Json::Value payload(Json::objectValue);
                payload["db"] = zoneConfig.gain.gainValue;
                payload["norm"] = norm;

                if (!SendRealtimeCommand("setGain", payload, updZoneIdx))
                {
                    return false;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
            if (zoneConfig.gain.defaultMuteValue != zoneConfig.gain.muteState)
            {
                Json::Value payload(Json::objectValue);

                spdlog::info("Starting Mute update");

                payload["state"] = zoneConfig.gain.muteState;

                if (!SendRealtimeCommand("setMute", payload, updZoneIdx))
                {
                    return false;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
            if (zoneConfig.sourceIndex != 0)
            {
                Json::Value payload(Json::objectValue);
                payload["index"] = zoneConfig.sourceIndex;

                if (!SendRealtimeCommand("setSource", payload, zoneIndex))
                {
                    return false;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }

            updZoneIdx++;
        }
    }

    return true;
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

    {
        std::lock_guard<std::mutex> lock(g_protocolMutex);
        if (!g_pendingAudioSettings || !g_latestAudioSettings.isObject())
        {
            return true;
        }
        audioSnapshot = g_latestAudioSettings;
        g_pendingAudioSettings = false;
    }

    FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();
    std::map<std::string, int> objectTrackerSnapshot = bridge.getObjectTrackerSnapshot();
    std::vector<TuiiZoneConfig> zoneSnapshot = bridge.getZoneConfigsSnapshot();

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
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        if (settings.isMember("mute") && settings["mute"].isBool())
        {
            Json::Value payload(Json::objectValue);
            payload["state"] = settings["mute"].asBool();

            if (!SendRealtimeCommand("setMute", payload, zoneIndex))
            {
                return false;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        if (settings.isMember("input") && settings["input"].isInt())
        {
            Json::Value payload(Json::objectValue);
            payload["index"] = settings["input"].asInt()-1;

            if (!SendRealtimeCommand("setSource", payload, zoneIndex))
            {
                return false;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
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
            }

            FusionTUIIBridge &bridge = FusionTUIIBridge::getInstance();
            std::vector<TuiiZoneConfig> zoneSnapshot = bridge.getZoneConfigsSnapshot();

           
            {
                std::lock_guard<std::mutex> lock(g_protocolMutex);
                g_initialSyncDone = false;
                g_readyAckReceived = false;
            }
#if ENABLE_QA_PROXY
            g_qaTxCv.notify_all();
#endif
              
            Json::Value readyPacket(Json::objectValue);
            readyPacket["action"] = "ready"; 

            
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
            g_readyAckReceived = false;  // Reset readyAck flag.

            if (!SetInitialBrightness())
            {
                continue;
            }

            if (!PerformInitializationCycle(deviceSnapshot, zoneSnapshot))
            {
                continue;
            }

            {
                std::lock_guard<std::mutex> lock(g_protocolMutex);
                g_initialSyncDone = true;
                g_readyAckReceived = false;
            }

#if ENABLE_QA_PROXY
            g_qaTxCv.notify_all();
#endif

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

                    // Check if display device was reset.
                    if (g_readyAckReceived)
                    {
                        g_readyAckReceived = false;  // Reset readyAck flag.
                        break;
                    }

                    if (g_pendingDeviceConfig || g_pendingZoneConfig || g_pendingAudioSettings)
                    {
                        if (g_pendingDeviceConfig || g_pendingZoneConfig)
                        {
                            g_pendingDeviceConfig = false;
                            g_pendingZoneConfig = false;
                            break;
                        }
                    }
                    g_protocolCv.wait_for(lock, std::chrono::milliseconds(50));
                    if (g_pendingDeviceConfig || g_pendingZoneConfig)
                    {
                        g_pendingDeviceConfig = false;
                        g_pendingZoneConfig = false;
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

    auto newTrackerPtr = rebuiltTracker;

    if (!bridge.updateZoneConfiguration(newTrackerPtr, rebuiltZoneConfigs))
    {
        spdlog::error("Rejected TUII configuration update because zone update failed");
        return;
    }

    QueueZoneConfigForProtocol();

    spdlog::info("TUII zone configuration update applied: {} zones, {} keys",
                 rebuiltZoneConfigs.size(), newTrackerPtr.size());
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
//end of code