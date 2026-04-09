#ifndef NAMED_SHARED_MEMORY_H
#define NAMED_SHARED_MEMORY_H

#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <pthread.h>
#include <string>
#include <vector>
#include <functional>
#include <atomic>
#include <bosepro/named_shared_memory_utility.h>

namespace bosepro {

struct SharedMemoryDataHeader {
    static constexpr uint32_t MAGIC = 0x4253484d; // "BSHM"
    static constexpr uint16_t PROTOCOL_VERSION = 1;
    static constexpr uint16_t SCHEMA_VERSION = 1;

    uint32_t magic;
    uint16_t protocolVersion;
    uint16_t schemaVersion;
    std::size_t payloadBytes;
    std::size_t payloadBlockCount;
};

struct SharedMemoryPayloadHeader {
    static constexpr uint32_t MAGIC = 0x42504159; // "BPAY"
    static constexpr uint16_t PROTOCOL_VERSION = 1;
    static constexpr uint16_t SCHEMA_VERSION = 1;

    uint32_t magic;
    uint16_t protocolVersion;
    uint16_t schemaVersion;
    char type[WriteBlock::TYPE_SIZE];
    std::size_t payloadBytes;
};

struct SharedMemoryBlobHeader {
    static constexpr uint32_t MAGIC = 0x42424c42; // "BBLB"
    static constexpr uint16_t PROTOCOL_VERSION = 1;
    static constexpr uint16_t SCHEMA_VERSION = 1;

    uint32_t magic;
    uint16_t protocolVersion;
    uint16_t schemaVersion;
    char contentType[WriteBlock::TYPE_SIZE];
    std::size_t payloadBytes;
};

/**
 * @class NamedSharedMemory
 * Provides an interface for creating, writing to, reading from, and managing
 * named shared memory. Handles synchronization between processes using a
 * process-shared mutex.
 */
class NamedSharedMemory {

public:
    static constexpr std::size_t META_DATA_SHM_LENGTH = Metadata::META_DATA_MAX_SIZE + sizeof(pthread_mutex_t);
    static constexpr std::size_t DATA_HEADER_LENGTH = sizeof(SharedMemoryDataHeader);
    static constexpr std::size_t PAYLOAD_HEADER_LENGTH = sizeof(SharedMemoryPayloadHeader);
    static constexpr std::size_t BLOB_HEADER_LENGTH = sizeof(SharedMemoryBlobHeader);


    NamedSharedMemory(const char* name, std::size_t size, bool create = true);
    NamedSharedMemory(const char* name);
    ~NamedSharedMemory();

    void write(const void* data, std::size_t size, const std::string& type);
    void lightWeightWrite(const void* data, std::size_t size);

    std::size_t read(void* buffer, std::size_t bufferSize);

    void setPersonalityAsReader();
    void setPersonalityAsWriter();
    bool isReader() const;


    /**
     * Reads data and updates metadata from the shared memory in a single operation.
     * - Reads metadata to determine the size of written data.
     * - Reads the data into the provided buffer.
     * @param buffer Pointer to the buffer to store the read data.
     */

    std::size_t readFullStateFromSharedMemory(void* buffer, std::size_t bufferSize);

    /**
     * Reads metadata from shared memory and updates the relevant members.
     */
    void readMetaDataFromSharedMemory();

    /**
     * Writes the current metadata to the shared memory metadata region.
     */
    void writeMetaDataToSharedMemory();


    /**
     * Reads totalBytesWritten from the metadata in shared memory and updates the relevant member.
     */
    void readNumberBytesFromSharedMemory();

    /**
     * Writes the member totalBytesWritten_ to the metadata in shared memory.
     */
    void writeNumberBytesToSharedMemory();

    /**
     * Resets the write pointer to the beginning of the shared memory.
     * Clears previously written data and metadata.
     */
    void resetWritePointer();

    /**
    * Resets the write pointer but does not clear metadata.
    This is useful since this operation is followed by writeMetaData anyways
    */
    void softResetWritePointer();

    /**
     * Gets the name of the shared memory region.
     * @return The name of the shared memory.
     */
    std::string getName() const;

    /**
     * Gets the size of the shared memory region.
     * @return The size of the shared memory in bytes.
     */
    std::size_t getSize() const;

    /**
     * Gets the total number of bytes written to the shared memory.
     * @return The total bytes written.
     */
    std::size_t getTotalBytesWritten() const;


    /**
     * Gets the metadata for all write operations.
     * @return A vector of WriteBlock structures.
     */
    const std::vector<WriteBlock>& getWriteBlocks() const;

    /**
     * Prints the value pointed to by each element of the writeBlocks_ vector.
     * The type of each value is interpreted based on WriteBlock::type.
     */
    void printWriteBlocksValues() const;

private:
    void initializeDataHeader();
    SharedMemoryDataHeader readDataHeader() const;
    void writePayloadBytesToDataHeader(std::size_t payloadBytes);
    void writePayloadHeader(std::size_t storageOffset, std::size_t payloadBytes, const std::string& type);
    SharedMemoryPayloadHeader readPayloadHeader(std::size_t storageOffset) const;
    void initializeBlobHeader();
    SharedMemoryBlobHeader readBlobHeader() const;
    bool tryReadBlobHeader(SharedMemoryBlobHeader& header) const;
    void writeBlobPayloadBytes(std::size_t payloadBytes);
    std::size_t calculateStoredBytes(const SharedMemoryDataHeader& dataHeader) const;
    std::size_t copyStructuredPayloadsToBuffer(void* buffer, std::size_t bufferSize,
                                               const SharedMemoryDataHeader& dataHeader) const;
    std::size_t copyBlobPayloadToBuffer(void* buffer, std::size_t bufferSize,
                                        const SharedMemoryDataHeader& dataHeader) const;

    Metadata metaData;
    boost::interprocess::shared_memory_object shm_; // Boost shared memory object
    boost::interprocess::mapped_region region_;     // Boost mapped region for accessing memory

    boost::interprocess::shared_memory_object metadataShm_; // Metadata shared memory
    boost::interprocess::mapped_region metadataRegion_;     // Metadata mapped region
                                                            //
    pthread_mutex_t* sharedMutex_; // Process-shared mutex
                                   //
    std::atomic<bool> isReaderObject; // NamedSharedMemory can have personality of producer or consumer at a given time, not both
    bool ownsSharedResources_;
    std::size_t physicalBytesWritten_;
};

}

#endif // NAMED_SHARED_MEMORY_H
