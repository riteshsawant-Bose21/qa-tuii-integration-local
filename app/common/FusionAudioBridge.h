/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : FusionAudioBridge - Centralized Fusion audio communication with echo suppression
 *
 */
#ifndef FUSIONAUDIOBRIDGE_H
#define FUSIONAUDIOBRIDGE_H

// ---- Include system wide include files ----
#include <string>
#include <deque>
#include <mutex>
#include <chrono>
#include <memory>
#include <map>
#include <vector>
#include <atomic>
#include <cmath>
#include <unordered_map>

// ---- Include local include files ----
#include <OCC/ControlDataTypes/OcaLiteWorkerDataTypes.h>
#include <OCC/ControlDataTypes/OcaLiteFrameworkDataTypes.h>

// ---- Forward declarations ----
class UDPSender;
class UDPValueMonitor;
class ConcreteGainActuator;

// ---- Helper types and constants ----

// ---- Class Definition ----
/**
 * @brief Centralized Fusion audio communication bridge with echo suppression
 *
 * This class manages all communication with the Fusion server for audio settings,
 * implements echo suppression to prevent feedback loops, and tracks the source
 * of gain changes to avoid unnecessary round-trips.
 */
class FusionAudioBridge
{
public:
    /**
     * @brief Get the singleton instance
     * @return Reference to the singleton instance
     */
    static FusionAudioBridge &getInstance();

    /**
     * @brief Initialize the Fusion audio bridge
     * @param serverIP Fusion server IP address
     * @param serverPort Fusion server port
     * @param objectTracker Shared pointer to the global object tracker map
     * @return true if initialization successful, false otherwise
     */
    bool initialize(const std::string &serverIP,
                    unsigned int serverPort,
                    std::shared_ptr<std::map<std::string, std::vector<::OcaONo>>> objectTracker);

    /**
     * @brief Send gain update to Fusion server
     * @param gainID The gain identifier (e.g., "gain1")
     * @param value The gain value in dB
     * @param source The source of the change ("aes70" or "fusion")
     */
    void sendGainToFusion(const std::string &gainID, double value);

    /**
     * @brief Handle gain update received from Fusion server
     * @param gainID The gain identifier
     * @param value The gain value in dB
     */
    void handleFusionGainUpdate(const std::string &gainID, double value);

    /**
     * @brief Send mute update to Fusion server
     * @param gainID The gain identifier (mute uses same ID as gain)
     * @param muteState The mute state (true = muted, false = unmuted)
     * @param source The source of the change ("aes70" or "fusion")
     */
    void sendMuteToFusion(const std::string &gainID, bool muteState);

    /**
     * @brief Handle mute update received from Fusion server
     * @param gainID The gain identifier (mute uses same ID as gain)
     * @param muteState The mute state (true = muted, false = unmuted)
     */
    void handleFusionMuteUpdate(const std::string &gainID, bool muteState);

    /**
     * @brief Send source selection update to Fusion server
     * @param zoneID The zone identifier
     * @param sourceIndex The selected source index
     * @param source The source of the change ("aes70" or "fusion")
     */
    void sendSourceToFusion(const std::string &zoneID, ::OcaUint16 sourceIndex);

    /**
     * @brief Handle source selection update received from Fusion server
     * @param zoneID The zone identifier
     * @param sourceIndex The selected source index
     */
    void handleFusionSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex);

    /**
     * @brief Shutdown the bridge and cleanup resources
     */
    void shutdown();

    /**
     * @brief Check if the bridge is initialized
     * @return true if initialized, false otherwise
     */
    bool isInitialized() const noexcept;

private:
    /**
     * @brief Private constructor for singleton pattern
     */
    FusionAudioBridge();

    /**
     * @brief Destructor
     */
    ~FusionAudioBridge() noexcept;

    /**
     * @brief Process a gain update by finding and calling the appropriate ConcreteGainActuator
     * @param gainID The gain identifier
     * @param value The gain value
     * @return true if processed successfully, false otherwise
     */
    bool processGainUpdate(const std::string &gainID, double value);

    /**
     * @brief Process a mute update by finding and calling the appropriate ConcreteMuteActuator
     * @param gainID The gain identifier
     * @param muteState The mute state
     * @return true if processed successfully, false otherwise
     */
    bool processMuteUpdate(const std::string &gainID, bool muteState);

    /**
     * @brief Process a source update by finding and calling the appropriate ConcreteSwitchActuator
     * @param zoneID The zone identifier
     * @param sourceIndex The source index
     * @return true if processed successfully, false otherwise
     */
    bool processSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex);

    // Shared pointer to object tracker for lock-free reads with snapshot semantics
    std::shared_ptr<const std::map<std::string, std::vector<::OcaONo>>> m_objectTrackerPtr;

    // Atomic for thread-safe access without mutex on fast path
    std::atomic<bool> m_initialized;

    mutable std::mutex m_initMutex;

    // Prevent copying and assignment
    FusionAudioBridge(const FusionAudioBridge &) = delete;
    FusionAudioBridge &operator=(const FusionAudioBridge &) = delete;
};

#endif // FUSIONAUDIOBRIDGE_H
