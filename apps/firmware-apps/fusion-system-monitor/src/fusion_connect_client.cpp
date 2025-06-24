#include <bosepro/module.h>
#include <bosepro/periodic_task.h>
#include <cstdint>
#include <string>
#include <sstream>
#include <cstring>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <vector>
#include <map>
#include <curl/curl.h>
#include <json/json.h>

namespace {

enum fusion_cn_ctrl_cmd {
    FUSION_CN_CTRL_CMD_NONE = 0,
    FUSION_CN_CTRL_CMD_START_MANAGER,
    FUSION_CN_CTRL_CMD_STOP_MANAGER,
    FUSION_CN_CTRL_CMD_ADD_STREAM,
    FUSION_CN_CTRL_CMD_REMOVE_STREAM
};

struct fusion_cn_ctrl_msg {
    uint32_t cmd;
    int32_t err;
    uint32_t data_size;
    void *data;
    uint32_t pid;
};

struct fusion_cn_stream_config {
    uint64_t stream_handle;
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
void dumpFusionCnStreamConfig(const fusion_cn_stream_config& config) {
    std::cout << "Fusion CN Stream Config Dump:" << std::endl;
    std::cout << "  Stream Handle: " << config.stream_handle << std::endl;
    std::cout << "  Sample Rate: " << config.sample_rate << " Hz" << std::endl;
    std::cout << "  Format: " << config.format << std::endl;
    std::cout << "  Channels: " << static_cast<int>(config.channels) << std::endl;
    std::cout << "  Frames per Packet: " << config.frames_per_packet << std::endl;
    std::cout << "  Dest IP: " << ipToString(config.dest_ip) << std::endl;
    std::cout << "  Dest Port: " << config.dest_port << std::endl;
    std::cout << "  Source Port: " << config.source_port << std::endl;
    std::cout << "  Source IP: " << ipToString(config.source_ip) << std::endl;
    std::cout << "  Payload Type: " << static_cast<int>(config.payload_type) << std::endl;
    std::cout << "  Playout Delay: " << config.playout_delay << std::endl;
    std::cout << "  Timestamp Offset: " << config.timestamp_offset << std::endl;
    std::cout << "  Is Source: " << (config.is_source ? "true" : "false") << std::endl;
    std::cout << "  Is Fusion Connect: " << (config.is_fusion_connect ? "true" : "false") << std::endl;
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

        memset(&src_addr, 0, sizeof(src_addr));
        src_addr.nl_family = AF_NETLINK;
        src_addr.nl_pid = getpid();
        if (bind(socket_fd, (struct sockaddr*)&src_addr, sizeof(src_addr)) < 0) {
            SPDLOG_ERROR("Failed to bind netlink socket: {}", strerror(errno));
            close(socket_fd);
            socket_fd = -1;
            return;
        }

        memset(&dst_addr, 0, sizeof(dst_addr));
        dst_addr.nl_family = AF_NETLINK;
        dst_addr.nl_pid = 0;
        dst_addr.nl_groups = 0;
    }

    ~NetlinkClient() {
        if (socket_fd >= 0) {
            close(socket_fd);
        }
    }

    bool is_valid() const { return socket_fd >= 0; }

    bool send_message(uint32_t cmd, void* data, uint32_t data_size, struct fusion_cn_ctrl_msg* reply) {
        struct nlmsghdr nlh;
        struct fusion_cn_ctrl_msg msg;
        struct iovec iov[2];
        struct msghdr netlink_msg;

        memset(&nlh, 0, sizeof(nlh));
        memset(&msg, 0, sizeof(msg));
        memset(&netlink_msg, 0, sizeof(netlink_msg));

        msg.cmd = cmd;
        msg.err = 0;
        msg.data_size = data_size;
        msg.data = data;
        msg.pid = getpid();

        nlh.nlmsg_len = NLMSG_LENGTH(sizeof(msg) + data_size);
        nlh.nlmsg_type = 0;
        nlh.nlmsg_flags = NLM_F_REQUEST;
        nlh.nlmsg_seq = 0;
        nlh.nlmsg_pid = getpid();

        iov[0].iov_base = &nlh;
        iov[0].iov_len = sizeof(nlh);
        iov[1].iov_base = &msg;
        iov[1].iov_len = sizeof(msg);

        netlink_msg.msg_name = &dst_addr;
        netlink_msg.msg_namelen = sizeof(dst_addr);
        netlink_msg.msg_iov = iov;
        netlink_msg.msg_iovlen = 2;

        if (sendmsg(socket_fd, &netlink_msg, 0) < 0) {
            SPDLOG_ERROR("Failed to send netlink message: {}", strerror(errno));
            return false;
        }

        char buf[4096];
        struct iovec iov_reply = { buf, sizeof(buf) };
        netlink_msg.msg_iov = &iov_reply;
        netlink_msg.msg_iovlen = 1;

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
std::string get_device_name(std::string& system_ip) {
    CURL* curl = curl_easy_init();
    if (!curl) {
        SPDLOG_ERROR("Failed to initialize curl");
        system_ip = "192.168.2.1";
        return "Fusion-Var";
    }

    std::string response;
    curl_easy_setopt(curl, CURLOPT_URL, "http://192.168.2.100:9090/device");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        SPDLOG_ERROR("curl request failed: {}", curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        system_ip = "192.168.2.1";
        return "Fusion-Var";
    }

    curl_easy_cleanup(curl);

    // Parse JSON response
    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(response, root)) {
        SPDLOG_ERROR("Failed to parse device response JSON: {}", response);
        system_ip = "192.168.2.1";
        return "Fusion-Var";
    }

    if (!root.isMember("name") || !root["name"].isString()) {
        SPDLOG_ERROR("Missing or invalid name in device response");
        system_ip = "192.168.2.1";
        return "Fusion-Var";
    }
    std::string device_name = root["name"].asString();

    if (!root.isMember("address") || !root["address"].isString()) {
        SPDLOG_ERROR("Missing or invalid address in device response");
        system_ip = "192.168.2.1";
        return device_name;
    }
    system_ip = root["address"].asString();

    return device_name;
}

// Query IP address for a device UID via curl
std::string query_device_ip(const std::string& device_uid) {
    CURL* curl = curl_easy_init();
    if (!curl) {
        SPDLOG_ERROR("Failed to initialize curl for device IP query");
        return "192.168.2.1";
    }

    std::string response;
    curl_easy_setopt(curl, CURLOPT_URL, "http://192.168.2.100:8080/devices");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        SPDLOG_ERROR("curl request failed for device IP query: {}", curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        return "192.168.2.1";
    }

    curl_easy_cleanup(curl);

    // Parse JSON array
    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(response, root) || !root.isArray()) {
        SPDLOG_ERROR("Failed to parse devices response JSON or not an array: {}", response);
        return "192.168.2.1";
    }

    for (const auto& device : root) {
        if (device.isMember("name") && device["name"].isString() &&
            device["name"].asString() == device_uid &&
            device.isMember("address") && device["address"].isString()) {
            return device["address"].asString();
        }
    }

    SPDLOG_ERROR("Device UID {} not found in devices response", device_uid);
    return "192.168.2.1";
}

class FusionConnectClient : public bosepro::Module {
public:
    FusionConnectClient(const bosepro::BlockConfiguration &configuration);
    virtual ~FusionConnectClient() = default;

    virtual void process();

private:
    NetlinkClient client;
    std::string device_name;
    std::string system_ip;
    std::map<std::string, fusion_cn_stream_config> aes67_stream_map; // Map stream_handle string to config
    std::vector<fusion_cn_stream_config> fusion_connect_stream_configs;

    std::string audio_streams_update; // String input for JSON parsing

    void create_stream(fusion_cn_stream_config& config);
    void audio_streams_update_func();

    MODULE_DECLARE(FusionConnectClient);
};

MODULE_REGISTER(FusionConnectClient, "fusion_connect_client");

FusionConnectClient::FusionConnectClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration) {
    system_ip = "192.168.2.1"; // Default
    device_name = get_device_name(system_ip);

    if (!client.is_valid()) {
        SPDLOG_ERROR("Failed to initialize netlink client");
        return;
    }

    struct fusion_cn_ctrl_msg reply = {0, 0, 0, nullptr, 0};
    if (client.send_message(FUSION_CN_CTRL_CMD_START_MANAGER, nullptr, 0, &reply)) {
        if (reply.err != 0) {
            SPDLOG_ERROR("Failed to start manager, err={}", reply.err);
        }
    } else {
        SPDLOG_ERROR("Failed to send start manager command");
    }
    if (reply.data) {
        free(reply.data);
    }

    assign_parameter("audio_streams_update", &audio_streams_update, 
                     POST_FUNCTION_SCALAR(audio_streams_update_func));
}

void FusionConnectClient::create_stream(fusion_cn_stream_config& config) {
    struct fusion_cn_ctrl_msg reply = {0, 0, 0, nullptr, 0};

    dumpFusionCnStreamConfig(config);

    if (client.send_message(FUSION_CN_CTRL_CMD_ADD_STREAM, &config, sizeof(config), &reply)) {
        if (reply.err == 0 && reply.data_size == sizeof(uint64_t) && reply.data) {
            uint64_t new_handle = *(uint64_t*)reply.data;
            config.stream_handle = new_handle;
            SPDLOG_DEBUG("Add RTP Stream: Success, new_handle={}", new_handle);
        } else {
            SPDLOG_ERROR("Add RTP Stream: Failed, err={}", reply.err);
        }
    } else {
        SPDLOG_ERROR("Failed to send Add RTP Stream command");
    }
    if (reply.data) {
        free(reply.data);
    }
}

void FusionConnectClient::audio_streams_update_func() {
    if (audio_streams_update.empty()) {
        SPDLOG_DEBUG("audio_streams_update is empty, exiting");
        return; // Silently exit if input is empty
    }

    SPDLOG_DEBUG("Received audio_streams_update: {}", audio_streams_update);

    // Parse JSON string
    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(audio_streams_update, root)) {
        SPDLOG_ERROR("Failed to parse audio_streams_update JSON: {}", audio_streams_update);
        return;
    }

    // Parse top-level fields
    std::string source_device_uid = root.isMember("source_device_uid") && root["source_device_uid"].isString()
        ? root["source_device_uid"].asString() : "";
    std::string dest_device_uid = root.isMember("dest_device_uid") && root["dest_device_uid"].isString()
        ? root["dest_device_uid"].asString() : "";
    SPDLOG_DEBUG("Parsed source_device_uid: {}, dest_device_uid: {}, device_name: {}", source_device_uid, dest_device_uid, device_name);
    if (source_device_uid != device_name && dest_device_uid != device_name) {
        SPDLOG_DEBUG("Stream not relevant to device {}", device_name);
        return;
    }

    // Parse properties
    if (!root.isMember("properties") || !root["properties"].isObject()) {
        SPDLOG_ERROR("Missing or invalid properties object");
        return;
    }
    const Json::Value& properties = root["properties"];

    // Validate required properties
    bool is_fusion_connect = false;
    if (properties.isMember("is_fusion_connect") && properties["is_fusion_connect"].isBool()) {
        is_fusion_connect = properties["is_fusion_connect"].asBool();
    } else {
        SPDLOG_ERROR("Missing or invalid is_fusion_connect in properties");
        return;
    }

    bool is_source = false;
    if (properties.isMember("is_source") && properties["is_source"].isBool()) {
        is_source = properties["is_source"].asBool();
    } else {
        SPDLOG_ERROR("Missing or invalid is_source in properties");
        return;
    }

    fusion_cn_stream_config config = {};
    config.is_source = is_source;
    config.is_fusion_connect = is_fusion_connect;

    if (is_fusion_connect) {
        // Fusion Connect stream
        if (properties.isMember("channels") && properties["channels"].isInt()) {
            unsigned int ch = properties["channels"].asInt();
            config.channels = (ch >= 1 && ch <= 64) ? ch : 1;
        } else {
            config.channels = 1; // Demo default
        }

        if (!properties.isMember("source_port") || !properties["source_port"].isInt()) {
            SPDLOG_ERROR("Missing or invalid source_port for Fusion Connect stream");
            return;
        }
        unsigned int port = properties["source_port"].asInt();
        config.source_port = (port >= 49152 && port <= 65535) ? port : 0;
        if (config.source_port == 0) {
            SPDLOG_ERROR("Source port out of range: {}", port);
            return;
        }

        // Apply Fusion Connect defaults
        config.sample_rate = 48000;
        config.format = 15; // FLOAT_BE
        config.frames_per_packet = 16;
        config.dest_port = 5004;
        config.payload_type = 96;
        config.playout_delay = 2000000;
        config.timestamp_offset = 0;

        // Set IPs
        if (is_source) {
            config.source_ip = inet_addr(system_ip.c_str());
            config.dest_ip = inet_addr(query_device_ip(dest_device_uid).c_str());
        } else {
            config.source_ip = inet_addr(query_device_ip(source_device_uid).c_str());
            config.dest_ip = inet_addr(system_ip.c_str());
        }
        if (config.source_ip == INADDR_NONE || config.dest_ip == INADDR_NONE) {
            SPDLOG_ERROR("Invalid IP address for Fusion Connect stream");
            return;
        }

        // Match stream
        auto stream_it = std::find_if(fusion_connect_stream_configs.begin(), fusion_connect_stream_configs.end(),
            [&](const auto& cfg) {
                return cfg.source_port == config.source_port && cfg.channels == config.channels;
            });

        if (stream_it != fusion_connect_stream_configs.end()) {
            config = *stream_it;
            config.is_source = is_source;
            config.is_fusion_connect = is_fusion_connect;
        }

        create_stream(config);
        if (config.stream_handle != 0) {
            if (stream_it == fusion_connect_stream_configs.end()) {
                fusion_connect_stream_configs.push_back(config);
            } else {
                *stream_it = config;
            }
        }
    } else {
        // AES67 stream
        if (!properties.isMember("stream_handle")) {
            SPDLOG_ERROR("Missing stream_handle for AES67 stream");
            return;
        }
        std::string stream_handle_str = properties["stream_handle"].asString();

        SPDLOG_INFO("stream_handle={}", properties["stream_handle"].asUInt64());

        if (!properties.isMember("dest_ip") || !properties["dest_ip"].isString()) {
            SPDLOG_ERROR("Missing or invalid dest_ip for AES67 stream");
            return;
        }
        config.dest_ip = inet_addr(properties["dest_ip"].asString().c_str());
        if (config.dest_ip == INADDR_NONE) {
            SPDLOG_ERROR("Invalid dest_ip: {}", properties["dest_ip"].asString());
            return;
        }

        if (is_source && (!properties.isMember("source_port") || !properties["source_port"].isInt())) {
            SPDLOG_ERROR("Missing or invalid source_port for AES67 stream");
            return;
        }

        config.stream_handle = properties["stream_handle"].asUInt64();
        config.channels = 1; // Demo default
        config.dest_port = 5004; // Demo default
        if (is_source) { 
            config.source_port = properties["source_port"].isInt();
        } else {
            config.source_port = 49152;
        }
        config.sample_rate = 48000; // Demo default
        config.format = 33; // S24_3BE (demo default)
        config.frames_per_packet = 48; // Demo default
        config.payload_type = 97; // Demo default
        config.playout_delay = 2000000; // Demo default
        config.timestamp_offset = 0; // Demo default
        config.source_ip = inet_addr(system_ip.c_str());
        config.is_source = is_source;
        config.is_fusion_connect = is_fusion_connect;

        // Match stream using the string key from JSON
        auto stream_it = aes67_stream_map.find(stream_handle_str);
        if (stream_it != aes67_stream_map.end()) {
            // Existing stream: use the stored config, including its uint64_t stream_handle
            config = stream_it->second;
            config.dest_ip = inet_addr(properties["dest_ip"].asString().c_str());
            config.is_source = is_source;
        }

        create_stream(config);
        if (config.stream_handle != 0) {
            aes67_stream_map[stream_handle_str] = config;
        }
    }
}

void FusionConnectClient::process() {
    // will do sap announcements
}

} // namespace
