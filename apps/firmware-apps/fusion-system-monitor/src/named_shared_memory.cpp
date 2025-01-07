#include <bosepro/named_shared_memory.h>
#include <boost/interprocess/exceptions.hpp>
#include <iostream>
#include <cstring>

using namespace boost::interprocess;

NamedSharedMemory::NamedSharedMemory(const std::string& name, std::size_t size, bool create)
    : name_(name), size_(size), totalBytesWritten_(0) {
    try {
        if (create) {
            shm_ = shared_memory_object(create_only, name.c_str(), read_write);
            shm_.truncate(size);
        } else {
            shm_ = shared_memory_object(open_only, name.c_str(), read_write);
        }
        region_ = mapped_region(shm_, read_write);
    } catch (const interprocess_exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        throw;
    }
}

NamedSharedMemory::~NamedSharedMemory() {
    try {
        shared_memory_object::remove(name_.c_str());
    } catch (const interprocess_exception&) {
        // Ignore exceptions in cleanup
    }
}

void NamedSharedMemory::resetWrite() {
    std::memset(region_.get_address(), 0, size_);
    totalBytesWritten_ = 0;
}

void NamedSharedMemory::clearMemory() {
    std::memset(region_.get_address(), 0, size_);
}

void NamedSharedMemory::write(const void* data, std::size_t size, const std::string& type) {
    if (totalBytesWritten_ + size > size_) {
        throw std::runtime_error("Data size exceeds shared memory capacity");
    }

    void* writePointer = static_cast<char*>(region_.get_address()) + totalBytesWritten_;
    std::memcpy(writePointer, data, size);

    totalBytesWritten_ += size;
    writeBlocks_.push_back({type, size, writePointer});
}

void NamedSharedMemory::read(void* buffer, std::size_t size) const {
    if (size > size_) {
        throw std::runtime_error("Buffer size exceeds shared memory size");
    }
    std::memcpy(buffer, region_.get_address(), size);
}

std::string NamedSharedMemory::getName() const {
    return name_;
}

std::size_t NamedSharedMemory::getTotalBytesWritten() const {
    return totalBytesWritten_;
}

const std::vector<WriteBlock>& NamedSharedMemory::getWriteBlocks() const {
    return writeBlocks_;
}

// Friend function to retrieve the value from a WriteBlock as a string
std::string getWriteBlockValue(const WriteBlock& block) {
    if (!block.pointer || block.length == 0) {
        return "";
    }
    return std::string(static_cast<const char*>(block.pointer), block.length);
}
