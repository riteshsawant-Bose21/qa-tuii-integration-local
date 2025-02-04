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


class TelemetryMonitor {
public:
    /// Constructor for singleton pattern--initialization in "initialize" method
    TelemetryMonitor()
        : shm_manager(NamedSharedMemoryManagerFactory::getInstance()),
          shm_names(NUM_SHM_REGIONS, ""),
          telemetry_manager_addr(),
          timeout(5),
          initialized(false),
          stop_flag(false)
    {
    }


    ~TelemetryMonitor() 
    {
        stop();
        unlink(client_path.c_str());
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
    void initialize(const std::string &filename, 
                    const std::string socket_path,
                    const std::string pub_name)
    {
        telemetry_messages = std::make_unique<TelemetryMessage>(filename);

        server_path = socket_path;
        publisher_name = pub_name;
        client_path = "/tmp/" + publisher_name + "_" + std::to_string(getpid());
        
        telemetry_fd = socket(AF_UNIX, SOCK_DGRAM, 0);
        if (telemetry_fd < 0)
        {
            SPDLOG_CRITICAL("Failed to create UDS socket.");
        }

        struct sockaddr_un client_addr {};
        client_addr.sun_family = AF_UNIX;
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
        strncpy(telemetry_manager_addr.sun_path, server_path.c_str(), sizeof(telemetry_manager_addr.sun_path) - 1);

        struct stat statbuf;
        int n = 0;
        while (n < timeout)
        {
            if (stat(server_path.c_str(), &statbuf) == 0 && S_ISSOCK(statbuf.st_mode)) 
            {
                SPDLOG_INFO("Telemetry Manager UDS exists at {}", server_path);
                break;
            }

            sleep(1);
            if (++n >= timeout)
            {
                SPDLOG_CRITICAL("Telemetry Manager UDS does NOT exist at {}", server_path);
                return;
            }
        }

        if (!register_with_telemetry_manager())
        {
            SPDLOG_CRITICAL("Failed to register with Telemetry Manager");
            return;
        }

        setup_callbacks();

        initialized = true;
    }


    /// Start the threads.
    void start() 
    {
        if (initialized)
        {
            SPDLOG_INFO("Starting TelemetryMonitor thread...");
            monitor_thread = std::thread(&TelemetryMonitor::monitor_loop, this);
            events_thread = std::thread(&TelemetryMonitor::manage_events_loop, this);
        }
    }


    /// Stop the threads.
    void stop() 
    {
        stop_flag = true;
        
        if (monitor_thread.joinable()) 
        {
            monitor_thread.join();
        }
        if (events_thread.joinable()) 
        {
            events_thread.join();
        }

        if (telemetry_fd)
        {
            close(telemetry_fd);
        }

        unlink(client_path.c_str());
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
            SPDLOG_TRACE("Registering meter {}", qualified_name);
            meters[qualified_name] = std::move(telemetry);
        }
        else if (telemetry->get_telemetry_type() == "event")
        {
            SPDLOG_TRACE("Registering event {}", qualified_name);
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
    /// specified period_type managed by the telemetry monitor. 
    ///
    /// @param period_type  The meters period_type filter
    /// @param default_message_size  The size of the default, empty
    ///                              meters update message
    /// @return  Total size of all meters of specified period_type managed
    size_t get_meters_size(const std::string &period_type, size_t default_message_size)
    {
        size_t size = 0;
        for (auto &m : meters)
        {
            if (m.second->get_period_type() == period_type)
            {
                size += m.second->get_meters_size();
                size += default_message_size;
            }
        }

        return size;
    }


    /// Get the number of meters of the specified period_type managed
    /// by the telemetry monitor
    ///
    /// @param period_type The meters period_type filter
    /// @return  Number of meters of specified period_type managed
    int get_num_meters(const std::string &period_type)
    {
        int num_items = 0;
        for (auto &m : meters)
        {
            if (m.second->get_period_type() == period_type)
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
    void send_event_uds(TelemetryMessage event_msg)
    {
        std::string serialized_tm = event_msg.serialize_message();
        const char *msg = serialized_tm.c_str();

        if (sendto(telemetry_fd, msg, strlen(msg), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_WARN("Couldn't send telemetry to socket.");
        }
    }


    /// Callback to update telemetry in shared memory
    ///
    /// @param cb_data the telemetry callback data to write
    void update_meters_shm(TelemetryMessage meter_msg, std::string period_type)
    {
        int region_index = period_type == "HI"  ? 0 :
                           period_type == "MED" ? 1 :
                           period_type == "LO"  ? 2 : -1;

        // Validate the region index and ensure shared memory is available
        if (region_index < 0) {
            return;
        }

        try 
        {
            // Write the telemetry message into the shared memory region
            std::string serialized_tm = meter_msg.serialize_message();
            const char *msg = serialized_tm.c_str();

            NamedSharedMemory& shm = shm_manager.getSharedMemory(shm_names[region_index]);
            shm.lightWeightWrite(msg, strlen(msg));

        } 
        catch (const std::runtime_error& e) {
            SPDLOG_ERROR("Error accessing shared memory: {}", e.what());
        }
    }


private:
    /// Helper method to send a message on the UDS
    ///
    /// @param message  TelemetryMessage with the message data
    /// @return  true if message sent successfully, false otherwise
    bool send_message(TelemetryMessage &message)
    {
        message.get_parameters().set_name(publisher_name);
        const std::string str = message.serialize_message();
        if (sendto(telemetry_fd, str.c_str(), str.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_ERROR("Failed to send message to telemetry manager.");
            return false;
        }

        return true;
    }


    /// Helper method to receive a message on the UDS
    ///
    /// @return  TelemetryMessage with the data or empty if an error occurred
    TelemetryMessage recv_message()
    {
        char buf[256];
        ssize_t recv_len = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    nullptr, nullptr);
        if (recv_len < 0)
        {
            SPDLOG_ERROR("Failed to receive response from telemetry manager.");
            TelemetryMessage message("");
            return message;
        }

        buf[recv_len] = '\0';

        std::stringstream ss(buf);
        TelemetryMessage message(ss);

        return message;
    }


    /// Pub initiated command to register with telemetry manager
    bool register_with_telemetry_manager()
    {
        TelemetryMessage req = telemetry_messages->get_default_command("pub_register_req");
        size_t meter_blob_size = telemetry_messages->get_default_meter().serialize_message().size();
        std::vector<size_t> block_size = {get_meters_size("HI", meter_blob_size),
                                          get_meters_size("MED", meter_blob_size),
                                          get_meters_size("LO", meter_blob_size)};
        req.get_parameters().set_block_size(block_size);
        req.set_packet_id();

        SPDLOG_TRACE("Sending registration req: \n\n{}", req.serialize_message());

        // Send the registration request
        if (!send_message(req))
        {
            SPDLOG_ERROR("Connection to telemetry manager failed. Aborting");
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        // Wait for a response
        TelemetryMessage rsp = recv_message();
        if (rsp.serialize_message().empty())
        {
            SPDLOG_ERROR("Connection to telemetry manager failed. Aborting");
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        if (rsp.get_message_name() == "pub_register_rsp" && 
            rsp.get_parameters().get_value() == "OK" && 
            rsp.get_packet_id() == req.get_packet_id())
        {
            SPDLOG_TRACE("Received valid registration rsp: \n\n{}", rsp.serialize_message());
        }
        else
        {
            SPDLOG_ERROR("Received bad rsp: \n\n{}", rsp.serialize_message());
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        shm_names = rsp.get_parameters().get_block_name();
        for (size_t i = 0; i < shm_names.size(); ++i) {
            if (block_size[i] > 0) {
                try {
                    NamedSharedMemory &shm = shm_manager.openSharedMemory(shm_names[i]);
                    shm.setPersonalityAsWriter();
                    
                    SPDLOG_TRACE("Found shared memory region {} with size {}", shm_names[i], block_size[i]);
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
        req.set_packet_id();

        if (!send_message(req))
        {
            return false;
        }

        // Wait for a response
        TelemetryMessage rsp = recv_message();
        if (rsp.serialize_message().empty())
        {
            return false;
        }

        if (rsp.get_message_name() == "pub_deregister_rsp" &&
            rsp.get_parameters().get_value() == "OK" &&
            rsp.get_packet_id() == req.get_packet_id())
        {
            SPDLOG_INFO("Received valid deregistration response: \n\n{}", rsp.serialize_message());
        }
        else
        {
            SPDLOG_ERROR("Received bad response: \n\n{}", rsp.serialize_message());
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
    /// @param req  The meters_update_req TelemetryMessage from the manager
    void update_meters(TelemetryMessage &req)
    {
        std::string period_type = req.get_parameters().get_period_type();

        int region_index = period_type == "HI"  ? 0 :
                           period_type == "MED" ? 1 :
                           period_type == "LO"  ? 2 : -1;

        // Validate the region index and ensure shared memory is available
        if (region_index < 0) {
            return;
        }

        NamedSharedMemory& shm = shm_manager.getSharedMemory(shm_names[region_index]);
        shm.softResetWritePointer();

        TelemetryMessage meter_msg(telemetry_messages->get_default_meter());

        for (auto &m: meters)
        {
            SPDLOG_TRACE("Update meter {} period_type {}", m.first, m.second->get_period_type());
            if (m.second->get_period_type() == period_type)
            {   
                try 
                {
                    m.second->send_meter(meters_callback, meter_msg);
                } 
                catch (const std::runtime_error& e) 
                {
                    SPDLOG_ERROR("Error accessing shared memory: {}", e.what());
                }
            }
        }

        shm.writeNumberBytesToSharedMemory();

        TelemetryMessage rsp = telemetry_messages->get_default_command("update_meters_rsp");
        rsp.get_parameters().set_value("OK");
        rsp.set_packet_id(req.get_packet_id());

        SPDLOG_TRACE("Sending response: \n{}", rsp.serialize_message());

        if (!send_message(rsp))
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
        else if (message.get_message_name() == "update_report_period_req")
        {
            // TODO
        }
        // TODO -- get all responses here too?
        else if (message.get_message_name() == "pub_register_rsp")
        {
            // TODO
        }
        else if (message.get_message_name() == "pub_deregister_rsp")
        {
            // TODO
        }
        else if (message.get_message_name() == "event_rsp")
        {
            // TODO
        }
    }


    /// Send any events that have changed
    void send_events()
    {
        TelemetryMessage event_msg(telemetry_messages->get_default_event());
        event_msg.get_parameters().set_name(publisher_name);

        for (auto &e: events)
        {
            e.second->send_event_if_changed(event_callback, event_msg);
        }
    }


    /// The main loop for monitoring telemetry data and executing commands.
    void monitor_loop() {
        if (telemetry_fd < 0)
        {
            SPDLOG_CRITICAL("Invalid connection socket.");
        }

        int error_timeout = 0;
        while (!stop_flag)
        {
            // Receive a message from the telemetry manager
            TelemetryMessage message = recv_message();
            if (message.serialize_message().empty())
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

            SPDLOG_TRACE("Received message from telemetry manager: \n\n{}", message.serialize_message());

            try
            {
                process_telemetry_message(message);
            }
            catch (const std::exception &e)
            {
                SPDLOG_ERROR("Error processing received message: {}", e.what());
            }

            usleep(100);
        }
    }


    /// Loop for managing events.
    void manage_events_loop() {
        while (!stop_flag)
        {
            send_events();

            usleep(100000);
        }
    }


    /// Setup send telemetry callback member funcs
    void setup_callbacks() {
        meters_callback = [this](TelemetryMessage meter_msg, std::string period_type) {
            update_meters_shm(meter_msg, period_type);
        };

        event_callback = [this](TelemetryMessage event_msg) {
            send_event_uds(event_msg);
        };
    }


    std::function<void(TelemetryMessage, std::string)> meters_callback;
    std::function<void(TelemetryMessage)> event_callback;

    std::string publisher_name;
    std::string server_path;
    std::string client_path;

    NamedSharedMemoryManager& shm_manager;
    int telemetry_fd;
    std::vector<std::string> shm_names;
    struct sockaddr_un telemetry_manager_addr;
    int timeout;
    bool initialized;
    std::atomic<bool> stop_flag;
    
    std::unique_ptr<TelemetryMessage> telemetry_messages;

    std::thread monitor_thread;
    std::thread events_thread;

    std::map<std::string, std::unique_ptr<Telemetry>> meters;
    std::map<std::string, std::unique_ptr<Telemetry>> events;
};

} // namespace bosepro
