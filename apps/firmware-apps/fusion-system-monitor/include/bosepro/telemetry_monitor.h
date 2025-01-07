#pragma once

#include <bosepro/telemetry.h>
#include <bosepro/named_shared_memory_manager_factory.h>

#include <string>
#include <functional>
#include <thread>
#include <sys/un.h>
#include <sys/socket.h>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h> 
#include <iostream>


namespace bosepro {


/// A navigator with mutability for telemetry message json file
class TelemetryMessage : public Navigator {
public:
    /// Build the command definitions for the system from the given JSON file.
    ///
    /// @param  filename  A JSON file containing the interface definitions.
    TelemetryMessage(const std::string &filename)
        : Navigator(filename)
    {
    }


    /// Build the command definitions for the system from the given JSON file.
    ///
    /// @param  ss  A string stream containing a JSON string.
    TelemetryMessage(std::stringstream &ss)
        : Navigator(ss)
    {
    }


    /// Get the json blob for the default command with name "name".
    ///
    /// @return  TelemetryMessage of the command node
    TelemetryMessage get_default_command(const std::string name) const
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "message_name", name);
    }


    /// Get the json blob for the default meter update node.
    ///
    /// @return  TelemetryMessage of the meter update node
    TelemetryMessage get_default_meter() const
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "meter_name", "");
    }


    /// Get the name of the TelemetryMessage.
    ///
    /// @return  The name of the TelemetryMessage.
    const std::string &get_message_name() const
    {
        return get_string("message_name");
    }


    /// Get the parameters node json 
    ///
    /// @return  TelemetryMessage of parameters node.
    TelemetryMessage &get_parameters() const
    {
        return (TelemetryMessage &)get_member("parameters");
    }


    /// Get the string from "value" property.
    ///
    /// @return  The string value of "value"
    const std::string get_value() const
    {
        return get_string("value");
    }


    /// Get the string from "type" property.
    ///
    /// @return  The string value of "type"
    const std::string get_type() const
    {
        return get_string("type");
    }


    /// Get the string from "rate" property.
    ///
    /// @return  The string value of "rate"
    const std::string get_period_type() const
    {
        return get_string("period_type");
    }


    /// Get the string from "packet_id" property.
    ///
    /// @return  The string value of "packet_id"
    const std::string get_packet_id() const
    {
        return get_string("packet_id");
    }


    /// Get the "block_name" array.
    ///
    /// @return  The block_name array
    std::vector<std::string> get_block_name()
    {
        const std::string block_name_key = "block_name";
        std::vector<std::string> block_name(3, "");

        get_list_value(block_name_key, 0, block_name[0]);
        get_list_value(block_name_key, 1, block_name[1]);
        get_list_value(block_name_key, 2, block_name[2]);

        return block_name;
    }


    /// Get the "block_size" array.
    ///
    /// @return  The block_size array
    std::vector<std::string> get_block_size()
    {
        const std::string block_size_key = "block_size";
        std::vector<std::string> block_size(3, "");

        get_list_value(block_size_key, 0, block_size[0]);
        get_list_value(block_size_key, 1, block_size[1]);
        get_list_value(block_size_key, 2, block_size[2]);

        return block_size;
    }


    /// Set the parameters.value value.
    ///
    /// @param value  The value to set parameters.value.
    template <typename T>
    void set_value(const T &value)
    {
        set_member("value", value);
    }


    /// Set the parameters.type value.
    ///
    /// @param value  The value to set parameters.type.
    template <typename T>
    void set_type(const T &value)
    {
        set_member("type", value);
    }


    /// Generate a timestamp and set the packet_id with it.
    void set_packet_id()
    {
        auto now = std::chrono::steady_clock::now();
        auto now_us = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();
        set_member("packet_id", static_cast<uint64_t>(now_us));
    }


    /// Set the packet_id value with the specified timestamp.
    ///
    /// @param timestamp  The value to set packet_id.
    void set_packet_id(std::string timestamp)
    {
        set_member("packet_id", timestamp);
    }


    /// Set the "block_size" array in the "parameters" object.
    /// If "block_size" exists, it will be updated with the new values.
    /// If it does not exist, an error is logged, and an exception is thrown.
    ///
    /// @param block_size The array of block sizes to set.
    void set_block_size(const std::vector<size_t> &block_size)
    {
        set_list("block_size", block_size);
    }


    /// Serialize the telemetry message.
    ///
    /// @return  The json blob string
    const std::string serialize_command() const
    {
        return serialize();
    }
};


class TelemetryMonitor {
public:
    /// Constructor for singleton pattern--initialization in "initialize" method
    TelemetryMonitor()
        : serverpath("/tmp/telm_core.socket"),
          shm_names(NUM_SHM_REGIONS, ""),
          telemetry_manager_addr(),
          timeout(5)
    {
        shm_manager = &NamedSharedMemoryManagerFactory::getInstance();
    }


    ~TelemetryMonitor() 
    {
        stop();
    }


    /// Get the singleton instance of TelemetryMonitor.
    static TelemetryMonitor& get_instance() 
    {
        static TelemetryMonitor instance;
        return instance;
    }


    /// Initialize the singleton object. Connect and register with Fusion Telemetry Manager
    ///
    /// @param filename  file to initialize the telemetry_messages
    void initialize(const std::string &filename)
    {
        telemetry_messages = std::make_unique<TelemetryMessage>(filename);
        
        telemetry_fd = socket(AF_UNIX, SOCK_DGRAM, 0);
        if (telemetry_fd < 0)
        {
            SPDLOG_CRITICAL("Failed to create UDS socket.");
        }

        struct sockaddr_un client_addr {};
        client_addr.sun_family = AF_UNIX;
        std::string client_path = "/tmp/system_monitor_uds_" + std::to_string(getpid());
        strncpy(client_addr.sun_path, client_path.c_str(), sizeof(client_addr.sun_path) - 1);
        unlink(client_path.c_str());

        if (bind(telemetry_fd, (struct sockaddr *)&client_addr, sizeof(client_addr)) < 0)
        {
            close(telemetry_fd);
            telemetry_fd = -1;
            SPDLOG_CRITICAL("Failed to bind UDS client socket to {}", client_path);
        }

        // Set up the telemetry manager address
        telemetry_manager_addr.sun_family = AF_UNIX;
        strncpy(telemetry_manager_addr.sun_path, serverpath.c_str(), sizeof(telemetry_manager_addr.sun_path) - 1);

        struct stat statbuf;
        int n = 0;
        while (n < timeout)
        {
            if (stat(serverpath.c_str(), &statbuf) == 0 && S_ISSOCK(statbuf.st_mode)) 
            {
                SPDLOG_INFO("Telemetry Manager UDS exists at {}", serverpath);
                break;
            }

            sleep(1);
            if (++n >= timeout)
            {
                SPDLOG_CRITICAL("Telemetry Manager UDS does NOT exist at {}", serverpath);
            }
        }

        if (!register_with_telemetry_manager())
        {
            SPDLOG_CRITICAL("Failed to register with Telemetry Manager");
        }

        setup_callbacks();
    }


    /// Start the threads.
    void start() 
    {
        SPDLOG_INFO("Starting TelemetryMonitor thread...");
        monitor_thread = std::thread(&TelemetryMonitor::monitor_loop, this);
        events_thread = std::thread(&TelemetryMonitor::manage_events_loop, this);
    }


    /// Stop the threads.
    void stop() 
    {
        if (monitor_thread.joinable()) 
        {
            monitor_thread.join();
        }
        if (events_thread.joinable()) 
        {
            events_thread.join();
        }
    }


    /// Register a telemetry item.
    ///
    /// @param telemetry  the unique_ptr to the telemetry item
    void register_telemetry(std::unique_ptr<Telemetry> telemetry) 
    {
        std::string qualified_name = telemetry->get_block_name() + "::" +
                                     telemetry->get_name();

        if (telemetry->get_telemetry_type() == "meter")
        {
            meters[qualified_name] = std::move(telemetry);
        }
        else if (telemetry->get_telemetry_type() == "event")
        {
            events[qualified_name] = std::move(telemetry);
        }
        else
        {
            SPDLOG_WARN("Unknown telemetry type '{}'", telemetry->get_telemetry_type());
        }
    }


    /// Unregister all telemetry items associated with a block.
    /// 
    /// @param block_name  The name of the block to unregister telemetry
    void unregister_block(const std::string &block_name) 
    {
        const std::string prefix = block_name + "::";

        for (auto it = meters.begin(); it != meters.end();) 
        {
            if (it->first.rfind(prefix, 0) == 0)
            {
                it = meters.erase(it); // Erase returns the next valid iterator
            }
            else
            {
                ++it; // Increment manually if no erase
            }
        }

        for (auto it = events.begin(); it != events.end();) 
        {
            if (it->first.rfind(prefix, 0) == 0)
            {
                it = events.erase(it); // Erase returns the next valid iterator
            }
            else
            {
                ++it;
            }
        }
    }


    /// Check if the telemetry monitor has a telemetry item of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::telemetry_name
    /// @return  True if the telemetry monitor has the telemetry item
    bool has_telemetry(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            if (events.count(qualified_name) == 0)
            {
                return false;
            }
        }

        return true;
    }


    /// Check if the telemetry monitor has a meter of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::meter_name
    /// @return  True if the telemetry monitor has the meter
    bool has_meter(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            return false;
        }

        return true;
    }


    /// Check if the telemetry monitor has an event of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::event_name
    /// @return  True if the telemetry monitor has the event
    bool has_event(const std::string &qualified_name)
    {
        if (events.count(qualified_name) == 0)
        {
            return false;
        }

        return true;
    }


    /// Get a telemetry item using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::telemetry_name
    /// @return  The Telemetry
    Telemetry &get_telemetry(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            if (events.count(qualified_name) == 0)
            {
                SPDLOG_CRITICAL("Unknown telemetry '{}'", qualified_name);
            }
            return *events[qualified_name];
        }

        return *meters[qualified_name];
    }


    /// Get an event using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::meter_name
    /// @return  The meter Telemetry
    Telemetry &get_meter(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}'", qualified_name);
        }

        return *meters[qualified_name];
    }


    /// Get an event using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::event_name
    /// @return  The event Telemetry
    Telemetry &get_event(const std::string &qualified_name)
    {
        if (events.count(qualified_name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}'", qualified_name);
        }

        return *events[qualified_name];
    }


    /// Get the size of all meter messages for meters of the 
    /// specified rate managed by the telemetry monitor. 
    ///
    /// @param update_rate  The meters update rate filter
    /// @param default_message_size  The size of the default, empty
    ///                              meters update message
    /// @return  Total size of all meters of specified rate managed
    size_t get_meters_size(const std::string &update_rate, size_t default_message_size)
    {
        size_t size = 0;
        for (auto &m : meters)
        {
            if (m.second->get_period_type() == update_rate)
            {
                size += m.second->get_meters_size();
                size += default_message_size;
            }
        }

        return size;
    }


    /// Get the number of meters of the specified rate managed
    /// by the telemetry monitor
    ///
    /// @param update_rate  The meters update rate filter
    /// @return  Number of meters of specified rate managed
    int get_num_meters(const std::string &update_rate)
    {
        int num_items = 0;
        for (auto &m : meters)
        {
            if (m.second->get_period_type() == update_rate)
            {
                ++num_items;
            }
        }

        return num_items;
    }


    /// Get the number of events managed by the telemetry monitor
    ///
    /// @return  Number of events managed
    int get_num_events()
    {
        return events.size();
    }


    /// Callback to send event telemetry on UDS
    ///
    /// @param message the message to send
    void send_event_uds(bosepro::telemetry_cb_data &cb_data)
    {
        if (sendto(telemetry_fd, cb_data.message.c_str(), cb_data.message.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_WARN("Couldn't send telemetry to socket.");
        }
    }


    /// Callback to update telemetry in shared memory
    ///
    /// @param cb_data the telemetry callback data to write
    void update_meters_shm(bosepro::telemetry_cb_data &cb_data)
    {
        int region_index = cb_data.period_type == "HI"  ? 0 :
                           cb_data.period_type == "MED" ? 1 :
                           cb_data.period_type == "LO"  ? 2 : -1;

        // Validate the region index and ensure shared memory is available
        if (region_index < 0) {
            return;
        }

        try {
            // Write the telemetry message into the shared memory region
            NamedSharedMemory& shm = shm_manager->getSharedMemory(shm_names[region_index]);
            shm.write(cb_data.message.c_str(), cb_data.message.length(), "string");

        } catch (const std::runtime_error& e) {
            SPDLOG_ERROR("Error accessing shared memory: {}", e.what());
        }
    }


private:
    /// Pub initiated command to register with telemetry manager
    bool register_with_telemetry_manager()
    {
        TelemetryMessage req = telemetry_messages->get_default_command("pub_register_req");
        size_t meter_blob_size = telemetry_messages->get_default_meter().serialize_command().size();
        std::vector<size_t> block_size = {get_meters_size("HI", meter_blob_size),
                                          get_meters_size("MED", meter_blob_size),
                                          get_meters_size("LO", meter_blob_size)};
        req.get_parameters().set_block_size(block_size);
        req.set_packet_id();

        // Send the registration request
        const std::string req_str = req.serialize_command();
        if (sendto(telemetry_fd, req_str.c_str(), req_str.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_ERROR("Failed to send registration request to telemetry manager.");
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        SPDLOG_INFO("Registration request sent to telemetry manager.");

        // Wait for a response
        char buf[1024];
        struct sockaddr_un response_addr {};
        socklen_t response_addr_len = sizeof(response_addr);
        ssize_t recv_len = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    (struct sockaddr *)&response_addr, &response_addr_len);

        if (recv_len < 0)
        {
            SPDLOG_ERROR("Failed to receive response from telemetry manager.");
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        buf[recv_len] = '\0';

        std::stringstream ss(buf);
        TelemetryMessage rsp(ss);

        if (rsp.get_message_name() == "pub_register_rsp" && 
            rsp.get_parameters().get_value() == "OK" && 
            rsp.get_packet_id() == req.get_packet_id())
        {
            SPDLOG_INFO("Received valid registration rsp: \n\n{}", rsp.serialize_command());
        }
        else
        {
            SPDLOG_ERROR("Received NOK rsp: \n\n{}", rsp.serialize_command());
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        shm_names = rsp.get_parameters().get_block_name();
        for (size_t i = 0; i < shm_names.size(); ++i) {
            if (block_size[i] > 0) {
                try {
                    shm_manager->createSharedMemory(shm_names[i], block_size[i]);
                    SPDLOG_INFO("Found shared memory region {} with size {}", shm_names[i], block_size[i]);
                } catch (const std::runtime_error& e) {
                    SPDLOG_CRITICAL("Failed to create shared memory: {}", e.what());
                    return false;
                }
            }
        }

        return true;
    }


    /// Pub initiated command to deregister with the telemetry manager
    bool deregister_with_telemetry_manager()
    {
        TelemetryMessage req = telemetry_messages->get_default_command("pub_deregister_req");

        const std::string req_str = req.serialize_command();
        if (sendto(telemetry_fd, req_str.c_str(), req_str.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_ERROR("Failed to send pub_deregister_req.");
            return false;
        }

        // Wait for a response
        char buf[1024];
        struct sockaddr_un response_addr {};
        socklen_t response_addr_len = sizeof(response_addr);
        ssize_t recv_len = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    (struct sockaddr *)&response_addr, &response_addr_len);

        if (recv_len < 0)
        {
            SPDLOG_ERROR("Failed to receive response from telemetry manager.");
            return false;
        }

        buf[recv_len] = '\0';

        std::stringstream ss(buf);
        TelemetryMessage response(ss);

        if (response.get_message_name() == "pub_deregister_rsp" && response.get_parameters().get_value() == "OK")
        {
            SPDLOG_INFO("Received valid deregistration response: \n\n{}", response.serialize_command());
        }
        else
        {
            SPDLOG_ERROR("Received NOK response: \n\n{}", response.serialize_command());
            return false;
        }

        // clean up telemetry_manager assets and pause the telemetry monitor
        shm_names.clear();
        stop();

        return true;
    }


    /// Update all meters with meters_callback when we recieve "update_meters_req"
    /// command from telemetry manager. Send "update_meters_rsp" to confirm
    ///
    /// @param message  The TelemetryMessage from the manager
    void update_meters(TelemetryMessage &message)
    {
        std::string rate = message.get_parameters().get_period_type();

        shm_manager->getSharedMemory(rate).resetWrite();

        for (auto &m: meters)
        {
            if (m.second->get_period_type() == rate)
            {
                m.second->send_meters(meters_callback);
            }
        }

        TelemetryMessage rsp = telemetry_messages->get_default_command("update_meters_rsp");
        rsp.get_parameters().set_value("OK");
        rsp.set_packet_id(message.get_packet_id());

        SPDLOG_DEBUG("Sending message \n\n{}", rsp.serialize_command());

        const std::string rsp_str = rsp.serialize_command();
        if (sendto(telemetry_fd, rsp_str.c_str(), rsp_str.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_ERROR("Failed to send update_meters_rsp.");
        }
    }


    /// Process messages from the telemetry manager
    ///
    /// @param message  TelemetryMessage from the telemetry manager
    void process_telemetry_message(TelemetryMessage &message)
    {
        if (message.get_message_name() == "update_meters_req")
        {
            update_meters(message);
        }
    }


    /// Send any events that have changed
    void send_events()
    {
        for (auto &e: events)
        {
            e.second->send_event_if_changed(event_callback);
        }
    }


    /// The main loop for monitoring telemetry data and executing commands.
    void monitor_loop() {
        if (telemetry_fd < 0)
        {
            SPDLOG_CRITICAL("Invalid connection socket.");
        }

        char buf[1024];
        struct sockaddr_un manager_addr;
        socklen_t manager_addr_len = sizeof(manager_addr);
        int error_timeout = 0;

        while (1)
        {
            // Receive a message from the telemetry manager
            memset(buf, 0, sizeof(buf));
            ssize_t result = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    (struct sockaddr *)&manager_addr, &manager_addr_len);

            if (result <= 0)
            {
                SPDLOG_ERROR("Error receiving data from telemetry manager.");
                error_timeout++;
                if (error_timeout >= 10)
                {
                    SPDLOG_ERROR("Lost connection to telemetry manager... closing telemetry.");
                    break;
                }
                continue;
            }
            error_timeout = 0;

            buf[result] = '\0';

            SPDLOG_INFO("Received message from telemetry manager: \n{}", buf);

            try
            {
                // Parse the received message into a ParameterSetting object
                std::stringstream ss(buf);
                TelemetryMessage ps = TelemetryMessage(ss);
                process_telemetry_message(ps);
            }
            catch (const std::exception &e)
            {
                SPDLOG_ERROR("Error processing received message: {}", e.what());
            }

            usleep(100);
        }

        // Clean up the socket
        close(telemetry_fd);
    }


    /// Loop for managing events.
    void manage_events_loop() {
        while (1)
        {
            send_events();

            usleep(100000);
        }
    }


    /// Setup send telemetry callback member funcs
    void setup_callbacks() {
        meters_callback = [this](telemetry_cb_data &cb_data) {
            update_meters_shm(cb_data);
        };

        event_callback = [this](telemetry_cb_data &cb_data) {
            send_event_uds(cb_data);
        };
    }


    std::function<void(telemetry_cb_data &)> meters_callback;
    std::function<void(telemetry_cb_data &)> event_callback;

    NamedSharedMemoryManager* shm_manager;
    std::string serverpath;
    int telemetry_fd;
    std::vector<std::string> shm_names;
    struct sockaddr_un telemetry_manager_addr;
    int timeout;

    std::unique_ptr<TelemetryMessage> telemetry_messages;

    std::thread monitor_thread;
    std::thread events_thread;

    std::map<std::string, std::unique_ptr<Telemetry>> meters;
    std::map<std::string, std::unique_ptr<Telemetry>> events;
};

} // namespace bosepro
