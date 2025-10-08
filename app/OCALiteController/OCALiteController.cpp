/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALiteController.cpp : Defines the entry point for the OCA Controller application.
//

#include <HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.h>
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include <HostInterfaceLite/OCA/OCP.1/Ocp1LiteHostInterface.h>
#include <OCC/ControlClasses/Managers/OcaLiteNetworkManager.h>
#include <OCC/ControlDataTypes/OcaLiteClassIdentification.h>
#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>
#include <OCF/OcaLiteCommandHandlerController.h>
#include <OCP.1/Ocp1LiteNetwork.h>
#include <OCP.1/Ocp1LiteNetworkSystemInterfaceID.h>
#include <OCP.1/Ocp1LiteConnectParameters.h>
#include <Proxy/GeneralProxy.h>
#include <StandardLib/StandardLib.h>
#include <OCC/ControlDataTypes/OcaLiteManagerDescriptor.h>
#include <OCC/ControlDataTypes/OcaLiteBlockMember.h>
#include <unistd.h>
#include "OcaServiceDiscovery.h"
#include "HostInterfaceLite/OCA/OCF/Timer/IOcfLiteTimer.h"
#include <sys/time.h>
#include <iostream>
#include "../common/models/WallControllerConfigParser.h" // For deserializing JSON configuration
#include "../common/FusionOCAConstants.h"                // For custom ONO constants

#ifdef OCA_RUN
extern void Ocp1LiteServiceRun();
#else
extern void Ocp1LiteServiceRunWithFdSet(fd_set *readSet);
extern int Ocp1LiteServiceGetSocket();
#endif

// Helper functions
void DisplayDiscoveredDevices(const std::vector<OcaServiceDiscovery::DiscoveredDevice> &devices)
{
    OCA_LOG_INFO("=== Discovered OCA Devices ===");
    for (size_t i = 0; i < devices.size(); ++i)
    {
        const auto &device = devices[i];
        OCA_LOG_INFO_PARAMS("%zu. %s", i + 1, device.name.c_str());
        OCA_LOG_INFO_PARAMS("   Host: %s:%d", device.hostname.c_str(), device.port);
        OCA_LOG_INFO_PARAMS("   Protocol: OCA v%u", device.protocolVersion);

        // Display some TXT record info
        auto pathIt = device.txtRecords.find("path");
        if (pathIt != device.txtRecords.end())
        {
            OCA_LOG_INFO_PARAMS("   Path: %s", pathIt->second.c_str());
        }
    }
    OCA_LOG_INFO("===============================");
}

bool ConnectToDevice(const OcaServiceDiscovery::DiscoveredDevice &device,
                     ::Ocp1LiteNetwork *ocp1Network,
                     const std::string &customNodeId)
{
    OCA_LOG_INFO_PARAMS("Connecting to %s at %s:%d...",
                        device.name.c_str(), device.hostname.c_str(), device.port);

    // Create connection parameters
    ::Ocp1LiteConnectParameters connectParams(device.hostname, device.port);

    OCA_LOG_INFO_PARAMS("Connection parameters: host='%s', port=%d",
                        device.hostname.c_str(), device.port);

    // Attempt connection
    ::OcaSessionID sessionId = ocp1Network->Connect(connectParams);

    OCA_LOG_INFO_PARAMS("Connect() returned session ID: %u", sessionId);

    if (sessionId != 0)
    {
        OCA_LOG_INFO_PARAMS("✓ Connected to %s! Session ID: %u", device.name.c_str(), sessionId);

        ::OcaLiteString controllerId = customNodeId.empty() ? ::OcaLiteString("ctrl1") : ::OcaLiteString(customNodeId);

        OCA_LOG_INFO_PARAMS("Using controller ID: %s", controllerId.GetString().c_str());

        ::GeneralProxy proxy(sessionId, ocp1Network->GetObjectNumber());
        OCA_LOG_INFO_PARAMS("Created proxy with session ID: %u, network ONO: %u", sessionId, ocp1Network->GetObjectNumber());

        ::OcaLiteString configData;
        OCA_LOG_INFO_PARAMS("Calling OcaControllerConfigManager_GetConfigDetails with ONO %u...", CONTROLLER_CONFIG_MANAGER_ONO);
        OcaLiteStatus status = proxy.OcaControllerConfigManager_GetConfigDetails(CONTROLLER_CONFIG_MANAGER_ONO, controllerId, configData);

        if (OCASTATUS_OK == status)
        {
            OCA_LOG_INFO_PARAMS("✓ Successfully retrieved configuration data (%zu characters):", configData.GetString().length());
            OCA_LOG_INFO("=== Configuration JSON ===");

            // Print JSON in chunks to avoid log truncation
            const std::string jsonStr = configData.GetString();
            const size_t chunkSize = 200; // Print in 200 character chunks

            for (size_t i = 0; i < jsonStr.length(); i += chunkSize)
            {
                std::string chunk = jsonStr.substr(i, chunkSize);
                OCA_LOG_INFO(chunk.c_str());
            }
            OCA_LOG_INFO("=== End Configuration JSON ===");

            // Deserialize the JSON using ControlSystemConfigParser
            std::shared_ptr<Controller> controller = JsonStringToWallController(jsonStr);

            if (controller)
            {
                OCA_LOG_INFO("=== Parsed Controller Configuration ===");
                OCA_LOG_INFO_PARAMS("Controller ID: %s", controller->id.c_str());
                OCA_LOG_INFO_PARAMS("Controller Name: %s", controller->name.c_str());
                OCA_LOG_INFO_PARAMS("Number of Zones: %zu", controller->zones.size());

                for (size_t i = 0; i < controller->zones.size(); ++i)
                {
                    const auto &zone = controller->zones[i];
                    OCA_LOG_INFO_PARAMS("  Zone %zu: %s (%s)", i + 1, zone->name.c_str(), zone->id.c_str());
                    OCA_LOG_INFO_PARAMS("    ONOs - Zone: %u, Gain: %u, Mute: %u, Switch: %u",
                                        zone->ono.zone, zone->ono.gain, zone->ono.mute, zone->ono.sourceSelector);
                    OCA_LOG_INFO_PARAMS("    Gain ID: %s", zone->gain.gainID.c_str());
                    OCA_LOG_INFO_PARAMS("    Gain Range: %s to %s", zone->gain.min_value.c_str(), zone->gain.max_value.c_str());
                    OCA_LOG_INFO_PARAMS("    Default Gain: %s", zone->gain.default_gain_value.c_str());
                    OCA_LOG_INFO_PARAMS("    Default Mute: %s", zone->gain.default_mute_value.c_str());

                    OCA_LOG_INFO_PARAMS("    Sources: %zu", zone->sources.size());

                    for (size_t j = 0; j < zone->sources.size(); ++j)
                    {
                        const auto &source = zone->sources[j];
                        OCA_LOG_INFO_PARAMS("      Source %zu: Index %u - %s", j + 1, source.index, source.label.c_str());
                    }
                }

                OCA_LOG_INFO("=== End Parsed Configuration ===");
            }
            else
            {
                OCA_LOG_WARNING("✗ Failed to parse JSON configuration data");
            }
        }
        else
        {
            OCA_LOG_ERROR_PARAMS("✗ Failed to retrieve configuration data, status: %u (0x%X)", status, status);
            if (status == OCASTATUS_PROCESSING_FAILED)
                OCA_LOG_ERROR("Status OCASTATUS_PROCESSING_FAILED");
            else if (status == OCASTATUS_BAD_FORMAT)
                OCA_LOG_ERROR("Status OCASTATUS_BAD_FORMAT");
            else if (status == OCASTATUS_BAD_ONO)
                OCA_LOG_ERROR("Status OCASTATUS_BAD_ONO");
            else if (status == OCASTATUS_PARAMETER_ERROR)
                OCA_LOG_ERROR("Status OCASTATUS_PARAMETER_ERROR");
            else if (status == OCASTATUS_PARAMETER_OUT_OF_RANGE)
                OCA_LOG_ERROR("Status OCASTATUS_PARAMETER_OUT_OF_RANGE");
            else if (status == OCASTATUS_NOT_IMPLEMENTED)
                OCA_LOG_ERROR("Status OCASTATUS_NOT_IMPLEMENTED");
            else if (status == OCASTATUS_INVALID_REQUEST)
                OCA_LOG_ERROR("Status OCASTATUS_INVALID_REQUEST");
            else if (status == OCASTATUS_LOCKED)
                OCA_LOG_ERROR("Status OCASTATUS_LOCKED");
            else if (status == OCASTATUS_BAD_METHOD)
                OCA_LOG_ERROR("Status OCASTATUS_BAD_METHOD");
            else
                OCA_LOG_ERROR_PARAMS("Status %u: Unknown error code", status);
        }

        // Disconnect
        if (ocp1Network->Disconnect(sessionId))
        {
            OCA_LOG_INFO_PARAMS("✓ Disconnected from %s", device.name.c_str());
        }
        else
        {
            OCA_LOG_WARNING_PARAMS("✗ Failed to disconnect cleanly from %s", device.name.c_str());
        }

        return true;
    }
    else
    {
        OCA_LOG_ERROR_PARAMS("✗ Failed to connect to %s", device.name.c_str());
        return false;
    }
}

void ShowUsage(const char *programName)
{
    std::cout << "Usage: " << programName << " [OPTIONS]\n";
    std::cout << "Options:\n";
    std::cout << "  -id <string>    Set custom node ID (default: auto-generated)\n";
    std::cout << "  -h, --help      Show this help message\n";
    std::cout << "\nExample:\n";
    std::cout << "  " << programName << " -id \"MyController\"\n";
}

int main(int argc, const char *argv[])
{
    std::string customNodeId = "";

    // Parse command line arguments
    for (int i = 1; i < argc; i++)
    {
        std::string arg = argv[i];

        if (arg == "-h" || arg == "--help")
        {
            ShowUsage(argv[0]);
            return 0;
        }
        else if (arg == "-id")
        {
            if (i + 1 < argc)
            {
                customNodeId = argv[i + 1];
                i++; // Skip the next argument since it's the ID value
            }
            else
            {
                std::cerr << "Error: -id option requires a value\n";
                ShowUsage(argv[0]);
                return 1;
            }
        }
        else
        {
            std::cerr << "Error: Unknown option '" << arg << "'\n";
            ShowUsage(argv[0]);
            return 1;
        }
    }

    // Initialize Oca Device
    static_cast<void>(::OcaLiteBlock::GetRootBlock());

    OCA_LOG_INFO("=== OCA Lite Controller with Service Discovery ===");
    // Set log level to show INFO messages (including client connection logs)
    ::OcfLiteLogSetLogLevel(OCA_LOG_LVL_TRACE);

    // Initialize the host interfaces
    bool bSuccess = ::OcfLiteHostInterfaceInitialize();
    bSuccess = bSuccess && ::Ocp1LiteHostInterfaceInitialize();

    if (bSuccess)
    {
        OCA_LOG_INFO("✓ Host interfaces initialized");

        // Initialize network manager
        bSuccess = static_cast<bool>(::OcaLiteNetworkManager::GetInstance().Initialize());

        if (bSuccess)
        {
            OCA_LOG_INFO("✓ Network manager initialized");

            // Create a controller network object (no server port)
            Ocp1LiteNetworkSystemInterfaceID interfaceId = ::Ocp1LiteNetworkSystemInterfaceID(static_cast<::OcaUint32>(0));
            std::vector<std::string> txtRecords; // Empty for controller

            // Use custom node ID if provided, otherwise use auto-generated
            ::OcaLiteString nodeId;
            if (!customNodeId.empty())
            {
                nodeId = ::OcaLiteString(customNodeId);
                OCA_LOG_INFO_PARAMS("Using custom node ID: %s", customNodeId.c_str());
            }
            else
            {
                // ::OcaLiteString nodeId = ::OcaLiteString("OCALiteController@" + OcfLiteConfigureGetDeviceName());
                nodeId = ::OcaLiteString("OCALiteController@" + OcfLiteConfigureGetDeviceName());
                OCA_LOG_INFO_PARAMS("Using auto-generated node ID: %s", nodeId.GetString().c_str());
            }

            // Create network with port 0 (no server socket)
            ::Ocp1LiteNetwork *ocp1Network = new ::Ocp1LiteNetwork(static_cast<::OcaONo>(9001), static_cast<::OcaBoolean>(true),
                                                                   ::OcaLiteString("Ocp1LiteControllerNetwork"), ::Ocp1LiteNetworkNodeID(nodeId),
                                                                   interfaceId, txtRecords, ::OcaLiteString("local"), static_cast<::OcaUint16>(0)); // Port 0 = no server

            if (ocp1Network->Initialize())
            {
                OCA_LOG_INFO("✓ Controller network initialized (no server socket)");

                if (::OcaLiteBlock::GetRootBlock().AddObject(*ocp1Network))
                {
                    // Get the controller command handler
                    ::OcaLiteCommandHandlerController &controller = ::OcaLiteCommandHandlerController::GetInstance();
                    bSuccess = controller.Initialize();

                    if (bSuccess)
                    {
                        OCA_LOG_INFO("✓ Controller command handler initialized");

                        // Start service discovery
                        OcaServiceDiscovery discovery;

                        if (discovery.StartDiscovery())
                        {
                            OCA_LOG_INFO("✓ Service discovery started");

                            // Wait for devices to be discovered
                            size_t deviceCount = discovery.WaitForDevices(8000); // Wait 8 seconds

                            auto discoveredDevices = discovery.GetDiscoveredDevices();

                            if (deviceCount > 0)
                            {
                                DisplayDiscoveredDevices(discoveredDevices);

                                // Connect to the first discovered device
                                const auto &selectedDevice = discoveredDevices[0];
                                OCA_LOG_INFO_PARAMS("Automatically selecting: %s", selectedDevice.name.c_str());

                                if (ConnectToDevice(selectedDevice, ocp1Network, customNodeId))
                                {
                                    OCA_LOG_INFO("✓ Service discovery and connection test successful!");
                                }
                                else
                                {
                                    OCA_LOG_ERROR("✗ Connection test failed");
                                }
                            }
                            else
                            {
                                OCA_LOG_WARNING("No OCA devices discovered on the network");
                                OCA_LOG_INFO("Make sure:");
                                OCA_LOG_INFO("  1. An OCA device is running and advertising _oca._tcp service");
                                OCA_LOG_INFO("  2. The device is on the same network segment");
                                OCA_LOG_INFO("  3. Multicast DNS is working properly");

                                // Fallback to hardcoded connection for testing
                                OCA_LOG_INFO("Falling back to hardcoded connection test...");
                                ::Ocp1LiteConnectParameters connectParams("127.0.0.1", 65000);
                                ::OcaSessionID sessionId = ocp1Network->Connect(connectParams);

                                if (sessionId != 0)
                                {
                                    OCA_LOG_INFO_PARAMS("✓ Fallback connection successful! Session ID: %u", sessionId);
                                    sleep(2);
                                    ocp1Network->Disconnect(sessionId);
                                    OCA_LOG_INFO("✓ Fallback connection test completed");
                                }
                                else
                                {
                                    OCA_LOG_WARNING("✗ Fallback connection also failed");
                                }
                            }

                            discovery.StopDiscovery();
                        }
                        else
                        {
                            OCA_LOG_ERROR("✗ Failed to start service discovery");
                        }
                    }
                }
                else
                {
                    OCA_LOG_ERROR("✗ Failed to initialize controller command handler");
                }

                // Properly teardown before deleting
                ocp1Network->Teardown();
                OCA_LOG_INFO("✓ Network Teardown completed");

                ::OcaLiteBlock::GetRootBlock().RemoveObject(ocp1Network->GetObjectNumber());
                OCA_LOG_INFO("✓ Network Object Removed from Root");

                delete ocp1Network;
                OCA_LOG_INFO("✓ Network Object deleted");
            }
            else
            {
                OCA_LOG_ERROR("✗ Failed to initialize controller network");
            }
        }
        else
        {
            OCA_LOG_ERROR("✗ Failed to initialize network manager");
        }
    }
    else
    {
        OCA_LOG_ERROR("✗ Failed to initialize host interfaces");
    }

    OCA_LOG_INFO("Controller application completed.");
    return bSuccess ? 0 : 1;
}
