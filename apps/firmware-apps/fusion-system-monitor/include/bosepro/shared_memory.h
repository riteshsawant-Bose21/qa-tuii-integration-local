#pragma once

#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/sync/interprocess_mutex.hpp>
#include <boost/interprocess/containers/string.hpp>
#include <boost/interprocess/containers/map.hpp>
#include <boost/interprocess/allocators/allocator.hpp>
#include <map>
#include <string>
#include <vector>
#include <memory>
#include <stdexcept>
#include <cstring>
#include <mutex>
#include <iostream>

/**
 * @struct WriteBlock
 * Represents metadata for each write operation in shared memory.
 */
struct WriteBlock {
    std::string type;   // Type of the written data
    std::size_t length; // Length of the data in bytes
    void* pointer;      // Pointer to the written value in shared memory
};

namespace bosepro {

class NamedSharedMemory {
private:
    std::string name_;
    std::size_t size_;
    std::size_t totalBytesWritten_;
    boost::interprocess::shared_memory_object shm_;
    boost::interprocess::mapped_region region_;
    std::vector<WriteBlock> writeBlocks_;

public:
    NamedSharedMemory(const std::string& name, std::size_t size, bool create = false)
        : name_(name), size_(size), totalBytesWritten_(0) {
        try {
            if (create) {
                shm_ = boost::interprocess::shared_memory_object(
                    boost::interprocess::create_only, name.c_str(), boost::interprocess::read_write);
                shm_.truncate(size);
            } else {
                shm_ = boost::interprocess::shared_memory_object(
                    boost::interprocess::open_only, name.c_str(), boost::interprocess::read_write);
            }
            region_ = boost::interprocess::mapped_region(shm_, boost::interprocess::read_write);
        } catch (const boost::interprocess::interprocess_exception& e) {
            std::cerr << "Error: " << e.what() << std::endl;
            throw;
        }
    }

    ~NamedSharedMemory() {
        try {
            boost::interprocess::shared_memory_object::remove(name_.c_str());
        } catch (const boost::interprocess::interprocess_exception&) {
            // Ignore exceptions in cleanup
        }
    }

    void resetWrite() {
        std::memset(region_.get_address(), 0, size_);
        totalBytesWritten_ = 0;
    }

    void clearMemory() {
        std::memset(region_.get_address(), 0, size_);
    }

    void write(const void* data, std::size_t size, const std::string& type) {
        if (totalBytesWritten_ + size > size_) {
            throw std::runtime_error("Data size exceeds shared memory capacity");
        }

        void* writePointer = static_cast<char*>(region_.get_address()) + totalBytesWritten_;
        std::memcpy(writePointer, data, size);

        totalBytesWritten_ += size;
        writeBlocks_.push_back({type, size, writePointer});
    }

    void read(void* buffer, std::size_t size) const {
        if (size > size_) {
            throw std::runtime_error("Buffer size exceeds shared memory size");
        }
        std::memcpy(buffer, region_.get_address(), size);
    }

    std::string getName() const {
        return name_;
    }

    std::size_t getTotalBytesWritten() const {
        return totalBytesWritten_;
    }

    std::size_t getSize() const {
        return size_;
    }

    const std::vector<WriteBlock>& getWriteBlocks() const {
        return writeBlocks_;
    }

    friend std::string getWriteBlockValue(const WriteBlock& block) {
        if (!block.pointer || block.length == 0) {
            return "";
        }
        return std::string(static_cast<const char*>(block.pointer), block.length);
    }
};

class NamedSharedMemoryManager {
private:
    std::map<std::string, std::unique_ptr<NamedSharedMemory>> sharedMemoryMap_;

public:
    NamedSharedMemoryManager() 
    {
    }

    ~NamedSharedMemoryManager() {
        for (const auto& entry : sharedMemoryMap_) {
            boost::interprocess::shared_memory_object::remove(entry.first.c_str());
        }
    }

    static NamedSharedMemoryManager& getInstance() {
        static NamedSharedMemoryManager instance;
        return instance;
    }

    void createSharedMemory(const std::string& name, std::size_t size, bool create = false) {
        if (sharedMemoryMap_.find(name) != sharedMemoryMap_.end()) {
            throw std::runtime_error("Shared memory with name already exists: " + name);
        }
        sharedMemoryMap_[name] = std::make_unique<NamedSharedMemory>(name, size, create);
    }

    NamedSharedMemory& getSharedMemory(const std::string& name) {
        auto it = sharedMemoryMap_.find(name);
        if (it == sharedMemoryMap_.end()) {
            throw std::runtime_error("Shared memory not found: " + name);
        }
        return *it->second;
    }

    void removeSharedMemory(const std::string& name) {
        auto it = sharedMemoryMap_.find(name);
        if (it == sharedMemoryMap_.end()) {
            throw std::runtime_error("Shared memory not found: " + name);
        }
        boost::interprocess::shared_memory_object::remove(name.c_str());
        sharedMemoryMap_.erase(it);
    }

    std::vector<std::string> getSharedMemoryNames() const {
        std::vector<std::string> names;
        for (const auto& pair : sharedMemoryMap_) {
            names.push_back(pair.first);
        }
        return names;
    }

    std::size_t getTotalBytesAllocated() const {
        std::size_t totalBytes = 0;
        for (const auto& entry : sharedMemoryMap_) {
            totalBytes += entry.second->getTotalBytesWritten();
        }
        return totalBytes;
    }
};

class NamedSharedMemoryManagerFactory {
public:
    static std::unique_ptr<NamedSharedMemoryManager> createManager() {
        return std::make_unique<NamedSharedMemoryManager>();
    }
};

} // namespace bosepro
