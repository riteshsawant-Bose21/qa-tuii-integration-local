/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALiteController.cpp : Defines the entry point for the OCA Controller application.
//

#include <vector>
#include <algorithm>
#include <iostream>
#include <iterator>
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
#include <OCC/ControlDataTypes/OcaLiteBlockMember.h>
#include <OCC/ControlDataTypes/OcaLiteList.h>
#include <OCC/ControlDataTypes/OcaLiteMethod.h>
#include <unistd.h>
#include <iostream>
#include "../common/models/Models.h"  // For deserializing JSON configuration
#include "../common/models/WallControllerConfigParser.h"  // For deserializing JSON configuration
#include "../common/FusionOCAConstants.h" // For custom ONO constants
#include "../common/workers/ZoneGroup.h"
#include "workers/ControlPalGainActuator.h"
#include "workers/ControlPalMuteActuator.h"
#include "workers/ControlPalSwitchActuator.h"
#include "ControlPalCommandHandler.h"
#include "ControlPalOcaUtils.h"
#include "ControlPalSideBandInterface.h"
#ifdef STM32H7S7xx
#include "../PlatformInterface/stm32/OcaPlatformSTM32.h"
#else
#include <sys/time.h>
#endif

bool CheckNewMessages(ControlPal_MsgQueue<ControllerCmdIntfc> *cmdQueue,
                      ControllerCmdIntfc& newCmd)
{
    return cmdQueue->try_pop(newCmd);
}

void ProcessOcaCommand(ControllerCmdIntfc& newCmd, FusionProxy& fusion_proxy)
{
    ::OcaLiteRoot *target;

    switch (newCmd.cmd)
    {
        case CTRL_CMD_GAIN_GET:
            // Verify Class ID
            target = FindObject(newCmd.ono, ::OcaLiteGain::CLASS_ID);
            if (target)
            {
                //Send back value
                static_cast<::ControlPalGainActuator*>(target)->SendValue();
            }
            break;

        case CTRL_CMD_MUTE_GET:
            // Verify Class ID
            target = FindObject(newCmd.ono, ::OcaLiteMute::CLASS_ID);
            if (target)
            {
                //Send back value
                static_cast<::ControlPalMuteActuator*>(target)->SendValue();

            }
            break;

        case CTRL_CMD_SOURCE_GET:
            // Verify Class ID
            target = FindObject(newCmd.ono, ::OcaLiteSwitch::CLASS_ID);
            if (target)
            {
                //Send back value
                static_cast<::ControlPalSwitchActuator*>(target)->SendValue();
            }
            break;

        case CTRL_CMD_GAIN_SET:
            // Verify Class ID
            target = FindObject(newCmd.ono, ::OcaLiteGain::CLASS_ID);
            if (target)
            {
                ::OcaDB currGain, minGain, maxGain;
                ::ControlPalGainActuator *gainObj =
                    static_cast<::ControlPalGainActuator*>(target);

                // Get min & max Gain
                    static_cast<::ControlPalGainActuator*>(target)->GetGain(
                            currGain,   //Throwaway
                            minGain,
                            maxGain);

                // Verify no gain updates are currently in progress
                if (gainObj->UpdatesDone())
                {
                    // All acks received
                    gainObj->ClearSentCount();
                }

                currGain = newCmd.val.flt_val;

                // Clamp gain value
                if (currGain < minGain)
                {
                    currGain = minGain;
                }
                else if (currGain > maxGain)
                {
                    currGain = maxGain;
                }

                if (gainObj->LastUIGainGet() != currGain)
		{
			gainObj->LastGainSet(currGain);

			// Send message to Device
			fusion_proxy.ConcreteGainActuator_SetGain(
				target->GetObjectNumber(), currGain);
		}
            }
            break;

        case CTRL_CMD_MUTE_SET:
            // Verify Class ID
            target = FindObject(newCmd.ono, ::OcaLiteMute::CLASS_ID);
            if (target)
            {
                ::OcaLiteMuteState newState;
                static_cast<::ControlPalMuteActuator*>(target)->GetState(newState);

                // Toggle state
                if (newState == OCAMUTESTATE_MUTED)
                {
                    newState = OCAMUTESTATE_UNMUTED;
                }
                else
                {
                    newState = OCAMUTESTATE_MUTED;
                }

                // Send message to Device
                fusion_proxy.ConcreteMuteActuator_SetMute(
                                   target->GetObjectNumber(), newState);
            }
            break;

        case CTRL_CMD_SOURCE_SET:
            // Verify Class ID
            target = FindObject(newCmd.ono, ::OcaLiteSwitch::CLASS_ID);
            if (target)
            {
                ::OcaUint16 newPos, minPos, maxPos;
                static_cast<::ControlPalSwitchActuator*>(target)->GetPosition(
                                                    newPos, minPos, maxPos);
#ifdef STM32H7S7xx
                if ( (newCmd.val.int_val <= maxPos) &&
                     (newCmd.val.int_val >= minPos) )
                {
                    // Send message to Device
                    fusion_proxy.ConcreteSwitchActuator_SetSwitch(
                            target->GetObjectNumber(), newCmd.val.int_val);
                }
#else
                // Move to next position
                newPos = (newPos +1) % (maxPos - minPos + 1);

                // Send message to Device
                fusion_proxy.ConcreteSwitchActuator_SetSwitch(
                         target->GetObjectNumber(), newPos);
#endif
            }
            break;

        default:
            break;
    }
}

void ProcessSidebandCommand(ControllerCmdIntfc& newCmd,
                            SidebandInterface &fServIntfc)
{
    switch (newCmd.cmd)
    {
        case CTRL_CMD_REV_WINK_SET:
            {
                //TODO:
                std::ostringstream message;
                struct timeval tv;
                uint64_t timeNow;

                gettimeofday(&tv, NULL);
                timeNow = tv.tv_sec*1000000 + tv.tv_usec;
                message << "{"
                    << "\"action\": \"performReverseWink\", "
                    << "\"payload\": {"
                    << "\"duration\": \"" << 5000 << "\", "
                    << "\"timestamp\": \"" << timeNow << "\""
                    << "}"
                    << "}";
                fServIntfc.sendMessage(message.str());
            }
            break;

        case CTRL_CMD_WINK_SET:
            {
                //TODO:
                std::ostringstream message;
                message << "{"
                    << "\"action\": \"winkResponse\", "
                    << "\"payload\": {"
                    << "\"status\": \"done\""
                    << "}"
                    << "}";
                fServIntfc.sendMessage(message.str());
            }
            break;

        default:
            break;
    }
}

void ControlPalUICommandHandler(
                      ControlPal_MsgQueue<ControllerCmdIntfc> *cmdQueue,
                      std::vector<::OcaONo>& zoneONos,
                      FusionProxy& fusion_proxy,
                      SidebandInterface &fServIntfc)
{
    ControllerCmdIntfc newCmd;

    while (CheckNewMessages(cmdQueue, newCmd))
    {
        // Check if Sideband message
        if ((newCmd.cmd >= CTRL_CMD_REV_WINK_SET) &&
            (newCmd.cmd < CTRL_CMD_MAX))
        {
           ProcessSidebandCommand(newCmd, fServIntfc);
        }
        else
        {
            auto it = std::find(zoneONos.begin(), zoneONos.end(),
                    static_cast<::OcaONo>(newCmd.ono));

            if (it != zoneONos.end())
            {
                ProcessOcaCommand(newCmd, fusion_proxy);
            }
        }
    }
}
