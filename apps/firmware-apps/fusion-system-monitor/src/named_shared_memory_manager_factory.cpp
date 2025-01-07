#include <bosepro/named_shared_memory_manager_factory.h>

// Static member initialization
std::unique_ptr<NamedSharedMemoryManager> NamedSharedMemoryManagerFactory::instance_ = nullptr;
std::mutex NamedSharedMemoryManagerFactory::mutex_;

NamedSharedMemoryManager& NamedSharedMemoryManagerFactory::getInstance() {
    // Thread-safe singleton implementation using a mutex
    std::lock_guard<std::mutex> lock(mutex_);
    if (!instance_) {
        instance_ = std::make_unique<NamedSharedMemoryManager>();
    }
    return *instance_;
}
