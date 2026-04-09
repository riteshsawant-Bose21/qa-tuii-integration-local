// This file will contain thread related OS interface fuctions.

#ifndef OCA_LITE_OCF_THREAD_H_
#define OCA_LITE_OCF_THREAD_H_

#include <thread>
#include <functional>

void *OcaLiteOcfThread_create(void (*threadFunction)(void*), void* arg);

void OcaLiteOcfThread_Wait(void *threadPtr);

#endif   //OCA_LITE_OCF_THREAD_H_
