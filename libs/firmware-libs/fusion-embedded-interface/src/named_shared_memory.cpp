#include <bosepro/named_shared_memory.h>
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

void validateDataHeader(const bosepro::SharedMemoryDataHeader& header,
                        std::size_t payloadCapacity,
                        std::size_t expectedPayloadBytes)
{
    if (header.magic != bosepro::SharedMemoryDataHeader::MAGIC) {
        throw std::runtime_error("Invalid shared memory data header magic");
    }
    if (header.protocolVersion != bosepro::SharedMemoryDataHeader::PROTOCOL_VERSION) {
        throw std::runtime_error("Unsupported shared memory data header protocol version");
    }
    if (header.schemaVersion != bosepro::SharedMemoryDataHeader::SCHEMA_VERSION) {
        throw std::runtime_error("Unsupported shared memory data header schema version");
    }
    if (header.payloadBytes > payloadCapacity) {
        throw std::runtime_error("Shared memory data header payload size exceeds capacity");
    }
    if (header.payloadBytes != expectedPayloadBytes) {
        throw std::runtime_error("Shared memory data header payload size mismatch");
    }
    if (header.payloadBlockCount > bosepro::Metadata::MAX_WRITE_BLOCKS) {
        throw std::runtime_error("Shared memory data header block count exceeds supported maximum");
    }
}

void validateDataHeaderShape(const bosepro::SharedMemoryDataHeader& header,
                             std::size_t payloadCapacity)
{
    if (header.magic != bosepro::SharedMemoryDataHeader::MAGIC) {
        throw std::runtime_error("Invalid shared memory data header magic");
    }
    if (header.protocolVersion != bosepro::SharedMemoryDataHeader::PROTOCOL_VERSION) {
        throw std::runtime_error("Unsupported shared memory data header protocol version");
    }
    if (header.schemaVersion != bosepro::SharedMemoryDataHeader::SCHEMA_VERSION) {
        throw std::runtime_error("Unsupported shared memory data header schema version");
    }
    if (header.payloadBytes > payloadCapacity) {
        throw std::runtime_error("Shared memory data header payload size exceeds capacity");
    }
    if (header.payloadBlockCount > bosepro::Metadata::MAX_WRITE_BLOCKS) {
        throw std::runtime_error("Shared memory data header block count exceeds supported maximum");
    }
}

void validatePayloadHeader(const bosepro::SharedMemoryPayloadHeader& header,
                           std::size_t remainingCapacity)
{
    if (header.magic != bosepro::SharedMemoryPayloadHeader::MAGIC) {
        throw std::runtime_error("Invalid shared memory payload header magic");
    }
    if (header.protocolVersion != bosepro::SharedMemoryPayloadHeader::PROTOCOL_VERSION) {
        throw std::runtime_error("Unsupported shared memory payload header protocol version");
    }
    if (header.schemaVersion != bosepro::SharedMemoryPayloadHeader::SCHEMA_VERSION) {
        throw std::runtime_error("Unsupported shared memory payload header schema version");
    }
    if (header.payloadBytes > remainingCapacity) {
        throw std::runtime_error("Shared memory payload header length exceeds capacity");
    }
}

void validateBlobHeader(const bosepro::SharedMemoryBlobHeader& header,
                        std::size_t payloadCapacity,
                        std::size_t expectedPayloadBytes)
{
    if (header.magic != bosepro::SharedMemoryBlobHeader::MAGIC) {
        throw std::runtime_error("Invalid shared memory blob header magic");
    }
    if (header.protocolVersion != bosepro::SharedMemoryBlobHeader::PROTOCOL_VERSION) {
        throw std::runtime_error("Unsupported shared memory blob header protocol version");
    }
    if (header.schemaVersion != bosepro::SharedMemoryBlobHeader::SCHEMA_VERSION) {
        throw std::runtime_error("Unsupported shared memory blob header schema version");
    }
    if (header.payloadBytes > payloadCapacity) {
        throw std::runtime_error("Shared memory blob header payload size exceeds capacity");
    }
    if (header.payloadBytes != expectedPayloadBytes) {
        throw std::runtime_error("Shared memory blob header payload size mismatch");
    }
}

} // namespace

/**
 * Constructor
 * Initializes shared memory and metadata regions.
 */
bosepro::NamedSharedMemory::NamedSharedMemory(const char* name, std::size_t size, bool create)
    : sharedMutex_(nullptr), isReaderObject(false), ownsSharedResources_(create), physicalBytesWritten_(0) {

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
            shm_.truncate(size + DATA_HEADER_LENGTH + (Metadata::MAX_WRITE_BLOCKS * PAYLOAD_HEADER_LENGTH));
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
        : sharedMutex_(nullptr), isReaderObject(true), ownsSharedResources_(false), physicalBytesWritten_(0) {

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
        physicalBytesWritten_ = calculateStoredBytes(readDataHeader());
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

        if (physicalBytesWritten_ + PAYLOAD_HEADER_LENGTH + size > region_.get_size() - DATA_HEADER_LENGTH) {
            throw std::runtime_error("Structured payload exceeds shared memory storage capacity");
        }

        writePayloadHeader(physicalBytesWritten_, size, type);
        void* writePointer = static_cast<char*>(region_.get_address()) +
                             DATA_HEADER_LENGTH + physicalBytesWritten_ + PAYLOAD_HEADER_LENGTH;
        std::memcpy(writePointer, data, size);


        metaData.writeBlocks.push_back({type.c_str(), size, physicalBytesWritten_ + PAYLOAD_HEADER_LENGTH});
        metaData.totalBytesWritten += size;
        physicalBytesWritten_ += PAYLOAD_HEADER_LENGTH + size;

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
void bosepro::NamedSharedMemory::lightWeightWrite(const void* data, std::size_t size) {
    lockOrThrow(sharedMutex_, "lightWeightWrite");
    try {
        if (isReaderObject.load(std::memory_order_acquire)) {
            throw std::runtime_error("NamedShared Memory has Reader Personality, Write Forbidden");
        }

        if (metaData.totalBytesWritten + size > metaData.size) {
            throw std::runtime_error("Data size exceeds shared memory capacity");
        }

        if (physicalBytesWritten_ == 0) {
            initializeBlobHeader();
            physicalBytesWritten_ = BLOB_HEADER_LENGTH;
        }

        if (physicalBytesWritten_ + size > region_.get_size() - DATA_HEADER_LENGTH) {
            throw std::runtime_error("Data size exceeds shared memory storage capacity");
        }

        void* writePointer = static_cast<char*>(region_.get_address()) + DATA_HEADER_LENGTH + physicalBytesWritten_;
        std::memcpy(writePointer, data, size);
        metaData.totalBytesWritten += size;
        physicalBytesWritten_ += size;
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
        const auto dataHeader = readDataHeader();
        if (dataHeader.payloadBlockCount == 0) {
            retVal = copyBlobPayloadToBuffer(buffer, bufferSize, dataHeader);
        } else {
            retVal = copyStructuredPayloadsToBuffer(buffer, bufferSize, dataHeader);
        }


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
        const auto dataHeader = readDataHeader();
        if (dataHeader.payloadBlockCount == 0) {
            retVal = copyBlobPayloadToBuffer(buffer, bufferSize, dataHeader);
        } else {
            retVal = copyStructuredPayloadsToBuffer(buffer, bufferSize, dataHeader);
        }


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
        writePayloadBytesToDataHeader(metaData.totalBytesWritten);
        if (metaData.writeBlocks.empty() && physicalBytesWritten_ >= BLOB_HEADER_LENGTH) {
            writeBlobPayloadBytes(metaData.totalBytesWritten);
        }
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
        writePayloadBytesToDataHeader(metaData.totalBytesWritten);
        if (metaData.writeBlocks.empty() && physicalBytesWritten_ >= BLOB_HEADER_LENGTH) {
            writeBlobPayloadBytes(metaData.totalBytesWritten);
        }

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
        physicalBytesWritten_ = 0;
        std::memset(region_.get_address(), 0, region_.get_size());
        initializeDataHeader();
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
    physicalBytesWritten_ = 0;
    initializeDataHeader();
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

void bosepro::NamedSharedMemory::initializeDataHeader() {
    SharedMemoryDataHeader header{
        SharedMemoryDataHeader::MAGIC,
        SharedMemoryDataHeader::PROTOCOL_VERSION,
        SharedMemoryDataHeader::SCHEMA_VERSION,
        0,
        0,
    };
    std::memcpy(region_.get_address(), &header, sizeof(header));
}

void bosepro::NamedSharedMemory::initializeBlobHeader() {
    SharedMemoryBlobHeader header{
        SharedMemoryBlobHeader::MAGIC,
        SharedMemoryBlobHeader::PROTOCOL_VERSION,
        SharedMemoryBlobHeader::SCHEMA_VERSION,
        {},
        0,
    };
    std::strncpy(header.contentType, "json", WriteBlock::TYPE_SIZE - 1);
    header.contentType[WriteBlock::TYPE_SIZE - 1] = '\0';
    std::memcpy(static_cast<char*>(region_.get_address()) + DATA_HEADER_LENGTH, &header, sizeof(header));
}

void bosepro::NamedSharedMemory::writePayloadBytesToDataHeader(std::size_t payloadBytes) {
    SharedMemoryDataHeader header{};
    std::memcpy(&header, region_.get_address(), sizeof(header));
    validateDataHeaderShape(header, metaData.size);
    header.payloadBytes = payloadBytes;
    std::memcpy(region_.get_address(), &header, sizeof(header));
}

void bosepro::NamedSharedMemory::writeBlobPayloadBytes(std::size_t payloadBytes) {
    SharedMemoryBlobHeader header{};
    std::memcpy(&header, static_cast<char*>(region_.get_address()) + DATA_HEADER_LENGTH, sizeof(header));
    validateBlobHeader(header, metaData.size, header.payloadBytes);
    header.payloadBytes = payloadBytes;
    std::memcpy(static_cast<char*>(region_.get_address()) + DATA_HEADER_LENGTH, &header, sizeof(header));
}

void bosepro::NamedSharedMemory::writePayloadHeader(std::size_t storageOffset, std::size_t payloadBytes,
                                                    const std::string& type) {
    SharedMemoryPayloadHeader payloadHeader{
        SharedMemoryPayloadHeader::MAGIC,
        SharedMemoryPayloadHeader::PROTOCOL_VERSION,
        SharedMemoryPayloadHeader::SCHEMA_VERSION,
        {},
        payloadBytes,
    };
    std::strncpy(payloadHeader.type, type.c_str(), WriteBlock::TYPE_SIZE - 1);
    payloadHeader.type[WriteBlock::TYPE_SIZE - 1] = '\0';

    std::memcpy(static_cast<char*>(region_.get_address()) + DATA_HEADER_LENGTH + storageOffset,
                &payloadHeader, sizeof(payloadHeader));

    SharedMemoryDataHeader header{};
    std::memcpy(&header, region_.get_address(), sizeof(header));
    validateDataHeaderShape(header, metaData.size);
    header.payloadBlockCount += 1;
    std::memcpy(region_.get_address(), &header, sizeof(header));
}

bosepro::SharedMemoryPayloadHeader bosepro::NamedSharedMemory::readPayloadHeader(std::size_t storageOffset) const {
    SharedMemoryPayloadHeader header{};
    std::memcpy(&header, static_cast<const char*>(region_.get_address()) + DATA_HEADER_LENGTH + storageOffset,
                sizeof(header));
    validatePayloadHeader(header, metaData.size);
    return header;
}

std::size_t bosepro::NamedSharedMemory::calculateStoredBytes(const SharedMemoryDataHeader& dataHeader) const {
    if (dataHeader.payloadBlockCount == 0) {
        SharedMemoryBlobHeader blobHeader{};
        if (tryReadBlobHeader(blobHeader)) {
            validateBlobHeader(blobHeader, metaData.size, dataHeader.payloadBytes);
            return BLOB_HEADER_LENGTH + blobHeader.payloadBytes;
        }
        return dataHeader.payloadBytes;
    }

    std::size_t storageOffset = 0;
    std::size_t copiedBytes = 0;
    for (std::size_t i = 0; i < dataHeader.payloadBlockCount; ++i) {
        const auto payloadHeader = readPayloadHeader(storageOffset);
        storageOffset += PAYLOAD_HEADER_LENGTH + payloadHeader.payloadBytes;
        copiedBytes += payloadHeader.payloadBytes;
    }

    if (copiedBytes != dataHeader.payloadBytes) {
        throw std::runtime_error("Structured shared memory payload bytes mismatch");
    }

    return storageOffset;
}

std::size_t bosepro::NamedSharedMemory::copyBlobPayloadToBuffer(
    void* buffer, std::size_t bufferSize, const SharedMemoryDataHeader& dataHeader) const {
    SharedMemoryBlobHeader blobHeader{};
    if (!tryReadBlobHeader(blobHeader)) {
        if (bufferSize < dataHeader.payloadBytes) {
            throw std::runtime_error("Requested read size exceeds max buffer size");
        }
        std::memcpy(buffer, static_cast<char*>(region_.get_address()) + DATA_HEADER_LENGTH, dataHeader.payloadBytes);
        return dataHeader.payloadBytes;
    }

    validateBlobHeader(blobHeader, metaData.size, dataHeader.payloadBytes);
    if (bufferSize < blobHeader.payloadBytes) {
        throw std::runtime_error("Requested read size exceeds max buffer size");
    }
    std::memcpy(buffer,
                static_cast<const char*>(region_.get_address()) + DATA_HEADER_LENGTH + BLOB_HEADER_LENGTH,
                blobHeader.payloadBytes);
    return blobHeader.payloadBytes;
}

std::size_t bosepro::NamedSharedMemory::copyStructuredPayloadsToBuffer(
    void* buffer, std::size_t bufferSize, const SharedMemoryDataHeader& dataHeader) const {
    if (bufferSize < dataHeader.payloadBytes) {
        throw std::runtime_error("Requested read size exceeds max buffer size");
    }

    std::size_t storageOffset = 0;
    std::size_t copiedBytes = 0;
    auto* out = static_cast<char*>(buffer);

    for (std::size_t i = 0; i < dataHeader.payloadBlockCount; ++i) {
        const auto payloadHeader = readPayloadHeader(storageOffset);
        const auto* payloadAddress = static_cast<const char*>(region_.get_address()) +
                                     DATA_HEADER_LENGTH + storageOffset + PAYLOAD_HEADER_LENGTH;
        std::memcpy(out + copiedBytes, payloadAddress, payloadHeader.payloadBytes);
        storageOffset += PAYLOAD_HEADER_LENGTH + payloadHeader.payloadBytes;
        copiedBytes += payloadHeader.payloadBytes;
    }

    if (copiedBytes != dataHeader.payloadBytes) {
        throw std::runtime_error("Structured shared memory payload bytes mismatch");
    }

    return copiedBytes;
}

bosepro::SharedMemoryDataHeader bosepro::NamedSharedMemory::readDataHeader() const {
    SharedMemoryDataHeader header{};
    std::memcpy(&header, region_.get_address(), sizeof(header));
    validateDataHeader(header, metaData.size, metaData.totalBytesWritten);
    return header;
}

bosepro::SharedMemoryBlobHeader bosepro::NamedSharedMemory::readBlobHeader() const {
    SharedMemoryBlobHeader header{};
    std::memcpy(&header, static_cast<const char*>(region_.get_address()) + DATA_HEADER_LENGTH, sizeof(header));
    validateBlobHeader(header, metaData.size, metaData.totalBytesWritten);
    return header;
}

bool bosepro::NamedSharedMemory::tryReadBlobHeader(SharedMemoryBlobHeader& header) const {
    std::memcpy(&header, static_cast<const char*>(region_.get_address()) + DATA_HEADER_LENGTH, sizeof(header));
    return header.magic == SharedMemoryBlobHeader::MAGIC;
}


/**
 * Prints the value pointed to by each element of the writeBlocks vector.
 * The type of each value is interpreted based on WriteBlock::type.
 */
void bosepro::NamedSharedMemory::printWriteBlocksValues() const {
    const char* baseAddress = static_cast<char*>(region_.get_address()) + DATA_HEADER_LENGTH;

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
