#include "named_shared_memory_utility.h"
#include <stdexcept>

/**
 * Deserialize data from a contiguous serialized buffer.
 */
void bosepro::Metadata::deserialize(const char* buffer, std::size_t bufferSize) {
    // Calculate the expected size
    std::size_t expectedSize = sizeof(name) + sizeof(size) + sizeof(totalBytesWritten) +
                               sizeof(numberOfWriteBlocks) + sizeof(WriteBlock) * MAX_WRITE_BLOCKS;

    // Check buffer size
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }

    // Pointer to traverse the buffer
    const char* bufferPtr = buffer;

    // Deserialize name
    std::memcpy(name, bufferPtr, sizeof(name));
    bufferPtr += sizeof(name);
    name[NAME_MAX_LENGTH - 1] = '\0'; // Ensure null-termination

    // Deserialize size
    std::memcpy(&size, bufferPtr, sizeof(size));
    bufferPtr += sizeof(size);

    // Deserialize totalBytesWritten
    std::memcpy(&totalBytesWritten, bufferPtr, sizeof(totalBytesWritten));
    bufferPtr += sizeof(totalBytesWritten);

    // Deserialize numberOfWriteBlocks
    std::memcpy(&numberOfWriteBlocks, bufferPtr, sizeof(numberOfWriteBlocks));
    bufferPtr += sizeof(numberOfWriteBlocks);

    // Ensure the number of WriteBlocks does not exceed MAX_WRITE_BLOCKS
    if (numberOfWriteBlocks > MAX_WRITE_BLOCKS) {
        throw std::runtime_error("Number of WriteBlocks exceeds MAX_WRITE_BLOCKS");
    }

    // Deserialize writeBlocks
    // Read the writeBlocks from memory
    writeBlocks.clear();
    for (std::size_t i = 0; i < numberOfWriteBlocks; ++i) {
        WriteBlock block;
        std::memcpy(&block, bufferPtr, sizeof(WriteBlock));
        writeBlocks.push_back(block);
        bufferPtr += sizeof(WriteBlock); // Move to the next block
    }
}

/**
 * Serialize the Metadata structure into a contiguous buffer.
 */
void bosepro::Metadata::serialize(char* buffer, std::size_t bufferSize) const {
    // Calculate the expected size
    std::size_t expectedSize = sizeof(name) + sizeof(size) + sizeof(totalBytesWritten) +
                               sizeof(numberOfWriteBlocks) + sizeof(WriteBlock) * MAX_WRITE_BLOCKS;

    // Check if the buffer size is sufficient
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }

    // Pointer to traverse the buffer
    char* bufferPtr = buffer;

    // Serialize name
    std::memcpy(bufferPtr, name, sizeof(name));
    bufferPtr += sizeof(name);

    // Serialize size
    std::memcpy(bufferPtr, &size, sizeof(size));
    bufferPtr += sizeof(size);

    // Serialize totalBytesWritten
    std::memcpy(bufferPtr, &totalBytesWritten, sizeof(totalBytesWritten));
    bufferPtr += sizeof(totalBytesWritten);

    // Serialize numberOfWriteBlocks
    std::size_t numWriteBlocks = writeBlocks.size();
    std::memcpy(bufferPtr, &numWriteBlocks, sizeof(numWriteBlocks));
    bufferPtr += sizeof(numWriteBlocks);

    // Serialize writeBlocks
    for (const auto& block : writeBlocks) {
        std::memcpy(bufferPtr, &block, sizeof(WriteBlock));
        bufferPtr += sizeof(WriteBlock);
    }
}

/**
 * Updates the totalBytesWritten field in the serialized metadata buffer.
 */
void bosepro::Metadata::updateTotalBytesWrittenInBuffer(char* buffer, std::size_t bufferSize) const {
    // Calculate the expected offset for totalBytesWritten
    std::size_t offset = sizeof(name) + sizeof(size);

    // Calculate the expected minimum buffer size
    std::size_t expectedSize = sizeof(name) + sizeof(size) + sizeof(totalBytesWritten) +
                               sizeof(numberOfWriteBlocks) + sizeof(WriteBlock) * MAX_WRITE_BLOCKS;

    // Validate the buffer size
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }

    // Update the totalBytesWritten field in the buffer
    char* totalBytesWrittenPtr = buffer + offset;
    std::memcpy(totalBytesWrittenPtr, &totalBytesWritten, sizeof(totalBytesWritten));
}

/**
 * Deserializes only the totalBytesWritten field from a serialized metadata buffer.
 */
void bosepro::Metadata::deserializeTotalBytesWritten(const char* buffer, std::size_t bufferSize)  {
    // Calculate the expected offset for totalBytesWritten
    std::size_t offset = sizeof(name) + sizeof(size);

    // Calculate the expected minimum buffer size
    std::size_t expectedSize = sizeof(name) + sizeof(size) + sizeof(totalBytesWritten) +
                               sizeof(numberOfWriteBlocks) + sizeof(WriteBlock) * MAX_WRITE_BLOCKS;

    // Validate the buffer size
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }

    // Read the totalBytesWritten field from the buffer
    const char* totalBytesWrittenPtr = buffer + offset;
    std::memcpy(&totalBytesWritten, totalBytesWrittenPtr, sizeof(totalBytesWritten));
}
