#pragma once

#include <bosepro/telemetry.h>

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
    const std::string get_rate() const
    {
        return get_string("type");
    }


    /// Get the string from "packet_id" property.
    ///
    /// @return  The string value of "packet_id"
    const std::string get_packet_id() const
    {
        return get_string("packet_id");
    }


    /// Get the "block_path" array.
    ///
    /// @return  The block_path array
    std::vector<std::string> get_block_path()
    {
        const std::string block_path_key = "block_path";
        std::vector<std::string> block_path(3, "");

        get_list_value(block_path_key, 0, block_path[0]);
        get_list_value(block_path_key, 1, block_path[1]);
        get_list_value(block_path_key, 2, block_path[2]);

        return block_path;
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


    /// Set the packet_id value with a timestamp.
    void set_packet_id()
    {
        auto now = std::chrono::steady_clock::now();
        auto now_us = std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch()).count();
        set_member("packet_id", static_cast<uint64_t>(now_us));
    }


    /// Set the parameters.packet_id value with a timestamp.
    ///
    /// @param timestamp  The value to set packet_id.
    void set_packet_id(std::string &timestamp)
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
        : serverpath("/tmp/telemetry_uds"),
          shm_addr(NUM_SHM_REGIONS, nullptr),
          telemetry_manager_addr(),
          timeout(5)
    {
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

        if (telemetry->get_type() == "meter")
        {
            meters[qualified_name] = std::move(telemetry);
        }
        else if (telemetry->get_type() == "event")
        {
            events[qualified_name] = std::move(telemetry);
        }
        else
        {
            SPDLOG_WARN("Unknown telemetry type '{}'", telemetry->get_type());
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
            if (m.second->get_rate() == update_rate)
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
            if (m.second->get_rate() == update_rate)
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
        static char* current_addr = nullptr; // Use char* for easier arithmetic
        static int offset = 0;

        int region_index = cb_data.rate == "HI"  ? 0 :
                           cb_data.rate == "MED" ? 1 :
                           cb_data.rate == "LO"  ? 2 : -1;

        // Validate the region index and ensure shared memory is available
        if (region_index >= 0 && shm_addr[region_index] != nullptr)
        {
            if (current_addr == nullptr)
            {
                current_addr = static_cast<char*>(shm_addr[region_index]);
            }

            // Write the telemetry message into the shared memory region
            memcpy(current_addr + offset, cb_data.message.c_str(), cb_data.message.length());

            if (cb_data.more_data)
            {
                offset += cb_data.message.length(); // Move the pointer forward
            }
            else
            {
                // Reset for the next telemetry write
                current_addr = nullptr;
                offset = 0;
            }
        }
    }


private:
    /// Pub initiated command to register with telemetry manager
    bool register_with_telemetry_manager()
    {
        TelemetryMessage message = telemetry_messages->get_default_command("pub_register_req");
        size_t meter_blob_size = telemetry_messages->get_default_meter().serialize_command().size();
        std::vector<size_t> block_size = {get_meters_size("HI", meter_blob_size),
                                          get_meters_size("MED", meter_blob_size),
                                          get_meters_size("LO", meter_blob_size)};
        message.get_parameters().set_block_size(block_size);
        message.set_packet_id();

        // Send the registration request
        const std::string reg_req_str = message.serialize_command() + "\0";
        SPDLOG_DEBUG("Sending {}", reg_req_str);
        if (sendto(telemetry_fd, reg_req_str.c_str(), reg_req_str.size(), 0,
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
        TelemetryMessage response(ss);

        if (response.get_message_name() == "pub_register_rsp" && 
            response.get_parameters().get_value() == "OK" && 
            response.get_packet_id() == message.get_packet_id())
        {
            SPDLOG_INFO("Received valid registration response: \n\n{}", response.serialize_command());
        }
        else
        {
            SPDLOG_ERROR("Received NOK response: \n\n{}", response.serialize_command());
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        std::vector<std::string> shm_paths = response.get_parameters().get_block_path();
        std::vector<int> shm_fd(shm_paths.size(), -1);

        int i = 0;
        for (auto a : shm_paths)
        {
            if (block_size[i] == 0) 
            {
                ++i;
                continue;
            }

            shm_fd[i] = shm_open(shm_paths[i].c_str(), O_RDWR, 0666);
            if (shm_fd[i] < 0) 
            {
                SPDLOG_CRITICAL("shm_open failed for {}", shm_paths[i]);
                return false;
            }

            // Map the shared memory into the process's address space
            shm_addr[i] = mmap(nullptr, block_size[i], PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd[i], 0);
            if (shm_addr[i] == MAP_FAILED) 
            {
                SPDLOG_CRITICAL("mmap failed for {}", shm_paths[i]);
                close(shm_fd[i]);
                return false;
            }

            ++i;
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
        shm_addr.clear();
        stop();

        return true;
    }


    /// Update all meters with meters_callback when we recieve "update_meters_req"
    /// command from telemetry manager. Send "update_meters_rsp" to confirm
    ///
    /// @param message  The TelemetryMessage from the manager
    void update_meters(TelemetryMessage &message)
    {
        std::string rate = message.get_parameters().get_rate();
        int n = get_num_meters(rate);

        for (auto &m: meters)
        {
            if (m.second->get_rate() == rate)
            {
                m.second->send_meters(meters_callback, --n);
            }
        }

        TelemetryMessage rsp = telemetry_messages->get_default_command("update_meters_rsp");
        rsp.get_parameters().set_value("OK");
        rsp.set_packet_id(message.get_packet_id());

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

        while (1)
        {
            // Receive a message from the telemetry manager
            memset(buf, 0, sizeof(buf));
            ssize_t result = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    (struct sockaddr *)&manager_addr, &manager_addr_len);

            if (result <= 0)
            {
                SPDLOG_ERROR("Error receiving data from telemetry manager.");
                continue;
            }

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

    std::string serverpath;
    int telemetry_fd;
    std::vector<void *> shm_addr;
    struct sockaddr_un telemetry_manager_addr;
    int timeout;

    std::unique_ptr<TelemetryMessage> telemetry_messages;

    std::thread monitor_thread;
    std::thread events_thread;

    std::map<std::string, std::unique_ptr<Telemetry>> meters;
    std::map<std::string, std::unique_ptr<Telemetry>> events;
};

} // namespace bosepro
