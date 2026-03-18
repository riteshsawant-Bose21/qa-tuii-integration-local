#include <bosepro/named_shared_memory_utility.h>
#include <stdexcept>

namespace {

std::size_t expectedMetadataSize()
{
    return bosepro::Metadata::META_DATA_MAX_SIZE;
}

std::size_t totalBytesWrittenOffset()
{
    return bosepro::Metadata::HEADER_SIZE +
           bosepro::Metadata::NAME_FIELD_SIZE +
           sizeof(std::size_t); // size
}

void validateMetadataHeader(const bosepro::Metadata& metadata)
{
    if (metadata.magic != bosepro::Metadata::MAGIC) {
        throw std::runtime_error("Invalid shared memory metadata magic");
    }
    if (metadata.protocolVersion != bosepro::Metadata::PROTOCOL_VERSION) {
        throw std::runtime_error("Unsupported shared memory metadata protocol version");
    }
    if (metadata.schemaVersion != bosepro::Metadata::SCHEMA_VERSION) {
        throw std::runtime_error("Unsupported shared memory metadata schema version");
    }
}

} // namespace

/**
 * Deserialize data from a contiguous serialized buffer.
 */
void bosepro::Metadata::deserialize(const char* buffer, std::size_t bufferSize) {
    // Calculate the expected size
    std::size_t expectedSize = expectedMetadataSize();

    // Check buffer size
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }

    // Pointer to traverse the buffer
    const char* bufferPtr = buffer;

    // Deserialize metadata header
    std::memcpy(&magic, bufferPtr, sizeof(magic));
    bufferPtr += sizeof(magic);
    std::memcpy(&protocolVersion, bufferPtr, sizeof(protocolVersion));
    bufferPtr += sizeof(protocolVersion);
    std::memcpy(&schemaVersion, bufferPtr, sizeof(schemaVersion));
    bufferPtr += sizeof(schemaVersion);

    validateMetadataHeader(*this);

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
    writeBlocks.reserve(numberOfWriteBlocks);
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
    std::size_t expectedSize = expectedMetadataSize();

    // Check if the buffer size is sufficient
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }
    if (writeBlocks.size() > MAX_WRITE_BLOCKS) {
        throw std::runtime_error("Number of WriteBlocks exceeds MAX_WRITE_BLOCKS");
    }

    // Pointer to traverse the buffer
    char* bufferPtr = buffer;

    // Serialize metadata header
    std::memcpy(bufferPtr, &magic, sizeof(magic));
    bufferPtr += sizeof(magic);
    std::memcpy(bufferPtr, &protocolVersion, sizeof(protocolVersion));
    bufferPtr += sizeof(protocolVersion);
    std::memcpy(bufferPtr, &schemaVersion, sizeof(schemaVersion));
    bufferPtr += sizeof(schemaVersion);

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
    // Calculate the expected minimum buffer size
    std::size_t expectedSize = expectedMetadataSize();

    // Validate the buffer size
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }

    // Update the totalBytesWritten field in the buffer
    char* totalBytesWrittenPtr = buffer + totalBytesWrittenOffset();
    std::memcpy(totalBytesWrittenPtr, &totalBytesWritten, sizeof(totalBytesWritten));
}

/**
 * Deserializes only the totalBytesWritten field from a serialized metadata buffer.
 */
void bosepro::Metadata::deserializeTotalBytesWritten(const char* buffer, std::size_t bufferSize)  {
    // Calculate the expected minimum buffer size
    std::size_t expectedSize = expectedMetadataSize();

    // Validate the buffer size
    if (bufferSize < expectedSize) {
        throw std::runtime_error("Buffer size is smaller than the expected metadata size");
    }

    // Read the totalBytesWritten field from the buffer
    const char* totalBytesWrittenPtr = buffer + totalBytesWrittenOffset();
    std::memcpy(&totalBytesWritten, totalBytesWrittenPtr, sizeof(totalBytesWritten));
}
