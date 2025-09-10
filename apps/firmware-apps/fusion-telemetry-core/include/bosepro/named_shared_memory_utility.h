#ifndef UTILITIES_H
#define UTILITIES_H

#include <cstddef>
#include <cstring>
#include <vector>

namespace bosepro {
/**
 * @struct WriteBlock
 * Represents metadata for a single write operation in shared memory.
 */
struct WriteBlock {
    static constexpr std::size_t TYPE_SIZE = 32; // Fixed size for type string

    char type[TYPE_SIZE];       // Type of the data (e.g., "string", "int", "float", "json")
    std::size_t length;         // Length of the data in bytes
    std::size_t offset;         // Offset to the data from the start of shared memory

    // Constructor to initialize WriteBlock
    WriteBlock(const char* typeName, std::size_t len, std::size_t off)
        : length(len), offset(off) {
        std::strncpy(type, typeName, TYPE_SIZE - 1);
        type[TYPE_SIZE - 1] = '\0'; // Ensure null-termination
    }

    // Default constructor for uninitialized blocks
    WriteBlock() : type{}, length(0), offset(0) {}
};


/**
 * @struct Metadata
 * Represents the metadata stored in the metadata section of shared memory.
 */
struct Metadata {
    static constexpr std::size_t NAME_MAX_LENGTH = 32;   // Maximum length for the shared memory name
    static constexpr std::size_t MAX_WRITE_BLOCKS = 10; // Maximum number of WriteBlock entries
    static constexpr std::size_t META_DATA_MAX_SIZE = NAME_MAX_LENGTH*sizeof(char) + 
                                    3*sizeof(std::size_t) + sizeof(WriteBlock) * MAX_WRITE_BLOCKS;  

    char name[NAME_MAX_LENGTH];              // Name of the shared memory
    std::size_t size;                        // Total size of the shared memory
    std::size_t totalBytesWritten;           // Total bytes available to write to SHM
    std::size_t numberOfWriteBlocks;         // Number of WriteBlock entries
    std::vector<WriteBlock> writeBlocks;

    Metadata() : name{}, size(0), totalBytesWritten(0), numberOfWriteBlocks(0) {
        writeBlocks.clear();
    }
    

    /**
     * Deserialize data from a contiguous serialized buffer.
     * @param buffer Pointer to the serialized buffer.
     * @param bufferSize Size of the serialized buffer.
     * @throws std::runtime_error If the buffer is invalid or incomplete.
     */
    void deserialize(const char* buffer, std::size_t bufferSize);

    /**
     * Serialize the Metadata structure into a contiguous buffer.
     * @param buffer Pointer to the buffer where the serialized data will be written.
     * @param bufferSize Size of the buffer. Must be at least sizeof(Metadata).
     * @throws std::runtime_error If the buffer is too small.
     */
    void serialize(char* buffer, std::size_t bufferSize) const;

    /**
     * Updates the totalBytesWritten field in the serialized metadata buffer.
     * @param buffer Pointer to the serialized metadata buffer.
     * @param numBytesInBuffer Size of the serialized buffer in bytes.
     * @throws std::runtime_error If the buffer is invalid or too small.
     */
    void updateTotalBytesWrittenInBuffer(char* buffer, std::size_t bufferSize) const;

    /**
     * Deserializes only the totalBytesWritten field from a serialized metadata buffer.
     * @param buffer Pointer to the serialized metadata buffer.
     * @param numBytesInBuffer Size of the serialized buffer in bytes.
     * @throws std::runtime_error If the buffer is invalid or too small.
     */
    void deserializeTotalBytesWritten(const char* buffer, std::size_t bufferSize);


};
}




#endif // UTILITIES_H
