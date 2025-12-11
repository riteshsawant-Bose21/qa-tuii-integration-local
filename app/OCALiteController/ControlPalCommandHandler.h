#ifndef _CONTROLPAL_COMMAND_HANDLER_H
#define _CONTROLPAL_COMMAND_HANDLER_H

#if defined(STM32H7S7xx) || defined(STM32N657xx)
#include "PlatformInterface/stm32/OcaPlatformSTM32.h"
#else
#include "PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#endif
#include "HostInterface/CommandInterface/CommandInterface.h"
#include "../common/FusionProxy.h"
#include "ControlPalSideBandInterface.h"

void ControlPalUICommandHandler(
                      ControlPal_MsgQueue<ControllerCmdIntfc> *cmdQueue,
                      std::vector<::OcaONo>& zoneONos,
                      FusionProxy& fusion_proxy,
                      SidebandInterface &fServIntfc);

#endif
