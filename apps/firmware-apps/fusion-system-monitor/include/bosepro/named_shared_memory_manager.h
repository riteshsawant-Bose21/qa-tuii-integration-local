#ifndef NAMED_SHARED_MEMORY_MANAGER_H
#define NAMED_SHARED_MEMORY_MANAGER_H

#include <bosepro/named_shared_memory.h>
#include <map>
#include <memory>
#include <string>
#include <stdexcept>
#include <set>
#include <vector>

/**
 * @class NamedSharedMemoryManager
 * Manages multiple NamedSharedMemory objects, ensuring unique names globally.
 * This class provides centralized management of named shared memory regions,
 * allowing creation, retrieval, removal, and tracking of memory usage.
 */
class NamedSharedMemoryManager {
public:
    /**
     * Constructor
     * Initializes an empty manager.
     */
    NamedSharedMemoryManager();

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
    void createSharedMemory(const std::string& name, std::size_t size, bool create = false);

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

private:
    // Map of managed shared memory regions, identified by their unique names
    std::map<std::string, std::unique_ptr<NamedSharedMemory>> sharedMemoryMap_;

    // Global set to ensure shared memory names are unique across all managers
    static std::set<std::string> globalSharedMemoryNames_;
};

#endif // NAMED_SHARED_MEMORY_MANAGER_H
