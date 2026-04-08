#ifndef OCALITE_PLATFORM_STM32_PLATFORMMUTEX_H
#define OCALITE_PLATFORM_STM32_PLATFORMMUTEX_H

// PlatformMutex.h
// TODO: this is not needed now(may need later) refer PlatformSync.h for simpler mutex implementation.
#if 0
#if defined(__cplusplus) == 0
#error "PlatformMutex.h requires a C++ compiler"
#endif

// Choose CMSIS-RTOS v2 when available (project already uses osThreadNew).
#if defined(USE_CMSIS_OS) || defined(__CMSIS_RTOS) || defined(USE_HAL_DRIVER)
  #include "cmsis_os2.h"
  #define OCALITE_MUTEX_USE_CMSIS 1
#else
  #include "FreeRTOS.h"
  #include "semphr.h"
  #define OCALITE_MUTEX_USE_FREERTOS 1
#endif

#include <cstdint>

namespace OcaPlatform {

class Mutex {
public:
    Mutex() noexcept
    {
#if defined(OCALITE_MUTEX_USE_CMSIS)
        // create default mutex. If needed we can create non-recursive via attributes.
        m_id = osMutexNew(nullptr);
#elif defined(OCALITE_MUTEX_USE_FREERTOS)
        m_sem = xSemaphoreCreateMutex();
#endif
    }

    ~Mutex() noexcept
    {
#if defined(OCALITE_MUTEX_USE_CMSIS)
        if (m_id) osMutexDelete(m_id);
#elif defined(OCALITE_MUTEX_USE_FREERTOS)
        if (m_sem) vSemaphoreDelete(m_sem);
#endif
    }

    // non-copyable
    Mutex(const Mutex&) = delete;
    Mutex& operator=(const Mutex&) = delete;

    void lock() noexcept
    {
#if defined(OCALITE_MUTEX_USE_CMSIS)
        if (m_id) osMutexAcquire(m_id, osWaitForever);
#elif defined(OCALITE_MUTEX_USE_FREERTOS)
        if (m_sem) xSemaphoreTake(m_sem, portMAX_DELAY);
#endif
    }

    bool try_lock() noexcept
    {
#if defined(OCALITE_MUTEX_USE_CMSIS)
        if (!m_id) return false;
        return (osMutexAcquire(m_id, 0) == osOK);
#elif defined(OCALITE_MUTEX_USE_FREERTOS)
        if (!m_sem) return false;
        return (xSemaphoreTake(m_sem, 0) == pdTRUE);
#endif
    }

    void unlock() noexcept
    {
#if defined(OCALITE_MUTEX_USE_CMSIS)
        if (m_id) osMutexRelease(m_id);
#elif defined(OCALITE_MUTEX_USE_FREERTOS)
        if (m_sem) xSemaphoreGive(m_sem);
#endif
    }

private:
#if defined(OCALITE_MUTEX_USE_CMSIS)
    osMutexId_t m_id{nullptr};
#elif defined(OCALITE_MUTEX_USE_FREERTOS)
    SemaphoreHandle_t m_sem{nullptr};
#endif
};

class LockGuard {
public:
    explicit LockGuard(Mutex &m) noexcept : m_mutex(m) { m_mutex.lock(); }
    ~LockGuard() noexcept { m_mutex.unlock(); }
    LockGuard(const LockGuard&) = delete;
    LockGuard& operator=(const LockGuard&) = delete;
private:
    Mutex &m_mutex;
};

} // namespace OcaPlatform
#endif
#endif // OCALITE_PLATFORM_STM32_PLATFORMMUTEX_H
