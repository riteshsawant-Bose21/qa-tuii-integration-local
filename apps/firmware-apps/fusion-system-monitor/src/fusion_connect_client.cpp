#include <bosepro/module.h>
#include <bosepro/periodic_task.h>
#include <bosepro/sap_announcer.h>
#include <cstdint>
#include <string>
#include <sstream>
#include <cstring>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <linux/if_addr.h>
#include <curl/curl.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <vector>
#include <map>
#include <set>
#include <fstream>
#include <json/json.h>

namespace {

#define IFA_F_MCAUTOJOIN 0x400

enum fusion_cn_ctrl_cmd {
    FUSION_CN_CTRL_CMD_NONE = 0,
    FUSION_CN_CTRL_CMD_START_MANAGER,
    FUSION_CN_CTRL_CMD_STOP_MANAGER,
    FUSION_CN_CTRL_CMD_SET_PTP_SYNC,
    FUSION_CN_CTRL_CMD_ADD_STREAM,
    FUSION_CN_CTRL_CMD_REMOVE_STREAM
};

enum mgr_start_errno {
    MGR_START_OK = 0,
    MGR_START_ERRNO_RUNNING,
    MGR_START_ERRNO_PTP,
    MGR_START_ERRNO_MODE
};

struct fusion_cn_ctrl_msg {
    uint32_t cmd;
    int32_t err;
    uint32_t data_size;
    void *data;
    pid_t pid;
};

struct fusion_cn_stream_config {
    uint64_t stream_handle;
    char stream_name[32];
    uint32_t sample_rate;
    int32_t format;
    uint8_t channels;
    uint32_t frames_per_packet;
    uint32_t dest_ip;
    uint16_t dest_port;
    uint16_t source_port;
    uint32_t source_ip;
    uint8_t payload_type;
    uint32_t playout_delay;
    uint32_t timestamp_offset;
    uint8_t is_source;
    uint8_t is_fusion_connect;
} __attribute__((packed));

// Helper function to convert uint32_t IP to string
std::string ipToString(uint32_t ip) {
    struct in_addr addr;
    addr.s_addr = ip;
    return std::string(inet_ntoa(addr));
}

// Function to dump fusion_cn_stream_config struct
void dump_fusion_cn_stream_config(const fusion_cn_stream_config& config) {
    SPDLOG_INFO("Fusion CN Stream Config Dump:");
    SPDLOG_INFO("  Stream Handle: {}", config.stream_handle);
    SPDLOG_INFO("  Stream Name: {}", config.stream_name);
    SPDLOG_INFO("  Sample Rate: {} Hz", config.sample_rate);
    SPDLOG_INFO("  Format: {}", config.format);
    SPDLOG_INFO("  Channels: {}", static_cast<int>(config.channels));
    SPDLOG_INFO("  Frames per Packet: {}", config.frames_per_packet);
    SPDLOG_INFO("  Dest IP: {}", ipToString(config.dest_ip));
    SPDLOG_INFO("  Dest Port: {}", config.dest_port);
    SPDLOG_INFO("  Source Port: {}", config.source_port);
    SPDLOG_INFO("  Source IP: {}", ipToString(config.source_ip));
    SPDLOG_INFO("  Payload Type: {}", static_cast<int>(config.payload_type));
    SPDLOG_INFO("  Playout Delay: {}", config.playout_delay);
    SPDLOG_INFO("  Timestamp Offset: {}", config.timestamp_offset);
    SPDLOG_INFO("  Is Source: {}", config.is_source ? "true" : "false");
    SPDLOG_INFO("  Is Fusion Connect: {}", config.is_fusion_connect ? "true" : "false");
}

// Helper function to add Netlink attributes
int addattr_l(struct nlmsghdr *n, size_t maxlen, int type, const void *data, size_t alen) {
    size_t len = RTA_LENGTH(alen);
    if (NLMSG_ALIGN(n->nlmsg_len) + RTA_ALIGN(len) > maxlen) {
        SPDLOG_ERROR("addattr_l: Buffer overflow, nlmsg_len={}, len={}, maxlen={}", n->nlmsg_len, len, maxlen);
        return -1;
    }
    struct rtattr *rta = (struct rtattr *)(((char *)n) + NLMSG_ALIGN(n->nlmsg_len));
    rta->rta_type = type;
    rta->rta_len = len;
    if (alen && data) {
        memcpy(RTA_DATA(rta), data, alen);
    }
    n->nlmsg_len = NLMSG_ALIGN(n->nlmsg_len) + RTA_ALIGN(len);
    return 0;
}

// Helper function to get system IP address
std::string get_system_ip() {
    struct ifaddrs *ifaddr, *ifa;
    char addr_str[INET_ADDRSTRLEN] = {0};

    if (getifaddrs(&ifaddr) == -1) {
        SPDLOG_ERROR("Failed to get interface addresses: {}", strerror(errno));
        return "";
    }

    for (ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
        if (!ifa->ifa_addr || ifa->ifa_addr->sa_family != AF_INET) {
            continue;
        }

        // Skip loopback interface
        if (strcmp(ifa->ifa_name, "lo") == 0) {
            continue;
        }

        struct sockaddr_in *sa = (struct sockaddr_in *)ifa->ifa_addr;
        if (inet_ntop(AF_INET, &sa->sin_addr, addr_str, sizeof(addr_str))) {
            freeifaddrs(ifaddr);
            return std::string(addr_str);
        }
    }

    freeifaddrs(ifaddr);
    SPDLOG_ERROR("No valid IPv4 address found on non-loopback interfaces");
    return "";
}

class NetlinkClient {
private:
    int socket_fd;
    struct sockaddr_nl src_addr, dst_addr;

public:
    NetlinkClient() : socket_fd(-1) {
        socket_fd = socket(AF_NETLINK, SOCK_RAW, NETLINK_USERSOCK);
        if (socket_fd < 0) {
            SPDLOG_ERROR("Failed to create netlink socket: {}", strerror(errno));
            return;
        }

        src_addr = { .nl_family = AF_NETLINK, .nl_pad = 0, .nl_pid = static_cast<uint32_t>(getpid()), .nl_groups = 0 };
        if (bind(socket_fd, (struct sockaddr*)&src_addr, sizeof(src_addr)) < 0) {
            SPDLOG_ERROR("Failed to bind netlink socket: {}", strerror(errno));
            close(socket_fd);
            socket_fd = -1;
            return;
        }

        dst_addr = { .nl_family = AF_NETLINK, .nl_pad = 0, .nl_pid = 0, .nl_groups = 0 };
    }

    ~NetlinkClient() {
        if (socket_fd >= 0) {
            close(socket_fd);
        }
    }

    bool is_valid() const { return socket_fd >= 0; }

    bool send_message(uint32_t cmd, void* data, uint32_t data_size, struct fusion_cn_ctrl_msg* reply) {
        struct nlmsghdr nlh = { .nlmsg_len = NLMSG_LENGTH(sizeof(fusion_cn_ctrl_msg) + data_size), .nlmsg_type = 0, .nlmsg_flags = NLM_F_REQUEST, .nlmsg_seq = 0, .nlmsg_pid = static_cast<uint32_t>(getpid()) };
        struct fusion_cn_ctrl_msg msg = { .cmd = cmd, .err = 0, .data_size = data_size, .data = data, .pid = getpid() };
        struct iovec iov[2] = {
            { .iov_base = &nlh, .iov_len = sizeof(nlh) },
            { .iov_base = &msg, .iov_len = sizeof(msg) }
        };
        struct msghdr netlink_msg = { .msg_name = &dst_addr, .msg_namelen = sizeof(dst_addr), .msg_iov = iov, .msg_iovlen = 2, .msg_control = nullptr, .msg_controllen = 0, .msg_flags = 0 };

        if (sendmsg(socket_fd, &netlink_msg, 0) < 0) {
            SPDLOG_ERROR("Failed to send netlink message: {}", strerror(errno));
            return false;
        }

        char buf[4096];
        struct iovec iov_reply = { .iov_base = buf, .iov_len = sizeof(buf) };
        netlink_msg = { .msg_name = &dst_addr, .msg_namelen = sizeof(dst_addr), .msg_iov = &iov_reply, .msg_iovlen = 1, .msg_control = nullptr, .msg_controllen = 0, .msg_flags = 0 };

        ssize_t len = recvmsg(socket_fd, &netlink_msg, 0);
        if (len < 0) {
            SPDLOG_ERROR("Failed to receive netlink response: {}", strerror(errno));
            return false;
        }

        struct nlmsghdr* nlh_reply = (struct nlmsghdr*)buf;
        if (NLMSG_OK(nlh_reply, len) && nlh_reply->nlmsg_type != NLMSG_ERROR) {
            struct fusion_cn_ctrl_msg* reply_msg = (struct fusion_cn_ctrl_msg*)NLMSG_DATA(nlh_reply);
            *reply = *reply_msg;
            if (reply_msg->data_size > 0) {
                reply->data = malloc(reply_msg->data_size);
                if (!reply->data) {
                    SPDLOG_ERROR("Failed to allocate memory for reply data");
                    return false;
                }
                memcpy(reply->data, (char*)reply_msg + sizeof(*reply_msg), reply_msg->data_size);
            }
            return true;
        }

        SPDLOG_ERROR("Received invalid netlink response");
        return false;
    }
};

// Callback for curl to write response data
size_t curl_write_callback(void* contents, size_t size, size_t nmemb, std::string* output) {
    size_t total_size = size * nmemb;
    output->append((char*)contents, total_size);
    return total_size;
}

// Fetch device name and system IP via curl
std::string get_device_id(std::string& system_ip) {
    if (system_ip.empty()) {
        SPDLOG_ERROR("System IP is not set");
        return "";
    }

    CURL* curl = curl_easy_init();
    if (!curl) {
        SPDLOG_ERROR("Failed to initialize curl");
        return "";
    }

    std::string url = "http://" + system_ip + ":9090/device";
    std::string response;
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        SPDLOG_ERROR("curl request failed for {}: {}", url, curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        return "";
    }

    curl_easy_cleanup(curl);

    // Parse JSON response
    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(response, root)) {
        SPDLOG_ERROR("Failed to parse device response JSON: {}", response);
        return "";
    }

    if (!root.isMember("id") || !root["id"].isString()) {
        SPDLOG_ERROR("Missing or invalid id in device response");
        return "";
    }
    std::string device_id = root["id"].asString();

    if (!root.isMember("address") || !root["address"].isString()) {
        SPDLOG_ERROR("Missing or invalid address in device response");
        return "";
    }
    system_ip = root["address"].asString();

    return device_id;
}

// Query IP address for a device UID via curl
std::string query_device_ip(const std::string& device_uid, const std::string& system_ip) {
    if (system_ip.empty()) {
        SPDLOG_ERROR("System IP is not set");
        return "";
    }

    CURL* curl = curl_easy_init();
    if (!curl) {
        SPDLOG_ERROR("Failed to initialize curl for device IP query");
        return "";
    }

    std::string url = "http://" + system_ip + ":8080/devices";
    std::string response;
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        SPDLOG_ERROR("curl request failed for {}: {}", url, curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        return "";
    }

    curl_easy_cleanup(curl);

    SPDLOG_DEBUG("query_device_ip:{}", response);

    // Parse JSON array
    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(response, root) || !root.isArray()) {
        SPDLOG_ERROR("Failed to parse devices response JSON or not an array: {}", response);
        return "";
    }

    for (const auto& device : root) {
        if (device.isMember("id") && device["id"].isString() &&
            device["id"].asString() == device_uid &&
            device.isMember("address") && device["address"].isString()) {
            return device["address"].asString();
        }
    }

    SPDLOG_ERROR("Device UID {} not found in devices response", device_uid);
    return "";
}

class FusionConnectClient : public bosepro::Module {
public:
    FusionConnectClient(const bosepro::BlockConfiguration &configuration);
    virtual ~FusionConnectClient() = default;

    virtual void process();

private:
    NetlinkClient client;
    uint8_t ptp_synchronized;
    bool mgr_started;
    std::string device_id;
    std::string system_ip;
    std::map<std::string, fusion_cn_stream_config> fusion_connect_stream_map;
    std::map<std::string, fusion_cn_stream_config> aes67_stream_map;
    std::map<std::string, bool> pending_streams;
    std::string network_interface;
    SAPAnnouncer sap_announcer;
    uint32_t announce_counter;

    std::string audio_streams_update;

    int create_stream(fusion_cn_stream_config& config);
    int remove_stream(uint64_t stream_handle);
    void join_multicast_group(uint32_t multicast_ip);
    void audio_streams_update_func();

    MODULE_DECLARE(FusionConnectClient);
};

MODULE_REGISTER(FusionConnectClient, "fusion_connect_client");

FusionConnectClient::FusionConnectClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration), ptp_synchronized(0), mgr_started(false), device_id(""),
      network_interface("eth0"), sap_announcer(get_system_ip()), announce_counter(0) {
    system_ip = get_system_ip();
    if (system_ip.empty()) {
        SPDLOG_ERROR("Failed to initialize: No valid system IP found");
        return;
    }

    if (!client.is_valid()) {
        SPDLOG_ERROR("Failed to initialize netlink client");
        return;
    }

    assign_parameter("audio_streams_update", &audio_streams_update, 
                     POST_FUNCTION_SCALAR(audio_streams_update_func));
}

int FusionConnectClient::create_stream(fusion_cn_stream_config& config) {
    struct fusion_cn_ctrl_msg reply = { .cmd = 0, .err = 0, .data_size = 0, .data = nullptr, .pid = 0 };

    dump_fusion_cn_stream_config(config);

    config.stream_handle = 0;
    if (!client.send_message(FUSION_CN_CTRL_CMD_ADD_STREAM, &config, sizeof(config), &reply)) {
        SPDLOG_ERROR("Failed to send Add RTP Stream command for stream_name={}", config.stream_name);
        return -1;
    }

    if (reply.err != 0 && reply.err != -EEXIST) {
        SPDLOG_ERROR("Add RTP Stream: Failed for stream_name={}, err={}", config.stream_name, reply.err);
        return reply.err;
    }

    if (reply.data_size != sizeof(uint64_t) || !reply.data) {
        SPDLOG_ERROR("Add RTP Stream: Invalid reply for stream_name={}, data_size={}, expected {}, data={}", 
                     config.stream_name, reply.data_size, sizeof(uint64_t), reply.data ? "present" : "null");
        return -1;
    }

    config.stream_handle = *(uint64_t*)reply.data;
    SPDLOG_DEBUG("Add RTP Stream: Success for stream_name={}, new_handle={} {}", 
                 config.stream_name, static_cast<uint64_t>(config.stream_handle), 
                 reply.err == -EEXIST ? "(already exists)" : "");

    if (reply.data) {
        free(reply.data);
    }

    return 0;
}

int FusionConnectClient::remove_stream(uint64_t stream_handle) {
    struct fusion_cn_ctrl_msg reply = { .cmd = 0, .err = 0, .data_size = 0, .data = nullptr, .pid = 0 };

    if (!client.send_message(FUSION_CN_CTRL_CMD_REMOVE_STREAM, &stream_handle, sizeof(stream_handle), &reply)) {
        SPDLOG_ERROR("Failed to send Remove RTP Stream command for stream_handle={}", stream_handle);
        return -1;
    }

    if (reply.err != 0) {
        SPDLOG_ERROR("Remove RTP Stream: Failed for stream_handle={}, err={}", stream_handle, reply.err);
        return reply.err;
    }

    SPDLOG_DEBUG("Remove RTP Stream: Success for stream_handle={}", stream_handle);

    if (reply.data) {
        free(reply.data);
    }

    return 0;
}

void FusionConnectClient::join_multicast_group(uint32_t multicast_ip) {
    struct {
        struct nlmsghdr n;
        struct ifaddrmsg ifa;
        char buf[256];
    } req = {
        .n = { .nlmsg_len = NLMSG_LENGTH(sizeof(struct ifaddrmsg)), .nlmsg_type = RTM_NEWADDR, .nlmsg_flags = NLM_F_REQUEST | NLM_F_CREATE | NLM_F_EXCL, .nlmsg_seq = 0, .nlmsg_pid = static_cast<uint32_t>(getpid()) },
        .ifa = { .ifa_family = AF_INET, .ifa_prefixlen = 32, .ifa_flags = 0, .ifa_scope = 0, .ifa_index = 0 },
        .buf = {0}
    };
    struct sockaddr_nl nladdr = { .nl_family = AF_NETLINK, .nl_pad = 0, .nl_pid = 0, .nl_groups = 0 };
    int sock = -1;

    int ifindex = if_nametoindex(network_interface.c_str());
    if (!ifindex) {
        SPDLOG_ERROR("Failed to get interface index for {}: {}", network_interface, strerror(errno));
        return;
    }
    req.ifa.ifa_index = ifindex;

    struct in_addr addr;
    addr.s_addr = multicast_ip;
    uint32_t ifa_flags = IFA_F_MCAUTOJOIN;
    if (addattr_l(&req.n, sizeof(req), IFA_LOCAL, &addr, sizeof(addr)) < 0 ||
        addattr_l(&req.n, sizeof(req), IFA_ADDRESS, &addr, sizeof(addr)) < 0 ||
        addattr_l(&req.n, sizeof(req), IFA_FLAGS, &ifa_flags, sizeof(ifa_flags)) < 0) {
        SPDLOG_ERROR("Failed to add attributes for IGMP join");
        return;
    }

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0) {
        SPDLOG_ERROR("Failed to create netlink socket for IGMP: {}", strerror(errno));
        return;
    }

    SPDLOG_DEBUG("Joining multicast group {} on interface {}", ipToString(multicast_ip), network_interface);

    if (sendto(sock, &req, req.n.nlmsg_len, 0, (struct sockaddr*)&nladdr, sizeof(nladdr)) < 0) {
        SPDLOG_ERROR("Failed to send netlink message for IGMP join: {}", strerror(errno));
        close(sock);
        return;
    }

    close(sock);
    SPDLOG_INFO("Successfully joined multicast group {} on interface {}", ipToString(multicast_ip), network_interface);
}

void FusionConnectClient::audio_streams_update_func() {
    if (audio_streams_update.empty()) {
        SPDLOG_DEBUG("audio_streams_update is empty, exiting");
        return;
    }

    SPDLOG_DEBUG("Received audio_streams_update: {}", audio_streams_update);

    if (device_id.empty()) {
        device_id = get_device_id(system_ip);
        if (!device_id.empty()) {
            SPDLOG_INFO("Initialized device_id: {}, system_ip: {}", device_id, system_ip);
        } else {
            SPDLOG_ERROR("Failed to get device_id after audio_streams update!");
            return;
        }
    }

    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(audio_streams_update, root) || !root.isArray()) {
        SPDLOG_ERROR("Failed to parse audio_streams_update JSON or not an array: {}", audio_streams_update);
        return;
    }

    std::set<std::string> json_stream_names;

    for (const auto& stream : root) {
        if (!stream.isObject()) {
            SPDLOG_ERROR("Invalid stream object in audio_streams array");
            continue;
        }

        if (!stream.isMember("source_device_uid") && !stream.isMember("dest_device_uid")) {
            SPDLOG_ERROR("Missing device_uid in stream");
            continue;
        }

        std::string source_device_uid = stream.isMember("source_device_uid") && stream["source_device_uid"].isString()
            ? stream["source_device_uid"].asString() : "";
        std::string dest_device_uid = stream.isMember("dest_device_uid") && stream["dest_device_uid"].isString()
            ? stream["dest_device_uid"].asString() : "";
        if (source_device_uid != device_id && dest_device_uid != device_id) {
            continue;
        }

        if (!stream.isMember("properties") || !stream["properties"].isObject()) {
            SPDLOG_ERROR("Missing or invalid properties object in stream");
            continue;
        }
        const Json::Value& properties = stream["properties"];

        bool is_fusion_connect = false;
        if (properties.isMember("is_fusion_connect") && properties["is_fusion_connect"].isBool()) {
            is_fusion_connect = properties["is_fusion_connect"].asBool();
        } else {
            SPDLOG_ERROR("Missing or invalid is_fusion_connect in properties");
            continue;
        }

        if (is_fusion_connect) {
            if (!properties.isMember("channels") || !properties["channels"].isInt()) {
                SPDLOG_ERROR("Missing or invalid channels for Fusion Connect stream");
                continue;
            }
            unsigned int ch = properties["channels"].asInt();
            if (ch < 1 || ch > 64) {
                SPDLOG_ERROR("Channels out of range: {}", ch);
                continue;
            }

            if (!properties.isMember("source_port") || !properties["source_port"].isInt()) {
                SPDLOG_ERROR("Missing or invalid source_port for Fusion Connect stream");
                continue;
            }
            unsigned int port = properties["source_port"].asInt();
            if (port < 49152 || port > 65535) {
                SPDLOG_ERROR("Source port out of range: {}", port);
                continue;
            }

            bool create_source = source_device_uid == device_id;
            bool create_sink = dest_device_uid == device_id;

            if (!create_source && !create_sink) {
                continue;
            }

            fusion_cn_stream_config config = {};
            config.channels = ch;
            config.source_port = port;
            config.sample_rate = 48000;
            config.format = 15; // FLOAT_BE
            config.frames_per_packet = 48;
            config.dest_port = 5004;
            config.payload_type = 96;
            config.playout_delay = 1000000;
            config.timestamp_offset = 0;
            config.is_fusion_connect = true;

            if (create_source) {
                config.is_source = true;
                snprintf(config.stream_name, sizeof(config.stream_name), "FC_TX_%u", config.source_port);
                config.source_ip = inet_addr(system_ip.c_str());
                int retry = 0;
                config.dest_ip = INADDR_NONE;
                while (config.dest_ip == INADDR_NONE) {
                    if (retry++ >= 100) {
                        SPDLOG_ERROR("Failed to find {}'s connected sink stream in devices", config.stream_name);
                        break;
                    }

                    config.dest_ip = inet_addr(query_device_ip(dest_device_uid, system_ip).c_str());

                    usleep(500000);
                }
                if (config.source_ip == INADDR_NONE || config.dest_ip == INADDR_NONE) {
                    SPDLOG_ERROR("Invalid IP address for {}", config.stream_name);
                } else if (fusion_connect_stream_map.find(config.stream_name) == fusion_connect_stream_map.end()) {
                    fusion_connect_stream_map[config.stream_name] = config;
                    pending_streams[config.stream_name] = false;
                    SPDLOG_DEBUG("Added Fusion Connect source stream {} to pending", config.stream_name);
                    json_stream_names.insert(config.stream_name);
                }
            }

            if (create_sink) {
                config.is_source = false;
                snprintf(config.stream_name, sizeof(config.stream_name), "FC_RX_%u", config.source_port);
                int retry = 0;
                config.source_ip = INADDR_NONE;
                while (config.source_ip == INADDR_NONE) {
                    if (retry++ >= 100) {
                        SPDLOG_ERROR("Failed to find {}'s connected source stream in devices", config.stream_name);
                        break;
                    }

                    config.source_ip = inet_addr(query_device_ip(source_device_uid, system_ip).c_str());

                    usleep(500000);
                }
                config.dest_ip = inet_addr(system_ip.c_str());
                if (config.source_ip == INADDR_NONE || config.dest_ip == INADDR_NONE) {
                    SPDLOG_ERROR("Invalid IP address for {}", config.stream_name);
                } else if (fusion_connect_stream_map.find(config.stream_name) == fusion_connect_stream_map.end()) {
                    fusion_connect_stream_map[config.stream_name] = config;
                    pending_streams[config.stream_name] = false;
                    SPDLOG_DEBUG("Added Fusion Connect sink stream {} to pending", config.stream_name);
                    json_stream_names.insert(config.stream_name);
                }
            }
        } else {
            fusion_cn_stream_config config = {};
            if (!properties.isMember("stream_name") || !properties["stream_name"].isString()) {
                SPDLOG_ERROR("Missing or invalid stream_name for AES67 stream");
                continue;
            }
            std::string stream_name = "AES67_" + properties["stream_name"].asString();

            if (!properties.isMember("channels") || !properties["channels"].isInt()) {
                SPDLOG_ERROR("Missing or invalid channels for AES67 stream");
                continue;
            }
            unsigned int ch = properties["channels"].asInt();
            if (ch < 1 || ch > 64) {
                SPDLOG_ERROR("Channels out of range: {}", ch);
                continue;
            }

            if (!properties.isMember("dest_ip") || !properties["dest_ip"].isString()) {
                SPDLOG_ERROR("Missing or invalid dest_ip for AES67 stream");
                continue;
            }
            bool is_source = properties.isMember("is_source") && properties["is_source"].isBool() ? properties["is_source"].asBool() : false;

            strncpy(config.stream_name, stream_name.c_str(), sizeof(config.stream_name) - 1);
            config.stream_name[sizeof(config.stream_name) - 1] = '\0';
            config.dest_ip = inet_addr(properties["dest_ip"].asString().c_str());
            if (config.dest_ip == INADDR_NONE) {
                SPDLOG_ERROR("Invalid dest_ip: {}", properties["dest_ip"].asString());
                continue;
            }

            config.channels = ch;
            config.dest_port = 5004;
            config.source_port = 49152;
            config.sample_rate = 48000;
            config.format = 33; // S24_3BE
            config.frames_per_packet = 48;
            config.payload_type = 96;
            config.playout_delay = 0;
            config.timestamp_offset = 0;
            config.source_ip = inet_addr(system_ip.c_str());
            config.is_source = is_source;
            config.is_fusion_connect = is_fusion_connect;

            if (properties.isMember("source_port")) {
                config.source_port = properties["source_port"].asUInt();
            }

            if (properties.isMember("payload_type")) {
                config.payload_type = properties["payload_type"].asUInt();
                if (config.payload_type < 96 || config.payload_type > 127) {
                    config.payload_type = 96;
                }
            }

            if (properties.isMember("timestamp_offset")) {
                config.timestamp_offset = properties["timestamp_offset"].asUInt();
            }

            if (aes67_stream_map.find(stream_name) == aes67_stream_map.end()) {
                aes67_stream_map[stream_name] = config;
                pending_streams[stream_name] = false;
                SPDLOG_DEBUG("Added AES67 {} stream {} to pending", is_source ? "source" : "sink", stream_name);
            }
            json_stream_names.insert(stream_name);
        }
    }

    // Remove missing Fusion Connect streams
    auto fc_it = fusion_connect_stream_map.begin();
    while (fc_it != fusion_connect_stream_map.end()) {
        if (json_stream_names.find(fc_it->first) == json_stream_names.end()) {
            if (pending_streams[fc_it->first]) {
                if (remove_stream(fc_it->second.stream_handle) == 0) {
                    SPDLOG_DEBUG("Removed Fusion Connect stream with name {}", fc_it->first);
                } else {
                    SPDLOG_ERROR("Failed to remove Fusion Connect stream with name {}", fc_it->first);
                }
            }
            pending_streams.erase(fc_it->first);
            fc_it = fusion_connect_stream_map.erase(fc_it);
        } else {
            ++fc_it;
        }
    }

    // Remove missing AES67 streams
    auto aes67_it = aes67_stream_map.begin();
    while (aes67_it != aes67_stream_map.end()) {
        if (json_stream_names.find(aes67_it->first) == json_stream_names.end()) {
            if (pending_streams[aes67_it->first]) {
                if (aes67_it->second.is_source) {
                    sap_announcer.removeAnnouncement(aes67_it->first);
                }
                if (remove_stream(aes67_it->second.stream_handle) == 0) {
                    SPDLOG_DEBUG("Removed AES67 stream with name {}", aes67_it->first);
                } else {
                    SPDLOG_ERROR("Failed to remove AES67 stream with name {}", aes67_it->first);
                }
            }
            pending_streams.erase(aes67_it->first);
            aes67_it = aes67_stream_map.erase(aes67_it);
        } else {
            ++aes67_it;
        }
    }
}

void FusionConnectClient::process() {  
    if (!ptp_synchronized) {
        uint8_t sync = 1;
        struct fusion_cn_ctrl_msg reply = { .cmd = 0, .err = 0, .data_size = 0, .data = nullptr, .pid = 0 };
        if (client.send_message(FUSION_CN_CTRL_CMD_SET_PTP_SYNC, &sync, sizeof(sync), &reply)) {
            if (reply.err == 0) {
                ptp_synchronized = 1;
            } else {
                SPDLOG_ERROR("Failed to set ptp sync, err={}", reply.err);
            }
        } else {
            SPDLOG_DEBUG("Failed to send set ptp sync command (likely no driver)");
        }
        if (reply.data) {
            free(reply.data);
        }
    } 
    if (ptp_synchronized && !mgr_started) {
        struct fusion_cn_ctrl_msg reply = { .cmd = 0, .err = 0, .data_size = 0, .data = nullptr, .pid = 0 };
        if (client.send_message(FUSION_CN_CTRL_CMD_START_MANAGER, nullptr, 0, &reply)) {
            if (reply.err == -MGR_START_ERRNO_RUNNING) {
                mgr_started = true;
            } else if (reply.err == -MGR_START_ERRNO_PTP) {
                SPDLOG_DEBUG("PTP not yet sync'd");
            } else if (reply.err == MGR_START_OK) {
                mgr_started = true;
            }
        } else {
            SPDLOG_DEBUG("Failed to send start manager command (likely no driver)");
        }
        if (reply.data) {
            free(reply.data);
        }
    }

    if (ptp_synchronized && mgr_started) {
        for (auto& pair : fusion_connect_stream_map) {
            if (!pending_streams[pair.first]) {
                if (create_stream(pair.second) == 0) {
                    pending_streams[pair.first] = true;
                    SPDLOG_DEBUG("Created Fusion Connect stream {} in process loop", pair.first);
                    if (!pair.second.is_source) {
                        join_multicast_group(pair.second.dest_ip);
                    }
                } else {
                    SPDLOG_ERROR("Failed to create Fusion Connect stream {} in process loop, will retry", pair.first);
                }
            }
        }
        for (auto& pair : aes67_stream_map) {
            if (!pending_streams[pair.first]) {
                if (create_stream(pair.second) == 0) {
                    pending_streams[pair.first] = true;
                    SPDLOG_DEBUG("Created AES67 stream {} in process loop", pair.first);
                    if (!pair.second.is_source) {
                        join_multicast_group(pair.second.dest_ip);
                    } else {
                        sap_announcer.addAnnouncement(pair.first, pair.second.dest_ip, pair.second.channels,
                                                     pair.second.sample_rate, pair.second.format, pair.second.dest_port,
                                                     pair.second.payload_type, pair.second.stream_handle);
                    }
                } else {
                    SPDLOG_ERROR("Failed to create AES67 stream {} in process loop, will retry", pair.first);
                }
            }
        }
    }

    // SAP announcements every 30 seconds
    if (announce_counter++ % 30 == 0) {
        sap_announcer.announceAll();
    }
    // Handle deletion packets
    std::vector<std::string> to_delete;
    for (const auto& pair : sap_announcer.getAnnouncements()) {
        if (pair.second.is_deleted && pair.second.num_delete_pending > 0) {
            sap_announcer.sendAnnouncement(pair.second);
            to_delete.push_back(pair.first);
        }
    }
    for (const auto& stream_name : to_delete) {
        sap_announcer.handleDeletion(stream_name);
    }
}

} // namespace
