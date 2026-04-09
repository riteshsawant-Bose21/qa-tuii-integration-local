#include <gtest/gtest.h>

#include <atomic>
#include <sstream>
#include <string>
#include <unistd.h>

#include <boost/interprocess/shared_memory_object.hpp>

#include <bosepro/telemetry_message.h>
#include "telemetry_msg_handler.h"
#include "telemetry_core.h"

namespace {

std::string uniquePublisherName() {
  static std::atomic<unsigned long> counter{0};
  return "pub_" + std::to_string(getpid()) + "_" + std::to_string(++counter);
}

void cleanupPublisherSharedMemory(const std::string& publisherName) {
  for (const char* suffix : {"_hi", "_med", "_lo"}) {
    const std::string shmName = "telm_" + publisherName + suffix;
    boost::interprocess::shared_memory_object::remove(shmName.c_str());
    boost::interprocess::shared_memory_object::remove((shmName + "_metadata").c_str());
  }
}

struct PublisherCleanupGuard {
  explicit PublisherCleanupGuard(std::string publisherName)
      : name(std::move(publisherName)) {}
  ~PublisherCleanupGuard() { cleanupPublisherSharedMemory(name); }
  std::string name;
};

bosepro::Telemetry_configuration makeRegisterRequest(const std::string& publisherName,
                                                     int protocolVersion,
                                                     int schemaVersion) {
  std::stringstream ss;
  ss << "{"
     << "\"name\":\"" << publisherName << "\","
     << "\"protocol_version\":" << protocolVersion << ","
     << "\"schema_version\":" << schemaVersion << ","
     << "\"block_size\":[32,32,32]"
     << "}";
  return bosepro::Telemetry_configuration(ss);
}

bosepro::TelemetryMessage makePublisherResponse(const std::string& messageName,
                                                int protocolVersion,
                                                int schemaVersion) {
  std::stringstream ss;
  ss << "{"
     << "\"message_name\":\"" << messageName << "\","
     << "\"packet_id\":1,"
     << "\"parameters\":{"
     << "\"name\":\"publisher\","
     << "\"protocol_version\":" << protocolVersion << ","
     << "\"schema_version\":" << schemaVersion << ","
     << "\"value\":\"OK\","
     << "\"period_type\":\"HI\","
     << "\"block_name\":[\"a\",\"b\",\"c\"]"
     << "}"
     << "}";
  return bosepro::TelemetryMessage(ss);
}

}  // namespace

TEST(TelemetryMsgHandlerVersionTest, AcceptsCurrentAndPreviousProtocolVersion) {
  EXPECT_TRUE(bosepro::is_supported_telemetry_protocol_version(1));
  EXPECT_TRUE(bosepro::is_supported_telemetry_protocol_version(0));
}

TEST(TelemetryMsgHandlerVersionTest, RejectsFutureAndTooOldProtocolVersions) {
  EXPECT_FALSE(bosepro::is_supported_telemetry_protocol_version(2));
  EXPECT_FALSE(bosepro::is_supported_telemetry_protocol_version(-1));
}

TEST(TelemetryMsgHandlerVersionTest, AcceptsCurrentAndPreviousSchemaVersion) {
  EXPECT_TRUE(bosepro::is_supported_telemetry_schema_version(1));
  EXPECT_TRUE(bosepro::is_supported_telemetry_schema_version(0));
}

TEST(TelemetryMsgHandlerVersionTest, RejectsFutureAndTooOldSchemaVersions) {
  EXPECT_FALSE(bosepro::is_supported_telemetry_schema_version(2));
  EXPECT_FALSE(bosepro::is_supported_telemetry_schema_version(-1));
}

TEST(TelemetryMsgHandlerVersionTest, PubRegisterReqAcceptsNMinusOneVersions) {
  const std::string publisherName = uniquePublisherName();
  PublisherCleanupGuard cleanup(publisherName);

  bosepro::telemetryManager manager;
  auto req = makeRegisterRequest(publisherName, 0, 0);
  uint64_t packetId = 0;
  std::string reqName;
  bosepro::HandlerContext ctx;

  EXPECT_EQ(process_pub_register_req(manager, req, packetId, reqName, ctx), 0);
  EXPECT_EQ(reqName, publisherName);
}

TEST(TelemetryMsgHandlerVersionTest, PubRegisterReqRejectsTooOldOrFutureVersions) {
  const std::string publisherName = uniquePublisherName();

  {
    PublisherCleanupGuard cleanup(publisherName + "_future");
    bosepro::telemetryManager manager;
    auto req = makeRegisterRequest(publisherName + "_future", 2, 1);
    uint64_t packetId = 0;
    std::string reqName;
    bosepro::HandlerContext ctx;
    EXPECT_EQ(process_pub_register_req(manager, req, packetId, reqName, ctx), -1);
  }

  {
    PublisherCleanupGuard cleanup(publisherName + "_old");
    bosepro::telemetryManager manager;
    auto req = makeRegisterRequest(publisherName + "_old", 1, -1);
    uint64_t packetId = 0;
    std::string reqName;
    bosepro::HandlerContext ctx;
    EXPECT_EQ(process_pub_register_req(manager, req, packetId, reqName, ctx), -1);
  }
}

TEST(TelemetryMsgHandlerVersionTest, PublisherValidatorAcceptsCurrentAndPreviousVersions) {
  auto current = makePublisherResponse("pub_register_rsp", 1, 1);
  EXPECT_TRUE(current.has_supported_telemetry_versions());

  auto previous = makePublisherResponse("update_meters_req", 0, 0);
  EXPECT_TRUE(previous.has_supported_telemetry_versions());
}

TEST(TelemetryMsgHandlerVersionTest, PublisherValidatorRejectsUnsupportedVersions) {
  auto future = makePublisherResponse("pub_register_rsp", 2, 1);
  EXPECT_FALSE(future.has_supported_telemetry_versions());

  auto tooOld = makePublisherResponse("update_meters_req", 1, -1);
  EXPECT_FALSE(tooOld.has_supported_telemetry_versions());
}

TEST(TelemetryMsgHandlerVersionTest, PublisherValidatorRejectsMissingVersionFields) {
  std::stringstream ss;
  ss << "{"
     << "\"message_name\":\"pub_register_rsp\","
     << "\"packet_id\":1,"
     << "\"parameters\":{"
     << "\"name\":\"publisher\","
     << "\"value\":\"OK\""
     << "}"
     << "}";
  bosepro::TelemetryMessage message(ss);
  EXPECT_FALSE(message.has_supported_telemetry_versions());
}

TEST(TelemetryMsgHandlerVersionTest, RegisterRoundTripCurrentCoreAndPreviousPublisherIsCompatible) {
  const std::string publisherName = uniquePublisherName();
  PublisherCleanupGuard cleanup(publisherName);

  bosepro::telemetryManager manager;
  auto req = makeRegisterRequest(publisherName, 0, 0);
  uint64_t packetId = 0;
  std::string reqName;
  bosepro::HandlerContext ctx;

  ASSERT_EQ(process_pub_register_req(manager, req, packetId, reqName, ctx), 0);
  ASSERT_EQ(reqName, publisherName);

  std::ostringstream responseStream;
  ASSERT_EQ(process_pub_register_rsp(manager, reqName, 1234, true, responseStream, ctx), 0);

  std::stringstream responseInput(responseStream.str());
  bosepro::TelemetryMessage response(responseInput);
  EXPECT_EQ(response.get_message_name(), "pub_register_rsp");
  EXPECT_TRUE(response.has_supported_telemetry_versions());
  EXPECT_EQ(response.get_parameters().get_name(), publisherName);
  EXPECT_EQ(response.get_parameters().get_value(), "OK");
}

TEST(TelemetryMsgHandlerVersionTest, UpdateRequestGeneratedByCoreIsAcceptedByPreviousPublisher) {
  uint64_t packetId = 0;
  std::ostringstream requestStream;
  bosepro::HandlerContext ctx;

  ASSERT_EQ(process_update_meters_req("HI", packetId, requestStream, ctx), 0);

  std::stringstream requestInput(requestStream.str());
  bosepro::TelemetryMessage request(requestInput);
  EXPECT_EQ(request.get_message_name(), "update_meters_req");
  EXPECT_TRUE(request.has_supported_telemetry_versions());
  EXPECT_EQ(request.get_parameters().get_period_type(), "HI");
}

TEST(TelemetryMsgHandlerVersionTest, PreviousPublisherResponseIsAcceptedByCurrentCorePolicy) {
  auto response = makePublisherResponse("update_meters_rsp", 0, 0);
  EXPECT_TRUE(response.has_supported_telemetry_versions());
}
