#include <bosepro/NamedSharedMemoryManagerFactory.h>

// Static member definitions
//NamedSharedMemoryManager* NamedSharedMemoryManagerFactory::instance_ = nullptr;
std::unique_ptr<NamedSharedMemoryManager> NamedSharedMemoryManagerFactory::instance_ = nullptr;
std::mutex NamedSharedMemoryManagerFactory::mutex_;

NamedSharedMemoryManager& NamedSharedMemoryManagerFactory::getInstance() {
    if (!instance_) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!instance_) {
            //instance_ = new NamedSharedMemoryManager();
            instance_ = std::make_unique<NamedSharedMemoryManager>();
        }
    }
    return *instance_;
}
