/*  By downloading or using this file, the user agrees to be bound by the terms of the license 
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 */

/*
 *  Description         : The timer implementation of the Host Interface for
 *                        a platform running FreeRTOS.
 *
 */

// ---- Include system wide include files ----
#ifdef _WIN32
#include <Windows.h>
#else
#include <sys/time.h>
#include <stdio.h>
#include <unistd.h>
#endif

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include <HostInterfaceLite/OCA/OCF/Timer/IOcfLiteTimer.h>

// ---- Helper types and constants ----

// Platform-specific implementation of static method 'GetTimerTickCount' of base class
UINT32 OcfLiteTimerGetTimerTickCount(void)
{
#ifdef _WIN32
    return ::GetTickCount();
#else
    struct timeval start;
    gettimeofday(&start, NULL);
    return (UINT32)((start.tv_sec) * 1000 + start.tv_usec/1000.0);
#endif
}

// Get current time in nanoseconds since Unix epoch
bool OcfLiteTimerGetTimeNow(UINT64& timeNow, UINT32& timeNowNs)
{
#ifdef _WIN32
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    
    // Convert to Unix timestamp (100-nanosecond intervals since Jan 1, 1601)
    UINT64 winTime = ((UINT64)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
    // Convert to Unix epoch (subtract intervals from 1601 to 1970)
    UINT64 unixTime = (winTime - 116444736000000000ULL) / 10000000ULL;
    UINT32 nanos = (UINT32)((winTime - 116444736000000000ULL) % 10000000ULL) * 100;
    
    timeNow = unixTime;
    timeNowNs = nanos;
    return true;
#else
    struct timeval tv;
    if (gettimeofday(&tv, NULL) == 0)
    {
        timeNow = (UINT64)tv.tv_sec;
        timeNowNs = (UINT32)(tv.tv_usec * 1000); // Convert microseconds to nanoseconds
        return true;
    }
    return false;
#endif
}
