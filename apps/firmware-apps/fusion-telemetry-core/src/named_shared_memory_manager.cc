#include "named_shared_memory_manager.h"
#include <mutex>

// Static member definitions
std::set<std::string> bosepro::NamedSharedMemoryManager::globalSharedMemoryNames_;
std::mutex bosepro::NamedSharedMemoryManager::globalMutex_;

bosepro::NamedSharedMemoryManager::NamedSharedMemoryManager() {}

bosepro::NamedSharedMemoryManager::~NamedSharedMemoryManager() {
    std::lock_guard<std::mutex> mapLock(mapMutex_);
    std::lock_guard<std::mutex> lock(globalMutex_);
    for (const auto& entry : sharedMemoryMap_) {
        globalSharedMemoryNames_.erase(entry.first);
    }
}

bosepro::NamedSharedMemory& bosepro::NamedSharedMemoryManager::createSharedMemory(const std::string& name, std::size_t size) {
    std::lock_guard<std::mutex> mapLock(mapMutex_);
    if (sharedMemoryMap_.find(name) != sharedMemoryMap_.end()) {
        throw std::runtime_error("Shared memory with this name already exists in the current manager: " + name);
    }

    auto newSharedMemory = std::make_unique<bosepro::NamedSharedMemory>(name.c_str(), size);

    {
        std::lock_guard<std::mutex> lock(globalMutex_);
        if (globalSharedMemoryNames_.find(name) != globalSharedMemoryNames_.end()) {
            throw std::runtime_error("Shared memory with this name already exists globally: " + name);
        }
        globalSharedMemoryNames_.insert(name);
    }

    sharedMemoryMap_[name] = std::move(newSharedMemory);
    return *sharedMemoryMap_[name];
}

/**
 * Retrieves a NamedSharedMemory object by name, creating it if necessary.
 */
bosepro::NamedSharedMemory& bosepro::NamedSharedMemoryManager::openSharedMemory(const std::string& name) {
    std::lock_guard<std::mutex> mapLock(mapMutex_);
    auto it = sharedMemoryMap_.find(name);
    if (it != sharedMemoryMap_.end()) {
        return *(it->second); // Found in the map
    }

    // Attempt to open the shared memory region
    try {
        sharedMemoryMap_[name] = std::make_unique<bosepro::NamedSharedMemory>(name.c_str());
        return *sharedMemoryMap_[name];
    } catch (const std::exception& e) {
        throw std::runtime_error("Failed to open shared memory region '" + name + "': " + std::string(e.what()));
    }
}

bosepro::NamedSharedMemory& bosepro::NamedSharedMemoryManager::getSharedMemory(const std::string& name) {
    std::lock_guard<std::mutex> mapLock(mapMutex_);
    auto it = sharedMemoryMap_.find(name);
    if (it == sharedMemoryMap_.end()) {
        throw std::runtime_error("Shared memory '" + name + "' not found in this manager");
    }
    return *(it->second);
}

void bosepro::NamedSharedMemoryManager::removeSharedMemory(const std::string& name) {
    std::lock_guard<std::mutex> mapLock(mapMutex_);
    auto it = sharedMemoryMap_.find(name);
    if (it == sharedMemoryMap_.end()) {
        throw std::runtime_error("Shared memory '" + name + "' not found");
    }

    {
        std::lock_guard<std::mutex> lock(globalMutex_);
        globalSharedMemoryNames_.erase(name);
    }

    sharedMemoryMap_.erase(it);
}

std::vector<std::string> bosepro::NamedSharedMemoryManager::getSharedMemoryNames() const {
    std::lock_guard<std::mutex> mapLock(mapMutex_);
    std::vector<std::string> names;
    names.reserve(sharedMemoryMap_.size());
    for (const auto& entry : sharedMemoryMap_) {
        names.push_back(entry.first);
    }
    return names;
}

std::size_t bosepro::NamedSharedMemoryManager::getTotalBytesAllocated() const {
    std::lock_guard<std::mutex> mapLock(mapMutex_);
    std::size_t totalBytes = 0;
    for (const auto& entry : sharedMemoryMap_) {
        totalBytes += entry.second->getTotalBytesWritten();
    }
    return totalBytes;
}
