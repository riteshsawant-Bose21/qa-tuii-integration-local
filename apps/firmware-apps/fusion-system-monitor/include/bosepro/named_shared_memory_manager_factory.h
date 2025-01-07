#ifndef NAMED_SHARED_MEMORY_MANAGER_FACTORY_H
#define NAMED_SHARED_MEMORY_MANAGER_FACTORY_H

#include <bosepro/named_shared_memory_manager.h>
#include <memory>
#include <mutex>

/**
 * @class NamedSharedMemoryManagerFactory
 * Provides a singleton instance of NamedSharedMemoryManager.
 */
class NamedSharedMemoryManagerFactory {
public:
    /**
     * Retrieves the singleton instance of NamedSharedMemoryManager.
     * @return Reference to the singleton instance.
     */
    static NamedSharedMemoryManager& getInstance();

private:
    NamedSharedMemoryManagerFactory() = default;

    NamedSharedMemoryManagerFactory(const NamedSharedMemoryManagerFactory&) = delete;
    NamedSharedMemoryManagerFactory& operator=(const NamedSharedMemoryManagerFactory&) = delete;

    static std::unique_ptr<NamedSharedMemoryManager> instance_;
    static std::mutex mutex_;
};

#endif // NAMED_SHARED_MEMORY_MANAGER_FACTORY_H
