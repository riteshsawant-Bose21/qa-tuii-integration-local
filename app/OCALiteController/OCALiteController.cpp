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

bool ConnectToDevice(const OcaServiceDiscovery::DiscoveredDevice &device, ::Ocp1LiteNetwork *ocp1Network)
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

        // Demonstrate basic device introspection
        ::GeneralProxy proxy(sessionId, 9001); // Using our network object number

        // Get device managers
        ::OcaLiteList<::OcaLiteManagerDescriptor> managers;
        ::OcaLiteStatus status = proxy.OcaDeviceManager_GetManagers(managers);

        if (status == OCASTATUS_OK)
        {
            OCA_LOG_INFO_PARAMS("Device has %u managers:", managers.GetCount());
            for (::OcaUint16 i = 0; i < managers.GetCount(); ++i)
            {
                const auto &manager = managers.GetItem(i);
                OCA_LOG_INFO_PARAMS("  - Manager %u: Object #%u", i + 1, manager.GetObjectNumber());
            }
        }

        // Get root block members
        ::OcaLiteList<::OcaLiteBlockMember> members;
        status = proxy.OcaBlock_GetMembersRecursive(1, members); // Root block is typically object #1

        if (status == OCASTATUS_OK)
        {
            OCA_LOG_INFO_PARAMS("Device root block has %u members:", members.GetCount());
            for (::OcaUint16 i = 0; i < members.GetCount() && i < 5; ++i) // Show first 5
            {
                const auto &member = members.GetItem(i);
                OCA_LOG_INFO_PARAMS("  - Member %u: Object #%u", i + 1, member.GetMemberObjectIdentification().GetONo());
            }
            if (members.GetCount() > 5)
            {
                OCA_LOG_INFO_PARAMS("  ... and %u more", members.GetCount() - 5);
            }
        }

        // Keep connection open briefly
        OCA_LOG_INFO("Keeping connection open for 3 seconds...");
        sleep(3);

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

int main(int /*argc*/, const char * /*argv*/[])
{
    OCA_LOG_INFO("=== OCA Lite Controller with Service Discovery ===");

    // Set log level to show all messages including trace
    ::OcfLiteLogSetLogLevel(OCA_LOG_LVL_TRACE);

    // Initialize the host interfaces for controller mode
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
            ::OcaLiteString nodeId = ::OcaLiteString("OCALiteController@" + OcfLiteConfigureGetDeviceName());

            // Create network with port 0 (no server socket)
            ::Ocp1LiteNetwork *ocp1Network = new ::Ocp1LiteNetwork(static_cast<::OcaONo>(9001), static_cast<::OcaBoolean>(true),
                                                                   ::OcaLiteString("Ocp1LiteControllerNetwork"), ::Ocp1LiteNetworkNodeID(nodeId),
                                                                   interfaceId, txtRecords, ::OcaLiteString("local"), static_cast<::OcaUint16>(0)); // Port 0 = no server

            if (ocp1Network->Initialize())
            {
                OCA_LOG_INFO("✓ Controller network initialized (no server socket)");

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

                            if (ConnectToDevice(selectedDevice, ocp1Network))
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
                else
                {
                    OCA_LOG_ERROR("✗ Failed to initialize controller command handler");
                }

                // Properly teardown before deleting
                ocp1Network->Teardown();
                delete ocp1Network;
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
