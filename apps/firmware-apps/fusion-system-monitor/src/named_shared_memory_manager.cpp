#include <bosepro/named_shared_memory_manager.h>
#include <iostream>

// Static set to track globally unique shared memory names
std::set<std::string> NamedSharedMemoryManager::globalSharedMemoryNames_;

NamedSharedMemoryManager::NamedSharedMemoryManager() {
    // Constructor initializes an empty manager
}

NamedSharedMemoryManager::~NamedSharedMemoryManager() {
    // Destructor removes all shared memory names managed by this instance from the global set
    for (const auto& entry : sharedMemoryMap_) {
        globalSharedMemoryNames_.erase(entry.first);
    }
}

void NamedSharedMemoryManager::createSharedMemory(const std::string& name, std::size_t size, bool create) {

    if (create)
    {
        // Check if the name already exists globally
        if (globalSharedMemoryNames_.find(name) != globalSharedMemoryNames_.end()) {
            throw std::runtime_error("Shared memory with this name already exists globally: " + name);
        }
    }

    // Check if the name already exists locally in this manager
    if (sharedMemoryMap_.find(name) != sharedMemoryMap_.end()) {
        throw std::runtime_error("Shared memory with this name already exists in the current manager: " + name);
    }

    // Create a new NamedSharedMemory object and add it to the local map
    sharedMemoryMap_[name] = std::make_unique<NamedSharedMemory>(name, size, create);

    // Add the name to the global set
    globalSharedMemoryNames_.insert(name);
}

NamedSharedMemory& NamedSharedMemoryManager::getSharedMemory(const std::string& name) {
    // Retrieve a NamedSharedMemory object by name
    auto it = sharedMemoryMap_.find(name);
    if (it == sharedMemoryMap_.end()) {
        throw std::runtime_error("Shared memory not found: " + name);
    }
    return *(it->second);
}

void NamedSharedMemoryManager::removeSharedMemory(const std::string& name) {
    // Check if the shared memory exists in this manager
    auto it = sharedMemoryMap_.find(name);
    if (it == sharedMemoryMap_.end()) {
        throw std::runtime_error("Shared memory not found: " + name);
    }

    // Remove the shared memory from the local map
    sharedMemoryMap_.erase(it);

    // Remove the name from the global set
    globalSharedMemoryNames_.erase(name);
}

std::vector<std::string> NamedSharedMemoryManager::getSharedMemoryNames() const {
    // Retrieve the names of all managed shared memory objects
    std::vector<std::string> names;
    for (const auto& entry : sharedMemoryMap_) {
        names.push_back(entry.first);
    }
    return names;
}

std::size_t NamedSharedMemoryManager::getTotalBytesAllocated() const {
    // Calculate the cumulative total bytes written across all managed shared memory objects
    std::size_t totalBytes = 0;
    for (const auto& entry : sharedMemoryMap_) {
        totalBytes += entry.second->getTotalBytesWritten();
    }
    return totalBytes;
}
