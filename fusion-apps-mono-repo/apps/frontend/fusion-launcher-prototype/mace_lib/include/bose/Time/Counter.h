#pragma once
#ifndef COUNTER_H
#define COUNTER_H

#include <chrono>

namespace bosepro
{
    /**
     * \class       Counter
     *
     * \brief       Basic high resolution counter
     *
     * \details     
     */
    class Counter final
    {
        using Clock = std::chrono::high_resolution_clock;
        using Time = std::chrono::time_point<Clock>;

        auto                    elapsed()                                   const
        {
            if (!isZero(_start))
            {
                const Time tStop = !isZero(_stop) ? _stop : Clock::now();

                return tStop - _start;
            }

            return Time::duration::zero();
        }

    public:
        Counter(bool bStart = true) { reset(); if (bStart)start(); }
        Counter(const Counter&) = delete;
        Counter& operator=(const Counter&) = delete;
        Counter(Counter&&) = delete;
        Counter& operator=(Counter&&) = delete;
        ~Counter() = default;

        inline void             start(bool bReset = true) { if (bReset)reset(); if (isZero(_start))_start = Clock::now(); }
        inline uint64_t         stop() { _stop = Clock::now(); return getElapsedMilleseconds(); }

        inline uint64_t         getElapsedSeconds()                         const { return std::chrono::duration_cast<std::chrono::seconds>(elapsed()).count(); }
        inline uint64_t         getElapsedMilleseconds()                    const { return std::chrono::duration_cast<std::chrono::milliseconds>(elapsed()).count(); }
        inline uint64_t         getElapsedMicroseconds()                    const { return std::chrono::duration_cast<std::chrono::microseconds>(elapsed()).count(); }

    protected:
        inline void             reset() { _start = {}; _stop = {}; }

        static bool             isZero(const Time& t) { return t.time_since_epoch().count() == 0; }

    private:
        Time                    _start;
        Time                    _stop;
    };
}//bosepro

#endif //COUNTER_H