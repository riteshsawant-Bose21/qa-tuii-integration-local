
#include <bosepro/algorithm.h>
#include <bosepro/configuration.h>
#include <bosepro/session.h>

#include <doctest/doctest.h>
#include <spdlog/spdlog.h>

#include <iostream>

class TestConfiguration : public bosepro::Algorithm
{
public:
    TestConfiguration(const bosepro::BlockConfiguration &configuration);
    virtual ~TestConfiguration() = default;

    virtual void process() override;

    static bool get_bool_property() { return active_instance->bool_property; }
    static float get_float_property() { return active_instance->float_property; }
    static int_fast32_t get_integer_property() { return active_instance->integer_property; }
    static const std::string &get_string_property() { return active_instance->string_property; }
    static const std::string &get_enum_property() { return active_instance->enum_property; }
    static int get_terminal_channels() { return active_instance->terminal_channels; }


private:
    bool bool_property;
    float float_property;
    int_fast32_t integer_property;
    std::string string_property;
    std::string enum_property;
    int terminal_channels;

    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;

    static TestConfiguration *active_instance;

    ALGORITHM_DECLARE(TestConfiguration);
};

ALGORITHM_REGISTER(TestConfiguration, "test_configuration");

TestConfiguration *TestConfiguration::active_instance = nullptr;

TestConfiguration::TestConfiguration(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("bool_property", bool_property);
    get_property("float_property", float_property);
    get_property("integer_property", integer_property);
    get_property("string_property", string_property);
    get_property("enum_property", enum_property);

    assign_terminal("in", in);
    assign_terminal("out", out);
    get_terminal_num_channels("out", terminal_channels);
    active_instance = this;
}

void TestConfiguration::process()
{
}


TEST_SUITE_BEGIN("Configuration");


TEST_CASE("Basic JSON Validation")
{
    spdlog::set_level(spdlog::level::off);

    // Invalid JSON format
    std::stringstream ss;
    ss.str("{}");
    std::ofstream("test-configuration-temp.json") << ss.str();
    bosepro::Configuration config = bosepro::Configuration("test-configuration-temp.json");

    ss.str("{ blah");
    std::ofstream("test-configuration-temp.json") << ss.str();
    CHECK_THROWS(config = bosepro::Configuration("test-configuration-temp.json"));
}


TEST_CASE("Task Missing or Invalid Required Members")
{
    bosepro::Definition definition("test/test-configuration-definitions.json");
    bosepro::Configuration configuration("test/test-configuration-config.json");

    std::stringstream ss;

    // Missing "name" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"blocks\": [], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "blocks" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"name\": \"task1\", \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "block_connections" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"name\": \"task1\", \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"blocks\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Duplicate task names
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [], \"block_connections\": [] }, { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }
}


TEST_CASE("Block Missing or Invalid Required Members")
{
    bosepro::Definition definition("test/test-configuration-definitions.json");
    bosepro::Configuration configuration("test/test-configuration-config.json");

    std::stringstream ss;

    // Missing "name" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"algorithm\": \"blah\"}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "algorithm" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\"}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Invalid "algorithm" value
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"blah\"}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Duplicate block names
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\"}, {\"name\": \"block1\", \"algorithm\": \"test_configuration\"}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }
}


TEST_CASE("Invalid Property Settings")
{
    bosepro::Definition definition("test/test-configuration-definitions.json");
    bosepro::Configuration configuration("test/test-configuration-config.json");

    std::stringstream ss;

    // Missing "name" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"value\": true}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Name isn't a property for this algorithm
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"blah\", \"value\": true}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "value" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad Boolean values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\", \"value\": 2}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\", \"value\": 1.5}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\", \"value\": null}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\", \"value\": \"foo\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\", \"value\": [true]}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad float values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": true}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": null}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": \"foo\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": [1.5]}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad integer values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": true}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": 1.5}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": null}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": \"foo\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": [1]}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // We can't really enforce type for string values in a straightforward way
    // because of the way Boost property trees work -- everything is internally
    // represented as a string and converted back to float, int, etc. as needed.

    // Out of range float values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": -10.1}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": 10.1}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Out of range integer values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": -11}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": 11}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Excessively long string values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"string_property\", \"value\": \"abcdefghi\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Invalid enumerated string values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"enum_property\", \"value\": \"four\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }
}


TEST_CASE("Good Property Settings")
{
    bosepro::Definition definition("test/test-configuration-definitions.json");
    bosepro::Configuration configuration("test/test-configuration-config.json");

    std::stringstream ss;

    // Good Boolean values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\", \"value\": true}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_bool_property());
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"bool_property\", \"value\": false}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(!TestConfiguration::get_bool_property());
    }

    // Good integer values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": -10}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_integer_property() == -10);
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"integer_property\", \"value\": 10}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_integer_property() == 10);
    }

    // Good float values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": -10.0}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_float_property() == -10.0f);
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"float_property\", \"value\": 10.0}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_float_property() == 10.0f);
    }

    // Good string values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"string_property\", \"value\": \"abcdefgh\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_string_property() == "abcdefgh");
    }

    // Good enum values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"enum_property\", \"value\": \"one\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_enum_property() == "one");
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"enum_property\", \"value\": \"two\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_enum_property() == "two");
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"property_settings\": [{\"name\": \"enum_property\", \"value\": \"three\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_enum_property() == "three");
    }
}


TEST_CASE("Invalid Terminal Channels")
{
    bosepro::Definition definition("test/test-configuration-definitions.json");
    bosepro::Configuration configuration("test/test-configuration-config.json");

    std::stringstream ss;

    // Missing "name" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"channels\": 1}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "channels" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Invalid name
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"blah\", \"channels\": 1}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Named terminal has channels specified elsewhere
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"in\", \"channels\": 1}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad values for channels
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": true}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": false}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": null}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": null}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": null}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1.5}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": null}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": \"foo\"}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": null}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": [1]}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Out of range channels
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": -1}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 9}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }
}


TEST_CASE("Good Terminal Channels")
{
    bosepro::Definition definition("test/test-configuration-definitions.json");
    bosepro::Configuration configuration("test/test-configuration-config.json");

    std::stringstream ss;

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 0}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_terminal_channels() == 0);
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_terminal_channels() == 1);
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 8}]}], \"block_connections\": [] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        session.create_audio_tasks(config);
        CHECK(TestConfiguration::get_terminal_channels() == 8);
    }
}


TEST_CASE("Invalid Block Connections")
{
    bosepro::Definition definition("test/test-configuration-definitions.json");
    bosepro::Configuration configuration("test/test-configuration-config.json");

    std::stringstream ss;

    // Missing "source_block" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "output_terminal" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "output_channel" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "destination block" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "input_terminal" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Missing "input_channel" member
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\"} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad "source_block" name
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"blah\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad "output_terminal" name
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"blah\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // "output_terminal" is an input terminal.
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"in\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad "destination_block" name
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"blah\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Bad "input_terminal" name
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"blah\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // "input_terminal" is an output terminal.
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"out\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Out of range "output_channel" values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 0, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 2, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Out of range "input_channel" values
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 0} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 2} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }

    // Same input channel connected more than once
    {
        bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                    definition);
        ss.str("{ \"audio_tasks\": [ { \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}], \"name\": \"task1\", \"blocks\": [{\"name\": \"block1\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}, {\"name\": \"block2\", \"algorithm\": \"test_configuration\", \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]}], \"block_connections\": [ {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1}, {\"source_block\": \"block1\", \"output_terminal\": \"out\", \"output_channel\": 1, \"destination_block\": \"block2\", \"input_terminal\": \"in\", \"input_channel\": 1} ] } ] }");
        std::ofstream("test-configuration-temp.json") << ss.str();
        bosepro::Configuration config("test-configuration-temp.json");
        CHECK_THROWS(session.create_audio_tasks(config));
    }
}


TEST_SUITE_END(); // Parameter Settings
