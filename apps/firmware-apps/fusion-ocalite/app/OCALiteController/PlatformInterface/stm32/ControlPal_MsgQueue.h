#ifndef _CONTROLPAL_MSG_QUEUE_H_
#define _CONTROLPAL_MSG_QUEUE_H_

#include <cstdint>
#include <type_traits>

#if defined(__has_include)
#  if __has_include("cmsis_os2.h")
#    include "cmsis_os2.h"
#  else
#    error "ControlPal_MsgQueue.h requires cmsis_os2.h (CMSIS-RTOS v2)."
#  endif
#else
#  include "cmsis_os2.h"
#endif

template <typename T, unsigned int N = 8>
class ControlPal_MsgQueue {
public:
    // Default constructor: no RTOS handle yet
    ControlPal_MsgQueue()
        : m_rtosHandle(nullptr)
    {}

    // Constructor: accept an RTOS queue handle (osMessageQueueId_t is typedef'd to void*)
    explicit ControlPal_MsgQueue(void* rtosHandle)
        : m_rtosHandle(rtosHandle)
    {}

    // Set/replace the handle later
    void setHandle(void* rtosHandle) { m_rtosHandle = rtosHandle; }

    // Push a value (non-blocking, immediate return). If RTOS queue is full, return false.
    // Returns true on success.
    bool push(const T& value) {
        if (!m_rtosHandle) {
            // No RTOS handle — caller must provide one for STM32 build; indicate failure.
            return false;
        }

        // Safety: ensure the caller-created queue element size matches sizeof(T).
        // There's no portable runtime check here; rely on correct queue creation.
        osStatus_t st = osMessageQueuePut(static_cast<osMessageQueueId_t>(m_rtosHandle),
                                          const_cast<T*>(&value), 0, 0);
        return (st == osOK);
    }

    // Push by move (if T is movable). Returns true on success.
    bool push(T&& value) {
        if (!m_rtosHandle) return false;
        // use a local copy because osMessageQueuePut expects a pointer to memory
        // that must remain valid until the call completes
        T tmp = std::move(value);
        osStatus_t st = osMessageQueuePut(static_cast<osMessageQueueId_t>(m_rtosHandle),
                                          &tmp, 0, 0);
        return (st == osOK);
    }

    // Blocking pop: waits indefinitely until an item is available.
    // Caller-supplied reference `value` will be filled and function returns true on success.
    bool wait_and_pop(T& value) {
        if (!m_rtosHandle) return false;
        osStatus_t st = osMessageQueueGet(static_cast<osMessageQueueId_t>(m_rtosHandle),
                                          &value, nullptr, osWaitForever);
        return (st == osOK);
    }

    // Try pop (non-blocking). Returns true if an item was popped.
    bool try_pop(T& value) {
        if (!m_rtosHandle) return false;
        osStatus_t st = osMessageQueueGet(static_cast<osMessageQueueId_t>(m_rtosHandle),
                                          &value, nullptr, 0);
        return (st == osOK);
    }

    // Convenience: check if handle is set
    bool valid() const { return (m_rtosHandle != nullptr); }

private:
    // RTOS handle stored as void* to accept osMessageQueueId_t
    void* m_rtosHandle;
};

#endif // _CONTROLPAL_MSG_QUEUE_H_
