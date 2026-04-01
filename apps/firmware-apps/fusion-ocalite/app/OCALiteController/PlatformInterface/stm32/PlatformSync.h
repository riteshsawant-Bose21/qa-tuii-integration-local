#ifndef OCA_PLATFORM_STM32_PLATFORMSYNC_H
#define OCA_PLATFORM_STM32_PLATFORMSYNC_H

// Minimal sync primitives mapping to CMSIS-RTOS v2 or FreeRTOS
#include "cmsis_os2.h" // STM32Cube project already uses osThreadNew/osMessageQueue
#include <cstdint>

namespace OcaPlatform {

class Mutex {
public:
    Mutex() { m = osMutexNew(nullptr); }
    ~Mutex() { if (m) osMutexDelete(m); }
    Mutex(const Mutex&) = delete;
    Mutex& operator=(const Mutex&) = delete;
    void lock() { if (m) osMutexAcquire(m, osWaitForever); }
    bool try_lock() { return (osMutexAcquire(m, 0) == osOK); }
    void unlock() { if (m) osMutexRelease(m); }
private:
    osMutexId_t m{nullptr};
};

class LockGuard {
public:
    explicit LockGuard(Mutex &m_) : mtx(m_) { mtx.lock(); }
    ~LockGuard() { mtx.unlock(); }
private:
    Mutex &mtx;
};

// Simple condition variable using semaphore
class ConditionVariable {
public:
    ConditionVariable() { sem = osSemaphoreNew(1, 0, nullptr); }
    ~ConditionVariable() { if (sem) osSemaphoreDelete(sem); }
    void notify_one() { if (sem) osSemaphoreRelease(sem); }
    void wait(Mutex &m) {
        m.unlock();
        if (sem) osSemaphoreAcquire(sem, osWaitForever);
        m.lock();
    }
private:
    osSemaphoreId_t sem{nullptr};
};

// Thread wrapper
using ThreadFunction = void(*)(void*);
class Thread {
public:
    Thread() = default;
    ~Thread() = default;
    bool create(ThreadFunction fn, void* arg, const char* name = "oca", uint32_t stack = 1024, osPriority_t prio = osPriorityNormal) {
        osThreadAttr_t attr = {0};
        attr.name = name;
        attr.stack_size = stack;
        attr.priority = prio;
        tid = osThreadNew(fn, arg, &attr);
        return (tid != nullptr);
    }
    void detach() { /* no-op */ }
    void join() { /* join not supported in this simple wrapper */ }
private:
    osThreadId_t tid{nullptr};
};

} // namespace OcaPlatform

#endif // OCA_PLATFORM_STM32_PLATFORMSYNC_H
