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

// =============================================================================
// PUBLIC METHODS
// =============================================================================

FusionAudioBridge &FusionAudioBridge::getInstance()
{
    static FusionAudioBridge instance;
    return instance;
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
    if (!checkInitialized())
        return;

    std::string message = createGainMessage(gainID, value);
    sendMessageToFusion(message);
}

void FusionAudioBridge::handleFusionGainUpdate(const std::string &gainID, double value)
{
    if (!checkInitialized())
        return;

    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Processing Fusion gain update: %s = %.6f dB", gainID.c_str(), value);

    if (!processGainUpdate(gainID, value))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to process gain update for %s", gainID.c_str());
    }
}

void FusionAudioBridge::sendMuteToFusion(const std::string &gainID, bool muteState)
{
    if (!checkInitialized())
        return;

    std::string message = createMuteMessage(gainID, muteState);
    sendMessageToFusion(message);
}

void FusionAudioBridge::handleFusionMuteUpdate(const std::string &gainID, bool muteState)
{
    if (!checkInitialized())
        return;

    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Processing Fusion mute update: %s = %s", gainID.c_str(), muteState ? "MUTED" : "UNMUTED");

    if (!processMuteUpdate(gainID, muteState))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to process mute update for %s", gainID.c_str());
    }
}

void FusionAudioBridge::sendSourceToFusion(const std::string &zoneID, ::OcaUint16 sourceIndex)
{
    if (!checkInitialized())
        return;

    std::string message = createSourceMessage(zoneID, sourceIndex);
    sendMessageToFusion(message);
}

void FusionAudioBridge::handleFusionSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex)
{
    if (!checkInitialized())
        return;

    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Processing Fusion source update: %s = %u", zoneID.c_str(), sourceIndex);

    if (!processSourceUpdate(zoneID, sourceIndex))
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to process source update for %s", zoneID.c_str());
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

// =============================================================================
// PRIVATE METHODS - CORE LIFECYCLE
// =============================================================================

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

// =============================================================================
// PRIVATE METHODS - VALIDATION AND COMMUNICATION HELPERS
// =============================================================================

bool FusionAudioBridge::checkInitialized() const
{
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized");
        return false;
    }
    return true;
}

std::shared_ptr<const std::map<std::string, std::vector<::OcaONo>>> FusionAudioBridge::getObjectTrackerSnapshot() const
{
    std::lock_guard<std::mutex> lock(m_initMutex);
    if (!m_initialized.load())
    {
        OCA_LOG_INFO("[FusionAudioBridge] Bridge not initialized");
        return nullptr;
    }
    return m_objectTrackerPtr;
}

bool FusionAudioBridge::sendMessageToFusion(const std::string &jsonMessage)
{
    try
    {
        UDPSender &sender = UDPSender::getInstance();
        sender.sendMessage(jsonMessage);
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Sent to Fusion: %s", jsonMessage.c_str());
        return true;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Failed to send message to Fusion: %s", e.what());
        return false;
    }
}

// =============================================================================
// PRIVATE METHODS - JSON MESSAGE BUILDERS
// =============================================================================

std::string FusionAudioBridge::createGainMessage(const std::string &gainID, double value)
{
    std::ostringstream jsonStream;
    jsonStream << "{\"action\":\"set\",\"payload\":{\"settings\":{\"audio\":{\""
               << gainID << "\":{\"" << JSON_FIELD_GAIN << "\":" << std::fixed << std::setprecision(6) << value
               << "}}}}}";
    return jsonStream.str();
}

std::string FusionAudioBridge::createMuteMessage(const std::string &gainID, bool muteState)
{
    std::ostringstream jsonStream;
    jsonStream << "{\"action\":\"set\",\"payload\":{\"settings\":{\"audio\":{\""
               << gainID << "\":{\"" << JSON_FIELD_MUTE << "\":" << (muteState ? "true" : "false") << "}}}}}";
    return jsonStream.str();
}

std::string FusionAudioBridge::createSourceMessage(const std::string &zoneID, ::OcaUint16 sourceIndex)
{
    std::ostringstream jsonStream;
    jsonStream << "{\"action\":\"set\",\"payload\":{\"settings\":{\"audio\":{\""
               << zoneID << "\":{\"" << JSON_FIELD_INPUT << "\":" << sourceIndex + 1 << "}}}}}";
    return jsonStream.str();
}

// =============================================================================
// PRIVATE METHODS - OBJECT LOOKUP AND CASTING
// =============================================================================

OcaLiteRoot *FusionAudioBridge::getObjectFromTracker(const std::string &id, size_t objectIndex) const
{
    auto objectTrackerPtr = getObjectTrackerSnapshot();
    if (!objectTrackerPtr)
    {
        return nullptr;
    }

    auto it = objectTrackerPtr->find(id);
    if (it == objectTrackerPtr->end())
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] No object found for ID: %s", id.c_str());
        return nullptr;
    }

    const auto &targets = it->second;
    if (objectIndex >= targets.size())
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Invalid object index %zu for ID %s (has %zu objects)",
                            objectIndex, id.c_str(), targets.size());
        return nullptr;
    }

    ::OcaONo objectNumber = targets[objectIndex];
    OcaLiteRoot *pObject = ::OcaLiteBlock::GetRootBlock().GetObject(objectNumber);
    if (!pObject)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Could not find object %u", objectNumber);
    }

    return pObject;
}

ConcreteGainActuator *FusionAudioBridge::findGainActuator(const std::string &gainID) const
{
    OcaLiteRoot *object = getObjectFromTracker(gainID, GAIN_OBJECT_INDEX);
    if (!object)
    {
        return nullptr;
    }

    ConcreteGainActuator *actuator = dynamic_cast<ConcreteGainActuator *>(object);
    if (!actuator)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Object is not a ConcreteGainActuator for ID: %s", gainID.c_str());
    }

    return actuator;
}

ConcreteMuteActuator *FusionAudioBridge::findMuteActuator(const std::string &gainID) const
{
    OcaLiteRoot *object = getObjectFromTracker(gainID, MUTE_OBJECT_INDEX);
    if (!object)
    {
        return nullptr;
    }

    ConcreteMuteActuator *actuator = dynamic_cast<ConcreteMuteActuator *>(object);
    if (!actuator)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Object is not a ConcreteMuteActuator for ID: %s", gainID.c_str());
    }

    return actuator;
}

ConcreteSwitchActuator *FusionAudioBridge::findSwitchActuator(const std::string &zoneID) const
{
    OcaLiteRoot *object = getObjectFromTracker(zoneID, SWITCH_OBJECT_INDEX);
    if (!object)
    {
        return nullptr;
    }

    ConcreteSwitchActuator *actuator = dynamic_cast<ConcreteSwitchActuator *>(object);
    if (!actuator)
    {
        OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Object is not a ConcreteSwitchActuator for ID: %s", zoneID.c_str());
    }

    return actuator;
}

// =============================================================================
// PRIVATE METHODS - UPDATE PROCESSORS
// =============================================================================

bool FusionAudioBridge::processGainUpdate(const std::string &gainID, double value)
{
    ConcreteGainActuator *actuator = findGainActuator(gainID);
    if (!actuator)
    {
        return false;
    }

    actuator->handleFusionGainMessage(static_cast<::OcaDB>(value));
    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Successfully updated gain %s to %.6f dB", gainID.c_str(), value);
    return true;
}

bool FusionAudioBridge::processMuteUpdate(const std::string &gainID, bool muteState)
{
    ConcreteMuteActuator *actuator = findMuteActuator(gainID);
    if (!actuator)
    {
        return false;
    }

    actuator->handleFusionMuteMessage(muteState);
    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Successfully updated mute %s to %s",
                        gainID.c_str(), muteState ? "MUTED" : "UNMUTED");
    return true;
}

bool FusionAudioBridge::processSourceUpdate(const std::string &zoneID, ::OcaUint16 sourceIndex)
{
    ConcreteSwitchActuator *actuator = findSwitchActuator(zoneID);
    if (!actuator)
    {
        return false;
    }

    actuator->handleFusionSourceMessage(sourceIndex - 1);
    OCA_LOG_INFO_PARAMS("[FusionAudioBridge] Successfully updated source %s to %u", zoneID.c_str(), sourceIndex);
    return true;
}
