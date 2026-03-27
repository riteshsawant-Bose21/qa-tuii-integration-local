#pragma once

#include <spdlog/spdlog.h>

#include <cstdint>
#include <time.h>
#include <fstream>
#include <iostream>

namespace bosepro {


/// A class for profiling execution time.  This tracks the execution time (or
/// MIPS) across multiple timing runs, reporting the time of the first run, the
/// maximum time of all runs (except the first), and the average time of all
/// runs (except the first).
class Profile {
public:
    Profile();

    // We want the equivalent of `CLOCK_THREAD_CPUTIME_ID` in Linux, which
    // only includes time consumed by the thread.  This allows us to benchmark
    // real-time processes without worrying about whether the process has been
    // pre-empted during the measurement.  The C++ `std::chrono` can't do
    // thread-specific profiling.


    /// Start a timing run.
    inline void start()
    {
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &start_time);
    }


    /// Finish a timing run.
    inline double finish()
    {
        timespec finish_time;
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &finish_time);

        // Calculate the time since `start()` was called.
        timespec diff_time;
        diff_time.tv_sec = finish_time.tv_sec - start_time.tv_sec;
        diff_time.tv_nsec = finish_time.tv_nsec - start_time.tv_nsec;

        if (diff_time.tv_nsec < 0)
        {
            diff_time.tv_sec--;
            diff_time.tv_nsec += NSEC_MAX;
        }

        // Track the first timing run separately, in case there are effects
        // from program cache, etc., that have some impact.
        if (first_time.tv_sec == 0 && first_time.tv_nsec == 0)
        {
            first_time.tv_sec = diff_time.tv_sec;
            first_time.tv_nsec = diff_time.tv_nsec;
            return timespec_to_seconds(diff_time);
        }

        // Track the maximum execution time (the one we really care about).
        if (diff_time.tv_sec > max_time.tv_sec
            || (diff_time.tv_sec == max_time.tv_sec
                && diff_time.tv_nsec > max_time.tv_nsec))
        {
            max_time.tv_sec = diff_time.tv_sec;
            max_time.tv_nsec = diff_time.tv_nsec;
        }

        // Accumulate the total time, for reporting the average execution time.
        total_time.tv_sec += diff_time.tv_sec;
        total_time.tv_nsec += diff_time.tv_nsec;

        if (total_time.tv_nsec >= NSEC_MAX)
        {
            total_time.tv_sec++;
            total_time.tv_nsec -= NSEC_MAX;
        }

        num_runs++;
        return timespec_to_seconds(diff_time);
    }


    /// Return the time of the first timing run, in seconds.
    double get_first_time();


    /// Return the longest time of all timing runs (except the first), in
    /// seconds.
    double get_max_time();


    /// Return the average time of all timing runs (except the first), in
    /// seconds.
    double get_average_time();


    /// Return the resolution of the CPU timer, in seconds.
    static double get_resolution();


    /// Set the CPU MIPS value to be used for calculating MIPS consumed.
    static void set_cpu_mips(double mips);


    /// Return the CPU MIPS value that was set with `set_cpu_mips()`.
    static double get_cpu_mips();


    /// Set the period of the process being timed.  This allows the timing
    /// results to be reported in terms of MIPS.
    void set_period(double period);


    /// Return the number of MIPS consumed by the first timing run.
    double get_first_mips();


    /// Return the number of MIPS consumed by the longest timing run (excluding
    /// the first).
    double get_max_mips();


    /// Return the number of MIPS consumed by the average of all timing runs
    /// (excluding the first).
    double get_average_mips();

private:
    static const long NSEC_MAX = 1000000000L;
    static double cpu_mips;
    timespec start_time;
    timespec max_time;
    timespec first_time;
    timespec total_time;
    int_fast32_t num_runs;
    double inv_period;

    static inline double timespec_to_seconds(const timespec &ts)
    {
        return ts.tv_nsec / (double)NSEC_MAX + ts.tv_sec;
    }
};


} // namespace bosepro
