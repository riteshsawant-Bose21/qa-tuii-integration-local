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

class NetlinkClient {
private:
    int sock_fd;
    struct sockaddr_nl src_addr, dst_addr;

public:
    NetlinkClient() : sock_fd(-1) {
        sock_fd = socket(AF_NETLINK, SOCK_RAW, NETLINK_USERSOCK);
        if (sock_fd < 0) {
            SPDLOG_ERROR("Failed to create netlink socket: {}", strerror(errno));
            return;
        }

        memset(&src_addr, 0, sizeof(src_addr));
        src_addr.nl_family = AF_NETLINK;
        src_addr.nl_pid = getpid();
        if (bind(sock_fd, (struct sockaddr*)&src_addr, sizeof(src_addr)) < 0) {
            SPDLOG_ERROR("Failed to bind netlink socket: {}", strerror(errno));
            close(sock_fd);
            sock_fd = -1;
            return;
        }

        memset(&dst_addr, 0, sizeof(dst_addr));
        dst_addr.nl_family = AF_NETLINK;
        dst_addr.nl_pid = 0;
        dst_addr.nl_groups = 0;
    }

    ~NetlinkClient() {
        if (sock_fd >= 0) {
            close(sock_fd);
        }
    }

    bool is_valid() const { return sock_fd >= 0; }

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

        if (sendmsg(sock_fd, &netlink_msg, 0) < 0) {
            SPDLOG_ERROR("Failed to send netlink message: {}", strerror(errno));
            return false;
        }

        char buf[4096];
        struct iovec iov_reply = { buf, sizeof(buf) };
        netlink_msg.msg_iov = &iov_reply;
        netlink_msg.msg_iovlen = 1;

        ssize_t len = recvmsg(sock_fd, &netlink_msg, 0);
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

int32_t pcm_format_str_to_int(const std::string& str) {
    if (str == "L16") return 3;
    if (str == "L24") return 33;
    SPDLOG_ERROR("Invalid PCM format: {}", str);
    return 33; // Default to L24
}

// Placeholder for curl-based device ID retrieval
std::string get_device_id() {
    // TODO: Implement curl command to fetch device ID
    return "Fusion-Var";
}

// Placeholder for curl-based IP query
std::string query_device_ip(const std::string& device_id) {
    // TODO: Implement curl command to query IP for device_id
    (void)device_id; // Suppress unused parameter warning
    return "192.168.2.100";
}

class FusionConnectClient : public bosepro::Module {
public:
    FusionConnectClient(const bosepro::BlockConfiguration &configuration);
    virtual ~FusionConnectClient() = default;

    virtual void process() {}

private:
    NetlinkClient client;
    std::string device_id;
    std::string system_ip;
    std::map<uint64_t, std::string> aes67_descriptions; // Map stream_handle to description

    std::vector<struct fusion_cn_stream_config> aes67_stream_configs;
    std::vector<struct fusion_cn_stream_config> fusion_connect_stream_configs;

    std::string aes67_stream;
    std::string fusion_connect_stream;
    std::string sdp;

    void create_stream(struct fusion_cn_stream_config& config);
    void aes67_func();
    void fusion_connect_func();
    void sdp_func();

    MODULE_DECLARE(FusionConnectClient);
};

MODULE_REGISTER(FusionConnectClient, "fusion_connect_client");

FusionConnectClient::FusionConnectClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration) {
    device_id = get_device_id();
    system_ip = query_device_ip(device_id);

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

    assign_parameter("aes67_streams", &aes67_stream, 
                     POST_FUNCTION_SCALAR(aes67_func));
    assign_parameter("device_connections", &fusion_connect_stream, 
                     POST_FUNCTION_SCALAR(fusion_connect_func));
    assign_parameter("sessions", &sdp, 
                     POST_FUNCTION_SCALAR(sdp_func));
}

void FusionConnectClient::create_stream(struct fusion_cn_stream_config& config) {
    struct fusion_cn_ctrl_msg reply = {0, 0, 0, nullptr, 0};
    if (client.send_message(FUSION_CN_CTRL_CMD_ADD_STREAM, &config, sizeof(config), &reply)) {
        if (reply.err == 0 && reply.data_size == sizeof(uint64_t) && reply.data) {
            uint64_t new_handle = *(uint64_t*)reply.data;
            config.stream_handle = new_handle;
            SPDLOG_DEBUG("Add RTP Stream: Success, new handle={}", new_handle);
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

void FusionConnectClient::aes67_func() {
    std::map<std::string, std::string> fields;
    std::istringstream iss(aes67_stream);
    std::string token;
    while (std::getline(iss, token, ',')) {
        size_t pos = token.find('=');
        if (pos == std::string::npos) continue;
        fields[token.substr(0, pos)] = token.substr(pos + 1);
    }

    auto it = fields.find("source_device");
    std::string source_device = it != fields.end() ? it->second : "";
    it = fields.find("destination_device");
    std::string destination_device = it != fields.end() ? it->second : "";
    if (source_device != device_id && destination_device != device_id) {
        SPDLOG_DEBUG("Stream not relevant to device {}", device_id);
        return;
    }

    it = fields.find("multicast_destination_ip");
    if (it == fields.end()) {
        SPDLOG_ERROR("Missing multicast_destination_ip");
        return;
    }
    uint32_t dest_ip = inet_addr(it->second.c_str());
    if (dest_ip == INADDR_NONE) {
        SPDLOG_ERROR("Invalid multicast_destination_ip: {}", it->second);
        return;
    }

    it = fields.find("channels");
    if (it == fields.end()) {
        SPDLOG_ERROR("Missing channels");
        return;
    }
    uint8_t channels;
    try {
        unsigned int ch = std::stoul(it->second);
        channels = (ch >= 1 && ch <= 64) ? ch : 0;
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid channels: {}", e.what());
        return;
    }
    if (channels == 0) {
        SPDLOG_ERROR("Channels out of range: {}", it->second);
        return;
    }

    it = fields.find("description");
    std::string description = it != fields.end() ? it->second : "";
    it = fields.find("direction");
    std::string direction = it != fields.end() ? it->second : "";
    if (direction != "TX" && direction != "RX") {
        SPDLOG_ERROR("Invalid direction: {}", direction);
        return;
    }

    // Match stream
    auto stream_it = aes67_stream_configs.end();
    for (auto it = aes67_stream_configs.begin(); it != aes67_stream_configs.end(); ++it) {
        auto desc_it = aes67_descriptions.find(it->stream_handle);
        if (desc_it != aes67_descriptions.end() && desc_it->second == description &&
            it->dest_ip == dest_ip && it->channels == channels) {
            stream_it = it;
            break;
        }
    }

    struct fusion_cn_stream_config config;
    if (stream_it != aes67_stream_configs.end()) {
        config = *stream_it;
    } else {
        config = {};
        config.dest_ip = dest_ip;
        config.channels = channels;
        config.is_source = (direction == "TX");
        config.is_fusion_connect = 0;
        aes67_stream_configs.push_back(config);
        stream_it = aes67_stream_configs.end() - 1;
    }

    // Store description
    aes67_descriptions[config.stream_handle] = description;

    // Defer creation until SDP provides remaining fields
    SPDLOG_DEBUG("Added/Updated AES67 stream config, awaiting SDP");
}

void FusionConnectClient::fusion_connect_func() {
    std::map<std::string, std::string> fields;
    std::istringstream iss(fusion_connect_stream);
    std::string token;
    while (std::getline(iss, token, ',')) {
        size_t pos = token.find('=');
        if (pos == std::string::npos) continue;
        fields[token.substr(0, pos)] = token.substr(pos + 1);
    }

    auto it = fields.find("source_device");
    std::string source_device = it != fields.end() ? it->second : "";
    it = fields.find("destination_device");
    std::string destination_device = it != fields.end() ? it->second : "";
    if (source_device != device_id && destination_device != device_id) {
        SPDLOG_DEBUG("Stream not relevant to device {}", device_id);
        return;
    }

    it = fields.find("source_port");
    if (it == fields.end()) {
        SPDLOG_ERROR("Missing source_port");
        return;
    }
    uint16_t source_port;
    try {
        unsigned int port = std::stoul(it->second);
        source_port = (port >= 49152 && port <= 65535) ? port : 0;
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid source_port: {}", e.what());
        return;
    }
    if (source_port == 0) {
        SPDLOG_ERROR("Source port out of range: {}", it->second);
        return;
    }

    it = fields.find("channels");
    if (it == fields.end()) {
        SPDLOG_ERROR("Missing channels");
        return;
    }
    uint8_t channels;
    try {
        unsigned int ch = std::stoul(it->second);
        channels = (ch >= 1 && ch <= 64) ? ch : 0;
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid channels: {}", e.what());
        return;
    }
    if (channels == 0) {
        SPDLOG_ERROR("Channels out of range: {}", it->second);
        return;
    }

    std::string dest_ip_str = destination_device.empty() ? "" : query_device_ip(destination_device);
    if (dest_ip_str.empty()) {
        SPDLOG_ERROR("Failed to query dest_ip for device {}", destination_device);
        return;
    }
    uint32_t dest_ip = inet_addr(dest_ip_str.c_str());
    if (dest_ip == INADDR_NONE) {
        SPDLOG_ERROR("Invalid dest_ip: {}", dest_ip_str);
        return;
    }

    // Match stream
    auto stream_it = std::find_if(fusion_connect_stream_configs.begin(), fusion_connect_stream_configs.end(),
        [&](const auto& cfg) {
            return cfg.source_port == source_port && cfg.channels == channels;
        });

    struct fusion_cn_stream_config config;
    if (stream_it != fusion_connect_stream_configs.end()) {
        config = *stream_it;
    } else {
        config = {};
        config.stream_handle = 0;
        config.sample_rate = 48000;
        config.format = 15; // FLOAT_BE
        config.channels = channels;
        config.frames_per_packet = 16;
        config.dest_ip = dest_ip;
        config.dest_port = 5004;
        config.source_port = source_port;
        config.source_ip = inet_addr(system_ip.c_str());
        config.payload_type = 96;
        config.playout_delay = 2000000;
        config.timestamp_offset = 0;
        config.is_source = (source_device == device_id);
        config.is_fusion_connect = 1;
    }

    create_stream(config);
    if (config.stream_handle != 0) {
        if (stream_it == fusion_connect_stream_configs.end()) {
            fusion_connect_stream_configs.push_back(config);
        } else {
            *stream_it = config;
        }
    }
}

void FusionConnectClient::sdp_func() {
    std::istringstream iss(sdp);
    std::string line;
    std::map<std::string, std::string> sdp_fields;
    std::string session_name;

    while (std::getline(iss, line)) {
        if (line.empty()) continue;
        size_t pos = line.find('=');
        if (pos == std::string::npos) continue;
        std::string key = line.substr(0, pos);
        std::string value = line.substr(pos + 1);

        if (key == "s") {
            session_name = value;
        } else if (key == "o") {
            size_t ip_pos = value.rfind(' ');
            if (ip_pos != std::string::npos) {
                sdp_fields["source_ip"] = value.substr(ip_pos + 1);
            }
        } else if (key == "c") {
            size_t ip_pos = value.find("IP4 ");
            if (ip_pos != std::string::npos) {
                std::string ip = value.substr(ip_pos + 4);
                size_t slash_pos = ip.find('/');
                if (slash_pos != std::string::npos) {
                    ip = ip.substr(0, slash_pos);
                }
                sdp_fields["dest_ip"] = ip;
            }
        } else if (key == "m") {
            size_t port_pos = value.find(' ');
            if (port_pos != std::string::npos) {
                sdp_fields["port"] = value.substr(port_pos + 1, value.find(' ', port_pos + 1) - port_pos - 1);
                size_t pt_pos = value.rfind(' ');
                if (pt_pos != std::string::npos) {
                    sdp_fields["payload_type"] = value.substr(pt_pos + 1);
                }
            }
        } else if (key == "a") {
            if (value.find("rtpmap:") == 0) {
                size_t space_pos = value.find(' ');
                if (space_pos != std::string::npos) {
                    std::string rtpmap = value.substr(space_pos + 1);
                    size_t slash1 = rtpmap.find('/');
                    size_t slash2 = rtpmap.rfind('/');
                    if (slash1 != std::string::npos && slash2 != std::string::npos && slash1 != slash2) {
                        sdp_fields["format"] = rtpmap.substr(0, slash1);
                        sdp_fields["sample_rate"] = rtpmap.substr(slash1 + 1, slash2 - slash1 - 1);
                        sdp_fields["channels"] = rtpmap.substr(slash2 + 1);
                    }
                }
            } else if (value.find("ptime:") == 0) {
                sdp_fields["ptime"] = value.substr(6);
            } else if (value.find("mediaclk:direct=") == 0) {
                sdp_fields["timestamp_offset"] = value.substr(16);
            } else if (value == "recvonly") {
                sdp_fields["direction"] = "RX";
            } else if (value == "sendonly") {
                sdp_fields["direction"] = "TX";
            }
        }
    }

    // Verify stream relevance
    bool is_relevant = false;
    if (session_name == device_id) {
        is_relevant = true;
    } else {
        auto it = sdp_fields.find("source_ip");
        std::string source_ip = it != sdp_fields.end() ? it->second : "";
        it = sdp_fields.find("dest_ip");
        std::string dest_ip = it != sdp_fields.end() ? it->second : "";
        if (source_ip == system_ip || dest_ip == system_ip) {
            it = sdp_fields.find("port");
            std::string port = it != sdp_fields.end() ? it->second : "";
            if (source_ip == system_ip && !port.empty()) {
                try {
                    unsigned int p = std::stoul(port);
                    if (p >= 49152 && p <= 65535) {
                        is_relevant = true;
                    }
                } catch (const std::exception& e) {}
            } else if (dest_ip == system_ip) {
                is_relevant = true; // Sink streams use port 5004
            }
        }
    }
    if (!is_relevant) {
        SPDLOG_DEBUG("SDP not relevant to device {}", device_id);
        return;
    }

    // Validate required fields
    auto it = sdp_fields.find("dest_ip");
    if (it == sdp_fields.end()) {
        SPDLOG_ERROR("Missing dest_ip in SDP");
        return;
    }
    uint32_t dest_ip = inet_addr(it->second.c_str());
    if (dest_ip == INADDR_NONE) {
        SPDLOG_ERROR("Invalid dest_ip: {}", it->second);
        return;
    }

    it = sdp_fields.find("port");
    if (it == sdp_fields.end()) {
        SPDLOG_ERROR("Missing port in SDP");
        return;
    }
    uint16_t dest_port;
    try {
        dest_port = std::stoul(it->second);
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid port: {}", e.what());
        return;
    }

    it = sdp_fields.find("payload_type");
    if (it == sdp_fields.end()) {
        SPDLOG_ERROR("Missing payload_type in SDP");
        return;
    }
    uint8_t payload_type;
    try {
        unsigned int pt = std::stoul(it->second);
        payload_type = (pt >= 96 && pt <= 127) ? pt : 0;
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid payload_type: {}", e.what());
        return;
    }
    if (payload_type == 0) {
        SPDLOG_ERROR("Payload type out of range: {}", it->second);
        return;
    }

    it = sdp_fields.find("sample_rate");
    if (it == sdp_fields.end()) {
        SPDLOG_ERROR("Missing sample_rate in SDP");
        return;
    }
    uint32_t sample_rate;
    try {
        sample_rate = std::stoul(it->second);
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid sample_rate: {}", e.what());
        return;
    }

    it = sdp_fields.find("channels");
    if (it == sdp_fields.end()) {
        SPDLOG_ERROR("Missing channels in SDP");
        return;
    }
    uint8_t channels;
    try {
        unsigned int ch = std::stoul(it->second);
        channels = (ch >= 1 && ch <= 64) ? ch : 0;
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid channels: {}", e.what());
        return;
    }
    if (channels == 0) {
        SPDLOG_ERROR("Channels out of range: {}", it->second);
        return;
    }

    it = sdp_fields.find("format");
    if (it == sdp_fields.end()) {
        SPDLOG_ERROR("Missing format in SDP");
        return;
    }
    int32_t format = pcm_format_str_to_int(it->second);

    it = sdp_fields.find("ptime");
    if (it == sdp_fields.end()) {
        SPDLOG_ERROR("Missing ptime in SDP");
        return;
    }
    float ptime;
    try {
        ptime = std::stof(it->second);
    } catch (const std::exception& e) {
        SPDLOG_ERROR("Invalid ptime: {}", e.what());
        return;
    }
    uint32_t frames_per_packet = static_cast<uint32_t>(ptime * sample_rate / 1000);
    std::vector<uint32_t> valid_frames = {6, 12, 16, 48, 192};
    if (std::find(valid_frames.begin(), valid_frames.end(), frames_per_packet) == valid_frames.end()) {
        SPDLOG_ERROR("Invalid frames_per_packet: {}", frames_per_packet);
        return;
    }

    it = sdp_fields.find("timestamp_offset");
    uint32_t timestamp_offset = 0;
    if (it != sdp_fields.end()) {
        try {
            timestamp_offset = std::stoul(it->second);
        } catch (const std::exception& e) {
            SPDLOG_ERROR("Invalid timestamp_offset: {}", e.what());
            return;
        }
    }

    it = sdp_fields.find("direction");
    std::string direction = it != sdp_fields.end() ? it->second : "RX";
    if (direction != "TX" && direction != "RX") {
        SPDLOG_ERROR("Invalid direction: {}", direction);
        return;
    }

    // Match stream
    auto stream_it = std::find_if(aes67_stream_configs.begin(), aes67_stream_configs.end(),
        [&](const auto& cfg) {
            return cfg.dest_ip == dest_ip && cfg.dest_port == dest_port && cfg.channels == channels;
        });

    struct fusion_cn_stream_config config;
    if (stream_it != aes67_stream_configs.end()) {
        config = *stream_it;
    } else {
        config = {};
        config.stream_handle = 0;
    }

    config.sample_rate = sample_rate;
    config.format = format;
    config.channels = channels;
    config.frames_per_packet = frames_per_packet;
    config.dest_ip = dest_ip;
    config.dest_port = dest_port;
    config.source_port = (direction == "TX") ? 49152 : dest_port;
    config.source_ip = inet_addr(system_ip.c_str());
    config.payload_type = payload_type;
    config.playout_delay = 2000000;
    config.timestamp_offset = timestamp_offset;
    config.is_source = (direction == "TX");
    config.is_fusion_connect = 0;

    create_stream(config);
    if (config.stream_handle != 0) {
        if (stream_it == aes67_stream_configs.end()) {
            aes67_stream_configs.push_back(config);
        } else {
            *stream_it = config;
        }
        // Update description if available
        auto desc_it = sdp_fields.find("description");
        if (desc_it != sdp_fields.end()) {
            aes67_descriptions[config.stream_handle] = desc_it->second;
        }
    }
}

} // namespace