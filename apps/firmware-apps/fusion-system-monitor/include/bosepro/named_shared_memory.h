#ifndef NAMED_SHARED_MEMORY_H
#define NAMED_SHARED_MEMORY_H

#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <string>
#include <vector>

/**
 * @struct WriteBlock
 * Represents metadata for each write operation in shared memory.
 */
struct WriteBlock {
    std::string type;   // Type of the written data
    std::size_t length; // Length of the data in bytes
    void* pointer;      // Pointer to the written value in shared memory
};

class NamedSharedMemory {
public:
    /**
     * Constructor
     * Creates or opens a shared memory region.
     * @param name Name of the shared memory region.
     * @param size Size of the shared memory region in bytes.
     * @param create If true, creates a new shared memory region; otherwise opens an existing one.
     */
    NamedSharedMemory(const std::string& name, std::size_t size, bool create = false);

    /**
     * Destructor
     * Cleans up the shared memory region by removing it.
     */
    ~NamedSharedMemory();

    /**
     * Resets the TotalBytesWritten variable and
     * clears the NamedSharedMemory.
     */
    void resetWrite();

    /**
     * Clears the NamedSharedMemory.
     */
    void clearMemory();

    /**
     * Writes data to the shared memory.
     * @param data Pointer to the data to be written.
     * @param size Size of the data to be written in bytes.
     * @param type A string representing the type of data (e.g., "int", "string").
     */
    void write(const void* data, std::size_t size, const std::string& type);

    /**
     * Reads data from the shared memory.
     * @param buffer Buffer to store the read data.
     * @param size Size of the data to be read in bytes.
     */
    void read(void* buffer, std::size_t size) const;

    /**
     * Gets the name of the shared memory region.
     * @return The name of the shared memory.
     */
    std::string getName() const;

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
     * Friend function to retrieve the value from a WriteBlock as a string.
     * @param block The WriteBlock to retrieve the value from.
     * @return The value as a string.
     */
    friend std::string getWriteBlockValue(const WriteBlock& block);

private:
    std::string name_;                        // Name of the shared memory
    std::size_t size_;                        // Total size of the shared memory in bytes
    std::size_t totalBytesWritten_;           // Total bytes written to the shared memory
    boost::interprocess::shared_memory_object shm_; // Boost shared memory object
    boost::interprocess::mapped_region region_;     // Boost mapped region for accessing memory
    std::vector<WriteBlock> writeBlocks_;     // Metadata for all write operations
};

#endif // NAMED_SHARED_MEMORY_H
