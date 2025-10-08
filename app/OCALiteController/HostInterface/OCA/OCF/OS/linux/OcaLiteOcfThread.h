// This file will contain thread related OS interface fuctions.

#ifndef OCA_LITE_OCF_THREAD_H_
#define OCA_LITE_OCF_THREAD_H_

#include <thread>
#include <functional>

std::thread& OcaLiteOcfThread_create(std::function<void(int)> threadFunction,
                                     int arg);

void OcaLiteOcfThread_delete();

#endif   //OCA_LITE_OCF_THREAD_H_
