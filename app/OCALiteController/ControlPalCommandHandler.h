#ifndef _CONTROLPAL_COMMAND_HANDLER_H
#define _CONTROLPAL_COMMAND_HANDLER_H

#include "PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#include "HostInterface/CommandInterface/CommandInterface.h"
#include "../common/FusionProxy.h"

void ControlPalUICommandHandler(
                      ControlPal_MsgQueue<ControllerCmdIntfc> *cmdQueue,
                      std::vector<::OcaONo>& zoneONos,
                      FusionProxy& fusion_proxy);

#endif
