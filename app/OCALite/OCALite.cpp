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
#include "../common/CustomONODefinitions.h" // For custom ONO constants

#ifdef OCA_RUN
extern void Ocp1LiteServiceRun();
#else
extern void Ocp1LiteServiceRunWithFdSet(fd_set *readSet);
extern int Ocp1LiteServiceGetSocket();
#endif

int main(int argc, const char *argv[])
{
    unsigned int connectionPort = 65000;
    if (argc > 1)
    {
        static_cast<void>(sscanf(argv[1], "%u", &connectionPort));
    }
    printf("Using connection port %d\r\n", connectionPort);

    // Set log level to show INFO messages (including client connection logs)
    ::OcfLiteLogSetLogLevel(OCA_LOG_LVL_TRACE);

    // Initialize the host interfaces
    bool bSuccess = ::OcfLiteHostInterfaceInitialize();
    bSuccess = bSuccess && ::Ocp1LiteHostInterfaceInitialize();

    // Initialize Oca Device
    static_cast<void>(::OcaLiteBlock::GetRootBlock());

    // Example zone JSON with new nested zones object structure
    const char *zonesJson =
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

    BuiltZones bz = BuildZonesFromJson(zonesJson, ROOT_ZONE_CONTAINER_ONO);
    if (bz.zonesContainer)
    {
        ZoneGroup *rootZone = bz.zonesContainer.get();
        if (::OcaLiteBlock::GetRootBlock().AddObject(*rootZone))
        {
            printf("✓ Zones container (JSON) added (Object #%u) with %zu inner zone groups\r\n", ROOT_ZONE_CONTAINER_ONO, bz.zones.size());
            bz.zonesContainer.release();
        }
        else
        {
            printf("✗ Failed to add JSON Zones container to root (possible duplicate?)\r\n");
        }
    }

    bSuccess = bSuccess && static_cast<bool>(::OcaLiteNetworkManager::GetInstance().Initialize());
    bSuccess = bSuccess && static_cast<bool>(::OcaLiteSubscriptionManager::GetInstance().SetNrEvents(1 /*OCA_NR_EVENTS*/));
    bSuccess = bSuccess && static_cast<bool>(::OcaLiteSubscriptionManager::GetInstance().Initialize());
    bSuccess = bSuccess && static_cast<bool>(::OcaLiteDeviceManager::GetInstance().Initialize());
    bSuccess = bSuccess && static_cast<bool>(::OcaLiteFirmwareManager::GetInstance().Initialize());
    bSuccess = bSuccess && static_cast<bool>(::OcaLiteControllerConfigManager::GetInstance().Initialize());

    if (bSuccess)
    {
        // Build controllers from JSON and set them in the config manager
        std::vector<Controller> controllers = BuildControllersFromMetadataJson(zonesJson);
        if (!controllers.empty())
        {
            ::OcaLiteControllerConfigManager::GetInstance().SetConfigData(controllers);
            printf("✓ Controller configuration set with %zu controllers\r\n", controllers.size());
        }
        else
        {
            printf("✗ Failed to parse controllers from JSON\r\n");
        }
        Ocp1LiteNetworkSystemInterfaceID interfaceId = ::Ocp1LiteNetworkSystemInterfaceID(static_cast<::OcaUint32>(0));
        std::vector<std::string> txtRecords;
        txtRecords.push_back("modelGUID=DEADBEEFEATERS");
        ::OcaLiteString nodeId = ::OcaLiteString("OCALite@" + OcfLiteConfigureGetDeviceName());
        ::Ocp1LiteNetwork *ocp1Network = new ::Ocp1LiteNetwork(static_cast<::OcaONo>(9000), static_cast<::OcaBoolean>(true),
                                                               ::OcaLiteString("Ocp1LiteNetwork"), ::Ocp1LiteNetworkNodeID(nodeId),
                                                               interfaceId, txtRecords, ::OcaLiteString("local"), (OcaUint16)connectionPort);
        if (ocp1Network->Initialize())
        {
            if (::OcaLiteBlock::GetRootBlock().AddObject(*ocp1Network))
            {
                OcaLiteStatus rc(ocp1Network->Startup());
                if (OCASTATUS_OK == rc)
                {
                    bSuccess = bSuccess && ::OcaLiteCommandHandler::GetInstance().Initialize();
                    ::OcaLiteDeviceManager::GetInstance().SetErrorAndOperationalState(static_cast<::OcaBoolean>(!bSuccess), ::OcaLiteDeviceManager::OCA_OPSTATE_OPERATIONAL);
                    ::OcaLiteDeviceManager::GetInstance().SetEnabled(static_cast<::OcaBoolean>(bSuccess));

                    OCA_LOG_ERROR("Starting run loop..");
                    while (bSuccess)
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
                }
            }
        }
    }

    return 0;
}
