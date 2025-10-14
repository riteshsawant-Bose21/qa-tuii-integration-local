/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALite.cpp : Defines the entry point for the console application.
//

#include <HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.h>
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include <HostInterfaceLite/OCA/OCP.1/Ocp1LiteHostInterface.h>
#include <OCC/ControlDataTypes/OcaLiteStringInABlob.h>
#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>
#include <OCC/ControlClasses/Managers/OcaLiteDeviceManager.h>
#include <OCC/ControlClasses/Managers/OcaLiteNetworkManager.h>
#include <OCC/ControlClasses/Managers/OcaLiteSubscriptionManager.h>
#include <OCC/ControlClasses/Managers/OcaLiteFirmwareManager.h>
#include <OCF/OcaLiteCommandHandler.h>
#include <mutex>
#include <memory>
#ifndef UDP
#include <OCP.1/Ocp1LiteNetwork.h>
#else
#include <OCP.1/Ocp1LiteUdpNetwork.h>
#endif
#include <OCP.1/Ocp1LiteNetworkSystemInterfaceID.h>
#include "../common/workers/ConcreteGainActuator.h"
#include "../common/workers/ConcreteMuteActuator.h"
#include "../common/workers/ConcreteSwitchActuator.h"
#include "../common/workers/ZoneGroup.h"
#include "OcaLiteControllerConfigManager.h"
#include "../common/FusionOCAConstants.h" // For custom ONO constants
#include "Observer.h"                     // Add the UDP JSON Observer
#include "../common/models/ControlSystemConfigParser.h"
#include "../common/UDPSender.h"         // UDP JSON sender
#include "../common/FusionAudioBridge.h" // Centralized Fusion communication

#ifdef OCA_RUN
extern void Ocp1LiteServiceRun();
#else
extern void Ocp1LiteServiceRunWithFdSet(fd_set *readSet);
extern int Ocp1LiteServiceGetSocket();
#endif

// Global pointer to manage the UDP observer lifecycle
std::unique_ptr<UDPValueMonitor> g_udpObserver;

// Global state for main loop control
static bool g_bSuccess = false;

// Global state for configuration updates
static std::mutex g_configUpdateMutex;
static std::string g_pendingConfigJson;
static bool g_configUpdatePending = false;
static ::Ocp1LiteNetwork *g_ocp1Network = nullptr;

// Global connection port storage
static unsigned int g_connectionPort = 65000;

// Global object tracking for configuration management (shared with FusionAudioBridge)
static std::shared_ptr<std::map<std::string, std::vector<::OcaONo>>> g_objectTracker = std::make_shared<std::map<std::string, std::vector<::OcaONo>>>();

// Function declarations
bool InitializeHostInterfaces();
bool InitializeOCAManagers();
bool ApplyZoneConfiguration(const Json::Value &configJson);
::Ocp1LiteNetwork *SetupOCP1Network(unsigned int connectionPort);
bool StartOCAServices(::Ocp1LiteNetwork *ocp1Network);
void RunMainLoop();
bool InitializeFusionAudioBridge(const std::string &serverIP, unsigned int serverPort);
void HandleConfigurationUpdate(const Json::Value &newConfig);
void HandleAudioSettingsUpdate(const Json::Value &newSettings);
bool ValidateConfigurationJson(const Json::Value &config);
bool ProcessPendingConfigurationUpdate();
bool TeardownCurrentConfiguration();
bool RebuildConfiguration(const Json::Value &configJson);
void RemoveZoneObjectsFromRootBlock();
void BuildObjectTracker(const ControlSystemConfig &config);
void ClearObjectTracker();
void ShutdownFusionAudioBridge();
bool StartOCAServicesWithExponentialBackoff(::Ocp1LiteNetwork *ocp1Network);

int main(int argc, const char *argv[])
{
    unsigned int connectionPort = 65000;
    if (argc > 1)
    {
        static_cast<void>(sscanf(argv[1], "%u", &connectionPort));
    }
    OCA_LOG_INFO_PARAMS("Using connection port %d", connectionPort);

    // Store connection port globally for configuration updates
    g_connectionPort = connectionPort;

    // Set log level to show INFO messages (including client connection logs)
    ::OcfLiteLogSetLogLevel(OCA_LOG_LVL_TRACE);

    // Initialize the host interfaces
    g_bSuccess = InitializeHostInterfaces();
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ Host interface initialization failed");
        return -1;
    }

    // Initialize Oca Device
    static_cast<void>(::OcaLiteBlock::GetRootBlock());

    // Start with hardcoded configuration as fallback
    // UDP observer will update this when available

    Json::Value zonesJson;
    Json::Reader reader;
    if (!reader.parse(ZONES_JSON_STRING_FOR_DEV, zonesJson))
    {
        OCA_LOG_ERROR_PARAMS("Failed to parse hardcoded JSON: %s", reader.getFormattedErrorMessages().c_str());
        return -1;
    }

    // Initialize OCA managers
    g_bSuccess = InitializeOCAManagers();
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ OCA managers initialization failed");
        return -1;
    }

    // Setup OCP1 network
    g_ocp1Network = SetupOCP1Network(connectionPort);
    if (!g_ocp1Network)
    {
        OCA_LOG_ERROR("✗ OCP1 network setup failed");
        return -1;
    }
    // Apply zone configuration
    g_bSuccess = ApplyZoneConfiguration(zonesJson);
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ Zone configuration failed");
        return -1;
    }

    // Start OCA services
    g_bSuccess = StartOCAServices(g_ocp1Network);
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ OCA services startup failed");
        return -1;
    }

    // Initialize FusionAudioBridge for centralized Fusion communication
    g_bSuccess = InitializeFusionAudioBridge("192.168.0.19", 7947);
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ FusionAudioBridge initialization failed");
        // Continue without Fusion communication
        g_bSuccess = true;
    }

    // Run main loop
    RunMainLoop();

    // Clean up Fusion components before exit
    ShutdownFusionAudioBridge();

    return 0;
}

/**
 * @brief Main execution loop
 */
void RunMainLoop()
{
    OCA_LOG_INFO("Starting run loop..");

    while (g_bSuccess)
    {
        // Process any pending configuration updates
        if (!ProcessPendingConfigurationUpdate())
        {
            OCA_LOG_ERROR("Configuration update failed - continuing with current config");
        }

#ifdef OCA_RUN
        ::OcaLiteCommandHandler::GetInstance().RunWithTimeout(1000);
        Ocp1LiteServiceRun();
#else
        int highestFd(-1);
        fd_set readset;
        fd_set writeset;
        fd_set exceptset;
        FD_ZERO(&readset);
        FD_ZERO(&writeset);
        FD_ZERO(&exceptset);

        bool bShortSelect(::OcaLiteCommandHandler::GetInstance().AddSelectables(highestFd, readset, writeset, exceptset));

        int serviceFd(Ocp1LiteServiceGetSocket());
        if (-1 != serviceFd)
        {
            FD_SET(serviceFd, &readset);
            if (highestFd < serviceFd)
            {
                highestFd = serviceFd;
            }
        }

        timeval timeout = {bShortSelect ? 1 : 0, 0};
        select(highestFd + 1, &readset, &writeset, &exceptset, &timeout);

        ::OcaLiteCommandHandler::GetInstance().RunWithSelectSet(readset, writeset, exceptset);
        if (FD_ISSET(serviceFd, &readset))
        {
            Ocp1LiteServiceRunWithFdSet(&readset);
        }
#endif
    }

    OCA_LOG_INFO("Main loop terminated");
}

/**
 * @brief Initialize host interfaces
 * @return true if initialization successful, false otherwise
 */
bool InitializeHostInterfaces()
{
    bool success = ::OcfLiteHostInterfaceInitialize();
    success = success && ::Ocp1LiteHostInterfaceInitialize();

    if (success)
    {
        OCA_LOG_INFO("✓ Host interfaces initialized successfully");
    }
    else
    {
        OCA_LOG_ERROR("✗ Failed to initialize host interfaces");
    }
    return success;
}

/**
 * @brief Initialize all OCA managers
 * @return true if initialization successful, false otherwise
 */
bool InitializeOCAManagers()
{
    bool success = static_cast<bool>(::OcaLiteNetworkManager::GetInstance().Initialize());
    success = success && static_cast<bool>(::OcaLiteSubscriptionManager::GetInstance().SetNrEvents(1 /*OCA_NR_EVENTS*/));
    success = success && static_cast<bool>(::OcaLiteSubscriptionManager::GetInstance().Initialize());
    success = success && static_cast<bool>(::OcaLiteDeviceManager::GetInstance().Initialize());
    success = success && static_cast<bool>(::OcaLiteFirmwareManager::GetInstance().Initialize());
    success = success && static_cast<bool>(::OcaLiteControllerConfigManager::GetInstance().Initialize());

    if (success)
    {
        OCA_LOG_INFO("✓ OCA managers initialized successfully");
    }
    else
    {
        OCA_LOG_ERROR("✗ Failed to initialize OCA managers");
    }

    return success;
}

/**
 * @brief Setup OCP1 network
 * @param connectionPort Port number for the network connection
 * @return Pointer to created network or nullptr on failure
 */
::Ocp1LiteNetwork *SetupOCP1Network(unsigned int connectionPort)
{

    Ocp1LiteNetworkSystemInterfaceID interfaceId = ::Ocp1LiteNetworkSystemInterfaceID(static_cast<::OcaUint32>(0));
    std::vector<std::string> txtRecords;
    txtRecords.push_back("modelGUID=DEADBEEFEATERS");
    ::OcaLiteString nodeId = ::OcaLiteString("OCALite@" + OcfLiteConfigureGetDeviceName());

    ::Ocp1LiteNetwork *ocp1Network = new ::Ocp1LiteNetwork(
        static_cast<::OcaONo>(OCP_NETWORK_ONO),
        static_cast<::OcaBoolean>(true),
        ::OcaLiteString("Ocp1LiteNetwork"),
        ::Ocp1LiteNetworkNodeID(nodeId),
        interfaceId,
        txtRecords,
        ::OcaLiteString("local"),
        (OcaUint16)connectionPort);

    if (ocp1Network->Initialize())
    {
        if (::OcaLiteBlock::GetRootBlock().AddObject(*ocp1Network))
        {
            OCA_LOG_INFO_PARAMS("✓ OCP1 network setup successful on port %u...", connectionPort);
            return ocp1Network;
        }
        else
        {
            OCA_LOG_ERROR("✗ Failed to add OCP1 network to root block");
            delete ocp1Network;
            return nullptr;
        }
    }
    else
    {
        OCA_LOG_ERROR("✗ Failed to initialize OCP1 network");
        delete ocp1Network;
        return nullptr;
    }
}

/**
 * @brief Start OCA services
 * @param ocp1Network Pointer to the OCP1 network
 * @return true if services started successfully, false otherwise
 */
bool StartOCAServices(::Ocp1LiteNetwork *ocp1Network)
{
    OCA_LOG_INFO("Starting OCA services...");

    if (!ocp1Network)
    {
        OCA_LOG_ERROR("✗ Invalid network pointer");
        return false;
    }

    OcaLiteStatus rc(ocp1Network->Startup());
    if (OCASTATUS_OK == rc)
    {
        bool success = ::OcaLiteCommandHandler::GetInstance().Initialize();
        ::OcaLiteDeviceManager::GetInstance().SetErrorAndOperationalState(
            static_cast<::OcaBoolean>(!success),
            ::OcaLiteDeviceManager::OCA_OPSTATE_OPERATIONAL);
        ::OcaLiteDeviceManager::GetInstance().SetEnabled(static_cast<::OcaBoolean>(success));

        if (success)
        {
            OCA_LOG_INFO("✓ OCA services started successfully");
        }
        else
        {
            OCA_LOG_ERROR("✗ Failed to initialize command handler");
        }

        return success;
    }
    else
    {
        OCA_LOG_ERROR("✗ Failed to startup OCP1 network");
        return false;
    }
}

bool StartOCAServicesWithExponentialBackoff(::Ocp1LiteNetwork *ocp1Network)
{
    const int maxRetries = 15;
    int retryCount = 0;

    while (retryCount < maxRetries)
    {
        OCA_LOG_INFO_PARAMS("Attempting to restart OCA services (Attempt %d/%d)...",
                            retryCount + 1, maxRetries);

        // Try to restart the OCA services
        if (StartOCAServices(ocp1Network))
        {
            OCA_LOG_INFO("✓ OCA services restarted successfully");
            return true;
        }

        OCA_LOG_ERROR("Failed to restart OCA services");

        // Exponential backoff
        int backoffTime = (1 << retryCount) * 1000; // 2^retryCount * 1000 ms
        OCA_LOG_INFO_PARAMS("Waiting %d ms before retrying...", backoffTime);
        std::this_thread::sleep_for(std::chrono::milliseconds(backoffTime));

        retryCount++;
    }

    OCA_LOG_ERROR("✗ All attempts to restart OCA services failed");
    return false;
}

/**
 * @brief Initialize FusionAudioBridge for centralized Fusion communication
 * @param serverIP Fusion server IP address
 * @param serverPort Fusion server port
 * @return true if bridge initialized successfully, false otherwise
 */
bool InitializeFusionAudioBridge(const std::string &serverIP, unsigned int serverPort)
{
    try
    {
        // Initialize the FusionAudioBridge singleton
        FusionAudioBridge &bridge = FusionAudioBridge::getInstance();

        bool success = bridge.initialize(serverIP, serverPort, g_objectTracker);
        if (!success)
        {
            OCA_LOG_ERROR("✗ Failed to initialize FusionAudioBridge");
            return false;
        }

        // Only setup UDP observer if it doesn't already exist (preserve during config updates)
        if (!g_udpObserver)
        {
            // Setup UDP observer for configuration and audio updates
            g_udpObserver = std::unique_ptr<UDPValueMonitor>(new UDPValueMonitor(
                serverIP,
                serverPort,
                false)); // verbose = false

            OCA_LOG_INFO_PARAMS("✓ UDP Observer started - monitoring from %s:%u", serverIP.c_str(), serverPort);

            // Watch for configuration updates (both initial and ongoing)
            g_udpObserver->watch("wall_controller_config", [](const std::string &path,
                                                              const Json::Value &oldVal,
                                                              const Json::Value &newVal)
                                 { 
                                     OCA_LOG_INFO_PARAMS("Configuration update received at %s", path.c_str());
                                    OCA_LOG_INFO_PARAMS("Configuration update from %s to %s", oldVal.toStyledString().c_str(), newVal.toStyledString().c_str());

                                     HandleConfigurationUpdate(newVal); });

            // Watch for audio settings updates - use FusionAudioBridge for processing
            g_udpObserver->watch("settings.audio", [](const std::string &path,
                                                      const Json::Value &oldVal,
                                                      const Json::Value &newVal)
                                 { 
                                     OCA_LOG_INFO_PARAMS("Audio settings update received at %s oldValue: %s, newValue: %s", path.c_str(), oldVal.toStyledString().c_str(), newVal.toStyledString().c_str());
                                     HandleAudioSettingsUpdate(newVal); });
        }
        else
        {
            OCA_LOG_INFO("UDP Observer already running - preserved during configuration update");
        }

        OCA_LOG_INFO("✓ FusionAudioBridge initialized successfully");
        return true;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("✗ Failed to initialize FusionAudioBridge: %s", e.what());
        return false;
    }
}

/**
 * @brief Handle configuration updates from UDP
 * @param newConfig New configuration JSON
 */
void HandleConfigurationUpdate(const Json::Value &newConfig)
{
    // Add 10-second delay to allow system stabilization
    OCA_LOG_INFO("Waiting 10 seconds before processing configuration update...");
    std::this_thread::sleep_for(std::chrono::seconds(10));

    // Input Validation
    if (newConfig.isNull() || !newConfig.isObject())
    {
        OCA_LOG_ERROR("Invalid configuration JSON received - not an object");
        return;
    }

    // Full Configuration Validation
    if (!ValidateConfigurationJson(newConfig))
    {
        OCA_LOG_ERROR("Configuration validation failed - rejecting update");
        return;
    }

    // JSON Serialization for safe storage
    Json::StreamWriterBuilder builder;
    builder["indentation"] = ""; // Compact format
    std::string configString = Json::writeString(builder, newConfig);

    // Thread-safe queuing of configuration update
    std::lock_guard<std::mutex> lock(g_configUpdateMutex);

    if (g_configUpdatePending)
    {
        OCA_LOG_INFO("Configuration update already pending, replacing with newer version");
    }

    g_pendingConfigJson = configString;
    g_configUpdatePending = true;

    OCA_LOG_INFO("Configuration update queued for main thread processing");
}

/**
 * @brief Handle audio settings updates from UDP
 * @param newSettings New audio settings JSON
 */
void HandleAudioSettingsUpdate(const Json::Value &newSettings)
{
    OCA_LOG_INFO("Processing audio settings update...");

    try
    {
        // Validate that newSettings is an object
        if (!newSettings.isObject())
        {
            OCA_LOG_ERROR("Audio settings must be a JSON object - discarding message");
            return;
        }

        // Iterate through all gain settings in the audio settings
        for (const auto &gainID : newSettings.getMemberNames())
        {
            const Json::Value &gainSettings = newSettings[gainID];

            // Validate that each gain setting is an object with a "gain" property
            if (!gainSettings.isObject() || !gainSettings.isMember("gain"))
            {
                OCA_LOG_WARNING_PARAMS("Gain setting for '%s' missing 'gain' property - skipping", gainID.c_str());
                continue;
            }

            // Extract the gain value
            const Json::Value &gainValueJson = gainSettings["gain"];
            if (!gainValueJson.isNumeric())
            {
                OCA_LOG_WARNING_PARAMS("Gain value for '%s' is not numeric - skipping", gainID.c_str());
                continue;
            }

            double gainValue = gainValueJson.asDouble();

            OCA_LOG_INFO_PARAMS("Processing gain update: %s = %.6f dB", gainID.c_str(), gainValue);

            // Process the gain update via FusionAudioBridge
            FusionAudioBridge &bridge = FusionAudioBridge::getInstance();
            if (bridge.isInitialized())
            {
                bridge.handleFusionGainUpdate(gainID, gainValue);
            }
            else
            {
                OCA_LOG_WARNING("FusionAudioBridge not initialized - discarding gain update");
            }
        }

        OCA_LOG_INFO("Audio settings update processing completed");
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("Exception during audio settings update: %s", e.what());
    }
    catch (...)
    {
        OCA_LOG_ERROR("Unknown exception during audio settings update");
    }
}

/**
 * @brief Comprehensive validation of configuration JSON
 * @param config JSON configuration to validate
 * @return true if valid, false otherwise
 */
bool ValidateConfigurationJson(const Json::Value &config)
{
    // JSON Structure Validation
    if (!config.isObject())
    {
        OCA_LOG_ERROR("Configuration must be a JSON object");
        return false;
    }

    if (!config.isMember("zones") || !config["zones"].isArray())
    {
        OCA_LOG_ERROR("Configuration must contain 'zones' array");
        return false;
    }

    if (!config.isMember("controllers") || !config["controllers"].isArray())
    {
        OCA_LOG_ERROR("Configuration must contain 'controllers' array");
        return false;
    }

    const Json::Value &zones = config["zones"];
    const Json::Value &controllers = config["controllers"];

    // Zone Validation
    std::set<std::string> zoneIds;
    std::set<int> usedOnos;

    for (const auto &zone : zones)
    {
        if (!zone.isObject())
        {
            OCA_LOG_ERROR("Each zone must be a JSON object");
            return false;
        }

        // Check required zone fields
        const std::vector<std::string> requiredZoneFields = {"id", "name", "ono", "gain", "sources"};
        for (const auto &field : requiredZoneFields)
        {
            if (!zone.isMember(field))
            {
                OCA_LOG_ERROR_PARAMS("Zone missing required field: %s", field.c_str());
                return false;
            }
        }

        // Validate zone ID uniqueness
        std::string zoneId = zone["id"].asString();
        if (zoneIds.count(zoneId))
        {
            OCA_LOG_ERROR_PARAMS("Duplicate zone ID found: %s", zoneId.c_str());
            return false;
        }
        zoneIds.insert(zoneId);

        // Validate ONO structure and uniqueness
        const Json::Value &ono = zone["ono"];
        if (!ono.isObject())
        {
            OCA_LOG_ERROR_PARAMS("Zone '%s' ONO must be an object", zoneId.c_str());
            return false;
        }

        const std::vector<std::string> requiredOnoFields = {"zone", "gain", "mute", "sourceSelector"};
        for (const auto &field : requiredOnoFields)
        {
            if (!ono.isMember(field) || !ono[field].isInt())
            {
                OCA_LOG_ERROR_PARAMS("Zone '%s' ONO missing or invalid field: %s", zoneId.c_str(), field.c_str());
                return false;
            }

            int onoValue = ono[field].asInt();
            if (usedOnos.count(onoValue))
            {
                OCA_LOG_ERROR_PARAMS("Duplicate ONO value found: %d in zone '%s'", onoValue, zoneId.c_str());
                return false;
            }
            usedOnos.insert(onoValue);
        }

        // Validate gain structure
        const Json::Value &gain = zone["gain"];
        if (!gain.isObject())
        {
            OCA_LOG_ERROR_PARAMS("Zone '%s' gain must be an object", zoneId.c_str());
            return false;
        }

        const std::vector<std::string> requiredGainFields = {"gainID", "min_value", "max_value", "default_gain_value", "default_mute_value"};
        for (const auto &field : requiredGainFields)
        {
            if (!gain.isMember(field))
            {
                OCA_LOG_ERROR_PARAMS("Zone '%s' gain missing required field: %s", zoneId.c_str(), field.c_str());
                return false;
            }
        }

        // Validate sources array
        const Json::Value &sources = zone["sources"];
        if (!sources.isArray() || sources.size() == 0)
        {
            OCA_LOG_ERROR_PARAMS("Zone '%s' must have a non-empty sources array", zoneId.c_str());
            return false;
        }

        for (const auto &source : sources)
        {
            if (!source.isObject() || !source.isMember("index") || !source.isMember("label"))
            {
                OCA_LOG_ERROR_PARAMS("Zone '%s' source must have 'index' and 'label' fields", zoneId.c_str());
                return false;
            }
        }
    }

    // Controller Validation
    std::set<std::string> controllerIds;
    for (const auto &controller : controllers)
    {
        if (!controller.isObject())
        {
            OCA_LOG_ERROR("Each controller must be a JSON object");
            return false;
        }

        // Check required controller fields
        const std::vector<std::string> requiredControllerFields = {"id", "name", "zoneIds"};
        for (const auto &field : requiredControllerFields)
        {
            if (!controller.isMember(field))
            {
                OCA_LOG_ERROR_PARAMS("Controller missing required field: %s", field.c_str());
                return false;
            }
        }

        // Validate controller ID uniqueness
        std::string controllerId = controller["id"].asString();
        if (controllerIds.count(controllerId))
        {
            OCA_LOG_ERROR_PARAMS("Duplicate controller ID found: %s", controllerId.c_str());
            return false;
        }
        controllerIds.insert(controllerId);

        // Validate zone references
        const Json::Value &controllerZoneIds = controller["zoneIds"];
        if (!controllerZoneIds.isArray())
        {
            OCA_LOG_ERROR_PARAMS("Controller '%s' zoneIds must be an array", controllerId.c_str());
            return false;
        }

        for (const auto &zoneIdRef : controllerZoneIds)
        {
            std::string referencedZoneId = zoneIdRef.asString();
            if (!zoneIds.count(referencedZoneId))
            {
                OCA_LOG_ERROR_PARAMS("Controller '%s' references non-existent zone: %s",
                                     controllerId.c_str(), referencedZoneId.c_str());
                return false;
            }
        }
    }

    OCA_LOG_INFO_PARAMS("✓ Configuration validation successful - %zu zones, %zu controllers",
                        zones.size(), controllers.size());
    return true;
}

/**
 * @brief Build object tracker map from ControlSystemConfig
 * @param config ControlSystemConfig to extract object mappings from
 */
void BuildObjectTracker(const ControlSystemConfig &config)
{
    OCA_LOG_INFO("Building object tracker map from configuration...");

    g_objectTracker->clear();

    for (const auto &zonePtr : config.zones)
    {
        if (!zonePtr)
            continue; // Skip null pointers

        const Zone &zone = *zonePtr;

        // Extract zone information
        std::string zoneId = zone.id;
        std::string gainId = zone.gain.gainID;

        // Extract ONOs from zone
        ::OcaONo gainOno = static_cast<::OcaONo>(zone.ono.gain);
        ::OcaONo muteOno = static_cast<::OcaONo>(zone.ono.mute);
        ::OcaONo switchOno = static_cast<::OcaONo>(zone.ono.sourceSelector);

        // Map gainID to gain and mute ONOs
        (*g_objectTracker)[gainId] = {gainOno, muteOno};

        // Map zoneID to switch ONO
        (*g_objectTracker)[zoneId] = {switchOno};

        OCA_LOG_INFO_PARAMS("Tracked objects - GainID '%s': [%u, %u], ZoneID '%s': [%u]",
                            gainId.c_str(), gainOno, muteOno, zoneId.c_str(), switchOno);
    }

    OCA_LOG_INFO_PARAMS("✓ Object tracker built with %zu entries", g_objectTracker->size());
}

/**
 * @brief Clear the object tracker map
 */
void ClearObjectTracker()
{
    g_objectTracker->clear();
    OCA_LOG_INFO("Object tracker cleared");
}

/**
 * @brief Remove all zone-related objects from root block using object tracker
 */
/**
 * @brief Remove all zone-related objects from root block using object tracker
 */
void RemoveZoneObjectsFromRootBlock()
{
    OCA_LOG_INFO("Removing zone objects from root block using object tracker...");

    if (g_objectTracker->empty())
    {
        OCA_LOG_WARNING("Object tracker is empty - falling back to range-based removal");

        // Fallback to the old method if tracker is empty
        ::OcaLiteList<::OcaLiteObjectIdentification> members;
        if (OCASTATUS_OK == ::OcaLiteBlock::GetRootBlock().GetMembers(members))
        {
            for (::OcaUint16 i = 0; i < members.GetCount(); i++)
            {
                const ::OcaLiteObjectIdentification &member = members.GetItem(i);
                ::OcaONo memberONo = member.GetONo();

                // Remove zone-related objects (zones typically have ONOs in custom ranges)
                // Skip system objects (ONOs < 1000) and network objects
                if (memberONo >= 1000 && memberONo <= 9999) // Zone ONO range from our config
                {
                    OCA_LOG_INFO_PARAMS("Removing zone object with ONO: %u", memberONo);
                    ::OcaLiteBlock::GetRootBlock().RemoveObject(memberONo);
                }
            }
        }
        else
        {
            OCA_LOG_WARNING("Failed to get members list from root block");
        }
        return;
    }

    // Use object tracker for precise removal
    for (const auto &entry : *g_objectTracker)
    {
        const std::string &identifier = entry.first;
        const std::vector<::OcaONo> &onos = entry.second;

        OCA_LOG_INFO_PARAMS("Removing objects for identifier '%s':", identifier.c_str());

        for (::OcaONo ono : onos)
        {
            OCA_LOG_INFO_PARAMS("  Removing object with ONO: %u", ono);
            ::OcaLiteBlock::GetRootBlock().RemoveObject(ono);
        }
    }

    // Also remove the root zone container
    OCA_LOG_INFO_PARAMS("Removing root zone container with ONO: %u", ROOT_ZONE_CONTAINER_ONO);
    ::OcaLiteBlock::GetRootBlock().RemoveObject(ROOT_ZONE_CONTAINER_ONO);

    OCA_LOG_INFO("✓ Object tracker-based removal completed");
}

/**
 * @brief Teardown current OCA configuration safely
 * @return true if successful, false otherwise
 */
bool TeardownCurrentConfiguration()
{
    OCA_LOG_INFO("Starting configuration teardown...");

    // 1. Set device to shutting down state FIRST (required for object removal)
    OCA_LOG_INFO("Setting device to shutting down state...");
    ::OcaLiteDeviceManager::GetInstance().SetErrorAndOperationalState(
        static_cast<::OcaBoolean>(false),
        ::OcaLiteDeviceManager::OCA_OPSTATE_SHUTTING_DOWN);

    // Allow time for shutdown notification to be sent to connected clients
    OCA_LOG_INFO("Waiting 1 second for shutdown notification to be sent...");
    std::this_thread::sleep_for(std::chrono::seconds(2));

    // 2. Shutdown Command Handler
    OCA_LOG_INFO("Shutting down command handler...");
    ::OcaLiteCommandHandler::GetInstance().Shutdown();

    // // 2. Shutdown Subscription Manager
    // OCA_LOG_INFO("Shutting down subscription manager...");
    // ::OcaLiteSubscriptionManager::GetInstance().Shutdown();

    // 3. Shutdown and Teardown Network
    if (g_ocp1Network)
    {
        OCA_LOG_INFO("Shutting down OCP1 network...");

        ::OcaONo networkONo = g_ocp1Network->GetObjectNumber();
        ::OcaLiteStatus shutdownStatus = g_ocp1Network->Shutdown();
        if (OCASTATUS_OK != shutdownStatus)
        {
            OCA_LOG_WARNING_PARAMS("Network shutdown returned status: %u", shutdownStatus);
        }

        g_ocp1Network->Teardown();

        // Remove from root block
        ::OcaLiteBlock::GetRootBlock().RemoveObject(networkONo);

        // Clean up network object
        delete g_ocp1Network;
        g_ocp1Network = nullptr;

        OCA_LOG_INFO("✓ OCP1 network torn down successfully");
    }
    else
    {
        OCA_LOG_WARNING("No OCP1 network to teardown");
    }

    // 4. Clear Controller Configuration
    OCA_LOG_INFO("Clearing controller configuration...");
    ::OcaLiteControllerConfigManager::GetInstance().ClearConfigData();

    // 5. Remove Zone Objects
    RemoveZoneObjectsFromRootBlock();

    // 6. Clear Object Tracker
    ClearObjectTracker();

    OCA_LOG_INFO("✓ Configuration teardown completed");
    return true;
}

/**
 * @brief Stop and cleanup FusionAudioBridge and UDP Observer
 */
void ShutdownFusionAudioBridge()
{
    // Shutdown FusionAudioBridge
    FusionAudioBridge &bridge = FusionAudioBridge::getInstance();
    bridge.shutdown();
    OCA_LOG_INFO("FusionAudioBridge shutdown complete");

    // Shutdown UDP Observer - only during final shutdown
    if (g_udpObserver)
    {
        OCA_LOG_INFO("Stopping UDP Observer...");
        g_udpObserver->stop();
        g_udpObserver.reset();
    }
}

/**
 * @brief Apply zone configuration from JSON
 * @param configJson JSON configuration value
 * @return true if configuration applied successfully, false otherwise
 */
bool ApplyZoneConfiguration(const Json::Value &configJson)
{
    OCA_LOG_INFO("Applying zone configuration...");

    // TODO: Validate JSON configuration
    // TODO: What to do if configuration is invalid - Option integrate with telemetry core and raise a alarm

    ControlSystemConfig config = MakeControlSystemModelFromJson(configJson);

    // Build object tracker from parsed configuration
    BuildObjectTracker(config);

    auto zoneContainer = MakeZoneGroupFromControlSystemConfig(config);
    if (zoneContainer)
    {
        // Add the zone container to the root block
        if (::OcaLiteBlock::GetRootBlock().AddObject(*zoneContainer))
        {
            OCA_LOG_INFO("✓ Zone configuration applied successfully");
            zoneContainer.release(); // OCA now owns it

            // Get controllers from config and set them in the config manager
            if (!config.controllers.empty())
            {
                ::OcaLiteControllerConfigManager::GetInstance().SetConfigData(config.controllers);
            }
            else
            {
                OCA_LOG_WARNING("No controllers found in configuration");
            }

            return true;
        }
        else
        {
            OCA_LOG_ERROR("✗ Failed to add zone container to root block");
            return false;
        }
    }
    else
    {
        OCA_LOG_ERROR("✗ Failed to create zone container");
        return false;
    }
}

/**
 * @brief Rebuild OCA configuration with new JSON
 * @param configJson New configuration JSON value
 * @return true if successful, false otherwise
 */
bool RebuildConfiguration(const Json::Value &configJson)
{
    OCA_LOG_INFO("Rebuilding configuration with new JSON...");

    // 1. Set device to INITIALIZING state for object creation
    OCA_LOG_INFO("Setting device to INITIALIZING state for configuration rebuild...");
    ::OcaLiteDeviceManager::GetInstance().SetErrorAndOperationalState(
        static_cast<::OcaBoolean>(false),
        ::OcaLiteDeviceManager::OCA_OPSTATE_INITIALIZING);

    // 2. Re-setup OCP1 Network
    OCA_LOG_INFO("Re-setting up OCP1 network...");

    // Add a small delay to ensure socket is fully released
    OCA_LOG_INFO("Waiting 2 seconds for socket cleanup...");
    std::this_thread::sleep_for(std::chrono::seconds(2));

    g_ocp1Network = SetupOCP1Network(g_connectionPort);
    if (!g_ocp1Network)
    {
        OCA_LOG_ERROR("Failed to re-setup OCP1 network");
        return false;
    }

    // 3. Apply Zone Configuration
    OCA_LOG_INFO("Applying new zone configuration...");
    if (!ApplyZoneConfiguration(configJson))
    {
        OCA_LOG_ERROR("Failed to apply new zone configuration");
        return false;
    }

    // 4. Update Device Manager State (CRITICAL - must restore operational state)
    OCA_LOG_INFO("Updating device manager state to OPERATIONAL...");
    ::OcaLiteDeviceManager::GetInstance().SetErrorAndOperationalState(
        static_cast<::OcaBoolean>(false),
        ::OcaLiteDeviceManager::OCA_OPSTATE_OPERATIONAL);
    ::OcaLiteDeviceManager::GetInstance().SetEnabled(static_cast<::OcaBoolean>(true));

    // 5. Restart Command Handler
    OCA_LOG_INFO("Reinitializing command handler...");
    if (!::OcaLiteCommandHandler::GetInstance().Initialize())
    {
        OCA_LOG_ERROR("Failed to reinitialize command handler");
        return false;
    }

    // 6. Start OCA Services
    if (!StartOCAServicesWithExponentialBackoff(g_ocp1Network))
    {
        OCA_LOG_ERROR("Failed to start OCA services");
        return false;
    }

    OCA_LOG_INFO("✓ Configuration rebuild completed successfully");
    return true;
}

/**
 * @brief Process pending configuration update on main thread
 * @return true if successful, false otherwise
 */
bool ProcessPendingConfigurationUpdate()
{
    std::string configJson;

    // Check if there's a pending update
    {
        std::lock_guard<std::mutex> lock(g_configUpdateMutex);
        if (!g_configUpdatePending)
        {
            return true; // No update pending
        }

        configJson = g_pendingConfigJson;
        g_configUpdatePending = false;
        g_pendingConfigJson.clear();
    }

    OCA_LOG_INFO("Processing configuration update on main thread");

    // Parse JSON to validate structure
    Json::Value config;
    Json::Reader reader;
    if (!reader.parse(configJson, config))
    {
        OCA_LOG_ERROR_PARAMS("Failed to parse queued configuration JSON: %s",
                             reader.getFormattedErrorMessages().c_str());
        return false;
    }

    // Teardown current configuration
    if (!TeardownCurrentConfiguration())
    {
        OCA_LOG_ERROR("Failed to teardown current configuration");
        return false;
    }
    std::this_thread::sleep_for(std::chrono::seconds(2));
    // Small delay to ensure full cleanup
    // Rebuild with new configuration
    if (!RebuildConfiguration(config))
    {
        OCA_LOG_ERROR("Failed to rebuild configuration");
        return false;
    }

    OCA_LOG_INFO("✓ Configuration update completed successfully");
    return true;
}