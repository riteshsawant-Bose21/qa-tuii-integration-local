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
#include "workers/ConcreteMuteActuator.h"
#include "workers/ConcreteSwitchActuator.h"
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

void FusionAudioBridge::sendGainToFusion(const std::string &gainID, double value)
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized, cannot send gain");
        return;
    }

    try
    {

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

    // // Validate gain value
    // if (!std::isfinite(value))
    // {
    //     OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Invalid gain value (NaN/Inf) for %s, ignoring update", gainID.c_str());
    //     return;
    // }

    // Check if this is an echo of a message we recently sent
    // OCA_LOG_INFO_PARAMS("[FusionAudioBridge] DEBUG: Checking echo for %s = %.6f dB", gainID.c_str(), value);
    // if (isEchoMessage(gainID, value))
    // {
    //     OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Suppressing echo for %s = %.6f dB", gainID.c_str(), value);
    //     return;
    // }

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

    // Clear object tracker and server config
    m_objectTrackerPtr.reset();

    OCA_LOG_INFO("[FusionAudioBridge] Bridge shutdown complete");
}

bool FusionAudioBridge::isInitialized() const noexcept
{
    return m_initialized.load();
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

void FusionAudioBridge::sendMuteToFusion(const std::string &gainID, bool muteState)
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized, cannot send mute");
        return;
    }

    try
    {
        // Create JSON message: {"action":"set","settings":{"audio":{"gainID":{"mute": true/false}}}}
        std::ostringstream jsonStream;
        jsonStream << "{\"action\":\"set\",\"settings\":{\"audio\":{\""
                   << gainID << "\":{\"mute\":" << (muteState ? "true" : "false") << "}}}}";
        std::string message = jsonStream.str();

        // Send to Fusion using singleton
        UDPSender &sender = UDPSender::getInstance();
        sender.sendMessage(message);
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Sent mute to Fusion: %s", message.c_str());
    }
    catch (const std::exception &e)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to send mute to Fusion: %s", e.what());
    }
}

void FusionAudioBridge::handleFusionMuteUpdate(const std::string &gainID, bool muteState)
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized, cannot handle mute update");
        return;
    }

    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Processing Fusion mute update: %s = %s", gainID.c_str(), muteState ? "MUTED" : "UNMUTED");

    // Process the mute update
    if (!processMuteUpdate(gainID, muteState))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to process mute update for %s", gainID.c_str());
    }
}

void FusionAudioBridge::sendSourceToFusion(const std::string &zoneID, ::OcaUint16 sourceIndex)
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized, cannot send source");
        return;
    }

    try
    {
        // Create JSON message: {"action":"set","settings":{"audio":{"zoneID":{"source": sourceIndex}}}}
        std::ostringstream jsonStream;
        jsonStream << "{\"action\":\"set\",\"settings\":{\"audio\":{\""
                   << zoneID << "\":{\"input\":" << sourceIndex << "}}}}";
        std::string message = jsonStream.str();

        // Send to Fusion using singleton
        UDPSender &sender = UDPSender::getInstance();
        sender.sendMessage(message);
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Sent source to Fusion: %s", message.c_str());
    }
    catch (const std::exception &e)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to send source to Fusion: %s", e.what());
    }
}

void FusionAudioBridge::handleFusionSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex)
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized, cannot handle source update");
        return;
    }

    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Processing Fusion source update: %s = %u", zoneID.c_str(), sourceIndex);

    // Process the source update
    if (!processSourceUpdate(zoneID, sourceIndex))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to process source update for %s", zoneID.c_str());
    }
}

bool FusionAudioBridge::processMuteUpdate(const std::string &gainID, bool muteState)
{
    // Snapshot the object tracker pointer
    std::shared_ptr<const std::map<std::string, std::vector<::OcaONo>>> objectTrackerPtr;
    {
        std::lock_guard<std::mutex> lock(m_initMutex);
        if (!m_initialized.load())
        {
            OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized");
            return false;
        }
        objectTrackerPtr = m_objectTrackerPtr;
    }

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

    // For mute, we need the second object (muteOno) from the gain mapping
    const std::vector<::OcaONo> &targets = it->second;
    if (targets.size() < 2)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Invalid object mapping for gain ID %s - expected at least 2 objects", gainID.c_str());
        return false;
    }

    ::OcaONo muteOno = targets[1]; // Second object is the mute object

    // Get the worker object from the root block
    ::OcaLiteRoot *pObject = ::OcaLiteBlock::GetRootBlock().GetObject(muteOno);
    if (pObject != nullptr)
    {
        // Try to cast to ConcreteMuteActuator
        ConcreteMuteActuator *pMuteActuator = dynamic_cast<ConcreteMuteActuator *>(pObject);
        if (pMuteActuator != nullptr)
        {
            // Update the mute value with "fusion" source to prevent echo
            pMuteActuator->handleFusionMuteMessage(muteState);
            OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Successfully updated mute %s (object %u) to %s",
                                gainID.c_str(), muteOno, muteState ? "MUTED" : "UNMUTED");
            return true;
        }
        else
        {
            OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Object %u is not a ConcreteMuteActuator", muteOno);
        }
    }
    else
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Could not find mute object %u", muteOno);
    }

    return false;
}

bool FusionAudioBridge::processSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex)
{
    // Snapshot the object tracker pointer
    std::shared_ptr<const std::map<std::string, std::vector<::OcaONo>>> objectTrackerPtr;
    {
        std::lock_guard<std::mutex> lock(m_initMutex);
        if (!m_initialized.load())
        {
            OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized");
            return false;
        }
        objectTrackerPtr = m_objectTrackerPtr;
    }

    if (!objectTrackerPtr)
    {
        OCA_LOG_INFO("[FusionAudioBridge] Object tracker not available");
        return false;
    }

    // Find the object number(s) for this zone ID
    auto it = objectTrackerPtr->find(zoneID);
    if (it == objectTrackerPtr->end())
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] No object found for zone ID: %s", zoneID.c_str());
        return false;
    }

    // For source, we use the first (and only) object from the zone mapping
    const std::vector<::OcaONo> &targets = it->second;
    if (targets.empty())
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Empty object mapping for zone ID: %s", zoneID.c_str());
        return false;
    }

    ::OcaONo switchOno = targets[0]; // First object is the switch object

    // Get the worker object from the root block
    ::OcaLiteRoot *pObject = ::OcaLiteBlock::GetRootBlock().GetObject(switchOno);
    if (pObject != nullptr)
    {
        // Try to cast to ConcreteSwitchActuator
        ConcreteSwitchActuator *pSwitchActuator = dynamic_cast<ConcreteSwitchActuator *>(pObject);
        if (pSwitchActuator != nullptr)
        {
            // Update the source selection with "fusion" source to prevent echo
            pSwitchActuator->handleFusionSourceMessage(sourceIndex);
            OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Successfully updated source %s (object %u) to %u",
                                zoneID.c_str(), switchOno, sourceIndex);
            return true;
        }
        else
        {
            OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Object %u is not a ConcreteSwitchActuator", switchOno);
        }
    }
    else
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Could not find switch object %u", switchOno);
    }

    return false;
}
