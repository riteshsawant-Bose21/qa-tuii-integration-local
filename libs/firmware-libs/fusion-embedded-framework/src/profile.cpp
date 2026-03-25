#include <bosepro/profile.h>

namespace bosepro {

double Profile::cpu_mips = 1.0;

Profile::Profile()
    : start_time(), max_time(), first_time(), total_time(), num_runs()
{
}


double Profile::get_first_time()
{
    return timespec_to_seconds(first_time);
}


double Profile::get_max_time()
{
    return timespec_to_seconds(max_time);
}


double Profile::get_average_time()
{
    if (num_runs == 0)
    {
        return 0.0;
    }

    return timespec_to_seconds(total_time) / num_runs;
}


double Profile::get_resolution()
{
    timespec ts;
    clock_getres(CLOCK_THREAD_CPUTIME_ID, &ts);
    return timespec_to_seconds(ts);
}


void Profile::set_cpu_mips(double mips)
{
    cpu_mips = mips;
}


double Profile::get_cpu_mips()
{
    return cpu_mips;
}


void Profile::set_period(double period)
{
    inv_period = 1.0 / period;
}


double Profile::get_first_mips()
{
    return get_first_time() * cpu_mips * inv_period;
}


double Profile::get_max_mips()
{
    return get_max_time() * cpu_mips * inv_period;
}


double Profile::get_average_mips()
{
    return get_average_time() * cpu_mips * inv_period;
}


} // namespace bosepro
