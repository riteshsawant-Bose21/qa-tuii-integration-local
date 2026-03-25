#include <gtest/gtest.h>

#include <array>
#include <atomic>
#include <cstring>
#include <stdexcept>
#include <string>
#include <thread>
#include <unistd.h>
#include <vector>

#include <boost/interprocess/shared_memory_object.hpp>

#include <bosepro/named_shared_memory.h>
#include <bosepro/named_shared_memory_utility.h>

namespace {

std::string uniqueShmName() {
  static std::atomic<unsigned long> counter{0};
  const auto suffix = std::to_string(getpid()) + std::to_string(++counter);
  std::string name = "tshm_" + suffix;
  if (name.size() >= bosepro::Metadata::NAME_MAX_LENGTH) {
    name.resize(bosepro::Metadata::NAME_MAX_LENGTH - 1);
  }
  return name;
}

void cleanupSharedMemory(const std::string& name) {
  boost::interprocess::shared_memory_object::remove(name.c_str());
  boost::interprocess::shared_memory_object::remove((name + "_metadata").c_str());
}

struct SharedMemoryCleanupGuard {
  explicit SharedMemoryCleanupGuard(std::string n) : name(std::move(n)) {}
  ~SharedMemoryCleanupGuard() { cleanupSharedMemory(name); }
  std::string name;
};

bosepro::SharedMemoryDataHeader readDataHeader(const std::string& name) {
  boost::interprocess::shared_memory_object shm(
      boost::interprocess::open_only, name.c_str(), boost::interprocess::read_write);
  boost::interprocess::mapped_region region(shm, boost::interprocess::read_write);

  bosepro::SharedMemoryDataHeader header{};
  std::memcpy(&header, region.get_address(), sizeof(header));
  return header;
}

bosepro::SharedMemoryPayloadHeader readPayloadHeader(const std::string& name, std::size_t storageOffset) {
  boost::interprocess::shared_memory_object shm(
      boost::interprocess::open_only, name.c_str(), boost::interprocess::read_write);
  boost::interprocess::mapped_region region(shm, boost::interprocess::read_write);

  bosepro::SharedMemoryPayloadHeader header{};
  const auto* address = static_cast<const char*>(region.get_address()) +
                        bosepro::NamedSharedMemory::DATA_HEADER_LENGTH + storageOffset;
  std::memcpy(&header, address, sizeof(header));
  return header;
}

bosepro::SharedMemoryBlobHeader readBlobHeader(const std::string& name) {
  boost::interprocess::shared_memory_object shm(
      boost::interprocess::open_only, name.c_str(), boost::interprocess::read_write);
  boost::interprocess::mapped_region region(shm, boost::interprocess::read_write);

  bosepro::SharedMemoryBlobHeader header{};
  const auto* address = static_cast<const char*>(region.get_address()) +
                        bosepro::NamedSharedMemory::DATA_HEADER_LENGTH;
  std::memcpy(&header, address, sizeof(header));
  return header;
}

void writeDataHeader(const std::string& name, const bosepro::SharedMemoryDataHeader& header) {
  boost::interprocess::shared_memory_object shm(
      boost::interprocess::open_only, name.c_str(), boost::interprocess::read_write);
  boost::interprocess::mapped_region region(shm, boost::interprocess::read_write);
  std::memcpy(region.get_address(), &header, sizeof(header));
}

}  // namespace

TEST(MetadataTest, SerializeDeserializeRoundTripPreservesFields) {
  bosepro::Metadata metadata;
  std::strncpy(metadata.name, "roundtrip", bosepro::Metadata::NAME_MAX_LENGTH - 1);
  metadata.name[bosepro::Metadata::NAME_MAX_LENGTH - 1] = '\0';
  metadata.size = 512;
  metadata.totalBytesWritten = 42;
  metadata.writeBlocks = {
      bosepro::WriteBlock("int", sizeof(int), 0),
      bosepro::WriteBlock("float", sizeof(float), sizeof(int)),
  };

  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE> buffer{};
  ASSERT_NO_THROW(metadata.serialize(buffer.data(), buffer.size()));

  bosepro::Metadata deserialized;
  ASSERT_NO_THROW(deserialized.deserialize(buffer.data(), buffer.size()));
  EXPECT_EQ(deserialized.magic, bosepro::Metadata::MAGIC);
  EXPECT_EQ(deserialized.protocolVersion, bosepro::Metadata::PROTOCOL_VERSION);
  EXPECT_EQ(deserialized.schemaVersion, bosepro::Metadata::SCHEMA_VERSION);
  EXPECT_STREQ(deserialized.name, "roundtrip");
  EXPECT_EQ(deserialized.size, 512U);
  EXPECT_EQ(deserialized.totalBytesWritten, 42U);
  ASSERT_EQ(deserialized.writeBlocks.size(), 2U);
  EXPECT_STREQ(deserialized.writeBlocks[0].type, "int");
  EXPECT_EQ(deserialized.writeBlocks[1].offset, sizeof(int));
}

TEST(MetadataTest, SerializeRejectsSmallBuffer) {
  bosepro::Metadata metadata;
  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE - 1> smallBuffer{};
  EXPECT_THROW(metadata.serialize(smallBuffer.data(), smallBuffer.size()),
               std::runtime_error);
}

TEST(MetadataTest, DeserializeRejectsSmallBuffer) {
  bosepro::Metadata metadata;
  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE - 1> smallBuffer{};
  EXPECT_THROW(metadata.deserialize(smallBuffer.data(), smallBuffer.size()),
               std::runtime_error);
}

TEST(MetadataTest, SerializeRejectsTooManyWriteBlocks) {
  bosepro::Metadata metadata;
  metadata.writeBlocks.resize(bosepro::Metadata::MAX_WRITE_BLOCKS + 1);

  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE> buffer{};
  EXPECT_THROW(metadata.serialize(buffer.data(), buffer.size()), std::runtime_error);
}

TEST(MetadataTest, DeserializeRejectsInvalidWriteBlockCount) {
  bosepro::Metadata metadata;
  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE> buffer{};

  const uint32_t magic = bosepro::Metadata::MAGIC;
  const uint16_t protocolVersion = bosepro::Metadata::PROTOCOL_VERSION;
  const uint16_t schemaVersion = bosepro::Metadata::SCHEMA_VERSION;
  const std::size_t size = 64;
  const std::size_t totalBytesWritten = 12;
  const std::size_t invalidCount = bosepro::Metadata::MAX_WRITE_BLOCKS + 1;

  char* ptr = buffer.data();
  std::memcpy(ptr, &magic, sizeof(magic));
  ptr += sizeof(magic);
  std::memcpy(ptr, &protocolVersion, sizeof(protocolVersion));
  ptr += sizeof(protocolVersion);
  std::memcpy(ptr, &schemaVersion, sizeof(schemaVersion));
  ptr += sizeof(schemaVersion);
  std::memcpy(ptr, "test", 4);
  ptr += bosepro::Metadata::NAME_MAX_LENGTH;
  std::memcpy(ptr, &size, sizeof(size));
  ptr += sizeof(size);
  std::memcpy(ptr, &totalBytesWritten, sizeof(totalBytesWritten));
  ptr += sizeof(totalBytesWritten);
  std::memcpy(ptr, &invalidCount, sizeof(invalidCount));

  EXPECT_THROW(metadata.deserialize(buffer.data(), buffer.size()), std::runtime_error);
}

TEST(MetadataTest, DeserializeRejectsInvalidMagic) {
  bosepro::Metadata metadata;
  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE> buffer{};
  ASSERT_NO_THROW(metadata.serialize(buffer.data(), buffer.size()));

  const uint32_t badMagic = 0x0;
  std::memcpy(buffer.data(), &badMagic, sizeof(badMagic));

  bosepro::Metadata deserialized;
  EXPECT_THROW(deserialized.deserialize(buffer.data(), buffer.size()), std::runtime_error);
}

TEST(MetadataTest, DeserializeRejectsInvalidProtocolVersion) {
  bosepro::Metadata metadata;
  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE> buffer{};
  ASSERT_NO_THROW(metadata.serialize(buffer.data(), buffer.size()));

  const uint16_t badProtocolVersion = bosepro::Metadata::PROTOCOL_VERSION + 1;
  std::memcpy(buffer.data() + sizeof(uint32_t), &badProtocolVersion, sizeof(badProtocolVersion));

  bosepro::Metadata deserialized;
  EXPECT_THROW(deserialized.deserialize(buffer.data(), buffer.size()), std::runtime_error);
}

TEST(MetadataTest, UpdateTotalBytesWrittenUpdatesSerializedBuffer) {
  bosepro::Metadata metadata;
  metadata.totalBytesWritten = 7;

  std::array<char, bosepro::Metadata::META_DATA_MAX_SIZE> buffer{};
  ASSERT_NO_THROW(metadata.serialize(buffer.data(), buffer.size()));

  metadata.totalBytesWritten = 99;
  ASSERT_NO_THROW(metadata.updateTotalBytesWrittenInBuffer(buffer.data(), buffer.size()));

  bosepro::Metadata readBack;
  ASSERT_NO_THROW(readBack.deserializeTotalBytesWritten(buffer.data(), buffer.size()));
  EXPECT_EQ(readBack.totalBytesWritten, 99U);
}

TEST(NamedSharedMemoryTest, LightWeightWriteRejectsOverflow) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  {
    bosepro::NamedSharedMemory shm(name.c_str(), 8);
    shm.setPersonalityAsWriter();

    const std::array<char, 9> payload{};
    EXPECT_THROW(shm.lightWeightWrite(payload.data(), payload.size()),
                 std::runtime_error);
  }
}

TEST(NamedSharedMemoryTest, DataHeaderInitializesAndTracksPayloadBytes) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 128);
  shm.setPersonalityAsWriter();

  auto header = readDataHeader(name);
  EXPECT_EQ(header.magic, bosepro::SharedMemoryDataHeader::MAGIC);
  EXPECT_EQ(header.protocolVersion, bosepro::SharedMemoryDataHeader::PROTOCOL_VERSION);
  EXPECT_EQ(header.schemaVersion, bosepro::SharedMemoryDataHeader::SCHEMA_VERSION);
  EXPECT_EQ(header.payloadBytes, 0U);

  const std::string payload = "meter_data";
  ASSERT_NO_THROW(shm.write(payload.data(), payload.size(), "string"));
  ASSERT_NO_THROW(shm.writeNumberBytesToSharedMemory());

  header = readDataHeader(name);
  EXPECT_EQ(header.payloadBytes, payload.size());
  EXPECT_EQ(header.payloadBlockCount, 1U);

  const auto payloadHeader = readPayloadHeader(name, 0);
  EXPECT_EQ(payloadHeader.magic, bosepro::SharedMemoryPayloadHeader::MAGIC);
  EXPECT_EQ(payloadHeader.protocolVersion, bosepro::SharedMemoryPayloadHeader::PROTOCOL_VERSION);
  EXPECT_EQ(payloadHeader.schemaVersion, bosepro::SharedMemoryPayloadHeader::SCHEMA_VERSION);
  EXPECT_STREQ(payloadHeader.type, "string");
  EXPECT_EQ(payloadHeader.payloadBytes, payload.size());
}

TEST(NamedSharedMemoryTest, LightWeightWriteUsesVersionedBlobEnvelope) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 128);
  shm.setPersonalityAsWriter();

  const std::string payload = "{\"meter\":1}";
  ASSERT_NO_THROW(shm.lightWeightWrite(payload.data(), payload.size()));
  ASSERT_NO_THROW(shm.writeNumberBytesToSharedMemory());

  auto dataHeader = readDataHeader(name);
  EXPECT_EQ(dataHeader.payloadBytes, payload.size());
  EXPECT_EQ(dataHeader.payloadBlockCount, 0U);

  const auto blobHeader = readBlobHeader(name);
  EXPECT_EQ(blobHeader.magic, bosepro::SharedMemoryBlobHeader::MAGIC);
  EXPECT_EQ(blobHeader.protocolVersion, bosepro::SharedMemoryBlobHeader::PROTOCOL_VERSION);
  EXPECT_EQ(blobHeader.schemaVersion, bosepro::SharedMemoryBlobHeader::SCHEMA_VERSION);
  EXPECT_STREQ(blobHeader.contentType, "json");
  EXPECT_EQ(blobHeader.payloadBytes, payload.size());

  shm.setPersonalityAsReader();
  std::array<char, 128> buffer{};
  const auto bytes = shm.read(buffer.data(), buffer.size());
  EXPECT_EQ(bytes, payload.size());
  EXPECT_EQ(std::string(buffer.data(), bytes), payload);
}

TEST(NamedSharedMemoryTest, OpenRejectsCorruptedDataHeaderMagic) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory writer(name.c_str(), 128);
  writer.setPersonalityAsWriter();
  const std::string payload = "meter_data";
  ASSERT_NO_THROW(writer.write(payload.data(), payload.size(), "string"));
  ASSERT_NO_THROW(writer.writeNumberBytesToSharedMemory());

  auto header = readDataHeader(name);
  header.magic = 0;
  writeDataHeader(name, header);

  EXPECT_THROW({ bosepro::NamedSharedMemory reader(name.c_str()); }, std::runtime_error);
}

TEST(NamedSharedMemoryTest, ReadRejectsDataHeaderPayloadMismatch) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory writer(name.c_str(), 128);
  writer.setPersonalityAsWriter();
  const std::string payload = "meter_data";
  ASSERT_NO_THROW(writer.write(payload.data(), payload.size(), "string"));
  ASSERT_NO_THROW(writer.writeNumberBytesToSharedMemory());

  auto header = readDataHeader(name);
  header.payloadBytes = payload.size() - 1;
  writeDataHeader(name, header);

  writer.setPersonalityAsReader();
  std::array<char, 128> readBuffer{};
  EXPECT_THROW(writer.read(readBuffer.data(), readBuffer.size()), std::runtime_error);
}

TEST(NamedSharedMemoryTest, NonOwnerDestructorDoesNotRemoveSharedMemory) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  {
    bosepro::NamedSharedMemory creator(name.c_str(), 64);
    creator.setPersonalityAsWriter();

    {
      bosepro::NamedSharedMemory opener(name.c_str());
    }

    EXPECT_NO_THROW({ bosepro::NamedSharedMemory openerAgain(name.c_str()); });
  }

  EXPECT_THROW({ bosepro::NamedSharedMemory shouldFail(name.c_str()); },
               std::runtime_error);
}

TEST(NamedSharedMemoryTest, WriteReadRoundTripWithNumberSync) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 128);
  shm.setPersonalityAsWriter();

  const std::string payload = "meter_data";
  ASSERT_NO_THROW(shm.write(payload.data(), payload.size(), "string"));
  ASSERT_NO_THROW(shm.writeNumberBytesToSharedMemory());

  shm.setPersonalityAsReader();
  std::array<char, 128> readBuffer{};
  const auto bytes = shm.read(readBuffer.data(), readBuffer.size());
  EXPECT_EQ(bytes, payload.size());
  EXPECT_EQ(std::string(readBuffer.data(), bytes), payload);
}

TEST(NamedSharedMemoryTest, ReadFullStateLoadsWriteBlocks) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory writer(name.c_str(), 128);
  writer.setPersonalityAsWriter();
  const int first = 123;
  const float second = 4.5f;
  ASSERT_NO_THROW(writer.write(&first, sizeof(first), "int"));
  ASSERT_NO_THROW(writer.write(&second, sizeof(second), "float"));
  ASSERT_NO_THROW(writer.writeMetaDataToSharedMemory());

  bosepro::NamedSharedMemory reader(name.c_str());
  reader.setPersonalityAsReader();

  std::array<char, 128> readBuffer{};
  const auto bytes = reader.readFullStateFromSharedMemory(readBuffer.data(), readBuffer.size());
  EXPECT_EQ(bytes, sizeof(first) + sizeof(second));
  ASSERT_EQ(reader.getWriteBlocks().size(), 2U);
  EXPECT_STREQ(reader.getWriteBlocks()[0].type, "int");
  EXPECT_STREQ(reader.getWriteBlocks()[1].type, "float");
}

TEST(NamedSharedMemoryTest, ConstructorRejectsTooLongName) {
  std::string longName(bosepro::Metadata::NAME_MAX_LENGTH, 'x');
  EXPECT_THROW({ bosepro::NamedSharedMemory shm(longName.c_str(), 32); },
               std::runtime_error);
}

TEST(NamedSharedMemoryTest, WriteRejectsReaderPersonality) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 32);
  const int value = 1;
  EXPECT_THROW(shm.write(&value, sizeof(value), "int"), std::runtime_error);
}

TEST(NamedSharedMemoryTest, ReadRejectsWriterPersonality) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 32);
  shm.setPersonalityAsWriter();
  std::array<char, 32> buffer{};
  EXPECT_THROW(shm.read(buffer.data(), buffer.size()), std::runtime_error);
}

TEST(NamedSharedMemoryTest, ReadRejectsSmallDestinationBuffer) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 64);
  shm.setPersonalityAsWriter();
  const std::string payload = "0123456789";
  ASSERT_NO_THROW(shm.write(payload.data(), payload.size(), "string"));
  ASSERT_NO_THROW(shm.writeNumberBytesToSharedMemory());
  shm.setPersonalityAsReader();

  std::array<char, 2> tinyBuffer{};
  EXPECT_THROW(shm.read(tinyBuffer.data(), tinyBuffer.size()), std::runtime_error);
}

TEST(NamedSharedMemoryTest, ResetWritePointerClearsVisibleBytes) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 64);
  shm.setPersonalityAsWriter();
  const std::string payload = "payload";
  ASSERT_NO_THROW(shm.write(payload.data(), payload.size(), "string"));
  ASSERT_NO_THROW(shm.resetWritePointer());

  shm.setPersonalityAsReader();
  std::array<char, 64> buffer{};
  const auto bytes = shm.read(buffer.data(), buffer.size());
  EXPECT_EQ(bytes, 0U);
}

TEST(NamedSharedMemoryTest, OpenNonExistentSharedMemoryThrows) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);
  EXPECT_THROW({ bosepro::NamedSharedMemory missing(name.c_str()); },
               std::runtime_error);
}

TEST(NamedSharedMemoryTest, RapidWriteResetCyclesRemainConsistent) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory shm(name.c_str(), 256);
  shm.setPersonalityAsWriter();

  const std::string payload = "abcdef";
  for (int i = 0; i < 100; ++i) {
    ASSERT_NO_THROW(shm.write(payload.data(), payload.size(), "string"));
    ASSERT_NO_THROW(shm.writeNumberBytesToSharedMemory());

    shm.setPersonalityAsReader();
    std::array<char, 256> readBuffer{};
    const auto bytes = shm.read(readBuffer.data(), readBuffer.size());
    EXPECT_EQ(bytes, payload.size());
    EXPECT_EQ(std::string(readBuffer.data(), bytes), payload);

    shm.setPersonalityAsWriter();
    ASSERT_NO_THROW(shm.resetWritePointer());
  }
}

TEST(NamedSharedMemoryTest, RapidCreateOpenDestroyCycles) {
  for (int i = 0; i < 50; ++i) {
    const std::string name = uniqueShmName();
    SharedMemoryCleanupGuard cleanup(name);

    {
      bosepro::NamedSharedMemory creator(name.c_str(), 64);
      creator.setPersonalityAsWriter();
      const std::array<char, 4> payload{{'t', 'e', 's', 't'}};
      ASSERT_NO_THROW(creator.write(payload.data(), payload.size(), "bytes"));
      ASSERT_NO_THROW(creator.writeMetaDataToSharedMemory());

      bosepro::NamedSharedMemory opener(name.c_str());
      opener.setPersonalityAsReader();
      std::array<char, 64> out{};
      const auto bytes = opener.readFullStateFromSharedMemory(out.data(), out.size());
      EXPECT_EQ(bytes, payload.size());
    }
  }
}

TEST(NamedSharedMemoryTest, ConcurrentWriterReaderHandlesStayStable) {
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  bosepro::NamedSharedMemory writer(name.c_str(), 256);
  writer.setPersonalityAsWriter();

  bosepro::NamedSharedMemory reader(name.c_str());
  reader.setPersonalityAsReader();

  const std::string payload = "0123456789ABCDEF";
  std::atomic<int> failures{0};

  std::thread writerThread([&]() {
    for (int i = 0; i < 200; ++i) {
      try {
        writer.resetWritePointer();
        writer.write(payload.data(), payload.size(), "string");
        writer.writeNumberBytesToSharedMemory();
      } catch (...) {
        ++failures;
      }
    }
  });

  std::thread readerThread([&]() {
    std::array<char, 256> buffer{};
    for (int i = 0; i < 200; ++i) {
      try {
        const auto bytes = reader.read(buffer.data(), buffer.size());
        if (bytes != 0 && bytes != payload.size()) {
          ++failures;
          continue;
        }
        if (bytes == payload.size() &&
            std::string(buffer.data(), bytes) != payload) {
          ++failures;
        }
      } catch (...) {
        ++failures;
      }
    }
  });

  writerThread.join();
  readerThread.join();
  EXPECT_EQ(failures.load(), 0);
}
