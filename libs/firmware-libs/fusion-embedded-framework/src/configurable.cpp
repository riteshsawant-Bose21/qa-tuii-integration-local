
#include <bosepro/configurable.h>
#include <bosepro/definition.h>

#include <spdlog/spdlog.h>

#include <string>

namespace bosepro {


const Definition *Configurable::definitions;


Configurable::Configurable(const Configuration &configuration)
{
    if (configuration.has_property("frame_size"))
    {
        configuration.get_property("frame_size").get_value(frame_size);
    }
    else
    {
        frame_size = 32;
    }

    if (configuration.has_property("sample_rate"))
    {
        configuration.get_property("sample_rate").get_value(sample_rate);
    }
    else
    {
        sample_rate = 48000;
    }
}


void Configurable::set_definitions(const Definition &definitions)
{
    this->definitions = &definitions;
}


const ProcessorDefinition *Configurable::get_definition(const std::string &name) const
{
    if (definitions->has_algorithm(name))
    {
        return &definitions->get_algorithm(name);
    }
    else if (definitions->has_module(name))
    {
        return &definitions->get_module(name);
    }

    SPDLOG_CRITICAL("No definition available for algorithm/module '{}'.", name);
    return nullptr;
}


} // namespace bosepro
