#ifndef OCA_PLATFORM_STM32_H
#define OCA_PLATFORM_STM32_H

#include "cmsis_os2.h"
#include "main.h"
#include "lwip/sys.h"
#include <cstdint>
#include <cstring>

// Platform synchronization primitives
#include "PlatformSync.h"
#include "ControlPal_MsgQueue.h"

namespace OcaPlatform {

// Platform capabilities
static constexpr bool HasNetworkSupport = true;
static constexpr bool HasTouchGFX = true;
static constexpr uint32_t DefaultStackSize = 8192;
static constexpr uint32_t DefaultQueueSize = 16;

// Synchronization primitives
using Mutex = OcaPlatform::Mutex;
using LockGuard = OcaPlatform::LockGuard;
using Thread = OcaPlatform::Thread;
using ConditionVariable = OcaPlatform::ConditionVariable;

// Message queue with default size
template <typename T>
using MsgQueue = ControlPal_MsgQueue<T>;

// Platform time functions
uint64_t GetTickMs();
void Sleep(uint32_t ms);

// Logging levels
enum class LogLevel {
    Debug,
    Info,
    Warning,
    Error
};

// Logging functions
void Log(LogLevel level, const char* msg);
void LogDebug(const char* msg);
void LogInfo(const char* msg);
void LogWarning(const char* msg);
void LogError(const char* msg);

// Platform initialization
bool Initialize();
void Deinitialize();

} // namespace OcaPlatform

// POSIX compatibility layer declarations
extern "C" {
    int gettimeofday(struct timeval *tp, void *tzp);
    int _gettimeofday_r(struct _reent *r, struct timeval *tp, void *tzp);
    //int _gettimeofday_r(void* r, struct timeval *tp, void *tzp);
    int gethostname(char *name, size_t len);
    int _getentropy(void *buffer, size_t length);
}

#endif // OCA_PLATFORM_STM32_H
