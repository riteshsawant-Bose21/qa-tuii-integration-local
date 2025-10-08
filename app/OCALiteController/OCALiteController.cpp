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
#include <OCC/ControlDataTypes/OcaLiteList.h>
#include <OCC/ControlDataTypes/OcaLiteMethod.h>
#include <unistd.h>
#include "OcaServiceDiscovery.h"
#include "HostInterfaceLite/OCA/OCF/Timer/IOcfLiteTimer.h"
#include <sys/time.h>
#include <iostream>
#include "../common/ZoneConfigBuilder.h"  // For deserializing JSON configuration
#include "../common/FusionOCAConstants.h" // For custom ONO constants
#include "../common/workers/ZoneGroup.h"
#include "ControlPalGainActuator.h"
#include "ControlPalMuteActuator.h"
#include "ControlPalSwitchActuator.h"
#include "ControlPalSetupUtils.h"
#include "ControlPalConnectionMonitor.h"

#define OCA_RUN_TIMEOUT_MSEC    500

#ifdef OCA_RUN
extern void Ocp1LiteServiceRun();
#else
extern void Ocp1LiteServiceRunWithFdSet(fd_set *readSet);
extern int Ocp1LiteServiceGetSocket();
#endif

void ShowUsage(const char *programName)
{
    std::cout << "Usage: " << programName << " [OPTIONS]\n";
    std::cout << "Options:\n";
    std::cout << "  -id <string>    Set custom node ID (default: auto-generated)\n";
    std::cout << "  -h, --help      Show this help message\n";
    std::cout << "\nExample:\n";
    std::cout << "  " << programName << " -id \"MyController\"\n";
}

bool ocaMain(std::string& customNodeId)
{
    // Initialize Oca Device
    static_cast<void>(::OcaLiteBlock::GetRootBlock());

    OCA_LOG_INFO("=== OCA Lite Controller with Service Discovery ===");
    // Set log level to show INFO messages (including client connection logs)
    ::OcfLiteLogSetLogLevel(OCA_LOG_LVL_TRACE);

    // Initialize the host interfaces
    bool bSuccess = ::OcfLiteHostInterfaceInitialize();
    bSuccess = bSuccess && ::Ocp1LiteHostInterfaceInitialize();

    ::OcaSessionID sessionId;
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
            ::Ocp1LiteNetwork *ocp1Network = new ::Ocp1LiteNetwork(
                    static_cast<::OcaONo>(FUSION_NETWORK_ONO),
                    static_cast<::OcaBoolean>(true),
                    ::OcaLiteString("Ocp1LiteControllerNetwork"),
                    ::Ocp1LiteNetworkNodeID(nodeId),
                    interfaceId, txtRecords,
                    ::OcaLiteString("local"),
                    static_cast<::OcaUint16>(0)); // Port 0 = no server

            if (ocp1Network->Initialize())
            {
                OCA_LOG_INFO("✓ Controller network initialized (no server socket)");

                if (::OcaLiteBlock::GetRootBlock().AddObject(*ocp1Network))
                {
                    // Get the controller command handler
                    ::OcaLiteCommandHandlerController::GetInstance();
                    ::OcaLiteCommandHandler::GetInstance();
                    bSuccess = ::OcaLiteCommandHandlerController::GetInstance().Initialize();
                    bSuccess &= ::OcaLiteCommandHandler::GetInstance().Initialize();

                    if (bSuccess)
                    {
                        OCA_LOG_INFO("✓ Controller command handler initialized");

                        // Create Connection Monitor Object
                        ControlPalConnectionMonitor *connMonitor = 
                            new ControlPalConnectionMonitor(FUSION_CONNECTION_MON_ONO);

                        if (connMonitor)
                        {
                            if (::OcaLiteBlock::GetRootBlock().AddObject(*connMonitor))
                            {
                                // Register Connection Lost Monitor
                                ::OcaLiteCommandHandler::GetInstance().RegisterConnectionLostEventHandler(
                                        static_cast<::OcaLiteCommandHandler::IConnectionLostDelegate*>(connMonitor));

                                // Setup connection to the Device
                                if (ControlPalSetupConnection(ocp1Network, customNodeId, sessionId))
                                {
                                    ::GeneralProxy proxy(
                                            sessionId,
                                            ocp1Network->GetObjectNumber());
                                    OCA_LOG_INFO_PARAMS(
                                            "Created proxy with session ID: %u, network ONO: %u",
                                            sessionId, ocp1Network->GetObjectNumber());

                                    // TODO: 'controllerID' should be read from Flash config partition
                                    ::OcaLiteString controllerId =
                                        customNodeId.empty() ?
                                        ::OcaLiteString("ctrl1") :
                                        ::OcaLiteString(customNodeId);

                                    // Create and setup control objects
                                    if (ControlPalSetupControls(controllerId, proxy))
                                    {
                                        // Wait for Events from Device
                                        ::OcaLiteCommandHandler::GetInstance().RunWithTimeout(OCA_RUN_TIMEOUT_MSEC);

                                        //TODO: Check for local h/w events
                                    }
                                    else
                                    {
                                        OCA_LOG_ERROR("✗ SetupControls failed");
                                    }
                                }
                                else
                                {
                                    OCA_LOG_ERROR("✗ Failed to Setup Connection");
                                }

                            }
                        }
                    }
                    else
                    {
                        OCA_LOG_ERROR("✗ Failed to initialize controller command handler");
                    }
                }

                ::OcaLiteCommandHandlerController::GetInstance().Disconnect(sessionId, FUSION_NETWORK_ONO);

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
                // TODO: 'customNodeId' should be read from Flash config partition
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

    //
    // TODO: HW_Init()
    //
    // TODO: ControlInterface_Init();  // e.g. TochGFX, CLI interface etc
    //
    // IPC used to exchage upstream and 
    // downstream value changes.
    // TODO: IPC_init();  // e.g. semaphores, mutex etc.
    //
    // TODO: Create User Interface task. THis task handles UI, Physical Encoders etc.
    //

    // Start OCA processing
    return ocaMain(customNodeId);
}

