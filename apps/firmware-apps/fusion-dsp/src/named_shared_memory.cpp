#include <bosepro/named_shared_memory.h>
#include <boost/interprocess/exceptions.hpp>
#include <cstring>
#include <stdexcept>
#include <iostream>
#include <iomanip>

using namespace bosepro;
using namespace boost::interprocess;

/**
 * Constructor
 * Initializes shared memory and metadata regions.
 */
NamedSharedMemory::NamedSharedMemory(const char* name, std::size_t size, bool create)
    :  sharedMutex_(nullptr), isReaderObject(false) {

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
            metadataShm_.truncate(sizeof(pthread_mutex_t) + sizeof(std::size_t) * 3 + sizeof(WriteBlock) * Metadata::MAX_WRITE_BLOCKS);
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
NamedSharedMemory::NamedSharedMemory(const char* name)
        :isReaderObject(true) {

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
NamedSharedMemory::~NamedSharedMemory() {
    try {
        if (sharedMutex_) {
            pthread_mutex_destroy(sharedMutex_);
        }
        shared_memory_object::remove(metaData.name);
        shared_memory_object::remove((std::string(metaData.name) + "_metadata").c_str());
    } catch (...) {
        // Ignore errors during cleanup
    }
}

/**
 * Writes data to shared memory.
 */
void NamedSharedMemory::write(const void* data, std::size_t size, const std::string& type) {

    if (isReaderObject) {
        throw std::runtime_error("NamedShared Memory has Reader Personality, Write Forbidden");
    }
    pthread_mutex_lock(sharedMutex_);
    try {
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
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Writes data to shared memory but does not update Meta Data except for numBytesWritten
 * No validations - just mem copy
 */
void NamedSharedMemory::lightWeightWrite(const void* data, std::size_t size) {

    pthread_mutex_lock(sharedMutex_);
    try {
        void* writePointer = static_cast<char*>(region_.get_address()) + metaData.totalBytesWritten;
        std::memcpy(writePointer, data, size);
        metaData.totalBytesWritten += size;
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Reads data from shared memory.
 * @return Num of Valid Bytes in Buffer
 */
std::size_t NamedSharedMemory::read(void* buffer, std::size_t bufferSize) {

    if (!isReaderObject) {
        throw std::runtime_error("NamedShared Memory has Writer Personality, Read Forbidden");
    }
    std::size_t retVal = 0;
    pthread_mutex_lock(sharedMutex_);
    try {

        readNumberBytesFromSharedMemory();
        retVal = getTotalBytesWritten();
        if (bufferSize < retVal) {
            throw std::runtime_error("Requested read size exceeds max buffer size");
        }
        std::memcpy(buffer, region_.get_address(), retVal);


    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
    return retVal;
}

/**
 * Reads data from shared memory and full Meta data state
 * @return Num of Valid Bytes in Buffer
 */
std::size_t NamedSharedMemory::readFullStateFromSharedMemory(void* buffer, std::size_t bufferSize)  {

    if (!isReaderObject) {
        throw std::runtime_error("NamedShared Memory has Writer Personality, Read Forbidden");
    }
    std::size_t retVal = 0;
    pthread_mutex_lock(sharedMutex_);
    try {
        readMetaDataFromSharedMemory();
        retVal = getTotalBytesWritten();
        if (bufferSize < retVal) {
            throw std::runtime_error("In readFullStateFromSharedMemory, Requested read size exceeds max buffer size");
        }
        std::memcpy(buffer, region_.get_address(), retVal);


    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
    return retVal;
}

/**
 * Writes metadata to shared memory.
 *
 */
void NamedSharedMemory::writeMetaDataToSharedMemory() {

    if (isReaderObject) {
        throw std::runtime_error("NamedShared Memory has Reader Personality, WriteMetaData Forbidden");
    }
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);

        //Serialize Meta data to SHM
        metaData.serialize(metadata, Metadata::META_DATA_MAX_SIZE);
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}

/**
 * Reads metadata from shared memory.
 * - Reads the size of the writeBlocks vector and populates it from shared memory.
 */
void NamedSharedMemory::readMetaDataFromSharedMemory() {

    if (!isReaderObject) {
        throw std::runtime_error("NamedShared Memory has Writer Personality, ReadMetaData Forbidden");
    }
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        //Deserialize Meta data from SHM
        metaData.deserialize(metadata, Metadata::META_DATA_MAX_SIZE);

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
    if (!isReaderObject) {
        throw std::runtime_error("NamedShared Memory has Writer Personality, ReadNumberBytes Forbidden");
    }
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metaData.deserializeTotalBytesWritten(metadata, Metadata::META_DATA_MAX_SIZE);
    } catch (...) {
        pthread_mutex_unlock(sharedMutex_);
        throw;
    }
    pthread_mutex_unlock(sharedMutex_);
}


/**
 * Writes the totalBytesWritten member to the metadata in shared memory.
 */
void NamedSharedMemory::writeNumberBytesToSharedMemory() {
    if (isReaderObject) {
        throw std::runtime_error("NamedShared Memory has Reader Personality, WriteNumberBytes Forbidden");
    }
    pthread_mutex_lock(sharedMutex_);
    try {
        char* metadata = static_cast<char*>(metadataRegion_.get_address()) + sizeof(pthread_mutex_t);
        metaData.updateTotalBytesWrittenInBuffer(metadata, Metadata::META_DATA_MAX_SIZE);

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
    metaData.totalBytesWritten = 0;
    metaData.writeBlocks.clear();
    std::memset(region_.get_address(), 0, metaData.size);
    writeMetaDataToSharedMemory();
    pthread_mutex_unlock(sharedMutex_);

}


/**
 * Resets the write pointer but does not clear metadata.
   This is useful since this operation is followed by writeMetaData anyways
 */
void NamedSharedMemory::softResetWritePointer() {

    metaData.totalBytesWritten = 0;
    metaData.writeBlocks.clear();
}

/**
 * Gets the name of the shared memory region.
 */
std::string NamedSharedMemory::getName() const {
    return metaData.name;
}

/**
 * Gets the size of the shared memory region.
 */
std::size_t NamedSharedMemory::getSize() const {
    return metaData.size;
}

/**
 * Gets the total number of bytes written to the shared memory.
 */
std::size_t NamedSharedMemory::getTotalBytesWritten() const {
    return metaData.totalBytesWritten;
}

/**
 * Gets the metadata for all write operations.
 */
const std::vector<WriteBlock>& NamedSharedMemory::getWriteBlocks() const {
    return metaData.writeBlocks;
}

/**
 * Prints the value pointed to by each element of the writeBlocks vector.
 * The type of each value is interpreted based on WriteBlock::type.
 */
void NamedSharedMemory::printWriteBlocksValues() const {
    const char* baseAddress = static_cast<char*>(region_.get_address());

    for (const auto& block : metaData.writeBlocks) {
        const char* valueAddress = baseAddress + block.offset;

        std::cout << "Type: " << block.type << ", Length: " << block.length << ", Value: ";

        if (std::strcmp(block.type, "string") == 0 || std::strcmp(block.type, "json") == 0) {
            // Treat as null-terminated string
            std::cout << std::string(valueAddress, block.length);
        } else if (std::strcmp(block.type, "integer") == 0) {
            // Treat as integer
            if (block.length != sizeof(int)) {
                throw std::runtime_error("Invalid length for int type in WriteBlock");
            }
            int value = *reinterpret_cast<const int*>(valueAddress);
            std::cout << value;
        } else if (std::strcmp(block.type, "float") == 0) {
            // Treat as float
            if (block.length != sizeof(float)) {
                throw std::runtime_error("Invalid length for float type in WriteBlock");
            }
            float value = *reinterpret_cast<const float*>(valueAddress);
            std::cout << std::fixed << std::setprecision(2) << value;
        } else {
            std::cout << "<unknown type>";
        }

        std::cout << std::endl;
    }
}

void NamedSharedMemory::setPersonalityAsReader(){
    isReaderObject = true;
}
void NamedSharedMemory::setPersonalityAsWriter(){
    isReaderObject = false;
}
bool NamedSharedMemory::isReader() const {
    return isReaderObject;
}


namespace bosepro {

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

}
