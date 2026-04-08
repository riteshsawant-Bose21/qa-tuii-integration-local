#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/session.h>
#include <bosepro/conversion.h>


#define DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS
#include <doctest/doctest.h>

#include <cmath>
#include <memory>
#include <sstream>
#include <vector>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>


std::unique_ptr<bosepro::Session> make_meter_session(int channels = 1,
                                                    int frame_size = 16,
                                                    int sample_rate = 48000)
{
    std::ostringstream ss;

    ss << "{"
          "\"session\":{"
            "\"property_settings\":[{\"name\":\"frame_size\",\"value\":"
       << frame_size << "},{\"name\":\"sample_rate\",\"value\":"
       << sample_rate << "}]},"
          "\"audio_tasks\":[{"
            "\"name\":\"task1\","
            "\"property_settings\":[{\"name\":\"is_jack_client\",\"value\":false},"
            "{\"name\":\"frame_size\",\"value\":" << frame_size << "},"
            "{\"name\":\"sample_rate\",\"value\":" << sample_rate << "}],"
            "\"blocks\":[{"
               "\"name\":\"meter\","
               "\"algorithm\":\"meter\","
               "\"property_settings\":[{\"name\":\"channels\",\"value\":"
       << channels << "}]}],"
            "\"block_connections\":[]}],"
          "\"parameter_settings\":[";

    ss << "]}";

    std::stringstream config_stream(ss.str());
    bosepro::Configuration configuration(config_stream);
    bosepro::Definition definition("config/algorithm-definitions.json");
    auto session = std::make_unique<bosepro::Session>(configuration.get_session(), definition);
    session->create_audio_tasks(configuration);
    return session;
}

static std::vector<float> capture_meter_values(const std::string &qualified_name,
                                               int num_values)
{
    bosepro::Telemetry &telemetry = bosepro::TelemetryMonitor::get_instance().get_meter(qualified_name);
    bosepro::TelemetryMessage message("config/telemetry-messages.json");
    bosepro::TelemetryMessage meter_msg(message.get_default_meter());

    std::vector<float> values(num_values);
    bool called = false;

    telemetry.send_meter(
        [&](bosepro::TelemetryMessage msg, std::string, size_t) {
            std::stringstream ss(msg.serialize_message());
            boost::property_tree::ptree root;
            boost::property_tree::read_json(ss, root);

            auto value_node = root.get_child("value");
            int index = 0;
            for (auto &entry : value_node)
            {
                if (index >= num_values)
                {
                    break;
                }
                values[index++] = entry.second.get_value<float>();
            }
            called = true;
        },
        meter_msg,
        1);

    REQUIRE(called);
    return values;
}

TEST_SUITE_BEGIN("Meter algorithm process");

TEST_CASE("Single-channel meter reports peak level in dB")
{
    auto session = make_meter_session(1, 4, 48000);

    auto *task = session->get_task("task1");
    REQUIRE(task != nullptr);
    auto *block = task->get_block("meter");
    REQUIRE(block != nullptr);

    auto &in_term = block->get_terminal("in");
    float *in_buf = static_cast<float *>(in_term.get_buffer(0));

    std::vector<float> input = {0.1f, -0.5f, 0.3f, -0.2f};
    for (size_t i = 0; i < input.size(); ++i)
    {
        in_buf[i] = input[i];
    }

    session->process();

    auto values = capture_meter_values("meter::level", 1);
    CHECK(values[0] == doctest::Approx(bosepro::linear_to_db(0.5f)).epsilon(1e-4f));
}

TEST_CASE("Zero signal clamps meter to minimum dB")
{
    auto session = make_meter_session(1, 4, 48000);

    auto *task = session->get_task("task1");
    REQUIRE(task != nullptr);
    auto *block = task->get_block("meter");
    REQUIRE(block != nullptr);

    auto &in_term = block->get_terminal("in");
    float *in_buf = static_cast<float *>(in_term.get_buffer(0));

    for (int i = 0; i < 4; ++i)
    {
        in_buf[i] = 0.0f;
    }

    session->process();

    auto values = capture_meter_values("meter::level", 1);
    CHECK(values[0] == doctest::Approx(-60.0f));
}

TEST_CASE("Multi-channel meter reports independent channel peaks")
{
    auto session = make_meter_session(2, 4, 48000);

    auto *task = session->get_task("task1");
    REQUIRE(task != nullptr);
    auto *block = task->get_block("meter");
    REQUIRE(block != nullptr);

    auto &in_term = block->get_terminal("in");
    float *channel0 = static_cast<float *>(in_term.get_buffer(0));
    float *channel1 = static_cast<float *>(in_term.get_buffer(1));

    channel0[0] = 0.1f;
    channel0[1] = -0.2f;
    channel0[2] = 0.05f;
    channel0[3] = 0.0f;

    channel1[0] = -0.4f;
    channel1[1] = 0.2f;
    channel1[2] = 0.3f;
    channel1[3] = 0.1f;

    session->process();

    auto values = capture_meter_values("meter::level", 2);
    CHECK(values[0] == doctest::Approx(bosepro::linear_to_db(0.2f)).epsilon(1e-4f));
    CHECK(values[1] == doctest::Approx(bosepro::linear_to_db(0.4f)).epsilon(1e-4f));
}

TEST_SUITE_END();
