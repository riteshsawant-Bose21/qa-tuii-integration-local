/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : FusionTUIIBridge - Centralized Fusion audio communication
 *
 */

// ---- Include system wide include files ----
#include <sstream>
#include <iomanip>
#include <spdlog/spdlog.h>

// ---- Include local include files ----
#include "FusionTuiiBridge.h"
#include "UDPSender.h"

// ---- Class Implementation ----

FusionTUIIBridge &FusionTUIIBridge::getInstance()
{
    static FusionTUIIBridge instance;
    return instance;
}

bool FusionTUIIBridge::initialize(const std::string &serverIP,
                                   unsigned int serverPort,
                                   std::shared_ptr<std::map<std::string, int>> objectTracker,
                                   const std::vector<TuiiZoneConfig> &zoneConfigs,
                                   const Json::Value &deviceConfig)
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (m_initialized.load())
    {
        spdlog::info("[FusionTUIIBridge] Already initialized");
        return true;
    }

    try
    {
        m_objectTrackerPtr = objectTracker;
        m_zoneConfigs = zoneConfigs;
        m_deviceConfig = deviceConfig;

        UDPSender &sender = UDPSender::getInstance();
        if (!sender.initialize(serverIP, serverPort))
        {
            spdlog::error("[FusionTUIIBridge] Failed to initialize UDPSender");
            return false;
        }

        spdlog::info("[FusionTUIIBridge] Initialized with server {}:{}", serverIP, serverPort);
        m_initialized.store(true);
        return true;
    }
    catch (const std::exception &e)
    {
        spdlog::error("[FusionTUIIBridge] Initialization failed: {}", e.what());
        m_initialized.store(false);
        return false;
    }
}

bool FusionTUIIBridge::updateZoneConfiguration(std::shared_ptr<std::map<std::string, int>> objectTracker,
                                               const std::vector<TuiiZoneConfig> &zoneConfigs)
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (!m_initialized.load())
    {
        spdlog::warn("[FusionTUIIBridge] Cannot update zone configuration: bridge not initialized");
        return false;
    }

    m_objectTrackerPtr = objectTracker;
    m_zoneConfigs = zoneConfigs;

    spdlog::info("[FusionTUIIBridge] Zone configuration updated: {} zones, {} keys",
                 m_zoneConfigs.size(), m_objectTrackerPtr ? m_objectTrackerPtr->size() : 0U);
    return true;
}

bool FusionTUIIBridge::updateDeviceConfiguration(const Json::Value &deviceConfig)
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (!m_initialized.load())
    {
        spdlog::warn("[FusionTUIIBridge] Cannot update device configuration: bridge not initialized");
        return false;
    }

    m_deviceConfig = deviceConfig;
    spdlog::info("[FusionTUIIBridge] Device configuration updated");
    return true;
}

Json::Value FusionTUIIBridge::getDeviceConfig() const
{
    std::lock_guard<std::mutex> lock(m_initMutex);
    return m_deviceConfig;
}

void FusionTUIIBridge::sendGainToFusion(const std::string &gainID, double value)
{
    if (!checkInitialized())
        return;

    std::string message = createGainMessage(gainID, value);
    sendMessageToFusion(message);
}

void FusionTUIIBridge::handleFusionGainUpdate(const std::string &gainID, double value)
{
    if (!checkInitialized())
        return;

    spdlog::debug("[FusionTUIIBridge] Processing Fusion gain update: {} = {:.6f} dB", gainID, value);

    if (!processGainUpdate(gainID, value))
    {
        spdlog::warn("[FusionTUIIBridge] Failed to process gain update for {}", gainID);
    }
}

void FusionTUIIBridge::sendMuteToFusion(const std::string &gainID, bool muteState)
{
    if (!checkInitialized())
        return;

    std::string message = createMuteMessage(gainID, muteState);
    sendMessageToFusion(message);
}

void FusionTUIIBridge::handleFusionMuteUpdate(const std::string &gainID, bool muteState)
{
    if (!checkInitialized())
        return;

    spdlog::debug("[FusionTUIIBridge] Processing Fusion mute update: {} = {}",
                  gainID, muteState ? "MUTED" : "UNMUTED");

    if (!processMuteUpdate(gainID, muteState))
    {
        spdlog::warn("[FusionTUIIBridge] Failed to process mute update for {}", gainID);
    }
}

void FusionTUIIBridge::sendSourceToFusion(const std::string &zoneID, uint16_t sourceIndex)
{
    if (!checkInitialized())
        return;

    std::string message = createSourceMessage(zoneID, sourceIndex);
    sendMessageToFusion(message);
}

void FusionTUIIBridge::handleFusionSourceUpdate(const std::string &zoneID, uint16_t sourceIndex)
{
    if (!checkInitialized())
        return;

    spdlog::debug("[FusionTUIIBridge] Processing Fusion source update: {} = {}", zoneID, sourceIndex);

    if (!processSourceUpdate(zoneID, sourceIndex))
    {
        spdlog::warn("[FusionTUIIBridge] Failed to process source update for {}", zoneID);
    }
}

void FusionTUIIBridge::shutdown()
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (!m_initialized.load())
    {
        return;
    }

    m_initialized.store(false);
    m_objectTrackerPtr.reset();
    m_zoneConfigs.clear();
    m_deviceConfig = Json::Value(Json::objectValue);

    spdlog::info("[FusionTUIIBridge] Bridge shutdown complete");
}

bool FusionTUIIBridge::isInitialized() const noexcept
{
    return m_initialized.load();
}

// =============================================================================
// PRIVATE METHODS - CORE LIFECYCLE
// =============================================================================

FusionTUIIBridge::FusionTUIIBridge()
    : m_initialized(false)
{
    spdlog::info("[FusionTUIIBridge] FusionTUIIBridge created");
}

FusionTUIIBridge::~FusionTUIIBridge() noexcept
{
    shutdown();
    spdlog::info("[FusionTUIIBridge] FusionTUIIBridge destroyed");
}

// =============================================================================
// PRIVATE METHODS - VALIDATION AND COMMUNICATION HELPERS
// =============================================================================

bool FusionTUIIBridge::checkInitialized() const
{
    if (!m_initialized.load())
    {
        spdlog::warn("[FusionTUIIBridge] Bridge not initialized");
        return false;
    }
    return true;
}

std::shared_ptr<const std::map<std::string, int>> FusionTUIIBridge::getObjectTrackerSnapshot() const
{
    std::lock_guard<std::mutex> lock(m_initMutex);
    if (!m_initialized.load())
    {
        spdlog::warn("[FusionTUIIBridge] Bridge not initialized");
        return nullptr;
    }
    return m_objectTrackerPtr;
}

bool FusionTUIIBridge::sendMessageToFusion(const std::string &jsonMessage)
{
    try
    {
        UDPSender &sender = UDPSender::getInstance();
        sender.sendMessage(jsonMessage);
        spdlog::debug("[FusionTUIIBridge] Sent to Fusion: {}", jsonMessage);
        return true;
    }
    catch (const std::exception &e)
    {
        spdlog::error("[FusionTUIIBridge] Failed to send message to Fusion: {}", e.what());
        return false;
    }
}

// =============================================================================
// PRIVATE METHODS - JSON MESSAGE BUILDERS
// =============================================================================

std::string FusionTUIIBridge::createGainMessage(const std::string &gainID, double value)
{
    std::ostringstream jsonStream;
    jsonStream << "{\"action\":\"set\",\"payload\":{\"settings\":{\"audio\":{\""
               << gainID << "\":{\"" << JSON_FIELD_GAIN << "\":" << std::fixed << std::setprecision(6) << value
               << "}}}}}";
    return jsonStream.str();
}

std::string FusionTUIIBridge::createMuteMessage(const std::string &gainID, bool muteState)
{
    std::ostringstream jsonStream;
    jsonStream << "{\"action\":\"set\",\"payload\":{\"settings\":{\"audio\":{\""
               << gainID << "\":{\"" << JSON_FIELD_MUTE << "\":" << (muteState ? "true" : "false") << "}}}}}";
    return jsonStream.str();
}

std::string FusionTUIIBridge::createSourceMessage(const std::string &zoneID, uint16_t sourceIndex)
{
    std::ostringstream jsonStream;
    jsonStream << "{\"action\":\"set\",\"payload\":{\"settings\":{\"audio\":{\""
               << zoneID << "\":{\"" << JSON_FIELD_INPUT << "\":" << sourceIndex + 1 << "}}}}}";
    return jsonStream.str();
}

// =============================================================================
// PRIVATE METHODS - OBJECT LOOKUP
// =============================================================================

const TuiiZoneConfig *FusionTUIIBridge::getZoneConfigFromTracker(const std::string &id) const
{
    auto objectTrackerPtr = getObjectTrackerSnapshot();
    if (!objectTrackerPtr)
    {
        return nullptr;
    }

    auto it = objectTrackerPtr->find(id);
    if (it == objectTrackerPtr->end())
    {
        spdlog::warn("[FusionTUIIBridge] No object found for ID: {}", id);
        return nullptr;
    }

    int zoneIndex = it->second;
    if (zoneIndex < 0)
    {
        spdlog::warn("[FusionTUIIBridge] Invalid zone index {} for ID {}", zoneIndex, id);
        return nullptr;
    }

    const size_t idx = static_cast<size_t>(zoneIndex);
    if (idx >= m_zoneConfigs.size())
    {
        spdlog::warn("[FusionTUIIBridge] Zone index {} for ID {} out of range (size={})",
                     zoneIndex, id, m_zoneConfigs.size());
        return nullptr;
    }

    return &m_zoneConfigs[idx];
}

const std::string &FusionTUIIBridge::findGainZoneConfig(const std::string &gainID) const
{
    static const std::string empty;
    if (!getZoneConfigFromTracker(gainID))
    {
        spdlog::warn("[FusionTUIIBridge] No gain zone object found for ID: {}", gainID);
        return empty;
    }
    return gainID;
}

const std::string &FusionTUIIBridge::findMuteZoneConfig(const std::string &gainID) const
{
    static const std::string empty;
    if (!getZoneConfigFromTracker(gainID))
    {
        spdlog::warn("[FusionTUIIBridge] No mute zone object found for ID: {}", gainID);
        return empty;
    }
    return gainID;
}

const std::string &FusionTUIIBridge::findSwitchZoneConfig(const std::string &zoneID) const
{
    static const std::string empty;
    if (!getZoneConfigFromTracker(zoneID))
    {
        spdlog::warn("[FusionTUIIBridge] No switch zone object found for ID: {}", zoneID);
        return empty;
    }
    return zoneID;
}

// =============================================================================
// PRIVATE METHODS - UPDATE PROCESSORS (STUBS)
// =============================================================================

bool FusionTUIIBridge::processGainUpdate(const std::string &gainID, double value)
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (!m_objectTrackerPtr)
    {
        spdlog::error("[FusionTUIIBridge] Gain update failed: object tracker is null");
        return false;
    }

    const auto it = m_objectTrackerPtr->find(gainID);
    if (it == m_objectTrackerPtr->end())
    {
        spdlog::error("[FusionTUIIBridge] Gain update failed: key '{}' not found in tracker", gainID);
        return false;
    }

    const int zoneIndex = it->second;
    if (zoneIndex < 0)
    {
        spdlog::error("[FusionTUIIBridge] Gain update failed: invalid zone index {} for key '{}'",
                      zoneIndex, gainID);
        return false;
    }

    const size_t idx = static_cast<size_t>(zoneIndex);
    if (idx >= m_zoneConfigs.size())
    {
        spdlog::error("[FusionTUIIBridge] Gain update failed: zone index {} out of range (size={}) for key '{}'",
                      zoneIndex, m_zoneConfigs.size(), gainID);
        return false;
    }

    TuiiZoneConfig &zone = m_zoneConfigs[idx];
    const float oldGain = zone.gain.gainValue;
    const float minGain = zone.gain.minValue;
    const float maxGain = zone.gain.maxValue;

    float newGain = static_cast<float>(value);
    if (newGain < minGain)
    {
        spdlog::warn("[FusionTUIIBridge] Gain value {:.6f below min {:.6f for key '{}'; clamping",
                     newGain, minGain, gainID);
        newGain = minGain;
    }
    else if (newGain > maxGain)
    {
        spdlog::warn("[FusionTUIIBridge] Gain value {:.6f above max {:.6f for key '{}'; clamping",
                     newGain, maxGain, gainID);
        newGain = maxGain;
    }

    zone.gain.gainValue = newGain;
    spdlog::debug("[FusionTUIIBridge] Gain updated for key '{}': old={:.6f}, new={:.6f}",
                  gainID, oldGain, zone.gain.gainValue);
    return true;
}

bool FusionTUIIBridge::processMuteUpdate(const std::string &gainID, bool muteState)
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (!m_objectTrackerPtr)
    {
        spdlog::error("[FusionTUIIBridge] Mute update failed: object tracker is null");
        return false;
    }

    const auto it = m_objectTrackerPtr->find(gainID);
    if (it == m_objectTrackerPtr->end())
    {
        spdlog::error("[FusionTUIIBridge] Mute update failed: key '{}' not found in tracker", gainID);
        return false;
    }

    const int zoneIndex = it->second;
    if (zoneIndex < 0)
    {
        spdlog::error("[FusionTUIIBridge] Mute update failed: invalid zone index {} for key '{}'",
                      zoneIndex, gainID);
        return false;
    }

    const size_t idx = static_cast<size_t>(zoneIndex);
    if (idx >= m_zoneConfigs.size())
    {
        spdlog::error("[FusionTUIIBridge] Mute update failed: zone index {} out of range (size={}) for key '{}'",
                      zoneIndex, m_zoneConfigs.size(), gainID);
        return false;
    }

    TuiiZoneConfig &zone = m_zoneConfigs[idx];
    const bool oldMuteState = zone.gain.muteState;
    zone.gain.muteState = muteState;

    spdlog::debug("[FusionTUIIBridge] Mute updated for key '{}': old={}, new={}",
                  gainID,
                  oldMuteState ? "true" : "false",
                  zone.gain.muteState ? "true" : "false");
    return true;
}

bool FusionTUIIBridge::processSourceUpdate(const std::string &zoneID, uint16_t sourceIndex)
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (!m_objectTrackerPtr)
    {
        spdlog::error("[FusionTUIIBridge] Source update failed: object tracker is null");
        return false;
    }

    const auto it = m_objectTrackerPtr->find(zoneID);
    if (it == m_objectTrackerPtr->end())
    {
        spdlog::error("[FusionTUIIBridge] Source update failed: key '{}' not found in tracker", zoneID);
        return false;
    }

    const int zoneIndex = it->second;
    if (zoneIndex < 0)
    {
        spdlog::error("[FusionTUIIBridge] Source update failed: invalid zone index {} for key '{}'",
                      zoneIndex, zoneID);
        return false;
    }

    const size_t idx = static_cast<size_t>(zoneIndex);
    if (idx >= m_zoneConfigs.size())
    {
        spdlog::error("[FusionTUIIBridge] Source update failed: zone index {} out of range (size={}) for key '{}'",
                      zoneIndex, m_zoneConfigs.size(), zoneID);
        return false;
    }

    if (sourceIndex == 0)
    {
        spdlog::error("[FusionTUIIBridge] Source update failed: input {} is invalid for key '{}' (expected 1-based index)",
                      sourceIndex, zoneID);
        return false;
    }

    const int newZeroBasedIndex = static_cast<int>(sourceIndex) - 1;
    TuiiZoneConfig &zone = m_zoneConfigs[idx];

    if (newZeroBasedIndex < 0 || static_cast<size_t>(newZeroBasedIndex) >= zone.sources.size())
    {
        spdlog::error("[FusionTUIIBridge] Source update failed: input {} (0-based {}) out of range for key '{}' (sources={})",
                      sourceIndex, newZeroBasedIndex, zoneID, zone.sources.size());
        return false;
    }

    const int oldSourceIndex = zone.sourceIndex;
    zone.sourceIndex = newZeroBasedIndex;

    spdlog::debug("[FusionTUIIBridge] Source updated for key '{}': old={}, new={} (from input={})",
                  zoneID, oldSourceIndex, zone.sourceIndex, sourceIndex);
    return true;
}