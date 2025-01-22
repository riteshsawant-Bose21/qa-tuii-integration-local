#include <bosepro/NamedSharedMemory.h>
#include <boost/interprocess/exceptions.hpp>
#include <cstring>
#include <stdexcept>


using namespace boost::interprocess;

/**
 * Constructor
 * Initializes shared memory and metadata regions.
 */
NamedSharedMemory::NamedSharedMemory(const std::string& name, std::size_t size, bool create)
    : name_(name), size_(size), totalBytesWritten_(0), totalBytesPresentInSHM_(0), sharedMutex_(nullptr) {
    try {
        // Create or open the main shared memory region
        if (create) {
            shm_ = shared_memory_object(create_only, name.c_str(), read_write);
            shm_.truncate(size);
        } else {
            shm_ = shared_memory_object(open_only, name.c_str(), read_write);
        }
        region_ = mapped_region(shm_, read_write);

        // Create or open the metadata shared memory region
        std::string metadataName = name + "_metadata";
        if (create) {
            metadataShm_ = shared_memory_object(create_only, metadataName.c_str(), read_write);
            metadataShm_.truncate(sizeof(pthread_mutex_t) + sizeof(std::size_t) * 3 + sizeof(WriteBlock) * MAX_WRITE_BLOCKS);
        } else {
            metadataShm_ = shared_memory_object(open_only, metadataName.c_str(), read_write);
        }
        metadataRegion_ = mapped_region(metadataShm_, read_write);

        // Initialize shared mutex
        sharedMutex_ = static_cast<pthread_mutex_t*>(metadataRegion_.get_address());
        if (create) {
            pthread_mutexattr_t attr;
            pthread_mutexattr_init(&attr);
            pthread_mutexattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
            // Recursive Mutex for now, remove RECURSIVE attribute if we need to optimize performance
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
            // Initialize the mutex to start in the unlocked state
            if (pthread_mutex_init(sharedMutex_, &attr) != 0) {
                throw std::runtime_error("Failed to initialize shared mutex");
            }
            softResetWritePointer();
            writeMetaDataToSharedMemory();

        }
    } catch (const interprocess_exception& e) {
        if (create) {
            shared_memory_object::remove(name.c_str());
            shared_memory_object::remove((name + "_metadata").c_str());
        }
        throw std::runtime_error("Failed to initialize shared memory: " + std::string(e.what()));
    }
}

/**
 * Constructor for opening shared memory that has already been created
*/
NamedSharedMemory::NamedSharedMemory(const std::string& name)
    : name_(name) {
    try {
        // Open the shared memory object
        shm_ = shared_memory_object(open_only, name.c_str(), read_write);
        region_ = mapped_region(shm_, read_write);

        std::string metadataName = name + "_metadata";
        metadataShm_ = shared_memory_object(open_only, metadataName.c_str(), read_write);
        metadataRegion_ = mapped_region(metadataShm_, read_write);

        // Point to the mutex address in the meta data shared memory
        void* metadataAddress = metadataRegion_.get_address();
        sharedMutex_ = static_cast<pthread_mutex_t*>(metadataAddress);

        // Synchronize the meta data
        readMetaDataFromSharedMemory();
    } catch (const boost::interprocess::interprocess_exception& e) {
        throw std::runtime_error("Failed to open shared memory: " + std::string(e.what()));
    }
}


/**
 * Destructor
 * Cleans up shared memory regions and mutex.
 */
NamedSharedMemory::~NamedSharedMemory() {
    try {
        if (sharedMutex_) {
            pthread_mutex_destroy(sharedMutex_);
        }
        shared_memory_object::remove(name_.c_str());
        shared_memory_object::remove((name_ + "_metadata").c_str());
    } catch (...) {
        // Ignore errors during cleanup
    }
}

/**
 * Writes data to shared memory.
 */
void NamedSharedMemory::write(const void* data, std::size_t size, const std::string& type) {
    pthread_mutex_lock(sharedMutex_);
    try {
        if (totalBytesWritten_ + size > size_) {
            throw std::runtime_error("Data size exceeds shared memory capacity");
        }

        if (writeBlocks_.size() >= MAX_WRITE_BLOCKS) {
            throw std::runtime_error("Exceeded maximum number of WriteBlock elements");
        }

        void* writePointer = static_cast<char*>(region_.get_address()) + totalBytesWritten_;
        std::memcpy(writePointer, data, size);

        totalBytesWritten_ += size;
        writeBlocks_.push_back({type, size, writePointer});
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Reads data from shared memory.
 */
void NamedSharedMemory::read(void* buffer, std::size_t size) const {
    pthread_mutex_lock(sharedMutex_);
    try {
        if (size > size_) {
            throw std::runtime_error("Requested read size exceeds written data size");
        }
        std::memcpy(buffer, region_.get_address(), size);
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Writes data and metadata to shared memory.
 */
void NamedSharedMemory::writeFullStateToSharedMemory(const void* data, std::size_t size, const std::string& type) {
    
    softResetWritePointer();
    pthread_mutex_lock(sharedMutex_);
    write(data, size, type); // Involves a second superfluous recursive lock, pay attention for optimization
    writeMetaDataToSharedMemory(); // Involves a second superfluous recursive lock, pay attention for optimization
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Writes data and metadata to shared memory.
 */
void NamedSharedMemory::writeMinimalStateToSharedMemory(const void* data, std::size_t size, const std::string& type) {
    
    softResetWritePointer();
    pthread_mutex_lock(sharedMutex_);
    write(data, size, type); // Involves a second superfluous recursive lock, pay attention for optimization
    writeNumberBytesToSharedMemory(); // Involves a second superfluous recursive lock, pay attention for optimization
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Reads data and metadata from shared memory.
 */
void NamedSharedMemory::readFullStateFromSharedMemory(void* buffer) {

    // Read metadata first to determine the total bytes written
    readMetaDataFromSharedMemory();

    if (totalBytesPresentInSHM_ > size_) {
        throw std::runtime_error("Invalid metadata: totalBytesPresentInSHM_ exceeds shared memory size.");
    }
    try {
        pthread_mutex_lock(sharedMutex_);
        // Read data from shared memory into the provided buffer
        std::memcpy(buffer, region_.get_address(), totalBytesPresentInSHM_);
        pthread_mutex_unlock(sharedMutex_);
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
}

/**
 * Writes metadata to shared memory.
 * - Includes the size of the writeBlocks_ vector and its elements.
 */
void NamedSharedMemory::writeMetaDataToSharedMemory() {
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);

        // Write name
        std::memcpy(metadata, name_.c_str(), name_.size());
        metadata += name_.size();

        // Write size
        std::memcpy(metadata, &size_, sizeof(size_));
        metadata += sizeof(size_);

        // Write totalBytesWritten
        std::memcpy(metadata, &totalBytesWritten_, sizeof(totalBytesWritten_));
        metadata += sizeof(totalBytesWritten_);

        // Write number of WriteBlock elements
        std::size_t numWriteBlocks = writeBlocks_.size();
        std::memcpy(metadata, &numWriteBlocks, sizeof(numWriteBlocks));
        metadata += sizeof(numWriteBlocks);

        // Write WriteBlocks
        std::memcpy(metadata, writeBlocks_.data(), sizeof(WriteBlock) * numWriteBlocks);
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Reads metadata from shared memory.
 * - Reads the size of the writeBlocks_ vector and populates it from shared memory.
 */
void NamedSharedMemory::readMetaDataFromSharedMemory() {
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);

        // Read name
        name_ = std::string(metadata);
        metadata += name_.size();

        // Read size
        std::memcpy(&size_, metadata, sizeof(size_));
        metadata += sizeof(size_);

        // Read totalBytesWritten
        std::memcpy(&totalBytesPresentInSHM_, metadata, sizeof(totalBytesPresentInSHM_));
        metadata += sizeof(totalBytesPresentInSHM_);

        // Read number of WriteBlock elements
        std::size_t numWriteBlocks;
        std::memcpy(&numWriteBlocks, metadata, sizeof(numWriteBlocks));
        metadata += sizeof(numWriteBlocks);

        // Read the writeBlocks from memory
        writeBlocks_.resize(numWriteBlocks);
        std::memcpy(&writeBlocks_, metadata, sizeof(WriteBlock) * numWriteBlocks);
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Reads totalBytesWritten from the metadata and updates the relevant member.
 */
void NamedSharedMemory::readNumberBytesFromSharedMemory() {
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metadata += name_.size() + sizeof(size_);
        std::memcpy(&totalBytesPresentInSHM_, metadata, sizeof(totalBytesPresentInSHM_));
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}


/**
 * Writes the totalBytesWritten_ member to the metadata in shared memory.
 */
void NamedSharedMemory::writeNumberBytesToSharedMemory() {
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);

        // Skip name
        metadata += name_.size();

        // Skip size_
        metadata += sizeof(size_);

        // Write totalBytesWritten
        std::memcpy(metadata, &totalBytesWritten_, sizeof(totalBytesWritten_));
        metadata += sizeof(totalBytesWritten_);
        
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Resets the write pointer and clears metadata.
 */
void NamedSharedMemory::resetWritePointer() {
    pthread_mutex_lock(sharedMutex_);
    totalBytesWritten_ = 0;
    writeBlocks_.clear();
    std::memset(region_.get_address(), 0, size_);
    pthread_mutex_unlock(sharedMutex_);
    writeMetaDataToSharedMemory();
}


/**
 * Resets the write pointer but does not clear metadata.
   This is useful since this operation is followed by writeMetaData anyways
 */
void NamedSharedMemory::softResetWritePointer() {

    totalBytesWritten_ = 0;
    writeBlocks_.clear();
}

/**
 * Gets the name of the shared memory region.
 */
std::string NamedSharedMemory::getName() const {
    return name_;
}

/**
 * Gets the size of the shared memory region.
 */
std::size_t NamedSharedMemory::getSize() const {
    return size_;
}

/**
 * Gets the total number of bytes written to the shared memory.
 */
std::size_t NamedSharedMemory::getTotalBytesWritten() const {
    return totalBytesWritten_;
}

/**
 * Gets the metadata for all write operations.
 */
const std::vector<WriteBlock>& NamedSharedMemory::getWriteBlocks() const {
    return writeBlocks_;
}

/**
 * Gets the total number of bytes written to the shared memory.
 */
std::size_t NamedSharedMemory::getTotalBytesPresentInSHM() const {
    return totalBytesPresentInSHM_;
}


/**
 * This function allows a lambda function to be executed under Mutex Syncrhonization.
   The use case at the time of creation was to verify that Mutex works in a multiprocessing deployment ( not just multithreaded)
 */
void accessSharedMemoryWithMutex(NamedSharedMemory& sharedMemory, const std::function<void()>& action) {
    pthread_mutex_lock(sharedMemory.sharedMutex_);
    try {
        action();
    } catch (...) {
        pthread_mutex_unlock(sharedMemory.sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMemory.sharedMutex_);
}


