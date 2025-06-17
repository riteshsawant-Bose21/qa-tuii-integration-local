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

namespace {

// Define netlink message structures and commands
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
    if (str == "S16_BE") return 3;
    if (str == "S24_3BE") return 33;
    if (str == "FLOAT_BE") return 15;
    SPDLOG_ERROR("Invalid PCM format: {}", str);
    return 15; // Default to FLOAT_BE
}

class FusionConnectClient : public bosepro::Module {
public:
    FusionConnectClient(const bosepro::BlockConfiguration &configuration);
    virtual ~FusionConnectClient() = default;

    virtual void process() {}

private:
    NetlinkClient client;
    std::string create_stream_input;
    std::string remove_stream_input;

    void create_stream_func();
    void remove_stream_func();

    MODULE_DECLARE(FusionConnectClient);
};

MODULE_REGISTER(FusionConnectClient, "fusion_connect_client");

FusionConnectClient::FusionConnectClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration) {
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

    assign_parameter("create_stream", &create_stream_input, 
                     POST_FUNCTION_SCALAR(create_stream_func));
    assign_parameter("remove_stream", &remove_stream_input, 
                     POST_FUNCTION_SCALAR(remove_stream_func));
}

void FusionConnectClient::create_stream_func() {
    struct fusion_cn_stream_config config = {};
    config.stream_handle = 0;
    config.sample_rate = 48000;
    config.format = pcm_format_str_to_int("FLOAT_BE");
    config.channels = 1;
    config.frames_per_packet = 16;
    config.dest_ip = inet_addr("127.0.0.1");
    config.source_ip = inet_addr("127.0.0.1");
    config.dest_port = htons(5004);
    config.source_port = htons(49152);
    config.payload_type = 96;
    config.playout_delay = 2000000;
    config.timestamp_offset = 0;
    config.is_source = 1;
    config.is_fusion_connect = 1;

    std::istringstream iss(create_stream_input);
    std::string token;
    while (std::getline(iss, token, ';')) {
        size_t pos = token.find('=');
        if (pos == std::string::npos) continue;
        std::string key = token.substr(0, pos);
        std::string value = token.substr(pos + 1);

        try {
            if (key == "stream_handle") config.stream_handle = std::stoull(value);
            else if (key == "sample_rate") {
                config.sample_rate = std::stoul(value);
                if (config.sample_rate == 0) config.sample_rate = 48000;
            }
            else if (key == "format") config.format = pcm_format_str_to_int(value);
            else if (key == "channels") {
                unsigned int channels = std::stoul(value);
                config.channels = (channels >= 1 && channels <= 64) ? channels : 1;
            }
            else if (key == "frames_per_packet") {
                config.frames_per_packet = std::stoul(value);
                if (config.frames_per_packet == 0) config.frames_per_packet = 16;
            }
            else if (key == "dest_ip") {
                config.dest_ip = inet_addr(value.c_str());
                if (config.dest_ip == INADDR_NONE) config.dest_ip = inet_addr("127.0.0.1");
            }
            else if (key == "source_ip") {
                config.source_ip = inet_addr(value.c_str());
                if (config.source_ip == INADDR_NONE) config.source_ip = inet_addr("127.0.0.1");
            }
            else if (key == "dest_port") {
                unsigned int port = std::stoul(value);
                config.dest_port = (port > 0 && port <= 65535) ? htons(port) : htons(5004);
            }
            else if (key == "source_port") {
                unsigned int port = std::stoul(value);
                config.source_port = (port > 0 && port <= 65535) ? htons(port) : htons(49152);
            }
            else if (key == "payload_type") {
                unsigned int pt = std::stoul(value);
                config.payload_type = (pt >= 96 && pt <= 127) ? pt : 96;
            }
            else if (key == "playout_delay") config.playout_delay = std::stoul(value);
            else if (key == "timestamp_offset") config.timestamp_offset = std::stoul(value);
            else if (key == "is_source") {
                int val = std::stoi(value);
                config.is_source = (val == 0 || val == 1) ? val : 1;
            }
            else if (key == "is_fusion_connect") {
                int val = std::stoi(value);
                config.is_fusion_connect = (val == 0 || val == 1) ? val : 1;
            }
        } catch (const std::exception& e) {
            SPDLOG_ERROR("Invalid value for {}: {}", key, e.what());
        }
    }

    struct fusion_cn_ctrl_msg reply = {0, 0, 0, nullptr, 0};
    if (client.send_message(FUSION_CN_CTRL_CMD_ADD_STREAM, &config, sizeof(config), &reply)) {
        if (reply.err == 0 && reply.data_size == sizeof(uint64_t) && reply.data) {
            uint64_t new_handle = *(uint64_t*)reply.data;
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

void FusionConnectClient::remove_stream_func() {
    uint64_t handle = 0;
    std::istringstream iss(remove_stream_input);
    std::string token;
    while (std::getline(iss, token, ';')) {
        size_t pos = token.find('=');
        if (pos == std::string::npos || token.substr(0, pos) != "stream_handle") continue;
        try {
            handle = std::stoull(token.substr(pos + 1));
        } catch (const std::exception& e) {
            SPDLOG_ERROR("Invalid stream handle: {}", e.what());
            return;
        }
    }

    if (handle == 0) {
        SPDLOG_ERROR("No valid stream handle provided");
        return;
    }

    struct fusion_cn_ctrl_msg reply = {0, 0, 0, nullptr, 0};
    if (client.send_message(FUSION_CN_CTRL_CMD_REMOVE_STREAM, &handle, sizeof(handle), &reply)) {
        if (reply.err == 0) {
            SPDLOG_DEBUG("Remove RTP Stream {}: Success", handle);
        } else {
            SPDLOG_ERROR("Remove RTP Stream {}: Failed, err={}", handle, reply.err);
        }
    } else {
        SPDLOG_ERROR("Failed to send Remove RTP Stream command");
    }
    if (reply.data) {
        free(reply.data);
    }
}

} // namespace