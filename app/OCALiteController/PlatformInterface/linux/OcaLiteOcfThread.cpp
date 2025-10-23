// This file will contain thread related OS interface fuctions.
#include <iostream>
#include <thread>
#include <chrono> // For std::this_thread::sleep_for
                 

std::thread OcaLiteOcfThread_create(void (*threadFunction)(void*), void* arg)
{
    // Construct the thread and return it (moved)
    return std::thread(threadFunction, arg);
}


void OcaLiteOcfThread_delete()
{
}
