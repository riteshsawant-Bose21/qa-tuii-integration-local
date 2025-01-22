#ifndef NAMED_SHARED_MEMORY_H
#define NAMED_SHARED_MEMORY_H


#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <pthread.h>
#include <string>
#include <vector>
#include <functional>

// Maximum number of WriteBlock elements
#define MAX_WRITE_BLOCKS 100

/**
 * @struct WriteBlock
 * Represents metadata for each write operation in shared memory.
 */
struct WriteBlock {
    std::string type;   // Type of the written data
    std::size_t length; // Length of the data in bytes
    void* pointer;      // Pointer to the written value in shared memory
};

/**
 * @class NamedSharedMemory
 * Provides an interface for creating, writing to, reading from, and managing named shared memory.
 * Handles synchronization between processes using a process-shared mutex.
 */
class NamedSharedMemory {
public:
    NamedSharedMemory(const std::string& name, std::size_t size, bool create = true);
    NamedSharedMemory(const std::string& name);
    ~NamedSharedMemory();

    void write(const void* data, std::size_t size, const std::string& type);
    void read(void* buffer, std::size_t size) const;

    /**
     * Writes data and metadata to the shared memory in a single operation.
     * @param data Pointer to the data to be written.
     * @param size Size of the data in bytes.
     * @param type A string representing the type of data (e.g., "int", "string", "json").
     */
    void writeFullStateToSharedMemory(const void* data, std::size_t size, const std::string& type);

    /**
     * Writes data and metadata to the shared memory in a single operation.
     * @param data Pointer to the data to be written.
     * @param size Size of the data in bytes.
     * @param type A string representing the type of data (e.g., "int", "string", "json").
     */
    void writeMinimalStateToSharedMemory(const void* data, std::size_t size, const std::string& type);    


    /**
     * Reads data and updates metadata from the shared memory in a single operation.
     * - Reads metadata to determine the size of written data.
     * - Reads the data into the provided buffer.
     * @param buffer Pointer to the buffer to store the read data.
     */
    void readFullStateFromSharedMemory(void* buffer);

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
     * Gets the total number of bytes written to the shared memory.
     * @return The total bytes written.
     */
    std::size_t getTotalBytesPresentInSHM() const;
    

    /**
     * Gets the metadata for all write operations.
     * @return A vector of WriteBlock structures.
     */
    const std::vector<WriteBlock>& getWriteBlocks() const;

   // Friend function  to access sharedMutex_ for synchronization
    friend void accessSharedMemoryWithMutex(NamedSharedMemory& sharedMemory, const std::function<void()>& action);    

private:
    std::string name_;                        // Name of the shared memory
    std::size_t size_;                        // Total size of the shared memory in bytes
    std::size_t totalBytesWritten_;           // Total bytes written to the shared memory
    std::size_t totalBytesPresentInSHM_;           // Total bytes written to the shared memory by external producer
    boost::interprocess::shared_memory_object shm_; // Boost shared memory object
    boost::interprocess::mapped_region region_;     // Boost mapped region for accessing memory
    std::vector<WriteBlock> writeBlocks_;     // Metadata for all write operations

    boost::interprocess::shared_memory_object metadataShm_; // Metadata shared memory
    boost::interprocess::mapped_region metadataRegion_;     // Metadata mapped region
    pthread_mutex_t* sharedMutex_; // Process-shared mutex
};

#endif // NAMED_SHARED_MEMORY_H
