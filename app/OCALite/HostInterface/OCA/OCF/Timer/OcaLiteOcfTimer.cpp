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

// Platform-specific implementation for getting current time
bool OcfLiteTimerGetTimeNow(UINT64& seconds, UINT32& nanoSeconds)
{
#ifdef _WIN32
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    
    // Convert FILETIME to Unix timestamp
    ULARGE_INTEGER ull;
    ull.LowPart = ft.dwLowDateTime;
    ull.HighPart = ft.dwHighDateTime;
    
    // FILETIME is in 100ns intervals since January 1, 1601
    // Unix timestamp is seconds since January 1, 1970
    // The difference is 11644473600 seconds
    UINT64 unixTime = (ull.QuadPart / 10000000ULL) - 11644473600ULL;
    seconds = unixTime;
    nanoSeconds = (UINT32)((ull.QuadPart % 10000000ULL) * 100);
    
    return true;
#else
    struct timeval tv;
    if (gettimeofday(&tv, NULL) == 0)
    {
        seconds = (UINT64)tv.tv_sec;
        nanoSeconds = (UINT32)(tv.tv_usec * 1000); // Convert microseconds to nanoseconds
        return true;
    }
    return false;
#endif
}
