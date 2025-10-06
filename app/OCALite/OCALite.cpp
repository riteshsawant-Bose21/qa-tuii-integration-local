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
#ifndef UDP
#include <OCP.1/Ocp1LiteNetwork.h>
#else
#include <OCP.1/Ocp1LiteUdpNetwork.h>
#endif
#include <OCP.1/Ocp1LiteNetworkSystemInterfaceID.h>
#include "workers/ConcreteGainActuator.h"
#include "workers/ConcreteMuteActuator.h"
#include "workers/ConcreteSwitchActuator.h"
#include "workers/ZoneGroup.h"
#include "ZoneConfigBuilder.h"
#include "OcaLiteControllerConfigManager.h"
#include "../common/FusionOCAConstants.h" // For custom ONO constants
#include "Observer.h"                     // Add the UDP JSON Observer

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

// Function declarations
bool InitializeHostInterfaces();
bool InitializeOCAManagers();
bool ApplyZoneConfiguration(const std::string &configJson);
::Ocp1LiteNetwork *SetupOCP1Network(unsigned int connectionPort);
bool StartOCAServices(::Ocp1LiteNetwork *ocp1Network);
void RunMainLoop();
bool SetupUDPWatchers(const std::string &serverIP, unsigned int serverPort);
void HandleConfigurationUpdate(const Json::Value &newConfig);
void HandleAudioSettingsUpdate(const Json::Value &newSettings);

/**
 * @brief Stop and cleanup UDP Observer
 */
void ShutdownUDPObserver()
{
    if (g_udpObserver)
    {
        OCA_LOG_INFO("Stopping UDP Observer...");
        g_udpObserver->stop();
        g_udpObserver.reset();
    }
}

/**
 * @brief Initialize host interfaces
 * @return true if initialization successful, false otherwise
 */
bool InitializeHostInterfaces()
{
    OCA_LOG_INFO("Initializing host interfaces...");
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
    OCA_LOG_INFO("Initializing OCA managers...");
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
 * @brief Apply zone configuration from JSON
 * @param configJson JSON configuration string
 * @return true if configuration applied successfully, false otherwise
 */
bool ApplyZoneConfiguration(const std::string &configJson)
{
    OCA_LOG_INFO("Applying zone configuration...");

    // TODO: Validate JSON configuration
    // TODO: What to do if configuration is invalid - Option integrate with telemetry core and raise a alarm

    BuiltZones bz = BuildZonesFromJson(configJson.c_str(), ROOT_ZONE_CONTAINER_ONO);
    if (bz.zonesContainer)
    {
        ZoneGroup *rootZone = bz.zonesContainer.get();
        if (::OcaLiteBlock::GetRootBlock().AddObject(*rootZone))
        {
            OCA_LOG_INFO_PARAMS("✓ Zones container (JSON) added (Object #%u) with %zu inner zone groups",
                                ROOT_ZONE_CONTAINER_ONO, bz.zones.size());
            bz.zonesContainer.release();

            // Build controllers from JSON and set them in the config manager
            std::vector<Controller> controllers = BuildControllersFromMetadataJson(configJson.c_str());
            if (!controllers.empty())
            {
                ::OcaLiteControllerConfigManager::GetInstance().SetConfigData(controllers);
                return true;
            }
            else
            {
                OCA_LOG_ERROR("✗ Failed to parse controllers from JSON");
                return false;
            }
        }
        else
        {
            OCA_LOG_ERROR("✗ Failed to add JSON Zones container to root (possible duplicate?)");
            return false;
        }
    }
    else
    {
        OCA_LOG_ERROR("✗ Failed to build zones from JSON");
        return false;
    }
}

/**
 * @brief Setup OCP1 network
 * @param connectionPort Port number for the network connection
 * @return Pointer to created network or nullptr on failure
 */
::Ocp1LiteNetwork *SetupOCP1Network(unsigned int connectionPort)
{
    OCA_LOG_INFO_PARAMS("Setting up OCP1 network on port %u...", connectionPort);

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
            OCA_LOG_INFO("✓ OCP1 network setup successful");
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

/**
 * @brief Main execution loop
 */
void RunMainLoop()
{
    OCA_LOG_INFO("Starting main loop...");
    OCA_LOG_ERROR("Starting run loop..");

    while (g_bSuccess)
    {
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
 * @brief Setup UDP watchers for configuration and audio settings
 * @param serverIP UDP server IP address
 * @param serverPort UDP server port
 * @return true if watchers setup successfully, false otherwise
 */
bool SetupUDPWatchers(const std::string &serverIP, unsigned int serverPort)
{
    OCA_LOG_INFO("Setting up UDP watchers...");

    try
    {
        g_udpObserver = std::unique_ptr<UDPValueMonitor>(new UDPValueMonitor(
            serverIP,
            serverPort,
            false)); // verbose = false

        OCA_LOG_INFO_PARAMS("✓ UDP Observer started - monitoring from %s:%u", serverIP.c_str(), serverPort);

        // Watch for configuration updates
        g_udpObserver->watch("wall_controller_config", [](const std::string &path,
                                                          const Json::Value &oldVal,
                                                          const Json::Value &newVal)
                             { 
                                 OCA_LOG_INFO_PARAMS("Configuration update received at %s", path.c_str());
                                 HandleConfigurationUpdate(newVal); });

        // Watch for audio settings updates
        g_udpObserver->watch("settings.audio", [](const std::string &path,
                                                  const Json::Value &oldVal,
                                                  const Json::Value &newVal)
                             { 
                                 OCA_LOG_INFO_PARAMS("Audio settings update received at %s", path.c_str());
                                 HandleAudioSettingsUpdate(newVal); });

        return true;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("✗ Failed to setup UDP watchers: %s", e.what());
        return false;
    }
}

/**
 * @brief Handle configuration updates from UDP
 * @param newConfig New configuration JSON
 */
void HandleConfigurationUpdate(const Json::Value &newConfig)
{
    // OCA_LOG_INFO("Processing configuration update...");
    printf("Processing configuration update...\n %s", newConfig.toStyledString().c_str());

    // TODO: Implement configuration update logic
    // This will involve tearing down and rebuilding the OCA stack
    // TODO: what to do if configuration update fails

    OCA_LOG_INFO("Configuration update processing not yet implemented");
}

/**
 * @brief Handle audio settings updates from UDP
 * @param newSettings New audio settings JSON
 */
void HandleAudioSettingsUpdate(const Json::Value &newSettings)
{
    OCA_LOG_INFO("Processing audio settings update...");

    // TODO: Implement audio settings update logic
    // This should update OCA device values without tearing down the stack

    OCA_LOG_INFO("Audio settings update processing not yet implemented");
}

int main(int argc, const char *argv[])
{
    unsigned int connectionPort = 65000;
    if (argc > 1)
    {
        static_cast<void>(sscanf(argv[1], "%u", &connectionPort));
    }
    OCA_LOG_INFO_PARAMS("Using connection port %d", connectionPort);

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

    // TODO: In future, get this configuration from UDP observer
    // For now, using hardcoded configuration as fallback
    const std::string zonesJson =
        "{\n"
        "  \"controllers\": {\n"
        "    \"ctrl1\": {\n"
        "      \"id\": \"ctrl1\",\n"
        "      \"name\": \"Controller 1\",\n"
        "      \"zoneIds\": [\"zone1\"]\n"
        "    },\n"
        "    \"ctrl2\": {\n"
        "      \"id\": \"ctrl2\",\n"
        "      \"name\": \"Controller 2\",\n"
        "      \"zoneIds\": [\"zone2\", \"zone3\"]\n"
        "    }\n"
        "  },\n"
        "  \"zones\": {\n"
        "    \"zone1\": {\n"
        "      \"id\": \"zone1\",\n"
        "      \"name\": \"Living Room\",\n"
        "      \"gainID\": \"gain1\",\n"
        "      \"ono\": {\n"
        "        \"zone\": 8001,\n"
        "        \"gain\": 8002,\n"
        "        \"mute\": 8003,\n"
        "        \"sourceSelector\": 8004\n"
        "      },\n"
        "      \"sources\": [\n"
        "        {\"index\": 0, \"label\": \"HDMI 1\"},\n"
        "        {\"index\": 1, \"label\": \"HDMI 2\"},\n"
        "        {\"index\": 2, \"label\": \"Bluetooth\"}\n"
        "      ]\n"
        "    },\n"
        "    \"zone2\": {\n"
        "      \"id\": \"zone2\",\n"
        "      \"name\": \"Kitchen\",\n"
        "      \"gainID\": \"gain2\",\n"
        "      \"ono\": {\n"
        "        \"zone\": 8005,\n"
        "        \"gain\": 8006,\n"
        "        \"mute\": 8007,\n"
        "        \"sourceSelector\": 8008\n"
        "      },\n"
        "      \"sources\": [\n"
        "        {\"index\": 0, \"label\": \"Radio\"},\n"
        "        {\"index\": 1, \"label\": \"Streaming\"}\n"
        "      ]\n"
        "    },\n"
        "    \"zone3\": {\n"
        "      \"id\": \"zone3\",\n"
        "      \"name\": \"Bedroom\",\n"
        "      \"gainID\": \"gain3\",\n"
        "      \"ono\": {\n"
        "        \"zone\": 8009,\n"
        "        \"gain\": 8010,\n"
        "        \"mute\": 8011,\n"
        "        \"sourceSelector\": 8012\n"
        "      },\n"
        "      \"sources\": [\n"
        "        {\"index\": 0, \"label\": \"TV\"},\n"
        "        {\"index\": 1, \"label\": \"AUX\"},\n"
        "        {\"index\": 2, \"label\": \"AirPlay\"}\n"
        "      ]\n"
        "    }\n"
        "  }\n"
        "}";

    // Initialize OCA managers
    g_bSuccess = InitializeOCAManagers();
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ OCA managers initialization failed");
        return -1;
    }

    // Setup OCP1 network
    ::Ocp1LiteNetwork *ocp1Network = SetupOCP1Network(connectionPort);
    if (!ocp1Network)
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
    g_bSuccess = StartOCAServices(ocp1Network);
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ OCA services startup failed");
        return -1;
    }

    // Setup UDP watchers
    g_bSuccess = SetupUDPWatchers("192.168.64.53", 7947);
    if (!g_bSuccess)
    {
        OCA_LOG_ERROR("✗ UDP watchers setup failed");
        // //TODO: what to do if UDP observer setup fails
        // For now, continue without UDP observer
        g_bSuccess = true;
    }

    // Run main loop
    RunMainLoop();

    // Clean up UDP Observer before exit
    ShutdownUDPObserver();

    return 0;
}
