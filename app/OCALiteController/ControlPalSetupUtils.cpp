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
#include <StandardLib/StandardLib.h>
#include <OCC/ControlDataTypes/OcaLiteBlockMember.h>
#include <OCC/ControlDataTypes/OcaLiteList.h>
#include <OCC/ControlDataTypes/OcaLiteMethod.h>
#include <unistd.h>
#include <iostream>
#include "../common/models/Models.h"  // For deserializing JSON configuration
#include "../common/models/WallControllerConfigParser.h"  // For deserializing JSON configuration
#include "../common/FusionOCAConstants.h" // For custom ONO constants
#include "../common/workers/ZoneGroup.h"
#include "ControlPalGainActuator.h"
#include "ControlPalMuteActuator.h"
#include "ControlPalSwitchActuator.h"
#include "ControlPalSetupUtils.h"


// Helper functions
void DisplayDiscoveredDevices(
        const std::vector<OcaServiceDiscovery::DiscoveredDevice> &devices)
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

::OcaBoolean ConnectToDevice(
                     const OcaServiceDiscovery::DiscoveredDevice &device,
                     ::OcaSessionID& sessionId)
{
    ::OcaBoolean rc(true);

    OCA_LOG_INFO_PARAMS("Connecting to %s at %s:%d...",
            device.name.c_str(), device.hostname.c_str(), device.port);

    // Create connection parameters
    ::Ocp1LiteConnectParameters connectParams(device.hostname, device.port);

    OCA_LOG_INFO_PARAMS("Connection parameters: host='%s', port=%d",
            device.hostname.c_str(), device.port);

    // Attempt connection
    sessionId = ::OcaLiteCommandHandlerController::GetInstance().Connect(connectParams, FUSION_NETWORK_ONO);

    OCA_LOG_INFO_PARAMS("Connect() returned session ID: %u", sessionId);

    if (sessionId <= 0)
    {
        rc = false;
    }

    return rc;
}

::OcaLiteStatus GetControllerConfig(::OcaLiteString& controllerId,
                                    FusionProxy& proxy,
                                    Controller& controllerCfg)
{
    Controller newController;
    OCA_LOG_INFO_PARAMS("Using controller ID: %s",
                        controllerId.GetString().c_str());

    ::OcaLiteString configData;
    OCA_LOG_INFO_PARAMS("Calling OcaControllerConfigManager_GetConfigDetails with ONO %u...", CONTROLLER_CONFIG_MANAGER_ONO);
    OcaLiteStatus status =
        proxy.OcaControllerConfigManager_GetConfigDetails(
                                        CONTROLLER_CONFIG_MANAGER_ONO,
                                        controllerId,
                                        configData);

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

        // Deserialize the JSON using ZoneConfigBuilder
        std::shared_ptr<Controller> newController = JsonStringToWallController(jsonStr);

        // Check if requested ID matches received data
        if (newController && (newController->id == controllerId.GetString()))
        {
            controllerCfg = *newController;

            // TODO: Delete this section after debug done
            OCA_LOG_INFO("=== Parsed Controller Configuration ===");
            OCA_LOG_INFO_PARAMS("Controller ID: %s", newController->id.c_str());
            OCA_LOG_INFO_PARAMS("Controller Name: %s", newController->name.c_str());
            OCA_LOG_INFO_PARAMS("Number of Zones: %zu", newController->zones.size());

            for (size_t i = 0; i < newController->zones.size(); ++i)
            {
                const auto &zone = newController->zones[i];
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
            status = OCASTATUS_PARAMETER_ERROR;
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

    return status;
}

::OcaBoolean AddSubscriptions(Zone& newZone, GeneralProxy& proxy)
{
    // These two do not need to be initialized, they are not used  in OcaLib
    OcaLiteNetworkAddress  sub_addr; // This is not used in RELIABLE mode
    const ::OcaLiteBlob    sub_blob; // Not used

    ::OcaBoolean     status(false);

    //// Subscribe to Gain
    {
        // Set remote(device) event to subscribe to
        ::OcaLiteEvent sub_event(newZone.ono.gain,
                    ::OcaLiteEventID(OcaLiteRoot::CLASS_ID.GetFieldCount(),
                    ::OcaLiteRoot::OCA_EVENT_PROPERTY_CHANGED));

        // Set method(local) to invoke when event is received
        ::OcaLiteMethod sub_method(newZone.ono.gain,
                ::OcaLiteMethodID(::OcaLiteGain::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteGain::SET_GAIN));

        status = proxy.OcaSubscriptionManager_AddSubscription(
                                    sub_event,
                                    sub_method,
                                    sub_blob,
                                    OCANOTIFICATIONDELIVERYMODE_RELIABLE,
                                    sub_addr);
    }

    //// Subscribe to Mute
    {
        // Set remote(device) event to subscribe to
        ::OcaLiteEvent sub_event(newZone.ono.mute,
                    ::OcaLiteEventID(OcaLiteRoot::CLASS_ID.GetFieldCount(),
                    ::OcaLiteRoot::OCA_EVENT_PROPERTY_CHANGED));

        // Set method(local) to invoke when event is received
        ::OcaLiteMethod sub_method(newZone.ono.mute,
                ::OcaLiteMethodID(::OcaLiteMute::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteMute::SET_STATE));

        status |= proxy.OcaSubscriptionManager_AddSubscription(
                                    sub_event,
                                    sub_method,
                                    sub_blob,
                                    OCANOTIFICATIONDELIVERYMODE_RELIABLE,
                                    sub_addr);
    }

    //// Subscribe to Selector
    {
        // Set remote(device) event to subscribe to
        ::OcaLiteEvent sub_event(newZone.ono.sourceSelector,
                    ::OcaLiteEventID(OcaLiteRoot::CLASS_ID.GetFieldCount(),
                    ::OcaLiteRoot::OCA_EVENT_PROPERTY_CHANGED));

        // Set method(local) to invoke when event is received
        ::OcaLiteMethod sub_method(newZone.ono.sourceSelector,
                ::OcaLiteMethodID(::OcaLiteSwitch::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteSwitch::SET_POSITION));

        status |= proxy.OcaSubscriptionManager_AddSubscription(
                                    sub_event,
                                    sub_method,
                                    sub_blob,
                                    OCANOTIFICATIONDELIVERYMODE_RELIABLE,
                                    sub_addr);
    }

    return status;
}

ZoneGroup* CreateZoneGroup(Zone& newZone, FusionProxy &fusion_proxy,
                                                   void *commandQueue)
{
    // Create a block/zone
    ZoneGroup* newZoneGrp = new ZoneGroup(newZone.ono.zone,
                                          static_cast<::OcaBoolean>(true),
                                          ::OcaLiteString(newZone.id),
                                          ::OcaLiteString(newZone.name),
                                          commandQueue);

    if (newZoneGrp)
    {
        // Create Gain object
        static ::OcaLiteList<::OcaLitePort> emptyPorts;
        ControlPalGainActuator* newGainObj = new ControlPalGainActuator(
                newZone.ono.gain,
                static_cast<::OcaBoolean>(true),
                static_cast<const ::OcaLiteString>("Gain"),
                emptyPorts,
                -20.0,
                60.0,
                newZone.gain.gainID,
                newZone.ono.zone,
                commandQueue);
        if (newGainObj)
        {
            newZoneGrp->AddObject(*newGainObj);
        }

        ControlPalMuteActuator* newMuteObj = new ControlPalMuteActuator(
                newZone.ono.mute,
                static_cast<::OcaBoolean>(true),
                static_cast<const ::OcaLiteString>("Mute"),
                emptyPorts,
                newZone.gain.gainID,
                newZone.ono.zone,
                commandQueue);
        if (newMuteObj)
        {
            newZoneGrp->AddObject(*newMuteObj);
        }

        // Create selector object

        //Extract index and label from newZone.sources[]
        std::map<unsigned, std::string> selector;
        ::OcaLiteList<::OcaLiteString> label;
        ::OcaLiteList<::OcaBoolean> enable;

        // Sorting by indexes
        for (auto &zselect:newZone.sources)
        {
            selector.emplace(zselect.index, zselect.label);
        }

        for (const auto& pair : selector)
        {
            label.Add(::OcaLiteString(pair.second));
            enable.Add(false);
        }

        ControlPalSwitchActuator* newSelectorObj = new ControlPalSwitchActuator(
                newZone.ono.sourceSelector,
                static_cast<::OcaBoolean>(true),
                static_cast<const ::OcaLiteString>("SourceSelect"),
                emptyPorts,
                static_cast<::OcaUint16>(0),    // Min Pos. TODO: Is '0' the right value?
                static_cast<::OcaUint16>(newZone.sources.size() - 1), // Max Pos.
                label,
                enable,
                newZone.id,
                newZone.ono.zone,
                commandQueue);

        // Add to block
        if (newSelectorObj)
        {
            newZoneGrp->AddObject(*newSelectorObj);
        }

        // Send Zone Name to frontend
        newZoneGrp->SendValue();

        // Sync Control values (with Device)
        // Get & Set Gain value
        ::OcaDB gainVal;
        fusion_proxy.ConcreteGainActuator_GetGain(
                                     newGainObj->GetObjectNumber(),
                                     gainVal);

        // Also sends updated value to front-end
        newGainObj->SetGain(gainVal);

        // Get & Set Mute state
        ::OcaLiteMuteState state;
        fusion_proxy.ConcreteMuteActuator_GetMute(
                                     newMuteObj->GetObjectNumber(),
                                     state);

        // Also sends updated value to front-end
        newMuteObj->SetState(state);

        // Get & Set Switch Position
        ::OcaUint16 position;
        fusion_proxy.ConcreteSwitchActuator_GetSwitch(
                                newSelectorObj->GetObjectNumber(),
                                position);

        // Also sends updated value to front-end
        newSelectorObj->SendConfigurationValue();
    }

    return newZoneGrp;
}

::OcaBoolean ControlPalSetupConnection(::OcaSessionID& sessionId)
{
    ::OcaBoolean retVal(false);

    // Start service discovery
    OcaServiceDiscovery discovery;

    if (discovery.StartDiscovery())
    {
        OCA_LOG_INFO("✓ Service discovery started");

        // Wait for devices to be discovered
        size_t deviceCount(0);
        uint8_t retry_cnt(0);

        // NOTE: In the case of a retry after a Device disconnect,
        //       discovery could find the service and resolve the address
        //       even if the Device is down. This is due to records not
        //       getting cleared from the DNS server.
        //       It will however fail to establish connection when it tries
        //       to connect. This can be mitigated to some extent if aging
        //       and scavenging are enabled on the DNS server.
        deviceCount = discovery.WaitForDevices(1000);

        // Retry loop
        while ( (deviceCount <= 0 ) && (retry_cnt++ < 10))
        {
            deviceCount = discovery.WaitForDevices(1000);
        }

        if (deviceCount > 0)
        {
            auto discoveredDevices = discovery.GetDiscoveredDevices();

            DisplayDiscoveredDevices(discoveredDevices);

            // Connect to the first discovered device
            const auto &selectedDevice = discoveredDevices[0];
            OCA_LOG_INFO_PARAMS("Automatically selecting: %s",
                                selectedDevice.name.c_str());

            if (ConnectToDevice(selectedDevice, sessionId))
            {
                retVal = true;
            }
        }
    }
    discovery.StopDiscovery();

    if (retVal)
    {
        OCA_LOG_INFO("✓ Service discovery and connection successful!");
    }
    return retVal;
}

::OcaBoolean ControlPalSetupControls(::OcaLiteString& controllerId,
                                        ::GeneralProxy& gen_proxy,
                                        FusionProxy& proxy,
                                        void *commandQueue,
                                        std::vector<::OcaONo>& zoneONo)
{
    ::OcaBoolean bSuccess(false);
    Controller controllerCfg;

    if (OCASTATUS_OK == GetControllerConfig(controllerId,
                                            proxy,
                                            controllerCfg))
    {
        if (controllerCfg.zones.size() > 0)
        {
            ControlPal_MsgQueue<ControllerCmdIntfc> *ocaQue =
            static_cast<ControlPal_MsgQueue<ControllerCmdIntfc>*>(commandQueue);
            ControllerCmdIntfc cfgCmd;

            // Configuration start message to UI
            cfgCmd.cmd          = CTRL_CMD_ZONE_CFG_START;
            cfgCmd.ono          = 0;  // Don't care for message
            strcpy(cfgCmd.val.char_val, controllerCfg.name.c_str()); // Controller Name
            ocaQue->push(cfgCmd);

            for (auto newZone : controllerCfg.zones)
            {
                // Create Worker Objects andd add to FusionBlock
                ZoneGroup *newGroup =
                    CreateZoneGroup(*newZone, proxy, commandQueue);

                // Add 'ZoneGroup' to 'Root' block
                bSuccess |= ::OcaLiteBlock::GetRootBlock().AddObject(*newGroup);

                // Add event subscriptions
                bSuccess |= AddSubscriptions(*newZone, gen_proxy);

                if (bSuccess)
                {
                    zoneONo.push_back(newGroup->GetObjectNumber());
                }
            }

            // Configuration done msg to UI
            cfgCmd.cmd         = CTRL_CMD_ZONE_CFG_END;
            cfgCmd.ono         = 0;  // Don't care for message
            cfgCmd.val.int_val = 0;  // Don't care for message
            ocaQue->push(cfgCmd);

        }
    }

    return bSuccess;
}

void ControlPalTeardownControls(std::vector<::OcaONo>& zoneBlockONo)
{
    for (auto tdownBlockONo : zoneBlockONo)
    {
        ::OcaLiteList<::OcaLiteObjectIdentification> tdownMembers;
        ::OcaLiteBlock* tdownBlock;

        // Get Zone(Block) object
        tdownBlock = static_cast<::OcaLiteBlock *>(
                  ::OcaLiteBlock::GetRootBlock().GetOCAObject(tdownBlockONo));

        if (OCASTATUS_OK == tdownBlock->GetMembers(tdownMembers))
        {
            // Clear the ZoneBlock
            for (::OcaUint16 i = 0; i < tdownMembers.GetCount(); i++)
            {
                // Get worker objects in zone
                ::OcaONo       workerONo   = tdownMembers.GetItem(i).GetONo();
                ::OcaLiteRoot* tdownWorker =
                                     tdownBlock->GetOCAObject(workerONo);

                // Remove worker object from zone
                tdownBlock->RemoveObject(workerONo);

                // Delete worker object
                delete tdownWorker;
            }

            // Remove Block object from Root block.
            ::OcaLiteBlock::GetRootBlock().RemoveObject(tdownBlockONo);

            // Delete Block object
            delete tdownBlock;
        }
    }
}

