#ifndef NAMED_SHARED_MEMORY_MANAGER_H
#define NAMED_SHARED_MEMORY_MANAGER_H

#include <bosepro/named_shared_memory.h>
#include <map>
#include <memory>
#include <string>
#include <stdexcept>
#include <set>
#include <vector>
#include <mutex>

namespace bosepro {
/**
 * @class NamedSharedMemoryManager
 * Manages multiple NamedSharedMemory objects, ensuring unique names globally.
 */
class NamedSharedMemoryManager {
public:
    /**
     * Destructor
     * Cleans up all managed shared memory objects and their names.
     */
    ~NamedSharedMemoryManager();

    /**
     * Creates a new NamedSharedMemory object and adds it to the manager.
     * @param name Name of the shared memory region.
     * @param size Size of the shared memory region in bytes.
     * @throws std::runtime_error If the name already exists globally or locally.
     */
    NamedSharedMemory& createSharedMemory(const std::string& name, std::size_t size);

        /**
     * Retrieves a NamedSharedMemory object by name.
     * If the object is not in the map, attempts to open it.
     * @param name Name of the shared memory region.
     * @return Reference to the NamedSharedMemory object.
     * @throws std::runtime_error If the name does not exist in the system.
     */
    NamedSharedMemory& openSharedMemory(const std::string& name);

    /**
     * Retrieves a NamedSharedMemory object by name.
     * @param name Name of the shared memory region.
     * @return Reference to the NamedSharedMemory object.
     * @throws std::runtime_error If the name does not exist.
     */
    NamedSharedMemory& getSharedMemory(const std::string& name);

    /**
     * Removes a NamedSharedMemory object by name.
     * @param name Name of the shared memory region to remove.
     * @throws std::runtime_error If the name does not exist.
     */
    void removeSharedMemory(const std::string& name);

    /**
     * Gets the names of all managed shared memory objects.
     * @return A vector of shared memory names.
     */
    std::vector<std::string> getSharedMemoryNames() const;

    /**
     * Gets the cumulative total bytes of shared memory allocated.
     * @return The total bytes allocated across all managed shared memory objects.
     */
    std::size_t getTotalBytesAllocated() const;

    // Friend declaration for NamedSharedMemoryManagerFactory
    friend class NamedSharedMemoryManagerFactory;  

    // Allow unique_ptr to access to private constructor
    friend std::unique_ptr<NamedSharedMemoryManager> std::make_unique<NamedSharedMemoryManager>();

private:
    // Private constructor to ensure it can only be accessed by NamedSharedMemoryManagerFactory
    NamedSharedMemoryManager();

    // Make the copy constructor and assignment operator private to prevent copying
    NamedSharedMemoryManager(const NamedSharedMemoryManager&) = delete;
    NamedSharedMemoryManager& operator=(const NamedSharedMemoryManager&) = delete;


    std::map<std::string, std::unique_ptr<NamedSharedMemory>> sharedMemoryMap_; // Managed shared memory regions
    mutable std::mutex mapMutex_;
    static std::set<std::string> globalSharedMemoryNames_;                     // Global set of shared memory names
    static std::mutex globalMutex_;                                           // Mutex for thread-safe access to global names
};

}
#endif // NAMED_SHARED_MEMORY_MANAGER_H
