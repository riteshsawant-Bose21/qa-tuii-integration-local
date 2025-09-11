#include "named_shared_memory_manager_factory.h"

// Static member definitions
//NamedSharedMemoryManager* NamedSharedMemoryManagerFactory::instance_ = nullptr;
std::unique_ptr<bosepro::NamedSharedMemoryManager> bosepro::NamedSharedMemoryManagerFactory::instance_ = nullptr;
std::mutex bosepro::NamedSharedMemoryManagerFactory::mutex_;

bosepro::NamedSharedMemoryManager& bosepro::NamedSharedMemoryManagerFactory::getInstance() {
    if (!instance_) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!instance_) {
            //instance_ = new NamedSharedMemoryManager();
            instance_ = std::make_unique<bosepro::NamedSharedMemoryManager>();
        }
    }
    return *instance_;
}
