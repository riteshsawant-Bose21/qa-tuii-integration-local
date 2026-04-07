#pragma once

#include <bosepro/telemetry.h>
#include <bosepro/named_shared_memory_manager_factory.h>

#include <string>
#include <functional>
#include <thread>
#include <sched.h>
#include <sys/un.h>
#include <sys/socket.h>
#include <cstring>
#include <cerrno>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h> 
#include <iostream>

#define METER_TIMEOUT 5

namespace bosepro {

class TelemetryMonitor {
public:
    /// Constructor for singleton pattern--initialization in "initialize" method
    TelemetryMonitor();


    ~TelemetryMonitor();


    /// Get the singleton instance of TelemetryMonitor.
    static TelemetryMonitor& get_instance();


    /// Initialize the singleton object. Connect and register with Fusion Telemetry Manager
    ///
    /// @param filename  file to initialize the telemetry_messages
    void initialize(const std::string &filename,
                    const std::string socket_path,
                    const std::string pub_name);


    /// check if the monitor is currently running
    bool is_running();


    /// Start the threads.
    void start();


    /// Stop the TelemetryMonitor and reset it's data for a new registration.
    void unregister_all_telemetry();


    /// Stop the TelemetryMonitor and reset it's data for a new registration.
    void stop();


    /// Register a telemetry item.
    ///
    /// @param telemetry  the unique_ptr to the telemetry item
    void register_telemetry(std::unique_ptr<Telemetry> telemetry);


    /// Unregister all telemetry items associated with a block.
    ///
    /// @param block_name  The name of the block to unregister telemetry
    void unregister_block(const std::string &block_name);


    /// Check if the telemetry monitor has a telemetry item of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::telemetry_name
    /// @return  True if the telemetry monitor has the telemetry item
    bool has_telemetry(const std::string &qualified_name);


    /// Check if the telemetry monitor has a meter of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::meter_name
    /// @return  True if the telemetry monitor has the meter
    bool has_meter(const std::string &qualified_name);


    /// Check if the telemetry monitor has an event of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::event_name
    /// @return  True if the telemetry monitor has the event
    bool has_event(const std::string &qualified_name);


    /// Get a telemetry item using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::telemetry_name
    /// @return  The Telemetry
    Telemetry &get_telemetry(const std::string &qualified_name);


    /// Get an event using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::meter_name
    /// @return  The meter Telemetry
    Telemetry &get_meter(const std::string &qualified_name);


    /// Get an event using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::event_name
    /// @return  The event Telemetry
    Telemetry &get_event(const std::string &qualified_name);


    /// Get the size of all meter messages for meters of the 
    /// specified period_type managed by the telemetry monitor. 
    ///
    /// @param period_type  The meters period_type filter
    /// @param default_message_size  The size of the default, empty
    ///                              meters update message
    /// @return  Total size of all meters of specified period_type managed
    size_t get_meters_size(const std::string &period_type,
                           size_t default_message_size);


    /// Get the number of meters of the specified period_type managed
    /// by the telemetry monitor
    ///
    /// @param period_type The meters period_type filter
    /// @return  Number of meters of specified period_type managed
    int get_num_meters(const std::string &period_type);


    /// Get the number of events managed by the telemetry monitor
    ///
    /// @return  Number of events managed
    int get_num_events();


private:
    void pin_thread(std::thread &t, const char *thread_label) const;


    void name_thread(std::thread &t, const char *name) const;


    /// Callback to send event telemetry on UDS
    ///
    /// @param message the message to send
    void send_event_uds(TelemetryMessage event_msg);


    /// Callback to update telemetry in shared memory
    ///
    /// @param cb_data the telemetry callback data to write
    void update_meters_shm(TelemetryMessage meter_msg, std::string period_type,
                           size_t meters_remaining);


    /// Helper method to send a message on the UDS
    ///
    /// @param message  TelemetryMessage with the message data
    /// @return  true if message sent successfully, false otherwise
    bool send_message(TelemetryMessage &message);


    /// Helper method to receive a message on the UDS
    ///
    /// @return  TelemetryMessage with the data or empty if an error occurred
    TelemetryMessage recv_message();


    /// Pub initiated command to register with telemetry manager
    bool register_with_telemetry_manager();


    /// Pub initiated command to deregister with the telemetry manager
    bool deregister_with_telemetry_manager();


    /// Update all meters with meters_callback when we recieve "update_meters_req"
    /// command from telemetry manager. Send "update_meters_rsp" to confirm
    ///
    /// @param req  The meters_update_req TelemetryMessage from the manager
    void update_meters(TelemetryMessage &req);


    // Handle the deregistration process
    void handle_deregistration(TelemetryMessage &rsp);


    /// Process messages from the telemetry manager
    ///
    /// @param message  TelemetryMessage from the telemetry manager
    void process_telemetry_message(TelemetryMessage &message);


    /// Send any events that have changed
    void send_events();


    /// The main loop for monitoring telemetry data and executing commands.
    void monitor_loop();


    /// Loop for managing events.
    void manage_events_loop();


    /// Setup send telemetry callback member funcs
    void setup_callbacks();


    std::function<void(TelemetryMessage, std::string, size_t)> meters_callback;
    std::function<void(TelemetryMessage)> event_callback;

    std::string publisher_name;
    std::string server_path;
    std::string client_path;

    NamedSharedMemoryManager& shm_manager;
    int telemetry_fd;
    std::vector<std::string> shm_names;
    std::vector<int_fast32_t> shm_sizes;
    struct sockaddr_un telemetry_manager_addr;

    int error;

    std::atomic<bool> initialized;
    std::atomic<bool> running;
    std::atomic<bool> stop_flag;

    std::unique_ptr<TelemetryMessage> telemetry_messages;

    std::thread monitor_thread;
    std::thread events_thread;

    std::map<std::string, std::unique_ptr<Telemetry>> meters;
    std::map<std::string, std::unique_ptr<Telemetry>> events;

    std::map<std::string, std::string> msg_in_flight;
};

} // namespace bosepro
