
#include <bosepro/audio_task.h>
#include <bosepro/telemetry_monitor.h>

#include <boost/property_tree/json_parser.hpp>

namespace bosepro {

namespace {

constexpr const char *COMPOSITE_BLOCK_SEPARATOR = "/";

bool is_inherited_reference(const std::string &value)
{
    return !value.empty() && value[0] == '$';
}

std::string inherited_name(const std::string &value)
{
    return value.substr(1);
}

std::string join_block_name(const std::string &composite_name,
                            const std::string &internal_name)
{
    return composite_name + COMPOSITE_BLOCK_SEPARATOR + internal_name;
}

std::string to_json(const boost::property_tree::ptree &tree)
{
    std::ostringstream ss;
    boost::property_tree::write_json(ss, tree, false);
    return ss.str();
}

int get_channel_or_default(const boost::property_tree::ptree &connection,
                           const std::string &member_name)
{
    boost::optional<int_fast32_t> value = connection.get_optional<int_fast32_t>(member_name);
    if (value)
    {
        return static_cast<int>(*value);
    }
    return 1;
}

} // namespace


int AudioSubtask::task_count = 0;


AudioSubtask::AudioSubtask(void (*run_function)(void *), void *obj,
                           int_fast32_t sample_rate, int_fast32_t frame_size,
                           int_fast32_t base_frame_size)
    : run_function(run_function), obj(obj), sample_rate(sample_rate),
      frame_size(frame_size), ticks(0)
{
    int err;
    pthread_mutexattr_t attr;

    if (frame_size % base_frame_size != 0)
    {
        SPDLOG_CRITICAL("frame_size ({}) must be a multiple of "
                        "base_frame_size ({})",
                        frame_size, base_frame_size);
    }

    period = frame_size / base_frame_size;

    err = pthread_mutexattr_init(&attr);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_mutexattr_init() failed: {}", strerror(err));
    }


    err = pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_mutexattr_setprotocol() failed: {}",
                        strerror(err));
    }


    err = pthread_mutex_init(&ticks_mutex, &attr);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_mutex_init() failed: {}", strerror(err));
    }


    err = pthread_cond_init(&ticks_cond, NULL);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_cond_init() failed: {}", strerror(err));
    }

    err = pthread_cond_init(&done_cond, NULL);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_cond_init() (done_cond) failed: {}", strerror(err));
    }

    err = pthread_create(&thread, NULL, run, this);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_create() failed: {}", strerror(err));
    }

    profile.set_period((double)frame_size / sample_rate);

    task_id = task_count++;
}


AudioSubtask::~AudioSubtask()
{
    SPDLOG_DEBUG("AudioTask {} MIPS: {} first, {} max, {} avg.",
                 task_id, profile.get_first_mips(),
                 profile.get_max_mips(), profile.get_average_mips());
}


void AudioSubtask::set_priority(int priority)
{
#ifdef USE_MAC_THREADS
    // In macOS, the pthread real-time scheduler doesn't have actual
    // real-time priority (but allows you to set real-time priority without
    // complaint).  Instead, we need to use the native macOS threads to
    // set priority.

    thread_time_constraint_policy_data_t policy;

    double frame_period_ns = frame_size * 1.0e9 / sample_rate;
    policy.period = AudioConvertNanosToHostTime(frame_period_ns);
    // thread_policy_set() doesn't like constraints more than 100ms
    frame_period_ns = (frame_period_ns > 1.0e8) ? 1.0e8 : frame_period_ns;
    policy.computation = AudioConvertNanosToHostTime(frame_period_ns / 2);
    policy.constraint = AudioConvertNanosToHostTime(frame_period_ns);
    policy.preemptible = 1;

    kern_return_t result = thread_policy_set(pthread_mach_thread_np(thread),
                                             THREAD_TIME_CONSTRAINT_POLICY,
                                             (thread_policy_t)&policy,
                                             THREAD_TIME_CONSTRAINT_POLICY_COUNT);

    if (result != KERN_SUCCESS)
    {
        SPDLOG_ERROR("Failed to set task priority {}", priority);
    }
#else
    int err;
    struct sched_param sched_param;

    sched_param.sched_priority = priority;

    err = pthread_setschedparam(thread, SCHED_FIFO, &sched_param);

    if (err != 0)
    {
        SPDLOG_ERROR("Failed to set task priority: {}", strerror(err));
    }
#endif
}


void *AudioSubtask::run(void *p_task)
{
    AudioSubtask *task = (AudioSubtask *)p_task;
    while (true)
    {
        pthread_mutex_lock(&task->ticks_mutex);
        while (task->ticks < task->period)
        {
            pthread_cond_wait(&task->ticks_cond, &task->ticks_mutex);
        }
        task->ticks -= task->period;
        bool non_realtime = task->non_realtime;
        if (non_realtime)
        {
            task->subtask_busy = true;
        }
        pthread_mutex_unlock(&task->ticks_mutex);
        task->profile.start();
        task->run_function(task->obj);
        task->profile.finish();
        if (non_realtime)
        {
            pthread_mutex_lock(&task->ticks_mutex);
            task->subtask_busy = false;
            pthread_cond_signal(&task->done_cond);
            pthread_mutex_unlock(&task->ticks_mutex);
        }
    }
}


AudioTask::AudioTask(const TaskConfiguration &configuration)
    : Configurable(configuration), cpu_affinity(-1), client(nullptr)
{
    // Use this task's region manager while allocating blocks within the
    // task.
    region_manager.open_region();

    frames_to_run = -1;

    bool is_jack_client = true;

    // Set "is_jack_client" to false for non-JACK configurations (usually
    // for file I/O testing).
    if (configuration.has_property("is_jack_client"))
    {
        configuration.get_property("is_jack_client").get_value(is_jack_client);
    }

    if (is_jack_client)
    {
        // The client name is the same as the task name unless something
        // else is specified in the configuration.
        if (configuration.has_property("jack_client_name"))
        {
            std::string client_name;
            configuration.get_property("jack_client_name").get_value(client_name);
            client = Jack::create_client(client_name, this);
        }
        else
        {
            client = Jack::create_client(configuration.get_name(), this);
        }
    }

    if (configuration.has_property("cpu_affinity"))
    {
        configuration.get_property("cpu_affinity").get_value(cpu_affinity);
    }

    struct CompositeEndpoint {
        std::string block_name;
        std::string terminal_name;
    };

    std::map<std::string, std::map<std::string, CompositeEndpoint>> composite_input_map;
    std::map<std::string, std::map<std::string, CompositeEndpoint>> composite_output_map;

    std::vector<std::unique_ptr<Configuration>> expanded_block_configurations;
    std::vector<std::unique_ptr<Configuration>> expanded_connection_configurations;
    std::vector<std::unique_ptr<ParameterSetting>> expanded_parameter_settings;

    // Expand composite blocks into concrete blocks and connections.
    for (auto &b : configuration.get_blocks())
    {
        const BlockConfiguration *bc =
            reinterpret_cast<const BlockConfiguration *>(&b.second);

        const CompositeAlgorithmDefinition *composite_definition =
            get_composite_definition(bc->get_algorithm());

        if (composite_definition == nullptr)
        {
            std::stringstream ss;
            ss << to_json(b.second);
            expanded_block_configurations.push_back(
                std::make_unique<Configuration>(ss));
            continue;
        }

        if (!composite_definition->has_implementation())
        {
            throw std::runtime_error("Composite algorithm '" + bc->get_algorithm()
                                     + "' has no implementation object.");
        }

        const CompositeImplementationDefinition &implementation =
            composite_definition->get_implementation();

        if (!implementation.has_blocks())
        {
            throw std::runtime_error("Composite algorithm '" + bc->get_algorithm()
                                     + "' has no implementation blocks.");
        }

        // Track composite block names for opacity enforcement in apply_parameter_setting.
        composite_block_names.insert(bc->get_name());
        if (composite_definition->is_opaque())
        {
            opaque_composite_block_names.insert(bc->get_name());
        }

        for (const auto &impl_block : implementation.get_blocks())
        {
            boost::property_tree::ptree expanded_block;
            const std::string internal_name = impl_block.second.get<std::string>("name");
            expanded_block.put("name", join_block_name(bc->get_name(), internal_name));
            expanded_block.put("algorithm", impl_block.second.get<std::string>("algorithm"));

            if (impl_block.second.get_child_optional("property_settings"))
            {
                boost::property_tree::ptree properties;
                for (const auto &property : impl_block.second.get_child("property_settings"))
                {
                    boost::property_tree::ptree resolved_property = property.second;
                    boost::optional<std::string> maybe_ref =
                        property.second.get_optional<std::string>("value");

                    if (maybe_ref && is_inherited_reference(*maybe_ref))
                    {
                        const std::string inherited = inherited_name(*maybe_ref);
                        bool found = false;

                        if (b.second.get_child_optional("property_settings"))
                        {
                            for (const auto &configured_property : b.second.get_child("property_settings"))
                            {
                                if (configured_property.second.get<std::string>("name") == inherited)
                                {
                                    resolved_property.put_child("value",
                                                                configured_property.second.get_child("value"));
                                    found = true;
                                    break;
                                }
                            }
                        }

                        if (!found)
                        {
                            throw std::runtime_error("Composite block '" + bc->get_name()
                                                     + "' references unknown property '$"
                                                     + inherited + "'.");
                        }
                    }

                    properties.push_back(std::make_pair("", resolved_property));
                }
                expanded_block.put_child("property_settings", properties);
            }

            if (impl_block.second.get_child_optional("terminal_channels"))
            {
                boost::property_tree::ptree terminals;
                for (const auto &terminal : impl_block.second.get_child("terminal_channels"))
                {
                    boost::property_tree::ptree resolved_terminal = terminal.second;
                    boost::optional<std::string> maybe_ref =
                        terminal.second.get_optional<std::string>("channels");

                    if (maybe_ref && is_inherited_reference(*maybe_ref))
                    {
                        const std::string inherited = inherited_name(*maybe_ref);
                        bool found = false;

                        if (b.second.get_child_optional("terminal_channels"))
                        {
                            for (const auto &configured_terminal : b.second.get_child("terminal_channels"))
                            {
                                if (configured_terminal.second.get<std::string>("name") == inherited)
                                {
                                    resolved_terminal.put_child("channels",
                                                                configured_terminal.second.get_child("channels"));
                                    found = true;
                                    break;
                                }
                            }
                        }

                        // If not resolved from terminal_channels, also check
                        // property_settings (e.g. a "channels" property used to
                        // set how many channels an internal terminal should have).
                        if (!found && b.second.get_child_optional("property_settings"))
                        {
                            for (const auto &configured_property : b.second.get_child("property_settings"))
                            {
                                if (configured_property.second.get<std::string>("name") == inherited)
                                {
                                    resolved_terminal.put_child("channels",
                                                                configured_property.second.get_child("value"));
                                    found = true;
                                    break;
                                }
                            }
                        }

                        if (!found)
                        {
                            throw std::runtime_error("Composite block '" + bc->get_name()
                                                     + "' references unknown terminal '$"
                                                     + inherited + "'.");
                        }
                    }

                    terminals.push_back(std::make_pair("", resolved_terminal));
                }
                expanded_block.put_child("terminal_channels", terminals);
            }

            std::stringstream ss;
            ss << to_json(expanded_block);
            expanded_block_configurations.push_back(
                std::make_unique<Configuration>(ss));
        }

        if (implementation.has_block_connections())
        {
            for (const auto &connection : implementation.get_block_connections())
            {
                const std::string source_block = connection.second.get<std::string>("source_block");
                const std::string destination_block = connection.second.get<std::string>("destination_block");
                const std::string output_terminal = connection.second.get<std::string>("output_terminal");
                const std::string input_terminal = connection.second.get<std::string>("input_terminal");

                if (is_inherited_reference(source_block))
                {
                    composite_input_map[bc->get_name()][inherited_name(source_block)] = {
                        join_block_name(bc->get_name(), destination_block),
                        input_terminal};
                    continue;
                }

                if (is_inherited_reference(destination_block))
                {
                    composite_output_map[bc->get_name()][inherited_name(destination_block)] = {
                        join_block_name(bc->get_name(), source_block),
                        output_terminal};
                    continue;
                }

                boost::property_tree::ptree expanded_connection;
                expanded_connection.put("source_block", join_block_name(bc->get_name(), source_block));
                expanded_connection.put("destination_block", join_block_name(bc->get_name(), destination_block));
                expanded_connection.put("output_terminal", output_terminal);
                expanded_connection.put("input_terminal", input_terminal);
                expanded_connection.put("output_channel", get_channel_or_default(connection.second, "output_channel"));
                expanded_connection.put("input_channel", get_channel_or_default(connection.second, "input_channel"));

                std::stringstream ss;
                ss << to_json(expanded_connection);
                expanded_connection_configurations.push_back(
                    std::make_unique<Configuration>(ss));
            }
        }

        if (implementation.has_parameter_settings())
        {
            for (const auto &setting : implementation.get_parameter_settings())
            {
                boost::property_tree::ptree expanded_setting = setting.second;
                expanded_setting.put("target", join_block_name(
                    bc->get_name(), setting.second.get<std::string>("target")));

                std::stringstream ss;
                ss << to_json(expanded_setting);
                expanded_parameter_settings.push_back(
                    std::make_unique<ParameterSetting>(ss));
            }
        }

        if (implementation.has_parameter_map())
        {
            for (const auto &map_item : implementation.get_parameter_map())
            {
                const ParameterMapEntryDefinition &entry =
                    reinterpret_cast<const ParameterMapEntryDefinition &>(map_item.second);
                const std::string &composite_parameter = entry.get_composite_parameter();
                const std::string &block_name = entry.get_block_name();
                const std::string &block_parameter = entry.get_block_parameter();

                composite_parameter_map[bc->get_name() + "::" + composite_parameter]
                    .push_back(std::make_pair(join_block_name(bc->get_name(), block_name),
                                              block_parameter));
            }
        }

        if (implementation.has_telemetry_map())
        {
            for (const auto &map_item : implementation.get_telemetry_map())
            {
                const TelemetryMapEntryDefinition &entry =
                    reinterpret_cast<const TelemetryMapEntryDefinition &>(map_item.second);
                const std::string &composite_telemetry = entry.get_composite_telemetry();
                const std::string &block_name = entry.get_block_name();
                const std::string &block_telemetry = entry.get_block_telemetry();

                const std::string internal_qualified =
                    join_block_name(bc->get_name(), block_name) + "::" + block_telemetry;
                const std::string composite_qualified =
                    bc->get_name() + "::" + composite_telemetry;

                TelemetryMonitor::get_instance().register_telemetry_alias(
                    internal_qualified, composite_qualified);
            }
        }
    }

    // Rewrite task-level block connections to concrete blocks.
    for (auto &c : configuration.get_block_connections())
    {
        const BlockConnectionConfiguration *cc =
            reinterpret_cast<const BlockConnectionConfiguration *>(&c.second);

            std::string source_block = cc->get_source_block();
            std::string output_terminal = cc->get_output_terminal();
            std::string destination_block = cc->get_destination_block();
            std::string input_terminal = cc->get_input_terminal();

            if (composite_output_map.count(source_block) != 0)
            {
                if (composite_output_map[source_block].count(output_terminal) == 0)
                {
                    throw std::runtime_error("Composite output terminal '" + source_block
                                             + ":" + output_terminal
                                             + "' is not mapped in implementation block_connections.");
                }

                const CompositeEndpoint &endpoint =
                    composite_output_map[source_block][output_terminal];
                source_block = endpoint.block_name;
                output_terminal = endpoint.terminal_name;
            }

            if (composite_input_map.count(destination_block) != 0)
            {
                if (composite_input_map[destination_block].count(input_terminal) == 0)
                {
                    throw std::runtime_error("Composite input terminal '" + destination_block
                                             + ":" + input_terminal
                                             + "' is not mapped in implementation block_connections.");
                }

                const CompositeEndpoint &endpoint =
                    composite_input_map[destination_block][input_terminal];
                destination_block = endpoint.block_name;
                input_terminal = endpoint.terminal_name;
            }

            boost::property_tree::ptree expanded_connection;
            expanded_connection.put("source_block", source_block);
            expanded_connection.put("destination_block", destination_block);
            expanded_connection.put("output_terminal", output_terminal);
            expanded_connection.put("input_terminal", input_terminal);
            expanded_connection.put("output_channel", cc->get_output_channel() + 1);
            expanded_connection.put("input_channel", cc->get_input_channel() + 1);

        std::stringstream ss;
        ss << to_json(expanded_connection);
        expanded_connection_configurations.push_back(
            std::make_unique<Configuration>(ss));
    }

    // Create all of the concrete blocks in the task.
    for (const auto &expanded_block : expanded_block_configurations)
    {
        const BlockConfiguration *bc =
            reinterpret_cast<const BlockConfiguration *>(expanded_block.get());

        if (block_map.count(bc->get_name()) != 0)
        {
            throw std::runtime_error("Duplicate blocks with name '"
                    + bc->get_name() + "'.");
        }

        SPDLOG_DEBUG("Creating block: {}.", bc->get_name());

        try
        {
            blocks.push_back(std::unique_ptr<Algorithm>(
                        ChildFactory<Algorithm,
                        const BlockConfiguration &>::create_child(
                            bc->get_algorithm(), *bc)));
            block_map[bc->get_name()] = blocks.back().get();
        }
        catch (std::exception &e)
        {
            throw std::runtime_error("Failed to create block '"
                    + bc->get_name() + "': " + e.what());
        }

        if (blocks.back() == nullptr)
        {
            throw std::runtime_error("Failed to create block '"
                    + bc->get_name() + ".'");
        }
    }

    for (auto &b : blocks)
    {
        b->initialize_terminals();
        b->initialize_parameters();
    }

    for (const auto &setting : expanded_parameter_settings)
    {
        if (block_map.count(setting->get_target()) == 0)
        {
            throw std::runtime_error("Composite implementation parameter target '"
                                     + setting->get_target() + "' not found.");
        }

        block_map[setting->get_target()]->set_parameter(*setting);
    }

    for (const auto &connection : expanded_connection_configurations)
    {
        const BlockConnectionConfiguration *cc =
            reinterpret_cast<const BlockConnectionConfiguration *>(connection.get());

        if (block_map.count(cc->get_source_block()) == 0)
        {
            throw std::runtime_error("Block '" + cc->get_source_block()
                    + "' not found.");
        }

        if (block_map.count(cc->get_destination_block()) == 0)
        {
            throw std::runtime_error("Block '" + cc->get_destination_block()
                    + "' not found.");
        }

        Algorithm *input_block = block_map[cc->get_destination_block()];
        Algorithm *ouput_block = block_map[cc->get_source_block()];
        Terminal &output_terminal =
            ouput_block->get_terminal(cc->get_output_terminal());
        int output_channel = cc->get_output_channel();
        int input_channel = cc->get_input_channel();

        SPDLOG_TRACE("Connecting {}:{}:{} -> {}:{}:{}.",
                cc->get_source_block(), cc->get_output_terminal(),
                cc->get_output_channel(), cc->get_destination_block(),
                cc->get_input_terminal(), cc->get_input_channel());

        input_block->connect_terminal(cc->get_input_terminal(),
                input_channel, output_terminal,
                output_channel);
    }

    int max_frame_size = 0;
    for (auto &b : blocks)
    {
        max_frame_size = std::max(max_frame_size, b->get_empty_frame_size());
    }

    if (max_frame_size > 0)
    {
        SPDLOG_DEBUG("Creating empty signal with size: {}.", max_frame_size);
        empty_signal.resize(max_frame_size);

        for (auto &b : blocks)
        {
            b->set_empty_signal(empty_signal);
        }
    }

    task_profile.set_period((double)get_frame_size() / get_sample_rate());

    if (configuration.has_property("timing_log_file"))
    {
        std::string timing_log_file;
        configuration.get_property("timing_log_file").get_value(timing_log_file);
        log_file = std::ofstream(timing_log_file, std::ios::binary);
        SPDLOG_DEBUG("Logging to file: {}", timing_log_file);
        log_file << configuration.get_name();
    }

    if (configuration.has_property("profile_blocks"))
    {
        configuration.get_property("profile_blocks").get_value(profile_blocks);
        if (log_file)
        {
            for (auto &block : blocks)
            {
                log_file << "," << block->get_block_name();
            }
        }
    }

    if (log_file)
    {
        log_file << "\n";
    }

    block_profile.resize(blocks.size());
    block_timings.resize(blocks.size());

    for (auto &bp : block_profile)
    {
        bp.set_period((double)get_frame_size() / get_sample_rate());
    }

    region_manager.close_region();
}


AudioTask::~AudioTask()
{
    frames_to_run = 0;

    if (client != nullptr)
    {
        client->stop();
        Jack::destroy_client(client->get_name());
    }

    // Use this task's region manager while destroying blocks within this
    // task (will occur after this destructor exits, when `blocks` is
    // destroyed).  The region will be closed when `region_manager` is
    // destroyed.
    region_manager.open_region();

    SPDLOG_DEBUG("AudioTask MIPS: {} first, {} max, {} avg.",
            task_profile.get_first_mips(),
            task_profile.get_max_mips(),
            task_profile.get_average_mips());

    if (profile_blocks)
    {
        int block_index = 0;
        for (auto &block : blocks)
        {
            SPDLOG_DEBUG("Block MIPS, {} ({}): {} first, {} max, {} avg.",
                    block->get_block_name(),
                    block->get_algorithm_name(),
                    block_profile[block_index].get_first_mips(),
                    block_profile[block_index].get_max_mips(),
                    block_profile[block_index].get_average_mips());
            block_index++;
        }
    }
}


/// Run one frame of audio through all of the blocks in this task.
void AudioTask::process()
{
    task_profile.start();

    if (!profile_blocks)
    {
        for (auto &block : blocks)
        {
            block->process();
            block->process_outputs();
        }
    }
    else
    {
        int block_index = 0;
        for (auto &block : blocks)
        {
            block_profile[block_index].start();
            block->process();
            block->process_outputs();
            block_timings[block_index] = block_profile[block_index].finish();
            block_index++;
        }
    }

    if (frames_to_run > 0)
    {
        frames_to_run--;
    }

    double task_time = task_profile.finish();

    if (log_file)
    {
        log_file << task_time;
        if (profile_blocks)
        {
            for (double time : block_timings)
            {
                log_file << "," << time;
            }
        }
        log_file << std::endl;
    }
}


Algorithm *AudioTask::get_block(const std::string &name)
{
    if (block_map.count(name) != 0)
    {
        return block_map[name];
    }
    else
    {
        return nullptr;
    }
}


bool AudioTask::apply_parameter_setting(const ParameterSetting &setting)
{
    const std::string &target = setting.get_target();

    // If the target looks like an internal composite block (contains the separator),
    // and its parent composite is opaque, reject it — the internal block must not
    // be visible to the user.
    const auto sep_pos = target.find(COMPOSITE_BLOCK_SEPARATOR);
    if (sep_pos != std::string::npos)
    {
        const std::string parent = target.substr(0, sep_pos);
        if (opaque_composite_block_names.count(parent) != 0)
        {
            SPDLOG_ERROR("Block '{}' does not exist.", target);
            return true;
        }
    }

    if (block_map.count(target) != 0)
    {
        block_map[target]->set_parameter(setting);
        return true;
    }

    const std::string map_key = target + "::" + setting.get_name();
    if (composite_parameter_map.count(map_key) == 0)
    {
        // If the target is a known composite block, the block exists but has
        // no mapping for this parameter — report a meaningful error rather than
        // letting the caller say "block does not exist".
        if (composite_block_names.count(target) != 0)
        {
            SPDLOG_ERROR("Block '{}' has no parameter '{}'.", target, setting.get_name());
            return true;
        }
        return false;
    }

    for (const auto &mapping : composite_parameter_map[map_key])
    {
        boost::property_tree::ptree mapped_setting = setting;
        mapped_setting.put("target", mapping.first);
        mapped_setting.put("name", mapping.second);

        std::stringstream ss;
        boost::property_tree::write_json(ss, mapped_setting, false);
        ParameterSetting translated_setting(ss);
        block_map[mapping.first]->set_parameter(translated_setting);
    }

    return true;
}


void AudioTask::start()
{
    if (client != nullptr)
    {
        client->start();
    }
    else
    {
        SPDLOG_ERROR("No JACK client associated with this task.");
    }
}


void AudioTask::stop()
{
    if (client != nullptr)
    {
        client->stop();
    }
    else
    {
        SPDLOG_ERROR("No JACK client associated with this task.");
    }
}


bool AudioTask::finished_running()
{
    return frames_to_run == 0;
}


void AudioTask::set_seconds_to_run(double seconds)
{
    frames_to_run =
        std::ceil(seconds * get_sample_rate() / get_frame_size());
}


int_fast32_t AudioTask::get_cpu_affinity()
{
    return cpu_affinity;
}


} // namespace bosepro
