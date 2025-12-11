/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ControlPalMsgInterface - Message interface class
 *
 */
#ifndef CONTROLPAL_MSG_INTERFACE_H
#define CONTROLPAL_MSG_INTERFACE_H

// ---- Include system wide include files ----

// ---- Include local include files ----
#if defined(STM32H7S7xx) || defined(STM32N657xx)
#include "PlatformInterface/stm32/OcaPlatformSTM32.h"
#else
#include "PlatformInterface/linux/OcaLiteOcfMsgQueue.h"
#endif

// ---- Referenced classes and types ----

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Class Definition ----
template <typename T>
class ControlPalMsgInterface 
{
public:
    ControlPalMsgInterface(void *pMsgQueue)
    {
        m_msgQueue = static_cast<ControlPal_MsgQueue<T>*>(pMsgQueue);
    }

    virtual void SendValue() = 0;

protected:

    void PushToMsgQueue(T& payload)
    {
        m_msgQueue->push(payload);
    }

private:
    ControlPal_MsgQueue<T> *m_msgQueue;
};

#endif
