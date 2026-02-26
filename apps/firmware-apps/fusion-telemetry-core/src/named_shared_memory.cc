#include "named_shared_memory.h"
#include <boost/interprocess/exceptions.hpp>
#include <cstring>
#include <stdexcept>
#include <iostream>
#include <iomanip>


using namespace boost::interprocess;

namespace {

void lockOrThrow(pthread_mutex_t *mutex, const char *where) {
    if (mutex == nullptr) {
        throw std::runtime_error(std::string("Shared mutex is not initialized in ") + where);
    }
    const int rc = pthread_mutex_lock(mutex);
    if (rc != 0) {
        throw std::runtime_error(std::string("Failed to lock shared mutex in ") + where + ": " +
                                 std::to_string(rc));
    }
}

void unlockOrThrow(pthread_mutex_t *mutex, const char *where) {
    if (mutex == nullptr) {
        throw std::runtime_error(std::string("Shared mutex is not initialized in ") + where);
    }
    const int rc = pthread_mutex_unlock(mutex);
    if (rc != 0) {
        throw std::runtime_error(std::string("Failed to unlock shared mutex in ") + where + ": " +
                                 std::to_string(rc));
    }
}

void unlockNoThrow(pthread_mutex_t *mutex) noexcept {
    if (mutex != nullptr) {
        (void)pthread_mutex_unlock(mutex);
    }
}

} // namespace

/**
 * Constructor
 * Initializes shared memory and metadata regions.
 */
bosepro::NamedSharedMemory::NamedSharedMemory(const char* name, std::size_t size, bool create)
    : sharedMutex_(nullptr), isReaderObject(false), ownsSharedResources_(create) {

    if (std::strlen(name) >= Metadata::NAME_MAX_LENGTH) {
        throw std::runtime_error("1. Shared memory name exceeds maximum length");
    }

    std::strncpy(metaData.name, name, Metadata::NAME_MAX_LENGTH);
    metaData.name[Metadata::NAME_MAX_LENGTH - 1] = '\0'; // Ensure null-termination
    metaData.size = size;
    try {
        // Create or open the main shared memory region
        if (create) {
            shm_ = shared_memory_object(create_only, name, read_write);
            shm_.truncate(size);
        } else {
            shm_ = shared_memory_object(open_only, name, read_write);
        }
        region_ = mapped_region(shm_, read_write);


        // Create or open the metadata shared memory region
        std::string metadataName = std::string(name) + "_metadata";
        if (create) {
            metadataShm_ = shared_memory_object(create_only, metadataName.c_str(), read_write);
            metadataShm_.truncate(META_DATA_SHM_LENGTH);
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
            // Initialize the mutex to start in the unlocked state
            if (pthread_mutex_init(sharedMutex_, &attr) != 0) {
                pthread_mutexattr_destroy(&attr);
                throw std::runtime_error("Failed to initialize shared mutex");
            }
            pthread_mutexattr_destroy(&attr);
            softResetWritePointer();
            writeMetaDataToSharedMemory();

        }
    } catch (const interprocess_exception& e) {
        if (create) {
            shared_memory_object::remove(name);
            shared_memory_object::remove((std::string(name) + "_metadata").c_str());
        }
        throw std::runtime_error("Failed to initialize shared memory: " + std::string(e.what()));
    }

    setPersonalityAsReader(); //Typically, the creator is a reader.
}

/**
 * Constructor for opening shared memory that has already been created
*/
bosepro::NamedSharedMemory::NamedSharedMemory(const char* name)
        : sharedMutex_(nullptr), isReaderObject(true), ownsSharedResources_(false) {

    if (std::strlen(name) >= Metadata::NAME_MAX_LENGTH) {
        throw std::runtime_error("2. Shared memory name exceeds maximum length");
    }

    std::strncpy(metaData.name, name, Metadata::NAME_MAX_LENGTH);
    metaData.name[Metadata::NAME_MAX_LENGTH - 1] = '\0'; // Ensure null-termination


    try {
        // Open the shared memory object
        shm_ = shared_memory_object(open_only, name, read_write);
        region_ = mapped_region(shm_, read_write);

         std::string metadataName = std::string(name) + "_metadata";
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

    setPersonalityAsWriter(); //Typically, the getter is a writer.
}


/**
 * Destructor
 * Cleans up shared memory regions and mutex.
 */
bosepro::NamedSharedMemory::~NamedSharedMemory() {
    try {
        if (ownsSharedResources_ && sharedMutex_) {
            pthread_mutex_destroy(sharedMutex_);
        }
        if (ownsSharedResources_) {
            shared_memory_object::remove(metaData.name);
            shared_memory_object::remove((std::string(metaData.name) + "_metadata").c_str());
        }
    } catch (...) {
        // Ignore errors during cleanup
    }
}

/**
 * Writes data to shared memory.
 */
void bosepro::NamedSharedMemory::write(const void* data, std::size_t size, const std::string& type) {
    lockOrThrow(sharedMutex_, "write");
    try {
        if (isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Reader Personality, Write Forbidden");
        }

        if (metaData.totalBytesWritten + size > metaData.size) {
            throw std::runtime_error("Data size exceeds shared memory capacity");
        }

        if (metaData.writeBlocks.size() >= Metadata::MAX_WRITE_BLOCKS) {
            throw std::runtime_error("Exceeded maximum number of WriteBlock elements");
        }

        void* writePointer = static_cast<char*>(region_.get_address()) + metaData.totalBytesWritten;
        std::memcpy(writePointer, data, size);


        metaData.writeBlocks.push_back({type.c_str(), size, metaData.totalBytesWritten});
        metaData.totalBytesWritten += size;

    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "write");
}

/**
 * Writes data to shared memory but does not update Meta Data except for numBytesWritten
 * No validations - just mem copy
 */
void bosepro::NamedSharedMemory::lightWeightWrite(const void* data, std::size_t size, const std::string& /*type*/) {
    lockOrThrow(sharedMutex_, "lightWeightWrite");
    try {
        if (isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Reader Personality, Write Forbidden");
        }

        if (metaData.totalBytesWritten + size > metaData.size) {
            throw std::runtime_error("Data size exceeds shared memory capacity");
        }

        void* writePointer = static_cast<char*>(region_.get_address()) + metaData.totalBytesWritten;
        std::memcpy(writePointer, data, size);
        metaData.totalBytesWritten += size;
    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "lightWeightWrite");
}

/**
 * Reads data from shared memory.
 * @return Num of Valid Bytes in Buffer
 */
std::size_t bosepro::NamedSharedMemory::read(void* buffer, std::size_t bufferSize) {
    std::size_t retVal = 0;
    lockOrThrow(sharedMutex_, "read");
    try {
        if (!isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Writer Personality, Read Forbidden");
        }
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metaData.deserializeTotalBytesWritten(metadata, Metadata::META_DATA_MAX_SIZE);
        retVal = getTotalBytesWritten();
        if (bufferSize < retVal) {
            throw std::runtime_error("Requested read size exceeds max buffer size");
        }
        std::memcpy(buffer, region_.get_address(), retVal);


    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "read");
    return retVal;
}

/**
 * Reads data from shared memory and full Meta data state
 * @return Num of Valid Bytes in Buffer
 */
std::size_t bosepro::NamedSharedMemory::readFullStateFromSharedMemory(void* buffer, std::size_t bufferSize)  {
    std::size_t retVal = 0;
    lockOrThrow(sharedMutex_, "readFullStateFromSharedMemory");
    try {
        if (!isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Writer Personality, Read Forbidden");
        }
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metaData.deserialize(metadata, Metadata::META_DATA_MAX_SIZE);
        retVal = getTotalBytesWritten();
        if (bufferSize < retVal) {
            throw std::runtime_error("In readFullStateFromSharedMemory, Requested read size exceeds max buffer size");
        }
        std::memcpy(buffer, region_.get_address(), retVal);


    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "readFullStateFromSharedMemory");
    return retVal;
}

/**
 * Writes metadata to shared memory.
 *
 */
void bosepro::NamedSharedMemory::writeMetaDataToSharedMemory() {
    lockOrThrow(sharedMutex_, "writeMetaDataToSharedMemory");
    try {
        if (isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Reader Personality, WriteMetaData Forbidden");
        }
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);

        //Serialize Meta data to SHM
        metaData.serialize(metadata, Metadata::META_DATA_MAX_SIZE);
    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "writeMetaDataToSharedMemory");
}

/**
 * Reads metadata from shared memory.
 * - Reads the size of the writeBlocks vector and populates it from shared memory.
 */
void bosepro::NamedSharedMemory::readMetaDataFromSharedMemory() {
    lockOrThrow(sharedMutex_, "readMetaDataFromSharedMemory");
    try {
        if (!isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Writer Personality, ReadMetaData Forbidden");
        }
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        //Deserialize Meta data from SHM
        metaData.deserialize(metadata, Metadata::META_DATA_MAX_SIZE);

    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "readMetaDataFromSharedMemory");
}

/**
 * Reads totalBytesWritten from the metadata and updates the relevant member.
 */
void bosepro::NamedSharedMemory::readNumberBytesFromSharedMemory() {
    lockOrThrow(sharedMutex_, "readNumberBytesFromSharedMemory");
    try {
        if (!isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Writer Personality, ReadNumberBytes Forbidden");
        }
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metaData.deserializeTotalBytesWritten(metadata, Metadata::META_DATA_MAX_SIZE);
    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "readNumberBytesFromSharedMemory");
}


/**
 * Writes the totalBytesWritten member to the metadata in shared memory.
 */
void bosepro::NamedSharedMemory::writeNumberBytesToSharedMemory() {
    lockOrThrow(sharedMutex_, "writeNumberBytesToSharedMemory");
    try {
        if (isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Reader Personality, WriteNumberBytes Forbidden");
        }
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metaData.updateTotalBytesWrittenInBuffer(metadata, Metadata::META_DATA_MAX_SIZE);

    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "writeNumberBytesToSharedMemory");
}

/**
 * Resets the write pointer and clears metadata.
 */
void bosepro::NamedSharedMemory::resetWritePointer() {
    lockOrThrow(sharedMutex_, "resetWritePointer");
    try {
        metaData.totalBytesWritten = 0;
        metaData.writeBlocks.clear();
        std::memset(region_.get_address(), 0, metaData.size);
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metaData.serialize(metadata, Metadata::META_DATA_MAX_SIZE);
    } catch (...) {
        unlockNoThrow(sharedMutex_);
        throw;
    }
    unlockOrThrow(sharedMutex_, "resetWritePointer");
}


/**
 * Resets the write pointer but does not clear metadata.
   This is useful since this operation is followed by writeMetaData anyways
 */
void bosepro::NamedSharedMemory::softResetWritePointer() {

    metaData.totalBytesWritten = 0;
    metaData.writeBlocks.clear();
}

/**
 * Gets the name of the shared memory region.
 */
std::string bosepro::NamedSharedMemory::getName() const {
    return metaData.name;
}

/**
 * Gets the size of the shared memory region.
 */
std::size_t bosepro::NamedSharedMemory::getSize() const {
    return metaData.size;
}

/**
 * Gets the total number of bytes written to the shared memory.
 */
std::size_t bosepro::NamedSharedMemory::getTotalBytesWritten() const {
    return metaData.totalBytesWritten;
}

/**
 * Gets the metadata for all write operations.
 */
const std::vector<bosepro::WriteBlock>& bosepro::NamedSharedMemory::getWriteBlocks() const {
    return metaData.writeBlocks;
}


/**
 * Prints the value pointed to by each element of the writeBlocks vector.
 * The type of each value is interpreted based on WriteBlock::type.
 */
void bosepro::NamedSharedMemory::printWriteBlocksValues() const {
    const char* baseAddress = static_cast<char*>(region_.get_address());

    for (const auto& block : metaData.writeBlocks) {
        const char* valueAddress = baseAddress + block.offset;

        std::cout << "Type: " << block.type << ", Length: " << block.length << ", Value: ";

        if (std::strcmp(block.type, "string") == 0 || std::strcmp(block.type, "json") == 0) {
            // Treat as null-terminated string
            std::cout << std::string(valueAddress, block.length);
        } else if (std::strcmp(block.type, "int") == 0) {
            // Treat as integer
            if (block.length != sizeof(int)) {
                throw std::runtime_error("Invalid length for int type in WriteBlock");
            }
            int value = 0;
            std::memcpy(&value, valueAddress, sizeof(value));
            std::cout << value;
        } else if (std::strcmp(block.type, "float") == 0) {
            // Treat as float
            if (block.length != sizeof(float)) {
                throw std::runtime_error("Invalid length for float type in WriteBlock");
            }
            float value = 0;
            std::memcpy(&value, valueAddress, sizeof(value));
            std::cout << std::fixed << std::setprecision(2) << value;
        } else {
            std::cout << "<unknown type>";
        }

        std::cout << std::endl;
    }
}

void bosepro::NamedSharedMemory::setPersonalityAsReader(){
    if (sharedMutex_ != nullptr) {
        lockOrThrow(sharedMutex_, "setPersonalityAsReader");
        isReaderObject.store(true, std::memory_order_release);
        unlockOrThrow(sharedMutex_, "setPersonalityAsReader");
        return;
    }
    isReaderObject.store(true, std::memory_order_release);
}
void bosepro::NamedSharedMemory::setPersonalityAsWriter(){
    if (sharedMutex_ != nullptr) {
        lockOrThrow(sharedMutex_, "setPersonalityAsWriter");
        isReaderObject.store(false, std::memory_order_release);
        unlockOrThrow(sharedMutex_, "setPersonalityAsWriter");
        return;
    }
    isReaderObject.store(false, std::memory_order_release);
}
bool bosepro::NamedSharedMemory::isReader() const {
    return isReaderObject.load(std::memory_order_acquire);
}
