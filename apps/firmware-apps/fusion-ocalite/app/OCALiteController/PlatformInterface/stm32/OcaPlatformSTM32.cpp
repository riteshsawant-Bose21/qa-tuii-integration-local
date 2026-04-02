#include <new> // Required for placement new and delete
#ifdef __cplusplus
extern "C" {
#endif
#include "FreeRTOS.h"
#include "task.h" // For pvPortMalloc and vPortFree
#ifdef __cplusplus
}
#endif
#include "OcaPlatformSTM32.h"
#include <sys/time.h>

namespace OcaPlatform {

uint64_t GetTickMs() {
    if (osKernelGetState() == osKernelRunning) {
        return osKernelGetTickCount();
    }
    return HAL_GetTick();
}

void Sleep(uint32_t ms) {
    if (osKernelGetState() == osKernelRunning) {
        osDelay(ms);
    } else {
        HAL_Delay(ms);
    }
}

void Log(LogLevel level, const char* msg) {
    const char* prefix = "";
    switch (level) {
        case LogLevel::Debug:   prefix = "[OCA-D] "; break;
        case LogLevel::Info:    prefix = "[OCA-I] "; break;
        case LogLevel::Warning: prefix = "[OCA-W] "; break;
        case LogLevel::Error:   prefix = "[OCA-E] "; break;
    }
    printf("%s%s\n", prefix, msg);
}

void LogDebug(const char* msg)   { Log(LogLevel::Debug, msg); }
void LogInfo(const char* msg)    { Log(LogLevel::Info, msg); }
void LogWarning(const char* msg) { Log(LogLevel::Warning, msg); }
void LogError(const char* msg)   { Log(LogLevel::Error, msg); }

bool Initialize() {
    LogInfo("Platform initializing...");
    return true;
}

void Deinitialize() {
    LogInfo("Platform shutting down");
}

} // namespace OcaPlatform

// POSIX compatibility layer implementation
extern "C" {

int gettimeofday(struct timeval *tp, void *tzp) {
    if (tp) {
        uint64_t ms = OcaPlatform::GetTickMs();
        tp->tv_sec = static_cast<long>(ms / 1000U);
        tp->tv_usec = static_cast<long>((ms % 1000U) * 1000U);
    }
    (void)tzp;
    return 0;
}

//int _gettimeofday_r(void* r, struct timeval *tp, void *tzp) {
int _gettimeofday_r(struct _reent *r, struct timeval *tp, void *tzp) {
    (void)r;
    return gettimeofday(tp, tzp);
}

int gethostname(char *name, size_t len) {
    static const char* hostname = "STM32H7";
    if (!name || len == 0) return -1;
    strncpy(name, hostname, len);
    name[len-1] = '\0';  // Ensure null termination
    return 0;
}

int _getentropy(void *buffer, size_t length) {
    if (!buffer) return -1;
    uint8_t* buf = static_cast<uint8_t*>(buffer);
    for (size_t i = 0; i < length; ++i) {
        buf[i] = static_cast<uint8_t>(HAL_GetTick() & 0xFF); // Simple entropy source
    }
    return 0;
}
} // extern "C"

// In a .cpp file (e.g., freertos_heap_allocator.cpp)

void* operator new(size_t size)
{
    return pvPortMalloc(size);
}

void operator delete(void* ptr) noexcept
{
    vPortFree(ptr);
}

// Optional: Overload for array new/delete
void* operator new[](size_t size)
{
    return pvPortMalloc(size);
}

void operator delete[](void* ptr) noexcept
{
    vPortFree(ptr);
}

