
#include <bosepro/algorithm.h>
#include <bosepro/configuration.h>
#include <bosepro/session.h>

#include <doctest/doctest.h>
#include <spdlog/spdlog.h>

#include <iostream>

class TestParameterSettings : public bosepro::Algorithm
{
public:
    TestParameterSettings(const bosepro::BlockConfiguration &configuration);
    virtual ~TestParameterSettings() = default;

    virtual void process() override;


    static bool get_bool_scalar() { return active_instance->bool_scalar; }
    static float get_float_scalar() { return active_instance->float_scalar; }
    static int_fast32_t get_integer_scalar() { return active_instance->integer_scalar; }
    static const std::string &get_string_scalar() { return active_instance->string_scalar; }
    static const std::string &get_enum_scalar() { return active_instance->enum_scalar; }
    static float get_float_vector(size_t index) { return active_instance->float_vector[index]; }
    static float get_float_matrix(size_t row, size_t col) { return active_instance->float_matrix[row][col]; }


private:
    bool bool_scalar;
    float float_scalar;
    int_fast32_t integer_scalar;
    std::string string_scalar;
    std::string enum_scalar;
    bosepro::DspCoeffMemory<float []> float_vector;
    bosepro::DspCoeffMemory<float *[]> float_matrix;

    static TestParameterSettings *active_instance;

    ALGORITHM_DECLARE(TestParameterSettings);
};

ALGORITHM_REGISTER(TestParameterSettings, "test_parameter_settings");

TestParameterSettings *TestParameterSettings::active_instance = nullptr;

TestParameterSettings::TestParameterSettings(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    assign_parameter("bool_scalar", &bool_scalar);
    assign_parameter("float_scalar", &float_scalar);
    assign_parameter("integer_scalar", &integer_scalar);
    assign_parameter("string_scalar", &string_scalar);
    assign_parameter("enum_scalar", &enum_scalar);
    assign_parameter("float_vector", float_vector);
    assign_parameter("float_matrix", float_matrix);
    active_instance = this;
}

void TestParameterSettings::process()
{
}


TEST_SUITE_BEGIN("Parameter Settings");


TEST_CASE("Basic JSON Validation")
{
    //spdlog::set_level(spdlog::level::off);

    // Invalid JSON format
    std::stringstream ss;
    ss.str("{ \"target\": \"foo\", \"name\": \"bar\", \"value\": true }");
    bosepro::ParameterSetting ps(ss);
    // Doctest doesn't like CHECK_THROWS(bosePro::ParameterSetting ps(ss))
    ss.str("{ blah");
    CHECK_THROWS(ps = bosepro::ParameterSetting(ss));
}


TEST_CASE("Missing Required Members")
{
    bosepro::Configuration configuration("test/test-parameter-settings-config.json");
    bosepro::Definition definition("test/test-parameter-settings-definitions.json");

    bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                definition);
    session.create_audio_tasks(configuration);

    std::stringstream ss;
    ss.str("{ \"target\": \"foo\", \"name\": \"bar\", \"value\": true }");
    bosepro::ParameterSetting ps(ss);

    // Missing "target" member
    ss.str("{ \"name\": \"bool_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Missing "name" member
    ss.str("{ \"target\": \"block1\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Missing "index" member
    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Missing "value" member
    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\" }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));
}


TEST_CASE("Bad Target Name")
{
    bosepro::Configuration configuration("test/test-parameter-settings-config.json");
    bosepro::Definition definition("test/test-parameter-settings-definitions.json");

    bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                definition);
    session.create_audio_tasks(configuration);

    std::stringstream ss;

    // A target name that isn't session or an existing block name
    ss.str("{ \"target\": \"blah\", \"name\": \"bool_scalar\", \"value\": true }");
    bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Bad value types for target name
    // These might start failing if we move away from Boost property trees,
    // which turn everything into strings.
    ss.str("{ \"target\": 5, \"name\": \"bool_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": 5.0, \"name\": \"bool_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": true, \"name\": \"bool_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": null, \"name\": \"bool_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": [0, 1, 2, 3], \"name\": \"bool_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": { \"foo\": \"bar\" }, \"name\": \"bool_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));
}


TEST_CASE("Bad Parameter Name")
{
    bosepro::Configuration configuration("test/test-parameter-settings-config.json");
    bosepro::Definition definition("test/test-parameter-settings-definitions.json");

    bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                definition);
    session.create_audio_tasks(configuration);

    std::stringstream ss;

    // Bad parameter name for algorithm
    ss.str("{ \"target\": \"block1\", \"name\": \"blah\", \"value\": true }");
    bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": 5, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": 5.0, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": true, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": null, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": [0, 1, 2, 3], \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": { \"foo\": \"bar\" }, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Bad parameter name for session
    ss.str("{ \"target\": \"session\", \"name\": \"blah\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"session\", \"name\": 5, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"session\", \"name\": 5.0, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"session\", \"name\": true, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"session\", \"name\": null, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"session\", \"name\": [0, 1, 2, 3], \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"session\", \"name\": { \"foo\": \"bar\" }, \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));
}


TEST_CASE("Bad Index")
{
    bosepro::Configuration configuration("test/test-parameter-settings-config.json");
    bosepro::Definition definition("test/test-parameter-settings-definitions.json");

    bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                definition);
    session.create_audio_tasks(configuration);

    std::stringstream ss;

    // Unexpected index dimensions
    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"index\": [1], \"value\": 3.0 }");
    bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"index\": [1, 1], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": [1, 1], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [1], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Index out of range
    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": [0], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [0, 1], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [1, 0], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": [5], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [5, 1], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [1, 5], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Weird index
    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": 1, \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": [\"foo\"], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": [1.5], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [1, 2.5], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));
}

TEST_CASE("Bad Value")
{
    bosepro::Configuration configuration("test/test-parameter-settings-config.json");
    bosepro::Definition definition("test/test-parameter-settings-definitions.json");

    bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                definition);
    session.create_audio_tasks(configuration);

    std::stringstream ss;

    // Bad Boolean values
    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\", \"value\": 2 }");
    bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\", \"value\": 1.5 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\", \"value\": null }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\", \"value\": \"foo\" }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\", \"value\": [true] }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Bad float values
    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": null }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": \"foo\" }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": [1.5] }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Bad integer values
    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": true }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": 1.5 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": null }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": \"foo\" }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": [1] }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // We can't really enforce type for string values in a straightforward way
    // because of the way Boost property trees work -- everything is internally
    // represented as a string and converted back to float, int, etc. as needed.

    // Out of range float values
    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": -12.1 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": 12.1 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Out of range integer values
    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": -13 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": 13 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Excessively long string values
    ss.str("{ \"target\": \"block1\", \"name\": \"string_scalar\", \"value\": \"abcdefghi\" }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));

    // Invalid enumerated string values
    ss.str("{ \"target\": \"block1\", \"name\": \"enum_scalar\", \"value\": \"four\" }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_THROWS(session.process_parameter_setting(ps));
}

TEST_CASE("Good Settings")
{
    bosepro::Configuration configuration("test/test-parameter-settings-config.json");
    bosepro::Definition definition("test/test-parameter-settings-definitions.json");

    bosepro::Session session = bosepro::Session(configuration.get_session(),
                                                definition);
    session.create_audio_tasks(configuration);

    std::stringstream ss;

    // Good Boolean values
    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\", \"value\": true }");
    bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_bool_scalar());

    ss.str("{ \"target\": \"block1\", \"name\": \"bool_scalar\", \"value\": false }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(!TestParameterSettings::get_bool_scalar());

    // Good integer values
    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": -12 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_integer_scalar() == -12);

    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": 0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_integer_scalar() == 0);

    ss.str("{ \"target\": \"block1\", \"name\": \"integer_scalar\", \"value\": 12 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_integer_scalar() == 12);

    // Good float values
    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": -12 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_scalar() == -12.0);

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": -12.0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_scalar() == -12.0);

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": 0.0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_scalar() == 0.0);

    ss.str("{ \"target\": \"block1\", \"name\": \"float_scalar\", \"value\": 12.0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_scalar() == 12.0);

    // Good string values
    ss.str("{ \"target\": \"block1\", \"name\": \"string_scalar\", \"value\": \"abc\" }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_string_scalar() == "abc");

    ss.str("{ \"target\": \"block1\", \"name\": \"string_scalar\", \"value\": \"\" }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_string_scalar() == "");

    ss.str("{ \"target\": \"block1\", \"name\": \"string_scalar\", \"value\": \"abcdefgh\" }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_string_scalar() == "abcdefgh");

    // Good enum values
    ss.str("{ \"target\": \"block1\", \"name\": \"enum_scalar\", \"value\": \"one\" }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_enum_scalar() == "one");

    ss.str("{ \"target\": \"block1\", \"name\": \"enum_scalar\", \"value\": \"two\" }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_enum_scalar() == "two");

    ss.str("{ \"target\": \"block1\", \"name\": \"enum_scalar\", \"value\": \"three\" }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_enum_scalar() == "three");

    // Good index values
    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": [1], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_vector(0) == 3.0);

    ss.str("{ \"target\": \"block1\", \"name\": \"float_vector\", \"index\": [4], \"value\": -3.0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_vector(3) == -3.0);

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [1, 1], \"value\": 3.0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_matrix(0, 0) == 3.0);

    ss.str("{ \"target\": \"block1\", \"name\": \"float_matrix\", \"index\": [4, 4], \"value\": -3.0 }");
    ps = bosepro::ParameterSetting(ss);
    session.process_parameter_setting(ps);
    CHECK(TestParameterSettings::get_float_matrix(3, 3) == -3.0);
}

TEST_SUITE_END(); // Parameter Settings
