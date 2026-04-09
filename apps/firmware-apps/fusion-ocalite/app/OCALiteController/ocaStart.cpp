/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// ocaStart.cpp : Defines the entry point for the OCA Controller application.
//

#include <unistd.h>
#include <sys/time.h>
#include <iostream>
#include <vector>
#include "lwip/netif.h"
#include "PlatformInterface/stm32/OcaPlatformSTM32.h"
#include "HostInterface/CommandInterface/CommandInterface.h"
#include <string>
#include <vector>

extern "C" {
    #include "dnssd.h"
    #include "lwip.h"
}

// External queue handles defined in main.c
extern osMessageQueueId_t AEStoUIHandle;
extern osMessageQueueId_t UItoAESHandle;

void uiThreadProc(void *queue);

// Forward declaration for OCA main function
extern bool ocaMain(std::string& customNodeId,
                   std::vector<ControlPal_MsgQueue<ControllerCmdIntfc>*> msgQues);

/* Definitions for UiProc */
osThreadId_t UiProcTaskHandle;
const osThreadAttr_t UiProcTask_attributes = {
  .name = "UiProcTask",
  .stack_size = 2*1024,
  .priority = (osPriority_t) osPriorityNormal,
};

extern "C" void ocaStart(void* argument)
{
    (void)argument;

    printf("OCA: Starting task...\n");


    while (!dhcp_supplied_address(&gnetif))
        osDelay(100);

    printf("OCA: Network ready! IP: %s\n", ip4addr_ntoa(netif_ip4_addr(netif_default)));

    // Create platform message queues wrapping the RTOS queues
    try {
        ControlPal_MsgQueue<ControllerCmdIntfc> ocaQueue(AEStoUIHandle);
        ControlPal_MsgQueue<ControllerCmdIntfc> uiQueue(UItoAESHandle);

        std::vector<ControlPal_MsgQueue<ControllerCmdIntfc>*> msgQues;
        msgQues.push_back(&ocaQueue);
        msgQues.push_back(&uiQueue);

        // Create UI task
        // UiProcTaskHandle = osThreadNew(uiThreadProc, static_cast<void *>(&msgQues), &UiProcTask_attributes);
        // if (UiProcTaskHandle == NULL)
        // {
        //     printf("Failed to create UI task\r\n");
        // }
        // else
        // {
        //     printf("UI task created successfully\r\n");
        // }

        // Use node ID "1" (could load from flash later)
        std::string customNodeId = "ctrl1";

        printf("OCA: Starting main loop...\n");

        // Start OCA main processing - this will block
        if (!ocaMain(customNodeId, msgQues)) {
            printf("OCA: Main loop failed!\n");
        }
    }
    catch (const std::exception& e) {
        printf("OCA: Exception: %s\n", e.what());
    }

    printf("OCA: Task exiting\n");
    osThreadExit();
}

