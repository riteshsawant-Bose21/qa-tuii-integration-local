#include <unistd.h>
#include <sys/time.h>
#include <iostream>
#include "ControllerMenu.h"
#include "../../../PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#include "../../../PlatformInterface/linux/OcaLiteOcfThread.h"
#include "../../../HostInterface/CommandInterface/CommandInterface.h"

#define VIEW_GAIN_INCREMENT_STEP 0.5f

void read_input_thread(void *arg);

void GetNewMessages(ControlPal_MsgQueue<ControllerCmdIntfc> *cmdQueue,
                    ControllerCmdIntfc& newCmd)
{
    cmdQueue->wait_and_pop(newCmd);
}

bool ViewCheckNewMessages(ControlPal_MsgQueue<ControllerCmdIntfc> *cmdQueue,
                    ControllerCmdIntfc& newCmd)
{
    return cmdQueue->try_pop(newCmd);
}

void ViewIncreaseGain(ControllerCmdIntfc &msg)
{
    // NOTE: ONo set in the calling fuction
    msg.cmd = CTRL_CMD_GAIN_SET;
    msg.val.flt_val = VIEW_GAIN_INCREMENT_STEP;
}

void ViewDecreaseGain(ControllerCmdIntfc &msg)
{
    // NOTE: ONo set in the calling fuction
    msg.cmd = CTRL_CMD_GAIN_SET;
    msg.val.flt_val = -1.0 * VIEW_GAIN_INCREMENT_STEP;
}

void ViewToggleMute(ControllerCmdIntfc &msg)
{
    // NOTE: ONo set in the calling fuction
    // NOTE: val is set in the AES module
    msg.cmd = CTRL_CMD_MUTE_SET;
}

void ViewCycleSource(ControllerCmdIntfc &msg)
{
    // NOTE: ONo set in the calling fuction
    // NOTE: val is set in the AES module
    msg.cmd = CTRL_CMD_SOURCE_SET;
}

void ViewCycleZone(ControllerCmdIntfc &msg)
{
    (void)msg;  // Not used

    // Do nothing
}

void ViewProcessMessages(ControllerMenu &m, ControllerCmdIntfc& newCmd)
{
    // Handle configuration messages
    switch (newCmd.cmd)
    { 
        case CTRL_CMD_GAIN_SET:
            m.setGain(newCmd.ono, newCmd.val.flt_val);
            break;

        case CTRL_CMD_MUTE_SET:
            m.setMute(newCmd.ono, newCmd.val.int_val);
            break;

        case CTRL_CMD_SOURCE_SET:
            m.setSource(newCmd.ono, newCmd.val.int_val);
            break;

        default:
            std::cout << " ViewProcessMessages Processing ERROR!!!" << std::endl;
            break;
    }
}

void ControllerViewProc(void *queue)
{
    std::vector<ControlPal_MsgQueue<ControllerCmdIntfc>*> *msgQues =
        static_cast<std::vector<ControlPal_MsgQueue<ControllerCmdIntfc>*>*>(queue);

    std::vector<std::string> sourceNames;
    std::string zoneName;
    uint32_t sourceIndex = 0;
    uint32_t sourceCount = 0;

    // AES70 --> UI
    ControlPal_MsgQueue<ControllerCmdIntfc> *ocaMsgQueue = msgQues->at(0);
    // UI --> AES70
    ControlPal_MsgQueue<ControllerCmdIntfc> *uiMsgQueue = msgQues->at(1);

    ControllerCmdIntfc newCmd;
    bool cfgStart(false);

    // Define globals used by the menu display
    float       g_gain = 0.0;
    uint32_t    g_mute = 1;
    std::string g_source;

    // Wait for configuration start messages
    while (!cfgStart)
    {
        // Check queue for messages
        GetNewMessages(ocaMsgQueue, newCmd);
        if (newCmd.cmd == CTRL_CMD_ZONE_CFG_START)
        {
            zoneName = newCmd.val.char_val;
            cfgStart = true;
        }
    }

    // Initialize Menu/UI
    ControllerMenu m(zoneName, static_cast<void *>(uiMsgQueue));

    m.addOption("Cycle    ZONE", ViewCycleZone);
    m.addOption("Increase GAIN (+)", ViewIncreaseGain);
    m.addOption("Decrease GAIN (-)", ViewDecreaseGain);
    m.addOption("Toggle   MUTE", ViewToggleMute);
    m.addOption("Cycle    SOURCE", ViewCycleSource);

    // Check queue for configuration messages
    uint32_t currZoneONo = 0;
    while (cfgStart)
    {
        GetNewMessages(ocaMsgQueue, newCmd);

        // Handle configuration messages
        switch (newCmd.cmd)
        { 
            case CTRL_CMD_ZONE_NAME_SET:
                if ((currZoneONo !=0) && (currZoneONo != newCmd.ono))
                {
                    // New zone starting, save current zone
                    m.addZone(currZoneONo, zoneName, g_gain, g_mute,
                            sourceIndex, sourceCount, sourceNames);
                }
                currZoneONo = newCmd.ono;  // Current zone being processed
                zoneName = newCmd.val.char_val;
                break;
            case CTRL_CMD_GAIN_SET:

                if (currZoneONo == newCmd.ono)
                {
                    g_gain = newCmd.val.flt_val;
                }
                else
                {
                    //OCA_LOG_ERROR("✗ COnfiguration ONo Mismatch.");
                }
                break;
            case CTRL_CMD_MUTE_SET:
                if (currZoneONo == newCmd.ono)
                {
                    g_mute = newCmd.val.int_val;
                }
                else
                {
                    //OCA_LOG_ERROR("✗ COnfiguration ONo Mismatch.");
                }
                break;
            case CTRL_CMD_SOURCE_SET:
                if (currZoneONo == newCmd.ono)
                {
                    sourceIndex = newCmd.val.int_val;
                }
                else
                {
                    //OCA_LOG_ERROR("✗ COnfiguration ONo Mismatch.");
                }
                break;
            case CTRL_CMD_SOURCE_COUNT_SET:
                if (currZoneONo == newCmd.ono)
                {
                    sourceCount = newCmd.val.int_val;
                }
                else
                {
                    //OCA_LOG_ERROR("✗ COnfiguration ONo Mismatch.");
                }
                break;
            case CTRL_CMD_SOURCE_1_SET:
            case CTRL_CMD_SOURCE_2_SET:
            case CTRL_CMD_SOURCE_3_SET:
            case CTRL_CMD_SOURCE_4_SET:
            case CTRL_CMD_SOURCE_5_SET:
                if (currZoneONo == newCmd.ono)
                {
                    sourceNames.push_back(newCmd.val.char_val);
                }
                else
                {
                    //OCA_LOG_ERROR("✗ COnfiguration ONo Mismatch.");
                }
                break;
            case CTRL_CMD_ZONE_CFG_END:
                // Add last Zone
                m.addZone(currZoneONo, zoneName, g_gain, g_mute,
                        sourceIndex, sourceCount, sourceNames);
                cfgStart = false;
                break;

        }
    }

    std::cout << "Configuration Done.\n";

    std::thread readThread = OcaLiteOcfThread_create(read_input_thread, NULL);

    while(true)
    {
        if (ViewCheckNewMessages(ocaMsgQueue, newCmd))
        {
            ViewProcessMessages(m, newCmd);
        }
        m.run();
    }

    std::cout << "Program finished.\n";
}
