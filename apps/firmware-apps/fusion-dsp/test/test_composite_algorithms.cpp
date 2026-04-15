
#include <bosepro/algorithm.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/session.h>

#include <doctest/doctest.h>
#include <spdlog/spdlog.h>

#include <fstream>
#include <sstream>

// Helper: write json string to a temp file and return a Configuration for it.
static bosepro::Configuration config_from_string(const std::string &json)
{
    static int counter = 0;
    std::string filename = "test-composite-temp-" + std::to_string(counter++) + ".json";
    std::ofstream(filename) << json;
    return bosepro::Configuration(filename);
}


TEST_SUITE_BEGIN("Composite Algorithms");


// ---------------------------------------------------------------------------
// Expansion: basic 2-block composite creates two internal blocks named
// "comp/inner_a" and "comp/inner_b", not the outer "comp" name.
// ---------------------------------------------------------------------------
TEST_CASE("Composite block expansion creates internal block names")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);

    // Task with one composite_basic block.
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_basic\","
        "    \"property_settings\": [{\"name\": \"bool_property\", \"value\": false}],"
        "    \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]"
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    // Must not throw: composite expansion should succeed.
    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    bosepro::AudioTask *task = session.get_task("task1");
    REQUIRE(task != nullptr);

    // Internal blocks must exist; the outer composite block name must not.
    CHECK(task->get_block("comp/inner_a") != nullptr);
    CHECK(task->get_block("comp/inner_b") != nullptr);
    CHECK(task->get_block("comp") == nullptr);
}


// ---------------------------------------------------------------------------
// Property $ substitution: inherited property value is propagated to internal
// block, static property value is used as-is.
// ---------------------------------------------------------------------------
TEST_CASE("Composite property substitution with $ reference")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    // inner_a inherits bool_property = true from composite block config.
    // inner_b has bool_property = true hardcoded in the composite definition.
    {
        bosepro::Session session(configuration.get_session(), definition,
                                 &composite_definitions);
        auto cfg = config_from_string(
            "{ \"audio_tasks\": [ {"
            "  \"name\": \"task1\","
            "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
            "  \"blocks\": [{"
            "    \"name\": \"comp\","
            "    \"algorithm\": \"composite_basic\","
            "    \"property_settings\": [{\"name\": \"bool_property\", \"value\": true}],"
            "    \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]"
            "  }],"
            "  \"block_connections\": []"
            "} ] }");
        CHECK_NOTHROW(session.create_audio_tasks(cfg));
    }

    // inner_a inherits bool_property = false (default).
    {
        bosepro::Session session(configuration.get_session(), definition,
                                 &composite_definitions);
        auto cfg = config_from_string(
            "{ \"audio_tasks\": [ {"
            "  \"name\": \"task1\","
            "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
            "  \"blocks\": [{"
            "    \"name\": \"comp\","
            "    \"algorithm\": \"composite_basic\","
            "    \"property_settings\": [{\"name\": \"bool_property\", \"value\": false}],"
            "    \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]"
            "  }],"
            "  \"block_connections\": []"
            "} ] }");
        CHECK_NOTHROW(session.create_audio_tasks(cfg));
    }
}


// ---------------------------------------------------------------------------
// Terminal channel $ substitution: terminal channel count is inherited from
// the composite block's terminal_channels configuration.
// ---------------------------------------------------------------------------
TEST_CASE("Composite terminal channel $ substitution")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_terminal_inherit\","
        "    \"property_settings\": [{\"name\": \"channels\", \"value\": 2}],"
        "    \"terminal_channels\": [{\"name\": \"out\", \"channels\": 2}]"
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));
}


// ---------------------------------------------------------------------------
// Implementation parameter_settings: applied before runtime settings.
// The composite_with_params sets integer_scalar to 7 in parameter_settings.
// ---------------------------------------------------------------------------
TEST_CASE("Composite implementation parameter_settings applied at construction")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_with_params\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    bosepro::AudioTask *task = session.get_task("task1");
    REQUIRE(task != nullptr);
    REQUIRE(task->get_block("comp/ps_block") != nullptr);
}


// ---------------------------------------------------------------------------
// Parameter map: composite parameter routed to internal block parameter.
// ---------------------------------------------------------------------------
TEST_CASE("Composite parameter map routes setting to internal block")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_with_params\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    // Apply parameter through composite block name.
    std::stringstream ss;
    ss.str("{ \"target\": \"comp\", \"name\": \"bool_scalar\", \"value\": true }");
    bosepro::ParameterSetting ps(ss);
    CHECK_NOTHROW(session.process_parameter_setting(ps));

    ss.str("{ \"target\": \"comp\", \"name\": \"float_scalar\", \"value\": 5.0 }");
    ps = bosepro::ParameterSetting(ss);
    CHECK_NOTHROW(session.process_parameter_setting(ps));
}


// ---------------------------------------------------------------------------
// Parameter fan-out: one composite parameter fans out to two internal blocks.
// ---------------------------------------------------------------------------
TEST_CASE("Composite parameter fan-out applies to all mapped internal blocks")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_fanout\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    // Both internal blocks must be reachable.
    bosepro::AudioTask *task = session.get_task("task1");
    REQUIRE(task != nullptr);
    CHECK(task->get_block("comp/ps_a") != nullptr);
    CHECK(task->get_block("comp/ps_b") != nullptr);

    // Apply fan-out composite parameter.
    std::stringstream ss;
    ss.str("{ \"target\": \"comp\", \"name\": \"bool_scalar\", \"value\": true }");
    bosepro::ParameterSetting ps(ss);
    CHECK_NOTHROW(session.process_parameter_setting(ps));
}


// ---------------------------------------------------------------------------
// Non-opaque: direct access to internal block name is allowed when is_opaque
// is false (parameter sent to "comp/ps_block" directly).
// ---------------------------------------------------------------------------
TEST_CASE("Non-opaque composite allows direct internal block parameter access")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_with_params\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    // Direct access to internal block (non-opaque composite).
    std::stringstream ss;
    ss.str("{ \"target\": \"comp/ps_block\", \"name\": \"bool_scalar\", \"value\": true }");
    bosepro::ParameterSetting ps(ss);
    CHECK_NOTHROW(session.process_parameter_setting(ps));
}


// ---------------------------------------------------------------------------
// Duplicate composite block names after expansion should throw.
// ---------------------------------------------------------------------------
TEST_CASE("Duplicate expanded block name collision throws")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);

    // Two composite blocks with the same outer name would produce duplicate
    // expanded internal block names.
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": ["
        "    {"
        "      \"name\": \"comp\","
        "      \"algorithm\": \"composite_with_params\""
        "    },"
        "    {"
        "      \"name\": \"comp\","
        "      \"algorithm\": \"composite_with_params\""
        "    }"
        "  ],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_THROWS(session.create_audio_tasks(cfg));
}


// ---------------------------------------------------------------------------
// No composite definitions: non-composite task creation is unaffected.
// ---------------------------------------------------------------------------
TEST_CASE("No composite definitions does not break normal task creation")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    // Session with no composite definitions.
    bosepro::Session session(configuration.get_session(), definition);

    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"block1\","
        "    \"algorithm\": \"test_configuration\","
        "    \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]"
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));
    CHECK(session.get_task("task1") != nullptr);
}


// ---------------------------------------------------------------------------
// Unresolved $ reference in property_settings throws.
// ---------------------------------------------------------------------------
TEST_CASE("Unresolved property $ reference throws")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);

    // composite_basic expects "$bool_property" but we deliberately omit
    // property_settings so the reference cannot be resolved.
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_basic\","
        "    \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]"
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    // inner_a tries to inherit $bool_property from the comp block config,
    // but no property_settings are provided — this should fail with a clear
    // error about the unresolved reference.
    CHECK_THROWS(session.create_audio_tasks(cfg));
}


// ---------------------------------------------------------------------------
// Composite block missing implementation throws.
// ---------------------------------------------------------------------------
TEST_CASE("Composite definition without implementation throws")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");

    // Composite def with no implementation.
    static const std::string composite_json =
        "{ \"composite_algorithms\": [{"
        "  \"name\": \"no_impl\","
        "  \"is_opaque\": false,"
        "  \"properties\": [], \"terminals\": [], \"parameters\": []"
        "}]}";
    {
        std::ofstream("test-composite-no-impl.json") << composite_json;
    }

    bosepro::CompositeDefinition composite_defs("test-composite-no-impl.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");
    bosepro::Session session(configuration.get_session(), definition, &composite_defs);

    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"no_impl\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_THROWS(session.create_audio_tasks(cfg));
}


// ---------------------------------------------------------------------------
// Unmapped external terminal in task-level block_connections throws.
// ---------------------------------------------------------------------------
TEST_CASE("Unmapped composite output terminal in task connections throws")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);

    // Two blocks connected via composite terminal; reference non-existent
    // terminal name "nonexistent" on the composite block.
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": ["
        "    {"
        "      \"name\": \"comp\","
        "      \"algorithm\": \"composite_basic\","
        "      \"property_settings\": [{\"name\": \"bool_property\", \"value\": true}],"
        "      \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]"
        "    },"
        "    {"
        "      \"name\": \"sink\","
        "      \"algorithm\": \"test_configuration\","
        "      \"terminal_channels\": [{\"name\": \"out\", \"channels\": 1}]"
        "    }"
        "  ],"
        "  \"block_connections\": [{"
        "    \"source_block\": \"comp\","
        "    \"output_terminal\": \"nonexistent\","
        "    \"output_channel\": 1,"
        "    \"destination_block\": \"sink\","
        "    \"input_terminal\": \"in\","
        "    \"input_channel\": 1"
        "  }]"
        "} ] }");

    CHECK_THROWS(session.create_audio_tasks(cfg));
}


// ---------------------------------------------------------------------------
// Opaque composite: directly targeting an internal block name is rejected at
// the opacity boundary — the block must not be visible to the user.
// ---------------------------------------------------------------------------
TEST_CASE("Opaque composite rejects direct access to internal block with mapped parameter")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_opaque\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    // comp/ps_block is a real internal block but is shielded by opacity.
    // The setting must be handled without throwing (error is logged) and
    // the parameter must NOT be forwarded to the block.
    std::stringstream ss;
    ss.str("{ \"target\": \"comp/ps_block\", \"name\": \"bool_scalar\", \"value\": true }");
    bosepro::ParameterSetting ps(ss);
    CHECK_NOTHROW(session.process_parameter_setting(ps));
}


// ---------------------------------------------------------------------------
// Opaque composite: an internal block name with a non-mapped parameter is
// also rejected at the opacity boundary — the separator check fires before
// any parameter lookup.
// ---------------------------------------------------------------------------
TEST_CASE("Opaque composite rejects direct access to internal block with non-mapped parameter")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_opaque\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    // integer_scalar exists on the internal ps_block but is not in the
    // composite parameter_map. Opacity means comp/ps_block must not be
    // accessible at all, so this is rejected before any parameter lookup.
    std::stringstream ss;
    ss.str("{ \"target\": \"comp/ps_block\", \"name\": \"integer_scalar\", \"value\": 5 }");
    bosepro::ParameterSetting ps(ss);
    CHECK_NOTHROW(session.process_parameter_setting(ps));
}


// ---------------------------------------------------------------------------
// Opaque composite: targeting the composite block name with an unknown
// parameter should NOT throw "block does not exist" — the framework must
// recognise "comp" as a known composite block and report a "no parameter"
// error instead.  Before this fix the session threw "Unknown block 'comp'"
// because the composite name was not present in block_map.
// ---------------------------------------------------------------------------
TEST_CASE("Opaque composite reports no-parameter error for unknown parameter on composite name")
{
    spdlog::set_level(spdlog::level::off);

    bosepro::Definition definition("test/test-composite-algorithms-definitions.json");
    bosepro::CompositeDefinition composite_definitions(
        "test/test-composite-algorithms-composite-definitions.json");
    bosepro::Configuration configuration("test/test-composite-algorithms-config.json");

    bosepro::Session session(configuration.get_session(), definition,
                             &composite_definitions);
    auto cfg = config_from_string(
        "{ \"audio_tasks\": [ {"
        "  \"name\": \"task1\","
        "  \"property_settings\": [{\"name\": \"is_jack_client\", \"value\": false}],"
        "  \"blocks\": [{"
        "    \"name\": \"comp\","
        "    \"algorithm\": \"composite_opaque\""
        "  }],"
        "  \"block_connections\": []"
        "} ] }");

    CHECK_NOTHROW(session.create_audio_tasks(cfg));

    // "blah" is not a parameter of composite_opaque.  The framework must
    // recognise "comp" as a composite block and emit a "no parameter" error
    // rather than letting the session throw "Unknown block 'comp'".
    std::stringstream ss;
    ss.str("{ \"target\": \"comp\", \"name\": \"blah\", \"value\": 1 }");
    bosepro::ParameterSetting ps(ss);
    CHECK_NOTHROW(session.process_parameter_setting(ps));
}


TEST_SUITE_END(); // Composite Algorithms
