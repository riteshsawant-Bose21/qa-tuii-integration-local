// This file will contain thread related OS interface fuctions.
#include <iostream>
#include <thread>
#include <chrono> // For std::this_thread::sleep_for
                 
void *OcaLiteOcfThread_create(void (*threadFunction)(void*), void* arg)
{
    // Construct the thread and return it (moved)
    std::thread *newThread = new std::thread(threadFunction, arg);

    return static_cast<void *>(newThread);
}

void OcaLiteOcfThread_Wait(void *threadPtr)
{
    static_cast<std::thread *>(threadPtr)->join();
}
