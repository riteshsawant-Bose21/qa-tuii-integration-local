/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALiteController.cpp : Defines the OCA Controller application.
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
#include "HostInterfaceLite/OCA/OCF/Timer/IOcfLiteTimer.h"
#include <sys/time.h>
#include <iostream>
#include "../common/models/Models.h"  // For deserializing JSON configuration
#include "../common/FusionOCAConstants.h" // For custom ONO constants
#include "../common/workers/ZoneGroup.h"
#include "workers/ControlPalGainActuator.h"
#include "workers/ControlPalMuteActuator.h"
#include "workers/ControlPalSwitchActuator.h"
#include "ControlPalSetupUtils.h"
#include "ControlPalConnectionMonitor.h"
#include "ControlPalCommandHandler.h"
#include "HostInterface/CommandInterface/CommandInterface.h"

#ifndef STM32H7S7xx
#include "PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#else
#include "PlatformInterface/stm32/OcaPlatformSTM32.h"
#include "dnssd.h"
#endif

#include "ControlPalSideBandInterface.h"

#define OCA_RUN_TIMEOUT_MSEC    500

extern void Ocp1LiteServiceRun();

bool terminateFlag(false);

bool ocaMain(std::string& customNodeId,
                std::vector<ControlPal_MsgQueue<ControllerCmdIntfc>*> msgQues)
{
    // AES70 --> UI
    ControlPal_MsgQueue<ControllerCmdIntfc> *ocaMsgQueue = msgQues.at(0);
    // UI --> AES70
    ControlPal_MsgQueue<ControllerCmdIntfc> *uiMsgQueue = msgQues.at(1);

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
        bSuccess =
            static_cast<bool>(::OcaLiteNetworkManager::GetInstance().Initialize());

        if (bSuccess)
        {
            OCA_LOG_INFO("✓ Network manager initialized");

            // Create a controller network object (no server port)
            Ocp1LiteNetworkSystemInterfaceID interfaceId =
                ::Ocp1LiteNetworkSystemInterfaceID(static_cast<::OcaUint32>(0));
            std::vector<std::string> txtRecords; // Empty for controller

            // Use custom node ID if provided, otherwise use auto-generated
            ::OcaLiteString nodeId;
            if (!customNodeId.empty())
            {
                nodeId = ::OcaLiteString(customNodeId);
                OCA_LOG_INFO_PARAMS("Using custom node ID: %s",
                        customNodeId.c_str());
            }
            else
            {
                nodeId = ::OcaLiteString("OCALiteController@" + OcfLiteConfigureGetDeviceName());
                OCA_LOG_INFO_PARAMS("Using auto-generated node ID: %s",
                                           nodeId.GetString().c_str());
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
                    OCA_LOG_INFO("✓ Controller command handler initialized");

                    if (bSuccess)
                    {
                        ::OcaLitePort dummy;
                        ::OcaLiteList< ::OcaLitePort> mgr_ports(0, &dummy);

                        // Create Connection Monitor Object
                        ControlPalConnectionMonitor *connMonitor =
                            new ControlPalConnectionMonitor(
                                    FUSION_CONNECTION_MON_ONO, mgr_ports);
                        if (connMonitor)
                        {
                            if (::OcaLiteBlock::GetRootBlock().AddObject(*connMonitor))
                            {
                                // Register Connection Lost Monitor
                                ::OcaLiteCommandHandler::GetInstance().RegisterConnectionLostEventHandler(
                                        static_cast<::OcaLiteCommandHandler::IConnectionLostDelegate*>(connMonitor));

                                //TODO: 'Fusion' service discovery

                                // TODO: 'controllerID' should be
                                // read from Flash config partition

                                ::OcaLiteString controllerId =
                                    customNodeId.empty() ?
                                    ::OcaLiteString("ctrl1") :
                                    ::OcaLiteString(customNodeId);

                                // TODO: Should be set at discovery
                                //std::string fservHost("192.168.0.167");
                                std::string fservHost("10.1.123.100");
                                int fservPort = 7950;

                                // Create SidebandInterface object
                                SidebandInterface fusionServerConn(
                                        controllerId.GetString(),
                                        fservHost,
                                        fservPort,
                                        static_cast<void *>(ocaMsgQueue));

                                while(!terminateFlag)
                                {
                                    // Establish Fusion server sideband connection
                                    if (fusionServerConn.sideBandConnect())
                                    {
                                        // Wait for side-band 'identity' request
                                        while (!fusionServerConn.IsIdentified())
                                        {
                                            fusionServerConn.messageHandler();
                                        }
                                        std::cout << " =========> IDENTIFIED SUCCESSFULLY" << std::endl;
#ifdef STM32H7S7xx
                                        OcaPlatform::Sleep(10);
#else
                                        sleep(1);
#endif

                                        // Setup AES connection to the Device
                                        if (ControlPalSetupConnection(sessionId))
                                        {
                                            // Set connected status to true
                                            connMonitor->SetSetting(static_cast<OcaBoolean>(true));

                                            ::GeneralProxy proxy(
                                                    sessionId,
                                                    ocp1Network->GetObjectNumber());
                                            OCA_LOG_INFO_PARAMS("Created proxy with session ID: %u, network ONO: %u",
                                                    sessionId, ocp1Network->GetObjectNumber());

                                            // Holds ONo of each zone assigned
                                            // to the controller
                                            std::vector<::OcaONo> zoneONos;

                                            FusionProxy fusion_proxy(
                                                    sessionId,
                                                    ocp1Network->GetObjectNumber());

                                            // Create and setup control objects
                                            ::OcaBoolean connectStatus(true);

                                            if (ControlPalSetupControls(
                                                        controllerId,
                                                        proxy,
                                                        fusion_proxy,
                                                        static_cast<void *>(ocaMsgQueue),
                                                        zoneONos))
                                            {

                                                while (connectStatus  && !terminateFlag)
                                                {
                                                    // Wait for Events from Device
                                                    ::OcaLiteCommandHandler::GetInstance().RunWithTimeout(OCA_RUN_TIMEOUT_MSEC);

                                                    // Check side-band for messages
                                                    fusionServerConn.messageHandler();

                                                    //Check for local UI command
                                                    {
                                                        ControlPalUICommandHandler(
                                                                uiMsgQueue,
                                                                zoneONos,
                                                                fusion_proxy,
                                                                fusionServerConn);
                                                    }

                                                    // Check Connection status
                                                    connMonitor->GetSetting(
                                                            connectStatus);
                                                }

                                                // Connection lost, teardown all
                                                // the control objects
                                                ControlPalTeardownControls(
                                                        zoneONos);
                                            }
                                            else
                                            {
                                                OCA_LOG_ERROR("✗ SetupControls failed");
                                                while (connectStatus &&
                                                        !terminateFlag)
                                                {
                                                    // Wait for Events from Device
                                                    ::OcaLiteCommandHandler::GetInstance().RunWithTimeout(OCA_RUN_TIMEOUT_MSEC);

                                                    // Check Connection status
                                                    connMonitor->GetSetting(
                                                            connectStatus);
                                                }
                                            }

                                            // OCA disconnect
                                            DisconnectFromDevice(
                                                    sessionId,
                                                    FUSION_NETWORK_ONO);

                                        }
                                        else
                                        {
                                            OCA_LOG_ERROR("✗ Failed to Setup Connection");
                                        }

#ifdef STM32H7S7xx
                                        // Reset discovery
                                        reset_oca_service_discovery();
#endif

                                        // Sideband disconnect
                                        fusionServerConn.sideBandDisconnect();

                                    }
                                    else
                                    {
                                        OCA_LOG_ERROR("✗ Failed Fusion (Sideband) Server Connection ");
                                    }

                                    // Wait for Events from Device (Keep alives)
                                    ::OcaLiteCommandHandler::GetInstance().RunWithTimeout(OCA_RUN_TIMEOUT_MSEC);

#ifdef STM32H7S7xx
                                    OcaPlatform::Sleep(9000);
#else
                                        sleep(9);
#endif

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

