// This file will contain thread related OS interface fuctions.
#include <iostream>
#include <thread>
#include <functional>
#include <chrono> // For std::this_thread::sleep_for
                 
std::thread* OcaLiteOcfThread_create(std::function<void(int)> threadFunction,
                                     void *arg)
{
    std::thread* ocaThread = new std::thread(threadFunction, arg);
    return ocaThread;
}

void OcaLiteOcfThread_delete()
{
}
