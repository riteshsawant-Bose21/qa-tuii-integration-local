/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALiteController.cpp : Defines the entry point for the OCA Controller application.
//

#if 0
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
#endif
#include <unistd.h>
#include <sys/time.h>
#include <iostream>
#include "PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#include "HostInterface/CommandInterface/CommandInterface.h"

bool ocaMain(std::string& customNodeId,
             std::vector<ControlPal_MsgQueue<ControllerCmdIntfc>*> msgQues);

// TODO: Add signal capturing to exit gracefully.

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

    // TODO: Create que objects
    ControlPal_MsgQueue<ControllerCmdIntfc> ocaQueue; // AES70 --> UI
    ControlPal_MsgQueue<ControllerCmdIntfc> uiQueue;   //    UI --> AES70

    // Populate vector that will be passed to UI task
    std::vector<ControlPal_MsgQueue<ControllerCmdIntfc>*> msgQues;
    msgQues.push_back(&ocaQueue);
    msgQues.push_back(&uiQueue);

#if 0
    // TODO: Create User Interface task. This task handles UI,
    //       Physical Encoders etc.
    std::thread *uiThread = OcaLiteOcfThread_create(ControllerView,
                                              static_cast<void *>(&msgQues));
#endif

    // Start OCA processing
    return ocaMain(customNodeId, msgQues);
}

