#ifndef NAMED_SHARED_MEMORY_MANAGER_FACTORY_H
#define NAMED_SHARED_MEMORY_MANAGER_FACTORY_H

#include "named_shared_memory_manager.h"
#include <memory>
#include <mutex>

namespace bosepro {

/**
    USAGE NOTE: 

    THIS FACTORY METHOD IS INTENDED TO CREATE A SINGLETON WITHIN A PROCESS.
    IF CALLED FROM DIFFERENT PROCESSES, IT CREATES A SINGLETON PER PROCESS
    
    
 */

/**
 * @class NamedSharedMemoryManagerFactory
 * Provides a thread-safe singleton instance of NamedSharedMemoryManager as a std::unique_ptr.
 */
class NamedSharedMemoryManagerFactory {
public:
    /**
     * Retrieves a unique_ptr to the singleton instance of NamedSharedMemoryManager.
     * Ensures thread-safe initialization.
     * @return A std::unique_ptr to the singleton instance.
     */
    static bosepro::NamedSharedMemoryManager& getInstance();

private:
    // Private constructor to prevent direct instantiation
    NamedSharedMemoryManagerFactory() = default;

    // Deleted copy constructor and assignment operator to enforce singleton behavior
    NamedSharedMemoryManagerFactory(const NamedSharedMemoryManagerFactory&) = delete;
    NamedSharedMemoryManagerFactory& operator=(const NamedSharedMemoryManagerFactory&) = delete;

    // Singleton instance
    //static NamedSharedMemoryManager* instance_;
    static std::unique_ptr<bosepro::NamedSharedMemoryManager> instance_;
    static std::mutex mutex_; // Mutex for thread-safe access
};

}
#endif // NAMED_SHARED_MEMORY_MANAGER_FACTORY_H
