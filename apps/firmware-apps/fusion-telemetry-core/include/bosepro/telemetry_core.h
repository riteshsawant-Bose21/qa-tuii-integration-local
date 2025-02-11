#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <variant>
#include <zmq.h>
#include <zmq.hpp>
#include "navigator.h"
#include "telemetry_configuration.h"
#include "named_shared_memory_manager_factory.h"

#ifndef _TELEMETRY_CORE_H_

#define _TELEMETRY_CORE_H_

enum etelemetryEndpointTypes {
    TELM_REQUESTER_SUBSCRIBER_TYPE = 0,
    TELM_REQUESTER_PUBLISHER_TYPE,
    TELM_REQUESTER_MAX_TYPE
};

// Describes if subscriber is internal (unix socket) or external (internet socket)
enum eSockConnType {
    TELM_CONN_TYPE_UNIX_SOCK = 0,
    TELM_CONN_TYPE_INTERNET_SOCK,
    TELM_CONN_TYPE_MAX,
};

enum eMeterCategory {
    TELM_METER_CTGRY_HI_PRIO = 0,
    TELM_METER_CTGRY_MED_PRIO,
    TELM_METER_CTGRY_LO_PRIO,
    TELM_METER_CTGRY_MAX
};

#define TELM_HI_PERIOD_MS_DEFAULT   10
#define TELM_MED_PERIOD_MS_DEFAULT  100
#define TELM_LO_PERIOD_MS_DEFAULT   1000

#define MAX_COMM_FAIL_COUNT          5

namespace bosepro {

class telemetryManager;

typedef struct shm_cfg {
    bosepro::NamedSharedMemory* handle;
    std::string                 name;
    uint32_t                    size;
} shared_mem_config;

typedef std::variant<sockaddr_un, sockaddr_in> telmVariantSockAddr;

// REQUEST Message handler prototype
typedef int (*telmReqProto)(telemetryManager &,
                   const bosepro::Telemetry_configuration &,
                   uint64_t&, std::string&, void *arg);

// RESPONSE Message handler prototype
typedef int (*telmRspProto)(telemetryManager &, std::string &,
                            uint64_t, bool, std::ostringstream&, void *arg);

typedef std::pair <telmReqProto, telmRspProto> telmPairMsgHdlr;

typedef std::pair <std::string, enum eMeterCategory> telmPairMeterMsg;


class telemetryPublisher
{
    public:
        telemetryPublisher(std::string pub_name, sockaddr_un& pub_addr,
                           std::vector<shared_mem_config>& shm_cfg
                           ): name(pub_name), shared_mem(shm_cfg)
        {
            // Save pub_addr
            sock_addr = new sockaddr_un(pub_addr);

            report_tick[TELM_METER_CTGRY_HI_PRIO]  = 0;
            report_tick[TELM_METER_CTGRY_MED_PRIO] = 0;
            report_tick[TELM_METER_CTGRY_LO_PRIO]  = 0;

            comm_fail_count = 0;
        }

        ~telemetryPublisher()
        {
            // free sock_addr
            delete sock_addr;

            shared_mem.clear();
        }

        /// Read the shared memory to retreive the meter data
        ///
        /// @param type       Meter type to read
        /// @param telm_data  String buffer to to hold meter data read.
        std::size_t read_meter_data(enum eMeterCategory type,
                                    std::string& telm_data)
        {
            std::size_t size;
            try {
                std::unique_ptr<char[]> buffer =
                    std::make_unique<char[]>(shared_mem[type].size);

                try {
                    char* buf_ptr = buffer.get();
                    size =
                        shared_mem[type].handle->read(
                                           static_cast<void *>(buf_ptr),
                                           shared_mem[type].size);

                    telm_data.assign(buf_ptr, size);
                } catch (std::runtime_error& e)
                {
                    SPDLOG_ERROR("Meter data read error ({})", e.what());
                    size = 0;
                }
            } catch (const std::bad_alloc& e)
            {
                SPDLOG_ERROR("read_meter_data(): Memory allocation failure");
                size = 0;
            }

            return size;
        }

        /// Get socket address of the Publisher
        ///
        /// @param  pub_sock_addr  Return Socket address
        void  get_address(telmVariantSockAddr& pub_sock_addr)
        {
            pub_sock_addr = *sock_addr;
        }

        /// Get name of the shared memory allocated to the Publisher.
        ///
        /// @param   Meter type that is requested
        /// @return  Shared memory name for the requested meter type
        std::string get_shared_mem_name(enum eMeterCategory type)
        {
            return shared_mem[type].name;
        }

        /// Get size of the shared memory allocated to the Publisher.
        ///
        /// @param   Meter type that is requested
        /// @return  Shared memory size for the requested meter type
        uint32_t get_shared_mem_size(enum eMeterCategory type)
        {
            return shared_mem[type].size;
        }

        /// Advance the meter report tick count for the publisher.
        /// This is used to keep track of when to report the meter
        /// data of the publisher to subscribers.
        ///
        /// @param  type  Meter type
        /// @return Current value of Tick count
        uint32_t advance_report_tick(enum eMeterCategory type)
        {
            return ++report_tick[type];
        }

        /// Get the meter report tick count for the publisher.
        /// This is used to keep track of when to report the meter
        /// data of the publisher to subscribers.
        ///
        /// @param  type  Meter type
        /// @return Current value of Tick count
        uint32_t get_report_tick(enum eMeterCategory type)
        {
            return report_tick[type];
        }

        /// Reset the meter report tick count for the publisher.
        /// This is used to keep track of when to report the meter
        /// data of the publisher to subscribers.
        ///
        /// @param  type  Meter type
        void reset_report_tick(enum eMeterCategory type)
        {
            report_tick[type] = 0;
        }

        uint32_t increment_fail_comm()
        {
            return ++comm_fail_count;
        }

        void reset_fail_comm()
        {
            comm_fail_count = 0;
        }

        uint32_t get_comm_fail_cnt()
        {
            return comm_fail_count;
        }

    private:

        /// Publisher name
        std::string name;

        // UNIX domain socket address of the publisher
        struct sockaddr_un *sock_addr;

        /// Shared memeory info
        std::vector<shared_mem_config> shared_mem;

        /// Meter report tick count
        /// This is used to keep track of when to report the meter
        /// data of the publisher to subscribers.
        uint32_t report_tick[TELM_METER_CTGRY_MAX];

        uint32_t comm_fail_count;
};

class telemetrySubscriberInterfaceBase
{
    public:
        virtual int  init() = 0;
        virtual int  attach(std::string&) = 0;   // Bind or connect
        virtual int send(const std::string&) = 0;
};

class telemetrySubscriberZmqInterface : public telemetrySubscriberInterfaceBase
{
    public:
        telemetrySubscriberZmqInterface(): telm_zmq_context(1) {}

        ~telemetrySubscriberZmqInterface()
        {
            telm_zmq_socket.close();
        }

        int init() override
        {
            int ret_val = 0;

            telm_zmq_socket = zmq::socket_t(telm_zmq_context, ZMQ_PUB);

            return ret_val;
        }

        int attach(std::string& addr) override
        {
            telm_zmq_socket.bind(addr.c_str());

            return 0;
        }

        int send(const std::string& pub_data) override
        {
            int ret_val = 0;
            zmq::message_t msg(pub_data.size());
            memcpy(msg.data(), pub_data.c_str(), pub_data.size());

            try
            {
                auto send_res = telm_zmq_socket.send(msg,
                                                     zmq::send_flags::none);
                if (send_res.has_value())
                {
                    SPDLOG_DEBUG("Message sent successfully ({} bytes)",
                                 send_res.value());
                }
                else
                {
                    SPDLOG_ERROR("Message send failed, EAGAIN encountered.");
                    ret_val = -1;
                }
            }
            catch (const zmq::error_t& e)
            {
                SPDLOG_ERROR("Error sending message: {}", e.what());
                ret_val = -1;
            }
            return ret_val;
        }

    private:
        zmq::context_t telm_zmq_context;
        zmq::socket_t  telm_zmq_socket;
};

class telemetryManager
{
    public:
        telemetryManager()
        {
            init_success = false;
            meter_update_frame_count = 0;
        }

        ~telemetryManager()
        {
            int null_fd = 0;

            clear_publishers();

            set_socket_descriptors(null_fd, null_fd);

            core_sock_path.clear();
            core_ip_addr.clear();
            core_ip_port = 0;
            clear_last_rcvd_addr();

            SPDLOG_CRITICAL("Telemery Manager Exiting ...");
        }

        /// Initialize the telemetry manager
        ///
        /// @param core_ip         IP address of the target where the manager
        ///                        runs. This is used to create and open the
        ///                        Internet socket.
        /// @param core_path       UNIX socket path the manager should use.
        /// @param update_periods  Vector holding HI, MED & LO update
        ///                        request periods for the system.
        /// @param report_periods  Vector holding HI, MED & LO report
        ///                        periods for the system.
        /// @return Success(0)/Failure (-1)
        int init(std::string& core_ip, std::string& core_path,
                 std::string& pub_sock_address,
                 std::vector<uint32_t>& update_periods,
                 std::vector<uint32_t>& report_periods)
        {
            int ret_val = 0;

            meter_update_frame_count = 0;

            core_sock_path.assign(core_path);
            std::size_t port_idx = core_ip.find(":");

            if (port_idx ==  std::string::npos)
            {
                SPDLOG_ERROR("Invalid IP format <IP:PORT>");
                ret_val = -1;
            }
            else
            {
                core_ip_addr = core_ip.substr(0, port_idx);
                core_ip_port = std::stoi(core_ip.substr(port_idx+1));
            }

            if (ret_val == 0)
            {
                if (set_meter_update_periods(update_periods) != 0)
                {
                    SPDLOG_CRITICAL("Invalid \"update periods\"");
                    ret_val = -1;
                }
                SPDLOG_DEBUG("Update periods: {} {} {}",
                              hi_update_period_frames,
                              med_update_period_frames,
                              lo_update_period_frames);
            }

            if (ret_val == 0)
            {
                if (set_meter_report_periods(report_periods) != 0)
                {
                    SPDLOG_CRITICAL("Invalid \"report periods\"");
                    ret_val = -1;
                }
                SPDLOG_DEBUG("Report periods: {} {} {}",
                              hi_report_period_frames,
                              med_report_period_frames,
                              lo_report_period_frames);
            }

            if (ret_val == 0)
            {
                // Initialize socket for meter data TX.
                if (subscriber_channel.init() == 0)
                {
                    if (subscriber_channel.attach(pub_sock_address) == 0)
                    {
                        init_success = true;
                    }
                    else
                    {
                        SPDLOG_ERROR("Socket bind failed! ");
                        ret_val = -1;
                    }
                }
            }

            return ret_val;
        }

        /// Register a new publisher to the system
        ///
        /// @param   pub_name  Publisher name.
        /// @param   shm_cfg   Vector containg the shared memory configuration
        ///                    for the 3 meter types.
        /// @return Success(0)/Failure (-1)
        int register_publisher(std::string pub_name,
                               std::vector<shared_mem_config>& shm_cfg)
        {
            int ret_val = 0;
            std::vector<shared_mem_config> shm_config = shm_cfg;
            struct sockaddr_un pub_addr;
            std::map<std::string,
                     std::unique_ptr<telemetryPublisher>>::iterator pub_it;
            pub_it =  publishers.find(pub_name);

            // Check if publisher exists
            if (pub_it == publishers.end())
            {
                get_last_rcvd_addr(pub_addr);

                //  Create SHM
                for (int idx = 0; idx < 3; idx++)
                {
                    if (shm_config[idx].size > 0)
                    {
                        SPDLOG_DEBUG("Shm Name: {}", shm_config[idx].name);

                        create_shared_mem(shm_config[idx].name,
                                shm_config[idx].size);
                        shm_config[idx].handle =
                            &(get_shared_mem(shm_config[idx].name));
                        shm_config[idx].handle->setPersonalityAsReader();
                    }
                }

                auto new_entry = publishers.emplace(
                        pub_name,
                        std::make_unique<telemetryPublisher>(pub_name,pub_addr,
                            shm_config));

                // Check list if already exists and Insert into Publisher list.
                // (emplace returns false if key already existe
                if (!new_entry.second)
                {
                    SPDLOG_ERROR("Publisher '{}' already exists.", pub_name);
                    ret_val = -1;
                }
                else
                {
                    // Increment publisher count
                    publisher_count[TELM_CONN_TYPE_UNIX_SOCK]++;
                }

            }
            else
            {
                SPDLOG_ERROR("Publisher '{}' already exists.", pub_name);
                ret_val = -1;
            }
            return ret_val;;
        }

        /// Deregister an existing publisher from the system
        ///
        /// @param   pub_name  Publisher name.
        /// @return Success(0)/Failure (-1)
        int deregister_publisher(std::string pub_name)
        {
            int ret_val = 0;

            std::map<std::string,
                     std::unique_ptr<telemetryPublisher>>::iterator pub_it;
            pub_it =  publishers.find(pub_name);

            if (pub_it != publishers.end())
            {
                if (pub_it->second->get_shared_mem_size(TELM_METER_CTGRY_HI_PRIO) > 0)
                {
                    std::string pub_shm_name;
                    pub_shm_name.assign(pub_it->second->get_shared_mem_name(TELM_METER_CTGRY_HI_PRIO));
                    remove_shared_mem(pub_shm_name);
                }
                if (pub_it->second->get_shared_mem_size(TELM_METER_CTGRY_MED_PRIO) > 0)
                {
                    std::string pub_shm_name;
                    pub_shm_name.assign(pub_it->second->get_shared_mem_name(TELM_METER_CTGRY_MED_PRIO));
                    remove_shared_mem(pub_shm_name);
                }
                if (pub_it->second->get_shared_mem_size(TELM_METER_CTGRY_LO_PRIO) > 0)
                {
                    std::string pub_shm_name;
                    pub_shm_name.assign(pub_it->second->get_shared_mem_name(TELM_METER_CTGRY_LO_PRIO));
                    remove_shared_mem(pub_shm_name);
                }

                // The publisher cannot be deleted until response has been sent
                // The deletion is performed after response is sent
                publisher_count[TELM_CONN_TYPE_UNIX_SOCK]--;
                deregister_endpoint_name.assign(pub_name);
            }
            else
            {
                ret_val = -1;
                SPDLOG_ERROR("Publiher not found");
            }

            return ret_val;
        }

        /// Set the system HI, MED & LO meter report periods
        ///
        /// @param   periods  Vector with the 3 period values
        /// @return Success(0)/Failure (-1)
        int set_meter_report_periods(std::vector<uint32_t>& periods)
        {
            int ret_val = 0;

            // Validate periods
            if ( (periods.size() <= 0)                      ||
                 (periods.size() > TELM_METER_CTGRY_MAX)    ||
                 (periods[TELM_METER_CTGRY_HI_PRIO] >=
                        periods[TELM_METER_CTGRY_MED_PRIO]) ||
                 (periods[TELM_METER_CTGRY_HI_PRIO] >=
                        periods[TELM_METER_CTGRY_LO_PRIO])  ||
                 (periods[TELM_METER_CTGRY_MED_PRIO] >=
                        periods[TELM_METER_CTGRY_LO_PRIO]) )
            {
                SPDLOG_CRITICAL("Invalid period values");
                ret_val = -1;
            }
            else
            {
                if ( ((periods[TELM_METER_CTGRY_HI_PRIO] %
                       hi_update_period_frames) != 0)  ||
                     ((periods[TELM_METER_CTGRY_MED_PRIO] %
                       med_update_period_frames) != 0) ||
                     ((periods[TELM_METER_CTGRY_LO_PRIO] %
                       lo_update_period_frames) != 0))
                {
                    SPDLOG_CRITICAL("Reporting periods MUST be multiple of Update periods");
                    ret_val = -1;
                }
                else
                {
                    hi_report_period_frames  =
                        periods[TELM_METER_CTGRY_HI_PRIO];
                    med_report_period_frames =
                        periods[TELM_METER_CTGRY_MED_PRIO];
                    lo_report_period_frames  =
                        periods[TELM_METER_CTGRY_LO_PRIO];

                    report_period_factor[TELM_METER_CTGRY_HI_PRIO] =
                        periods[TELM_METER_CTGRY_HI_PRIO] /
                        hi_update_period_frames;

                    report_period_factor[TELM_METER_CTGRY_MED_PRIO] =
                        periods[TELM_METER_CTGRY_MED_PRIO] /
                        med_update_period_frames;

                    report_period_factor[TELM_METER_CTGRY_LO_PRIO] =
                        periods[TELM_METER_CTGRY_LO_PRIO] /
                        lo_update_period_frames;

                }
            }

            return ret_val;
        }

        /// Set the system HI, MED & LO meter update request periods
        ///
        /// @param   periods  Vector with the 3 period values
        /// @return Success(0)/Failure (-1)
        int set_meter_update_periods(std::vector<uint32_t>& periods)
        {
            int ret_val = 0;

            // Validate periods
            if ( (periods.size() <= 0)      ||
                 (periods.size() > TELM_METER_CTGRY_MAX)    ||
                 (periods[TELM_METER_CTGRY_HI_PRIO] >=
                        periods[TELM_METER_CTGRY_MED_PRIO]) ||
                 (periods[TELM_METER_CTGRY_HI_PRIO] >=
                        periods[TELM_METER_CTGRY_LO_PRIO])  ||
                 (periods[TELM_METER_CTGRY_MED_PRIO] >=
                        periods[TELM_METER_CTGRY_LO_PRIO]) )
            {
                SPDLOG_CRITICAL("Invalid period values");
                ret_val = -1;
            }
            else
            {
                hi_update_period_frames  = periods[TELM_METER_CTGRY_HI_PRIO];
                med_update_period_frames = periods[TELM_METER_CTGRY_MED_PRIO];
                lo_update_period_frames  = periods[TELM_METER_CTGRY_LO_PRIO];
            }
            return ret_val;
        }

        /// Get the system HI, MED & LO meter report periods
        ///
        /// @param   periods  Vector with the 3 period values
        void get_meter_report_periods(std::vector<int>& periods)
        {
            periods[TELM_METER_CTGRY_HI_PRIO]  = hi_report_period_frames;
            periods[TELM_METER_CTGRY_MED_PRIO] = med_report_period_frames;
            periods[TELM_METER_CTGRY_LO_PRIO]  = lo_report_period_frames;
        }

        /// Get the system HI, MED & LO meter report periods
        ///
        /// @param   hi_period  HI report period value,
        /// @param   med_period MED report period value,
        /// @param   lo_period  LO report period value,
        void get_meter_report_periods(uint32_t& hi_period,
                uint32_t& med_period,
                uint32_t& lo_period)
        {
            hi_period  = hi_report_period_frames;
            med_period = med_report_period_frames;
            lo_period  = lo_report_period_frames;
        }

        /// Get the system HI, MED & LO meter update request periods
        ///
        /// @param   hi_period  HI update request period value,
        /// @param   med_period MED update request period value,
        /// @param   lo_period  LO update request period value,
        void get_meter_update_periods(uint32_t& hi_period,
                uint32_t& med_period,
                uint32_t& lo_period)
        {
            hi_period  = hi_update_period_frames;
            med_period = med_update_period_frames;
            lo_period  = lo_update_period_frames;
        }

        /// Receive data from the socket of the specified type.
        ///
        /// @param  type        Socket type
        /// @param  rx_buf      Buffer to store received data
        /// @param  rx_buf_size Size of the allocated buffer.
        /// @param  recv_size   Received data size
        void receive_data(enum eSockConnType type, char rx_buf[],
                          int rx_buf_size, uint32_t& recv_size)
        {
            clear_last_rcvd_addr();
            if (type == TELM_CONN_TYPE_UNIX_SOCK)
            {
                uint32_t addr_length = sizeof(ux_addr_last_rcvd);

                recv_size = recvfrom(socket_fd[TELM_CONN_TYPE_UNIX_SOCK],
                                     (void *)rx_buf,
                                     rx_buf_size, 0,
                                     (struct sockaddr*) &ux_addr_last_rcvd,
                                     &addr_length);
            }

            else
            {
                recv_size = recvfrom(socket_fd[TELM_CONN_TYPE_INTERNET_SOCK],
                        (void *)rx_buf, rx_buf_size,
                        0, NULL, NULL);
            }
        }

        /// Register the request and response handlers for the specified
        /// message.
        ///
        /// @param  message_name  Name of the message being registered.
        /// @param  req           Message request handler.
        /// @param  rsp           Message response handler.
        /// @return Success(0)/Failure (-1)
        int register_message_handler(const std::string& message_name,
                                     telmReqProto req , telmRspProto rsp)
        {
            int ret_val = 0;

            if (init_success)
            {
                if (message_handler.emplace(message_name,
                            telmPairMsgHdlr(req, rsp)).second)
                {
                    ret_val = 0;
                }
                else
                {
                    // Handler already registered
                    SPDLOG_ERROR("Handlers already registered - {}",
                                  message_name);
                    ret_val = -1;
                }
            }
            else
            {
                SPDLOG_CRITICAL("Telemetry Manager not initialzed, call init()");
                ret_val = -1;
            }
            return ret_val;
        }

        /// Transmit meter data to all subscribers
        ///
        /// @param  meter_data  Meter data string
        /// @return Success(0)/Failure (-1)
        int send_meter_data(std::ostringstream& meter_data);

        /// Transmit message packet to specified desstination
        ///
        /// @param  destination_name  Registerd name of destination
        ///                           (Publisher/Subscriber).
        /// @param  message           Message data to be transmitted.
        /// @return Success(0)/Failure (-1)
        int send_data(const std::string destination_name, std::ostringstream& message);

        /// Process received message
        ///
        /// @param  packet  Received message
        /// @return if response handler registered - Bytes tx'd
        ///         if response handler not registered - 0
        int process_rx_packet(std::string& packet);

        /// Find if registerd name is a subscriber or publisher.
        ///
        /// @param  req_name  Requestor name
        /// @param  type      Returns type
        void find_type(std::string req_name,
                       enum etelemetryEndpointTypes& type)
        {
            type = TELM_REQUESTER_MAX_TYPE;

            if (publishers.find(req_name) != publishers.end())
            {
                type = TELM_REQUESTER_PUBLISHER_TYPE;
            }
        }

        /// Get the UNIX socket path configured to use for system
        ///
        /// @param  ux_path  Socket path
        void get_ux_sock_path(std::string& ux_path)
        {
            ux_path = core_sock_path;
        }

        /// Get the IP address of system
        ///
        /// @param  ip_addr  IP address
        void get_inet_ip(std::string& ip_addr)
        {
            ip_addr = core_ip_addr;
        }

        /// Get IP Port number of system
        ///
        /// @param ip_port   Port number of system
        void get_inet_port(uint32_t& ip_port)
        {
            ip_port = core_ip_port;
        }

        /// Get the manager socket descriptor
        ///
        /// @param  type  Socket type of the descriptor being requested.
        /// @return   Socket descriptor of the requested type.
        int get_socket_descriptor(enum eSockConnType type)
        {
            return socket_fd[type];
        }

        /// Set the manager socket descriptors
        ///
        /// @param  ux_fd    UNIX socket descriptor
        /// @param  inet_fd  Internet socket descriptor
        void set_socket_descriptors(int& ux_fd, int& inet_fd)
        {
            // Set UNIX Socket for pubs & internal subs.
            socket_fd[TELM_CONN_TYPE_UNIX_SOCK] = ux_fd;

            // Set Internet socket for external subscribers.
            socket_fd[TELM_CONN_TYPE_INTERNET_SOCK] = inet_fd;
        }

        /// Allocate and create shared memory with requested name and size
        ///
        /// @param  shm_name  Shared memory name
        /// @param  shm_size  Shared memory size
        void create_shared_mem(std::string shm_name, std::size_t shm_size)
        {
            try {
                // Cleanup if shared memory leftover from previous bad exit
                shm_manager.removeSharedMemory(shm_name);
            }
            catch (const std::runtime_error& e)
            {
                //Ignore
            }
            shm_manager.createSharedMemory(shm_name, shm_size);
        }

        /// Delete allocated shared memory.
        ///
        /// @param  shm_name  Shared memory name
        void remove_shared_mem(std::string shm_name)
        {
            shm_manager.removeSharedMemory(shm_name);
        }

        /// Get handle for a created shared memory segment
        ///
        /// @param  shm_name  Shared memory segment name.
        /// @return  Shared memory handle
        bosepro::NamedSharedMemory& get_shared_mem(std::string shm_name)
        {
            return shm_manager.getSharedMemory(shm_name);
        }

        /// Get name of allocated shared memory segment for a
        /// specied publiher and meter type
        ///
        /// @param   pub_name    Publisher name
        /// @param   meter_type  Meter type
        std::string get_pub_shared_mem_name(std::string pub_name,
                                            enum eMeterCategory meter_type)
        {
            std::map<std::string,
                     std::unique_ptr<telemetryPublisher>>::iterator pub_it;
            pub_it =  publishers.find(pub_name);

            if (pub_it != publishers.end())
            {
                return pub_it->second->get_shared_mem_name(meter_type);
            }
            else
            {
                //Empty string
                SPDLOG_ERROR("Publisher not found ({})", pub_name);
                return std::string();
            }
        }

        /// Read meter data from shared memory for specified publisher and
        /// meter type
        ///
        /// @param   pub_name    Publisher name
        /// @param   meter_type  Meter type
        /// @param   meter_data  Meter data read
        std::size_t get_meter_data(std::string pub_name,
                            enum eMeterCategory meter_type,
                            std::string& meter_data)
        {
            std::size_t data_size = 0;

            std::map<std::string,
                     std::unique_ptr<telemetryPublisher>>::iterator pub_it;

            pub_it =  publishers.find(pub_name);

            if (pub_it != publishers.end())
            {
                data_size =
                    pub_it->second->read_meter_data(meter_type, meter_data);
            }
            else
            {
                SPDLOG_ERROR("Publisher not found ({})", pub_name);
            }

            return data_size;
        }

        /// Send update_meters_req message to all publishers at
        /// apparopriate times.
        void send_update_request();

        /// Get number of registered publishers in the system
        ///
        /// @return  Registered Publishers count.
        uint32_t get_publisher_count()
        {
            return publisher_count[TELM_CONN_TYPE_UNIX_SOCK];
        }

        /// Get the publisher name at specified index in the list
        ///
        /// @param index    Index to search
        /// @param pub_name Publisher name at 'index'.
        void get_publisher_name_by_index(uint32_t index, std::string& pub_name)
        {
            uint32_t idx = 0;

            for (auto& pubs : publishers)
            {
                if (idx == index)
                {
                    pub_name.assign(pubs.first);
                    break;
                }
            }
        }

        /// Validate the updated_meter_rsp message received froma publisher
        ///
        /// @param  pkt_id      Packet ID of the received message
        /// @param  req_name    Publisher name sending the response
        /// @param  ok_nok      meters_update_req result
        /// @parma  meter_type  Returns meter type corresponding to
        ///                     this response.
        int validate_update_meter_rsp(uint64_t& pkt_id, std::string& req_name,
                                      std::string ok_nok,
                                      enum eMeterCategory& meter_type);

        /// Check if it is time to report meter data for a
        /// publisher meter type.
        ///
        /// @param  pub_name   Pulisher name
        /// @param  meter_type Meter type
        /// @return true/false.
        bool time_to_report_meter(std::string& pub_name,
                                  enum eMeterCategory& meter_type);

        /// Cleanup dead endpoints that are unreachable.
        void cleanup_dead_endpoints(void);

    private:
        // Publisher list
        std::map<std::string,
                 std::unique_ptr<telemetryPublisher>> publishers;

        telemetrySubscriberZmqInterface subscriber_channel;

        // Message and Response handler registry
        std::map<const std::string, telmPairMsgHdlr> message_handler;

        std::map<uint64_t, telmPairMeterMsg> meter_update_tracker;

        // UNIX  & INTERNET socket descs.
        int socket_fd[TELM_CONN_TYPE_MAX] = {0, 0};

        bosepro::NamedSharedMemoryManager& shm_manager =
                         bosepro::NamedSharedMemoryManagerFactory::getInstance();

        // Periods (in frames) to send meter_update_request
        uint32_t hi_update_period_frames;
        uint32_t med_update_period_frames;
        uint32_t lo_update_period_frames;

        // Periods (in frames) to report meter data to subscribers
        uint32_t hi_report_period_frames;
        uint32_t med_report_period_frames;
        uint32_t lo_report_period_frames;

        uint32_t report_period_factor[TELM_METER_CTGRY_MAX];

        uint32_t publisher_count[TELM_CONN_TYPE_MAX];
        uint32_t subscriber_count[TELM_CONN_TYPE_MAX];

        std::string subscriber_port_address; // Socket address for subscribers
        std::string core_sock_path;   // UNIX sockeet path
        std::string core_ip_addr;     // IP address
        uint32_t    core_ip_port;     // Port number

        // Frame counter
        uint32_t meter_update_frame_count;

        std::string deregister_endpoint_name;

        sockaddr_un ux_addr_last_rcvd;

        bool init_success = false;

        void clear_last_rcvd_addr()
        {
            memset(&ux_addr_last_rcvd, 0, sizeof(ux_addr_last_rcvd));
        }

        // Variant visit structure for 'telmVariantSockAddr'
        struct tx_data {
            int *fd_;
            std::string in_msg_;

            tx_data(int *fd, const std::string& message) :
                                     fd_(fd), in_msg_(message){}

            // UNIX Socket
            int operator()(sockaddr_un addr)
            {
                const char* tx_stream = in_msg_.c_str();
                struct stat statbuf;

                if (stat(addr.sun_path , &statbuf) == 0 &&
                    S_ISSOCK(statbuf.st_mode))
                {
                    return
                        sendto(fd_[TELM_CONN_TYPE_UNIX_SOCK],
                                tx_stream, in_msg_.length(), 0,
                                (struct sockaddr *)&addr, sizeof(addr));
                }
                else
                {
                    SPDLOG_ERROR("{} does not exists", addr.sun_path);
                    return -1;
                }

            }

            // Internet Socket
            int operator()(sockaddr_in addr)
            {
                const char* tx_stream = in_msg_.c_str();

                return
                    sendto(fd_[TELM_CONN_TYPE_INTERNET_SOCK],
                           tx_stream, in_msg_.length(), 0,
                           (struct sockaddr *)&addr, sizeof(addr));
            }
        };

        /// When a deregister message is received the endpoint
        /// that was de-registerd cannot be purged until the response
        /// has been sent. This function performs the final dletion after
        /// the response has been sent.
        void post_deregister_cleanup()
        {
            if (deregister_endpoint_name.size() > 0)
            {
                enum etelemetryEndpointTypes end_type;

                find_type(deregister_endpoint_name, end_type);

                if (end_type == TELM_REQUESTER_PUBLISHER_TYPE)
                {
                    publishers.erase(deregister_endpoint_name);
                }
                deregister_endpoint_name.clear();
            }

        }

        void meter_update_req_add(uint64_t& pkt_id,
                                  const std::string& pub_name,
                                  enum eMeterCategory type)
        {
            telmPairMeterMsg new_pair(pub_name, type);

            meter_update_tracker.emplace(pkt_id, new_pair);
        }

        uint32_t meter_update_req_remove(uint64_t& pkt_id)
        {
            return
                meter_update_tracker.erase(pkt_id);
        }

        void meter_update_req_find(uint64_t& pkt_id, std::string& pub_name,
                                      enum eMeterCategory& meter_type)
        {
            std::map<uint64_t, telmPairMeterMsg>::iterator name_type;

            if ( (name_type = meter_update_tracker.find(pkt_id)) !=
                    meter_update_tracker.end())
            {
                pub_name.assign(name_type->second.first);
                meter_type = name_type->second.second;
            }
            else
            {
                meter_type = TELM_METER_CTGRY_MAX;
            }
        }

        void clear_publishers()
        {
            for (auto& pubs : publishers)
            {
                // This only removes the shared memory
                deregister_publisher(pubs.first);
            }

            // Delete all publishers
            publishers.clear();
        }

        /// Get the source address of the last received packet from the
        /// UNIX socket. This is used to determine the address of a
        /// subscriber that is local to the system.
        ///
        /// @param  Source address of the last received packet
        void get_last_rcvd_addr(sockaddr_un& addr)
        {
            memcpy(&addr, &ux_addr_last_rcvd, sizeof(ux_addr_last_rcvd));
        }

};

}
#endif //_TELEMETRY_CORE_H_
