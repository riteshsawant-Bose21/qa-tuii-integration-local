/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : FusionAudioBridge - Centralized Fusion audio communication with echo suppression
 *
 */

// ---- Include system wide include files ----
#include <iostream>
#include <sstream>
#include <iomanip>
#include <cmath>
#include <cassert>

// ---- Include local include files ----
#include "FusionAudioBridge.h"
#include "UDPSender.h"
#include "workers/ConcreteGainActuator.h"
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteGain.h>
#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>
#include <HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.h>
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>

// ---- Class Implementation ----

FusionAudioBridge &FusionAudioBridge::getInstance()
{
    static FusionAudioBridge instance;
    return instance;
}

FusionAudioBridge::FusionAudioBridge()
    : m_initialized(false)
{
    OCA_LOG_INFO("[FusionAudioBridge] FusionAudioBridge created");
}

FusionAudioBridge::~FusionAudioBridge() noexcept
{
    shutdown();
    OCA_LOG_INFO("[FusionAudioBridge] FusionAudioBridge destroyed");
}

bool FusionAudioBridge::initialize(const std::string &serverIP,
                                   unsigned int serverPort,
                                   std::shared_ptr<std::map<std::string, std::vector<::OcaONo>>> objectTracker)
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Already initialized");
        return true;
    }

    try
    {
        // Store server configuration
        // m_serverIP = serverIP;
        // m_serverPort = static_cast<uint16_t>(serverPort);

        m_objectTrackerPtr = objectTracker;

        // Initialize UDP sender with server configuration
        UDPSender &sender = UDPSender::getInstance();
        if (!sender.initialize(serverIP, serverPort))
        {
            OCA_LOG_INFO("[FusionAudioBridge] Failed to initialize UDPSender");
            return false;
        }

        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Initialized with server %s:%u", serverIP.c_str(), serverPort);
        m_initialized.store(true);
        return true;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Initialization failed: %s", e.what());
        m_initialized.store(false);
        return false;
    }
}

void FusionAudioBridge::sendGainToFusion(const std::string &gainID, double value, const std::string &source)
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized, cannot send gain");
        return;
    }

    // Validate gain value to prevent invalid JSON
    if (!std::isfinite(value))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Invalid gain value (NaN/Inf) for %s, skipping send", gainID.c_str());
        return;
    }

    // Only send to Fusion if the change originated from AES70
    if (source != "aes70")
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Skipping Fusion send for %s (source: %s)", gainID.c_str(), source.c_str());
        return;
    }

    try
    {
        // Record the value we're sending for echo detection
        recordSentValue(gainID, value, source);

        // Create JSON message with correct format:
        // {"action": "set", "settings": {"audio": {"gainID": {"gain": value}}}}
        std::ostringstream jsonStream;
        jsonStream << "{\"action\":\"set\",\"settings\":{\"audio\":{\""
                   << gainID << "\":{\"gain\":" << std::fixed << std::setprecision(6) << value << "}}}}";
        std::string message = jsonStream.str();

        // Send to Fusion using singleton
        UDPSender &sender = UDPSender::getInstance();
        sender.sendMessage(message);
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Sent to Fusion: %s", message.c_str());
    }
    catch (const std::exception &e)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to send gain to Fusion: %s", e.what());
    }
}

void FusionAudioBridge::handleFusionGainUpdate(const std::string &gainID, double value)
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized, cannot handle gain update");
        return;
    }

    // Validate gain value
    if (!std::isfinite(value))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Invalid gain value (NaN/Inf) for %s, ignoring update", gainID.c_str());
        return;
    }

    // Check if this is an echo of a message we recently sent
    if (isEchoMessage(gainID, value))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Suppressing echo for %s = %.6f dB", gainID.c_str(), value);
        return;
    }

    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Processing Fusion gain update: %s = %.6f dB", gainID.c_str(), value);

    // Process the gain update
    if (!processGainUpdate(gainID, value))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to process gain update for %s", gainID.c_str());
    }
}

void FusionAudioBridge::shutdown()
{
    std::lock_guard<std::mutex> lock(m_initMutex);

    if (!m_initialized.load())
    {
        return;
    }

    // Set initialized false first to prevent race conditions
    m_initialized.store(false);

    // Cleanup (Note: UDPSender is singleton, don't try to destroy it)

    // Clear tracked values
    {
        std::lock_guard<std::mutex> recordsLock(m_recordsMutex);
        m_recentByGain.clear();
    }

    // Clear object tracker and server config
    m_objectTrackerPtr.reset();

    OCA_LOG_INFO("[FusionAudioBridge] Bridge shutdown complete");
}

bool FusionAudioBridge::isInitialized() const noexcept
{
    return m_initialized.load();
}

bool FusionAudioBridge::isEchoMessage(const std::string &gainID, double value)
{
    std::string echoLogMessage;
    bool isEcho = false;

    {
        std::lock_guard<std::mutex> lock(m_recordsMutex);

        // Clean up old records for this specific gain first
        cleanupOldRecordsForGain(gainID);

        auto now = std::chrono::steady_clock::now();

        // Check only the records for this specific gain (O(1) typical case)
        auto gainIt = m_recentByGain.find(gainID);
        if (gainIt != m_recentByGain.end())
        {
            for (const auto &record : gainIt->second)
            {
                // Check if within time window
                auto timeDiff = std::chrono::duration_cast<std::chrono::milliseconds>(now - record.timestamp);
                if (timeDiff <= ECHO_WINDOW_MS)
                {
                    // Check if values are close enough to be considered the same
                    double valueDiff = std::abs(value - record.value);
                    if (valueDiff <= ECHO_TOLERANCE_DB)
                    {
                        // Prepare log message without logging while holding the lock
                        std::ostringstream logStream;
                        logStream << "Echo detected: " << gainID << " value=" << value
                                  << " matches recent send value=" << record.value
                                  << " (diff=" << valueDiff << "dB, time=" << timeDiff.count() << "ms)";
                        echoLogMessage = logStream.str();
                        isEcho = true;
                        break;
                    }
                }
            }
        }
    }

    // Log after releasing the lock to avoid blocking
    if (isEcho && !echoLogMessage.empty())
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] %s", echoLogMessage.c_str());
    }

    return isEcho;
}

void FusionAudioBridge::recordSentValue(const std::string &gainID, double value, const std::string &source)
{
    std::lock_guard<std::mutex> lock(m_recordsMutex);

    // Add new record to the specific gain's deque
    m_recentByGain[gainID].emplace_back(gainID, value, source);

    // Remove oldest records if we exceed the limit for this gain
    auto &gainRecords = m_recentByGain[gainID];
    while (gainRecords.size() > MAX_TRACKED_VALUES)
    {
        gainRecords.pop_front();
    }

    // Clean up old records for this gain
    cleanupOldRecordsForGain(gainID);
}

void FusionAudioBridge::cleanupOldRecordsForGain(const std::string &gainID) noexcept
{
    auto now = std::chrono::steady_clock::now();

    auto gainIt = m_recentByGain.find(gainID);
    if (gainIt == m_recentByGain.end())
    {
        return; // No records for this gain
    }

    auto &records = gainIt->second;

    // Remove records older than the echo window
    auto it = records.begin();
    while (it != records.end())
    {
        auto timeDiff = std::chrono::duration_cast<std::chrono::milliseconds>(now - it->timestamp);
        if (timeDiff > ECHO_WINDOW_MS)
        {
            it = records.erase(it);
        }
        else
        {
            ++it;
        }
    }

    // Remove the entire entry if no records remain
    if (records.empty())
    {
        m_recentByGain.erase(gainIt);
    }
}

bool FusionAudioBridge::processGainUpdate(const std::string &gainID, double value)
{
    // Snapshot the object tracker pointer with minimal lock time
    std::shared_ptr<const std::map<std::string, std::vector<::OcaONo>>> objectTrackerPtr;
    {
        std::lock_guard<std::mutex> lock(m_initMutex);
        if (!m_initialized.load())
        {
            OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized");
            return false;
        }
        objectTrackerPtr = m_objectTrackerPtr; // Copy shared_ptr (cheap)
    }

    // Use the snapshot without holding any locks
    if (!objectTrackerPtr)
    {
        OCA_LOG_INFO("[FusionAudioBridge] Object tracker not available");
        return false;
    }

    // Find the object number(s) for this gain ID
    auto it = objectTrackerPtr->find(gainID);
    if (it == objectTrackerPtr->end())
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] No object found for gain ID: %s", gainID.c_str());
        return false;
    }

    // Copy just the targets vector for this specific gain (not the entire map)
    std::vector<::OcaONo> targets = it->second;

    bool success = false;
    for (::OcaONo objectNumber : targets)
    {
        // Get the worker object from the root block
        ::OcaLiteRoot *pObject = ::OcaLiteBlock::GetRootBlock().GetObject(objectNumber);
        if (pObject != nullptr)
        {
            // Try to cast to ConcreteGainActuator
            ConcreteGainActuator *pGainActuator = dynamic_cast<ConcreteGainActuator *>(pObject);
            if (pGainActuator != nullptr)
            {
                // Update the gain value with "fusion" source to prevent echo
                pGainActuator->handleFusionGainMessage(static_cast<::OcaDB>(value));
                OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Successfully updated gain %s (object %u) to %.6f dB", gainID.c_str(), objectNumber, value);
                success = true;
            }
            else
            {
                OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Object %u is not a ConcreteGainActuator", objectNumber);
            }
        }
        else
        {
            OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Could not find object %u", objectNumber);
        }
    }

    return success;
}
