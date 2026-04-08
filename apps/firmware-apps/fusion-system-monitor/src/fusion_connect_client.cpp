#include <bosepro/module.h>
#include <bosepro/periodic_task.h>
#include <bosepro/sap_announcer.h>

#include <array>
#include <algorithm>
#include <cctype>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <climits>
#include <cstring>
#include <iomanip>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include <arpa/inet.h>
#include <curl/curl.h>
#include <fcntl.h>
#include <ifaddrs.h>
#include <json/json.h>
#include <linux/if_addr.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <net/if.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

namespace {

#define IFA_F_MCAUTOJOIN 0x400
#define STREAM_RETRY_CNT 4

enum stream_state {
    STREAM_CREATED,
    STREAM_CREATE_PENDING
};

struct fc_stream_state {
    enum stream_state state;
    uint8_t retry_cnt;
};

enum fusion_cn_ctrl_cmd {
    FUSION_CN_CTRL_CMD_NONE = 0,
    FUSION_CN_CTRL_CMD_START_MANAGER,
    FUSION_CN_CTRL_CMD_STOP_MANAGER,
    FUSION_CN_CTRL_CMD_ADD_STREAM,
    FUSION_CN_CTRL_CMD_REMOVE_STREAM,
    FUSION_CN_CTRL_CMD_GET_METRICS,
    FUSION_CN_CTRL_CMD_SET_PHC_ANCHOR,
    FUSION_CN_CTRL_CMD_GET_TIMING_STATUS,
    FUSION_CN_CTRL_CMD_RESET_TIMING_STATE,
    FUSION_CN_CTRL_CMD_SET_DEBUG,
    FUSION_CN_CTRL_CMD_SET_ETH_IFACE
};

enum mgr_start_errno {
    MGR_START_OK = 0,
    MGR_START_ERRNO_RUNNING,
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

struct fusion_cn_metrics_snapshot
{
    uint64_t ts_snapshot_ns;

    /* RX */
    uint64_t packets_total, bytes_total;
    uint64_t packets_lost, packets_reordered, packets_dup;
    uint64_t packets_marked, malformed_count;
    uint64_t late_drop_count;
    uint64_t rx_queue_drop_count;
    uint64_t burst_loss_max;

    uint32_t rfc3550_jitter_ns;
    uint32_t iat_min_ns, iat_p50_ns, iat_p99_ns;
    uint32_t batch_max;

    uint32_t jb_depth_cur_samples, jb_depth_min_samples, jb_depth_max_samples, jb_depth_avg_samples;
    uint32_t resync_count;

    uint32_t path_latency_est_ns, path_latency_min_ns, path_latency_max_ns;
    uint32_t path_latency_p50_ns, path_latency_p99_ns;

    /* TX */
    uint64_t tx_packets_total;
    uint64_t tx_bytes_total;

    uint32_t tx_iat_min_ns;
    uint32_t tx_iat_p50_ns;
    uint32_t tx_iat_p99_ns;
    uint32_t tx_sched_err_abs_p50_ns;
    uint32_t tx_sched_err_abs_max_ns;
} __attribute__((packed));

struct fusion_cn_metrics_record {
    uint64_t stream_handle;
    char stream_name[32];
    struct fusion_cn_metrics_snapshot snap;
} __attribute__((packed));

#ifndef CLOCKFD
#define CLOCKFD 3
#endif
#ifndef FD_TO_CLOCKID
#define FD_TO_CLOCKID(fd) ((clockid_t)((((unsigned int)~(fd)) << 3) | CLOCKFD))
#endif

struct fc_get_timing_status_reply
{
    uint8_t discipline_ready;
    uint8_t epoch_valid;
    uint8_t aligned;
    uint32_t pps_seq;
} __attribute__((packed));

// Helper function to convert uint32_t IP to string
std::string ip_to_string(uint32_t ip) {
    struct in_addr addr;
    addr.s_addr = ip;
    return std::string(inet_ntoa(addr));
}

bool is_ip_mcast(uint32_t ip) {
    uint32_t ip_host = ntohl(ip);
    return (ip_host >= 0xE0000000 && ip_host <= 0xEFFFFFFF); /* 224.0.0.0 - 239.255.255.255 */
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
    SPDLOG_INFO("  Dest IP: {}", ip_to_string(config.dest_ip));
    SPDLOG_INFO("  Dest Port: {}", config.dest_port);
    SPDLOG_INFO("  Source Port: {}", config.source_port);
    SPDLOG_INFO("  Source IP: {}", ip_to_string(config.source_ip));
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

// Helper function to get system IP address (prefers a named interface if provided)
std::string get_system_ip(const std::string& preferred_ifname = "", bool log_on_fail = true) {
    struct ifaddrs *ifaddr, *ifa;
    char addr_str[INET_ADDRSTRLEN] = {0};

    if (getifaddrs(&ifaddr) == -1) {
        SPDLOG_ERROR("Failed to get interface addresses: {}", strerror(errno));
        return "";
    }

    auto name_matches = [&](const char* name) -> bool {
        if (!name || preferred_ifname.empty()) return false;
        if (preferred_ifname == name) return true;
        const size_t n = preferred_ifname.size();
        return (strncmp(name, preferred_ifname.c_str(), n) == 0 && name[n] == '@');
    };

    if (!preferred_ifname.empty()) {
        for (ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
            if (!ifa->ifa_addr || ifa->ifa_addr->sa_family != AF_INET) continue;
            if (!name_matches(ifa->ifa_name)) continue;
            struct sockaddr_in *sa = (struct sockaddr_in *)ifa->ifa_addr;
            if (inet_ntop(AF_INET, &sa->sin_addr, addr_str, sizeof(addr_str))) {
                freeifaddrs(ifaddr);
                return std::string(addr_str);
            }
        }
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
    if (log_on_fail) {
        if (!preferred_ifname.empty()) {
            SPDLOG_ERROR("No valid IPv4 address found on interface '{}'", preferred_ifname);
        } else {
            SPDLOG_ERROR("No valid IPv4 address found on non-loopback interfaces");
        }
    }
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

    bool send_message(uint32_t cmd, const void* data, uint32_t data_size, struct fusion_cn_ctrl_msg* reply) {
        if (socket_fd < 0) return false;

        const size_t payload_len = sizeof(fusion_cn_ctrl_msg) + data_size;
        const size_t nl_len      = NLMSG_LENGTH(payload_len);

        std::vector<uint8_t> buf(nl_len, 0);
        auto *nlh  = reinterpret_cast<nlmsghdr*>(buf.data());
        auto *msg  = reinterpret_cast<fusion_cn_ctrl_msg*>(NLMSG_DATA(nlh));
        void *dst_data = reinterpret_cast<uint8_t*>(msg) + sizeof(*msg);

        nlh->nlmsg_len   = nl_len;
        nlh->nlmsg_type  = 0;
        nlh->nlmsg_flags = NLM_F_REQUEST;
        nlh->nlmsg_seq   = 0;
        nlh->nlmsg_pid   = static_cast<uint32_t>(getpid());

        msg->cmd       = cmd;
        msg->err       = 0;
        msg->data_size = data_size;
        msg->pid       = getpid();
        msg->data      = nullptr;

        if (data_size && data) memcpy(dst_data, data, data_size);

        iovec iov = { .iov_base = buf.data(), .iov_len = buf.size() };

        msghdr netlink_msg{};  // zero init!
        netlink_msg.msg_name    = &dst_addr;
        netlink_msg.msg_namelen = sizeof(dst_addr);
        netlink_msg.msg_iov     = &iov;
        netlink_msg.msg_iovlen  = 1;

        if (sendmsg(socket_fd, &netlink_msg, 0) < 0) {
            SPDLOG_ERROR("Failed to send netlink message: {}", strerror(errno));
            return false;
        }

        std::array<uint8_t, 64 * 1024> rbuf{};
        iov = { .iov_base = rbuf.data(), .iov_len = rbuf.size() };

        msghdr recv_msg{};     // zero init!
        recv_msg.msg_name    = &dst_addr;
        recv_msg.msg_namelen = sizeof(dst_addr);
        recv_msg.msg_iov     = &iov;
        recv_msg.msg_iovlen  = 1;

        const ssize_t rlen = recvmsg(socket_fd, &recv_msg, 0);
        if (rlen < 0) {
            SPDLOG_ERROR("Failed to receive netlink response: {}", strerror(errno));
            return false;
        }

        auto *nlh_reply = reinterpret_cast<nlmsghdr*>(rbuf.data());
        if (!NLMSG_OK(nlh_reply, rlen) || nlh_reply->nlmsg_type == NLMSG_ERROR) {
            SPDLOG_ERROR("Invalid netlink response");
            return false;
        }

        auto *reply_msg = reinterpret_cast<fusion_cn_ctrl_msg*>(NLMSG_DATA(nlh_reply));
        *reply = *reply_msg;

        if (reply_msg->data_size > 0) {
            reply->data = malloc(reply_msg->data_size);
            if (!reply->data) {
                SPDLOG_ERROR("Failed to allocate memory for reply data");
                return false;
            }
            const void *src_data = reinterpret_cast<const uint8_t*>(reply_msg) + sizeof(*reply_msg);
            memcpy(reply->data, src_data, reply_msg->data_size);
        } else {
            reply->data = nullptr;
        }
        return true;
    }
};

// static bool nl_start_manager(NetlinkClient& c) {
//     fusion_cn_ctrl_msg reply{};
//     if (!c.send_message(FUSION_CN_CTRL_CMD_START_MANAGER, nullptr, 0, &reply)) return false;
//     bool ok = (reply.err == MGR_START_OK || reply.err == -MGR_START_ERRNO_RUNNING);
//     if (!ok) SPDLOG_ERROR("START_MANAGER err={}", reply.err);
//     if (reply.data) free(reply.data);
//     return ok;
// }

// static bool nl_stop_manager(NetlinkClient& c) {
//     fusion_cn_ctrl_msg reply{};
//     if (!c.send_message(FUSION_CN_CTRL_CMD_STOP_MANAGER, nullptr, 0, &reply)) return false;
//     if (reply.err != 0) SPDLOG_ERROR("STOP_MANAGER err={}", reply.err);
//     if (reply.data) free(reply.data);
//     return reply.err == 0;
// }

static bool get_all_metrics(NetlinkClient &client,
                            std::vector<fusion_cn_metrics_record> *out)
{
    fusion_cn_ctrl_msg reply{};
    if (!client.send_message(FUSION_CN_CTRL_CMD_GET_METRICS, nullptr, 0, &reply)) {
        SPDLOG_ERROR("GET_METRICS: send_message failed");
        return false;
    }

    SPDLOG_TRACE("GET_METRICS: err={} payload={}B sizeof(record)={}B sizeof(snapshot)={}B",
                 reply.err, reply.data_size,
                 sizeof(fusion_cn_metrics_record),
                 sizeof(fusion_cn_metrics_snapshot));

    if (reply.err != 0) {
        SPDLOG_ERROR("GET_METRICS failed: err={}", reply.err);
        if (reply.data) free(reply.data);
        return false;
    }

    if (reply.data_size == 0) {
        out->clear();
        if (reply.data) free(reply.data);
        return true;
    }

    const size_t rec_size = sizeof(fusion_cn_metrics_record);
    if (reply.data_size % rec_size != 0) {
        // dump a small hex preview to see what we actually got
        const size_t dump = std::min<size_t>(reply.data_size, 64);
        std::string hex;
        if (reply.data) {
            auto *p = static_cast<const uint8_t*>(reply.data);
            std::ostringstream os;
            for (size_t i = 0; i < dump; ++i) os << std::hex << std::setw(2) << std::setfill('0') << (unsigned)p[i] << (i+1<dump?" ":"");
            hex = os.str();
        }
        SPDLOG_ERROR("GET_METRICS: payload {}B not a multiple of record {}B (snapshot {}B). First {}B: {}",
                     reply.data_size, rec_size, sizeof(fusion_cn_metrics_snapshot), dump, hex);
        if (reply.data) free(reply.data);
        return false;
    }

    const size_t n = reply.data_size / rec_size;
    out->resize(n);
    memcpy(out->data(), reply.data, reply.data_size);
    if (reply.data) free(reply.data);

    SPDLOG_DEBUG("GET_METRICS: {} record(s)", n);
    return true;
}

// static bool get_metrics_for_stream(NetlinkClient &client, uint64_t handle,
//                                    fusion_cn_metrics_record *out)
// {
//     struct fusion_cn_ctrl_msg reply{};
//     if (!client.send_message(FUSION_CN_CTRL_CMD_GET_METRICS, &handle, sizeof(handle), &reply))
//         return false;
//     if (reply.err != 0) {
//         SPDLOG_ERROR("GET_METRICS(handle={}): err={}", handle, reply.err);
//         if (reply.data) free(reply.data);
//         return false;
//     }
//     if (reply.data_size != sizeof(fusion_cn_metrics_record) || !reply.data) {
//         SPDLOG_ERROR("GET_METRICS(handle={}): bad payload", handle);
//         if (reply.data) free(reply.data);
//         return false;
//     }
//     memcpy(out, reply.data, sizeof(*out));
//     free(reply.data);
//     return true;
// }

static bool nl_set_phc_anchor(NetlinkClient& c, uint64_t phc_ns_at_pps) {
    fusion_cn_ctrl_msg reply{};
    if (!c.send_message(FUSION_CN_CTRL_CMD_SET_PHC_ANCHOR, &phc_ns_at_pps, sizeof(phc_ns_at_pps), &reply)) {
        return false;
    }
    if (reply.err != 0) {
        SPDLOG_ERROR("SET_PHC_ANCHOR({}) err={}", phc_ns_at_pps, reply.err);
    }
    if (reply.data) free(reply.data);
    return reply.err == 0;
}

// static bool nl_set_debug(NetlinkClient& c, bool enable) {
//     fusion_cn_ctrl_msg reply{};
//     uint8_t v = enable ? 1 : 0;
//     if (!c.send_message(FUSION_CN_CTRL_CMD_SET_DEBUG, &v, sizeof(v), &reply)) return false;
//     if (reply.err != 0) SPDLOG_ERROR("SET_DEBUG({}) err={}", (int)enable, reply.err);
//     if (reply.data) free(reply.data);
//     return reply.err == 0;
// }

static bool nl_set_eth_iface(NetlinkClient& c, const std::string& iface) {
    fusion_cn_ctrl_msg reply{};
    if (iface.empty()) return false;
    std::array<char, IFNAMSIZ> buf{};
    std::strncpy(buf.data(), iface.c_str(), buf.size() - 1);
    if (!c.send_message(FUSION_CN_CTRL_CMD_SET_ETH_IFACE, buf.data(), buf.size(), &reply)) return false;
    if (reply.err != 0) SPDLOG_ERROR("SET_ETH_IFACE({}) err={}", iface, reply.err);
    if (reply.data) free(reply.data);
    return reply.err == 0;
}

static bool nl_get_timing_status(NetlinkClient& c, fc_get_timing_status_reply *out)
{
    if (!out) return false;
    fusion_cn_ctrl_msg reply{};
    if (!c.send_message(FUSION_CN_CTRL_CMD_GET_TIMING_STATUS, nullptr, 0, &reply)) return false;
    if (reply.err != 0) {
        SPDLOG_ERROR("GET_TIMING_STATUS err={}", reply.err);
        if (reply.data) free(reply.data);
        return false;
    }
    if (reply.data_size != sizeof(*out) || !reply.data) {
        SPDLOG_ERROR("GET_TIMING_STATUS bad payload size={} data={}",
                     reply.data_size, reply.data ? "present" : "null");
        if (reply.data) free(reply.data);
        return false;
    }
    memcpy(out, reply.data, sizeof(*out));
    if (reply.data) free(reply.data);
    return true;
}

static bool nl_reset_timing_state(NetlinkClient& c)
{
    fusion_cn_ctrl_msg reply{};
    if (!c.send_message(FUSION_CN_CTRL_CMD_RESET_TIMING_STATE, nullptr, 0, &reply)) {
        return false;
    }
    if (reply.err != 0) {
        SPDLOG_ERROR("RESET_TIMING_STATE err={}", reply.err);
    }
    if (reply.data) free(reply.data);
    return reply.err == 0;
}

static bool read_phc_ns(uint64_t *out_ns)
{
    static int ptp_fd = -1;

    if (!out_ns) return false;
    if (ptp_fd < 0) {
        ptp_fd = open("/dev/ptp0", O_RDONLY);
        if (ptp_fd < 0) {
            SPDLOG_ERROR("Failed to open /dev/ptp0: {}", strerror(errno));
            return false;
        }
    }

    timespec ts{};
    clockid_t clkid = FD_TO_CLOCKID(ptp_fd);
    if (clock_gettime(clkid, &ts) != 0) {
        SPDLOG_ERROR("clock_gettime(/dev/ptp0) failed: {}", strerror(errno));
        return false;
    }

    *out_ns = (static_cast<uint64_t>(ts.tv_sec) * 1000000000ULL) +
              static_cast<uint64_t>(ts.tv_nsec);
    return true;
}

static bool poll_time_status_np(bool *gm_present, bool *gm_present_valid,
                                long long *master_offset, bool *master_offset_valid)
{
    if (gm_present) *gm_present = false;
    if (gm_present_valid) *gm_present_valid = false;
    if (master_offset) *master_offset = 0;
    if (master_offset_valid) *master_offset_valid = false;

    FILE* fp = popen("/usr/sbin/pmc -u -b 0 -f /etc/linuxptp/ptp4l.conf 'GET TIME_STATUS_NP'", "r");
    if (!fp) return false;

    char buf[512];
    bool found_any = false;
    auto trim = [](std::string s){
        const char* ws = " \t\r\n";
        size_t a = s.find_first_not_of(ws);
        size_t b = s.find_last_not_of(ws);
        return a == std::string::npos ? std::string() : s.substr(a, b - a + 1);
    };

    while (fgets(buf, sizeof(buf), fp)) {
        std::string line(buf);
        auto gm_pos = line.find("gmPresent");
        if (gm_pos != std::string::npos && gm_present && gm_present_valid) {
            std::string v = trim(line.substr(gm_pos + std::strlen("gmPresent")));
            for (char& ch : v) ch = (char)std::tolower((unsigned char)ch);
            if (v.find("true") != std::string::npos) {
                *gm_present = true;
                *gm_present_valid = true;
                found_any = true;
            } else if (v.find("false") != std::string::npos) {
                *gm_present = false;
                *gm_present_valid = true;
                found_any = true;
            }
        }

        auto mo_pos = line.find("master_offset");
        if (mo_pos != std::string::npos && master_offset && master_offset_valid) {
            std::string v = trim(line.substr(mo_pos + std::strlen("master_offset")));
            const char* s = v.c_str();
            char* endp   = nullptr;
            errno = 0;
            long long val = std::strtoll(s, &endp, 10);
            if (errno == 0 && endp != s) {
                *master_offset = val;
                *master_offset_valid = true;
                found_any = true;
            }
        }
    }

    int rc = pclose(fp);
    if (rc != 0) {
        SPDLOG_WARN("pmc GET TIME_STATUS_NP exited with status {}", rc);
        return false;
    }
    if (!found_any) {
        SPDLOG_WARN("pmc GET TIME_STATUS_NP returned no usable fields");
        return false;
    }
    return true;
}

static bool set_pps_enable(bool enable)
{
    const char *path = "/sys/class/ptp/ptp0/pps_enable";
    const char *val = enable ? "1" : "0";
    int fd = open(path, O_WRONLY | O_CLOEXEC);
    if (fd < 0) {
        SPDLOG_ERROR("Failed to open {}: {}", path, strerror(errno));
        return false;
    }

    ssize_t rc = write(fd, val, 1);
    if (rc != 1) {
        SPDLOG_ERROR("Failed to write {} to {}: rc={} err={}", val, path, rc, strerror(errno));
        close(fd);
        return false;
    }

    close(fd);
    return true;
}

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
    bool mgr_started;
    std::string device_id;
    std::string system_ip;
    std::map<std::string, fusion_cn_stream_config> fusion_connect_stream_map;
    std::map<std::string, fusion_cn_stream_config> aes67_stream_map;
    std::map<std::string, struct fc_stream_state> pending_streams;
    std::string enet_iface;
    int_fast32_t period_ms;
    bool debug_enabled;
    bool debug_sent;
    bool iface_sent;
    bool gpt_discipline_ready_logged;
    SAPAnnouncer sap_announcer;

    std::string audio_streams_update;
    bool audio_streams_update_pending;
    bool ptp_sync_good;
    bool ptp_anchor_pending;
    int ptp_good_streak;
    int ptp_bad_streak;
    int ptp_role_flag;
    int ptp_false_streak;
    std::chrono::steady_clock::time_point ptp_last_poll;
    std::chrono::steady_clock::time_point ptp_last_role_probe;
    std::chrono::steady_clock::time_point ptp_last_gm_present;
    std::chrono::steady_clock::time_point ptp_state_since;
    std::chrono::steady_clock::time_point ptp_last_anchor;
    std::chrono::steady_clock::time_point ptp_last_status_poll;
    std::chrono::steady_clock::time_point audio_update_last_retry;
    std::chrono::steady_clock::time_point mgr_last_start_attempt;
    int mgr_start_failures;
    enum class PtpState { RESET, WAIT_GM, WAIT_LOCK, SYNCED };
    PtpState ptp_state;

    bool is_source_stream(uint64_t stream_handle);
    int create_stream(fusion_cn_stream_config& config);
    int remove_stream(uint64_t stream_handle);
    void join_multicast_group(uint32_t multicast_ip);
    bool process_audio_streams_update();
    void audio_streams_update_func();
    void maybe_retry_audio_streams_update();
    void maybe_start_manager();
    void update_ptp_state();
    void start_timing_session();
    void reset_timing_session(const char *reason);
    void maybe_set_phc_anchor();

    MODULE_DECLARE(FusionConnectClient);
};

MODULE_REGISTER(FusionConnectClient, "fusion_connect_client");

FusionConnectClient::FusionConnectClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration), mgr_started(false), device_id(""),
      enet_iface("lan1"), period_ms(1000), debug_enabled(false),
      debug_sent(false), iface_sent(false),
      gpt_discipline_ready_logged(false), sap_announcer(""),
      audio_streams_update_pending(false),
      ptp_sync_good(false), ptp_anchor_pending(false), ptp_good_streak(0),
      ptp_bad_streak(0), ptp_role_flag(-1), ptp_false_streak(0), mgr_start_failures(0),
      ptp_state(PtpState::RESET) {
    system_ip = "";

    if (!client.is_valid()) {
        SPDLOG_ERROR("Failed to initialize netlink client");
        return;
    }

    get_property("period_ms", period_ms);
    get_property("enet_iface", enet_iface);
    get_property("debug", debug_enabled);
    if (period_ms <= 0) {
        period_ms = 1000;
    }
    if (enet_iface.empty()) {
        enet_iface = "lan1";
    }

    assign_parameter("audio_streams_update", &audio_streams_update, 
                     POST_FUNCTION_SCALAR(audio_streams_update_func));

    ptp_last_poll = std::chrono::steady_clock::now();
    ptp_last_role_probe = ptp_last_poll;
    ptp_last_gm_present = ptp_last_poll;
    ptp_state_since = ptp_last_poll;
    ptp_last_anchor = ptp_last_poll - std::chrono::seconds(60);
    ptp_last_status_poll = ptp_last_poll - std::chrono::seconds(1);
    audio_update_last_retry = ptp_last_poll - std::chrono::seconds(1);
    mgr_last_start_attempt = ptp_last_poll - std::chrono::seconds(2);
}

static bool is_source_stream_by_name(const char *name) {
    if (!name) return false;
    // Our conventions: FC_TX_* and AES67_tx are TX; FC_RX_* and AES67_rx are RX
    return (strncmp(name, "FC_TX_", 6) == 0) || (strncmp(name, "AES67_tx", 8) == 0);
}

bool FusionConnectClient::is_source_stream(uint64_t handle) {
    for (const auto &kv : fusion_connect_stream_map)
        if (kv.second.stream_handle == handle) return kv.second.is_source;
    for (const auto &kv : aes67_stream_map)
        if (kv.second.stream_handle == handle) return kv.second.is_source;
    return false; // unknown handle, we'll fall back to name
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
    // Build into a flat buffer so the attribute writes extend beyond nlmsghdr safely.
    std::array<char, 512> buf{};                       // ample space
    auto *nlh = reinterpret_cast<nlmsghdr*>(buf.data());

    // Base header
    nlh->nlmsg_len   = NLMSG_LENGTH(sizeof(ifaddrmsg));
    nlh->nlmsg_type  = RTM_NEWADDR;
    nlh->nlmsg_flags = NLM_F_REQUEST | NLM_F_CREATE | NLM_F_EXCL;
    nlh->nlmsg_seq   = 0;
    nlh->nlmsg_pid   = static_cast<uint32_t>(getpid());

    auto *ifa = reinterpret_cast<ifaddrmsg*>(NLMSG_DATA(nlh));
    memset(ifa, 0, sizeof(*ifa));
    ifa->ifa_family    = AF_INET;
    ifa->ifa_prefixlen = 32;
    ifa->ifa_flags     = 0;
    ifa->ifa_scope     = 0;

    int ifindex = if_nametoindex(enet_iface.c_str());
    if (!ifindex) {
        SPDLOG_ERROR("Failed to get interface index for {}: {}", enet_iface, strerror(errno));
        return;
    }
    ifa->ifa_index = ifindex;

    in_addr addr{};
    addr.s_addr = multicast_ip;  // expect BE/inet order upstream

    uint32_t ifa_flags_val = IFA_F_MCAUTOJOIN;

    // Add attributes into the same flat buffer (pass nlh and the *whole* buffer size)
    if (addattr_l(nlh, buf.size(), IFA_LOCAL,   &addr, sizeof(addr)) < 0 ||
        addattr_l(nlh, buf.size(), IFA_ADDRESS, &addr, sizeof(addr)) < 0 ||
        addattr_l(nlh, buf.size(), IFA_FLAGS,   &ifa_flags_val, sizeof(ifa_flags_val)) < 0) {
        SPDLOG_ERROR("Failed to add attributes for IGMP join");
        return;
    }

    int sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0) {
        SPDLOG_ERROR("Failed to create netlink socket for IGMP: {}", strerror(errno));
        return;
    }

    sockaddr_nl nladdr{};
    nladdr.nl_family = AF_NETLINK;

    SPDLOG_DEBUG("Joining multicast group {} on interface {}", ip_to_string(multicast_ip), enet_iface);

    if (sendto(sock, buf.data(), nlh->nlmsg_len, 0, reinterpret_cast<sockaddr*>(&nladdr), sizeof(nladdr)) < 0) {
        SPDLOG_ERROR("Failed to send netlink message for IGMP join: {}", strerror(errno));
        close(sock);
        return;
    }

    close(sock);
    SPDLOG_INFO("Successfully joined multicast group {} on interface {}", ip_to_string(multicast_ip), enet_iface);
}

bool FusionConnectClient::process_audio_streams_update() {
    if (audio_streams_update.empty()) {
        SPDLOG_DEBUG("audio_streams_update is empty, exiting");
        return false;
    }

    SPDLOG_DEBUG("Received audio_streams_update: {}", audio_streams_update);

    // --- Crucial pre-reqs -----------------------------------------------------
    if (system_ip.empty()) {
        SPDLOG_ERROR("Cannot process audio_streams_update: no system IP yet");
        return false;
    }
    if (device_id.empty()) {
        device_id = get_device_id(system_ip);
        if (device_id.empty()) {
            SPDLOG_ERROR("Failed to get device_id after audio_streams update!");
            return false;
        }
        SPDLOG_INFO("Initialized device_id: {}, system_ip: {}", device_id, system_ip);
    }

    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(audio_streams_update, root) || !root.isArray()) {
        SPDLOG_ERROR("Failed to parse audio_streams_update JSON or not an array: {}", audio_streams_update);
        return false;
    }

    auto ip_to_be32 = [](const std::string& s) -> uint32_t {
        if (s.empty()) return 0;
        return inet_addr(s.c_str()); // returns INADDR_NONE on invalid
    };

    auto local_ip_be = ip_to_be32(system_ip);
    if (local_ip_be == INADDR_NONE || local_ip_be == 0) {
        SPDLOG_ERROR("Invalid system_ip '{}'", system_ip);
        return false;
    }

    std::set<std::string> json_stream_names;
    bool needs_retry = false;

    // --- Process each stream ---------------------------------------------------
    for (const auto& stream : root) {
        if (!stream.isObject()) {
            SPDLOG_ERROR("Invalid stream object in audio_streams array");
            continue;
        }

        // Validate device matching first
        const std::string source_device_uid =
            (stream.isMember("source_device_uid") && stream["source_device_uid"].isString())
                ? stream["source_device_uid"].asString() : "";
        const std::string dest_device_uid =
            (stream.isMember("dest_device_uid") && stream["dest_device_uid"].isString())
                ? stream["dest_device_uid"].asString() : "";

        if (source_device_uid.empty() && dest_device_uid.empty()) {
            SPDLOG_ERROR("Missing device_uid in stream");
            continue;
        }

        const bool create_source = (source_device_uid == device_id);
        const bool create_sink   = (dest_device_uid   == device_id);
        if (!create_source && !create_sink) {
            // Not for this device
            continue;
        }

        // Validate properties presence
        if (!stream.isMember("properties") || !stream["properties"].isObject()) {
            SPDLOG_ERROR("Missing or invalid properties object in stream");
            continue;
        }
        const Json::Value& properties = stream["properties"];

        // is_fusion_connect (required)
        if (!properties.isMember("is_fusion_connect") || !properties["is_fusion_connect"].isBool()) {
            SPDLOG_ERROR("Missing or invalid is_fusion_connect in properties");
            continue;
        }
        const bool is_fusion_connect = properties["is_fusion_connect"].asBool();

        // channels (required, range-checked)
        if (!properties.isMember("channels") || !properties["channels"].isInt()) {
            SPDLOG_ERROR("Missing or invalid channels");
            continue;
        }
        unsigned int ch = properties["channels"].asInt();
        if (ch < 1 || ch > 64) {
            SPDLOG_ERROR("Channels out of range: {}", ch);
            continue;
        }

        // Common defaults for both FC and AES67
        fusion_cn_stream_config config = {};
        config.channels           = ch;
        config.sample_rate        = 48000;
        config.frames_per_packet  = 48;
        config.dest_port          = 5004;     // AES67 default; FC uses same
        config.source_port        = 49152;    // sensible default; FC overrides
        config.playout_delay      = 1000000;
        config.timestamp_offset   = 0;
        config.payload_type       = is_fusion_connect ? 100 : 97;
        config.format             = is_fusion_connect ? 15/*FLOAT_BE*/ : 33/*S24_3BE*/;
        config.is_fusion_connect  = is_fusion_connect;

        // IP defaults: DO NOT pre-fill to system_ip (prevents RX map mismatch)
        config.source_ip = 0; 
        config.dest_ip   = 0;

        // Allow standards overrides from properties (safe ones)
        if (properties.isMember("payload_type") && properties["payload_type"].isUInt()) {
            unsigned pt = properties["payload_type"].asUInt();
            if (pt >= 96 && pt <= 127) config.payload_type = pt;
        }
        if (properties.isMember("playout_delay") && properties["playout_delay"].isUInt())
            config.playout_delay = properties["playout_delay"].asUInt();
        if (properties.isMember("timestamp_offset") && properties["timestamp_offset"].isUInt())
            config.timestamp_offset = properties["timestamp_offset"].asUInt();
        if (properties.isMember("frames_per_packet") && properties["frames_per_packet"].isUInt())
            config.frames_per_packet = properties["frames_per_packet"].asUInt();
        if (properties.isMember("sample_rate") && properties["sample_rate"].isUInt())
            config.sample_rate = properties["sample_rate"].asUInt();
        if (properties.isMember("dest_port") && properties["dest_port"].isUInt())
            config.dest_port = properties["dest_port"].asUInt();
        if (properties.isMember("source_port") && properties["source_port"].isUInt())
            config.source_port = properties["source_port"].asUInt();

        if (is_fusion_connect) {
            // --- Fusion Connect path -----------------------------------------
            // source_port is required for FC
            if (!properties.isMember("source_port") || !properties["source_port"].isInt()) {
                SPDLOG_ERROR("Missing or invalid source_port for Fusion Connect stream");
                continue;
            }
            // Determine role(s)
            if (!create_source && !create_sink) continue;

            config.frames_per_packet  = 16;

            if (create_source) {
                config.is_source = true;
                std::snprintf(config.stream_name, sizeof(config.stream_name), "FC_TX_%u", config.source_port);

                // Role invariants: TX must set source_ip=local, dest_ip=peer
                config.source_ip = local_ip_be;

                // Resolve peer (dest device) IP once; outer audio update retry owns retries.
                config.dest_ip = ip_to_be32(query_device_ip(dest_device_uid, system_ip));

                if (config.dest_ip == 0 || config.dest_ip == INADDR_NONE) {
                    SPDLOG_ERROR("Failed to resolve destination IP for {}", config.stream_name);
                    needs_retry = true;
                } else if (!fusion_connect_stream_map.count(config.stream_name)) {
                    fusion_connect_stream_map[config.stream_name] = config;
                    pending_streams[config.stream_name].state = STREAM_CREATE_PENDING;
                    pending_streams[config.stream_name].retry_cnt = STREAM_RETRY_CNT;
                    SPDLOG_DEBUG("Added Fusion Connect source stream {} to pending", config.stream_name);
                    json_stream_names.insert(config.stream_name);
                }
            }

            if (create_sink) {
                fusion_cn_stream_config sink_cfg = config; // copy common defaults/overrides
                sink_cfg.is_source = false;
                std::snprintf(sink_cfg.stream_name, sizeof(sink_cfg.stream_name), "FC_RX_%u", sink_cfg.source_port);

                // Role invariants: RX must set dest_ip=local, source_ip=peer
                sink_cfg.dest_ip = local_ip_be;

                // Resolve peer (source device) IP once; outer audio update retry owns retries.
                sink_cfg.source_ip = ip_to_be32(query_device_ip(source_device_uid, system_ip));

                if (sink_cfg.source_ip == 0 || sink_cfg.source_ip == INADDR_NONE) {
                    SPDLOG_ERROR("Failed to resolve source IP for {}", sink_cfg.stream_name);
                    needs_retry = true;
                } else if (!fusion_connect_stream_map.count(sink_cfg.stream_name)) {
                    fusion_connect_stream_map[sink_cfg.stream_name] = sink_cfg;
                    pending_streams[sink_cfg.stream_name].state = STREAM_CREATE_PENDING;
                    pending_streams[sink_cfg.stream_name].retry_cnt = STREAM_RETRY_CNT;
                    SPDLOG_DEBUG("Added Fusion Connect sink stream {} to pending", sink_cfg.stream_name);
                    json_stream_names.insert(sink_cfg.stream_name);
                }
            }
        } else {
            // --- AES67 path ---------------------------------------------------
            // stream_name required
            if (!properties.isMember("stream_name") || !properties["stream_name"].isString()) {
                SPDLOG_ERROR("Missing or invalid stream_name for AES67 stream");
                continue;
            }
            const std::string pretty = "AES67_" + properties["stream_name"].asString();
            std::strncpy(config.stream_name, pretty.c_str(), sizeof(config.stream_name) - 1);
            config.stream_name[sizeof(config.stream_name) - 1] = '\0';

            // role
            const bool is_source = (properties.isMember("is_source") && properties["is_source"].isBool())
                                    ? properties["is_source"].asBool()
                                    : false;

            // Optional overrides
            if (properties.isMember("source_ip") && properties["source_ip"].isString())
                config.source_ip = ip_to_be32(properties["source_ip"].asString());
            if (properties.isMember("dest_ip") && properties["dest_ip"].isString())
                config.dest_ip   = ip_to_be32(properties["dest_ip"].asString());

            // Enforce role-specific invariants **after** overrides:
            config.is_source = is_source;

            if (is_source) {
                // TX: must have dest_ip (unicast or multicast). source_ip defaults to local if omitted.
                if (config.dest_ip == 0 || config.dest_ip == INADDR_NONE) {
                    SPDLOG_ERROR("Missing/invalid dest_ip for AES67 source {}", pretty);
                    continue;
                }
                if (config.source_ip == 0 || config.source_ip == INADDR_NONE) {
                    config.source_ip = local_ip_be;
                }
                // (No further constraints: multicast TX is allowed; unicast TX is allowed.)
            } else {
                // RX
                const bool have_dest = (config.dest_ip != 0 && config.dest_ip != INADDR_NONE);
                const bool dest_is_mcast = have_dest && is_ip_mcast(config.dest_ip);

                if (!dest_is_mcast) {
                    // require source_ip for 1:1 mapping in the driver for unicast rx
                    config.dest_ip = local_ip_be;
                    if (config.source_ip == 0 || config.source_ip == INADDR_NONE) {
                        SPDLOG_ERROR("Missing/invalid source_ip for AES67 unicast sink {}", pretty);
                        continue;
                    }
                }
            }

            if (!aes67_stream_map.count(pretty)) {
                aes67_stream_map[pretty] = config;
                pending_streams[pretty].state     = STREAM_CREATE_PENDING;
                pending_streams[pretty].retry_cnt = STREAM_RETRY_CNT;
                SPDLOG_DEBUG("Added AES67 {} stream {} to pending", is_source ? "source" : "sink", pretty);
            }
            json_stream_names.insert(pretty);
        }
    }

    // --- Remove missing Fusion Connect streams --------------------------------
    for (auto it = fusion_connect_stream_map.begin(); it != fusion_connect_stream_map.end(); ) {
        if (!json_stream_names.count(it->first)) {
            if (pending_streams[it->first].state == STREAM_CREATED) {
                if (remove_stream(it->second.stream_handle) == 0) {
                    SPDLOG_DEBUG("Removed Fusion Connect stream {}", it->first);
                } else {
                    SPDLOG_ERROR("Failed to remove Fusion Connect stream {}", it->first);
                }
            }
            pending_streams.erase(it->first);
            it = fusion_connect_stream_map.erase(it);
        } else {
            ++it;
        }
    }

    // --- Remove missing AES67 streams -----------------------------------------
    for (auto it = aes67_stream_map.begin(); it != aes67_stream_map.end(); ) {
        if (!json_stream_names.count(it->first)) {
            if (pending_streams[it->first].state == STREAM_CREATED) {
                if (it->second.is_source) {
                    sap_announcer.removeAnnouncement(it->first);
                }
                if (remove_stream(it->second.stream_handle) == 0) {
                    SPDLOG_DEBUG("Removed AES67 stream {}", it->first);
                } else {
                    SPDLOG_ERROR("Failed to remove AES67 stream {}", it->first);
                }
            }
            pending_streams.erase(it->first);
            it = aes67_stream_map.erase(it);
        } else {
            ++it;
        }
    }

    if (needs_retry) {
        SPDLOG_DEBUG("Deferring audio_streams_update until peer device discovery is available");
        return false;
    }

    return true;
}

void FusionConnectClient::audio_streams_update_func() {
    audio_streams_update_pending = true;
    if (process_audio_streams_update())
        audio_streams_update_pending = false;
}

void FusionConnectClient::maybe_retry_audio_streams_update() {
    const auto now = std::chrono::steady_clock::now();

    if (!audio_streams_update_pending)
        return;
    if (now - audio_update_last_retry < std::chrono::seconds(1))
        return;

    audio_update_last_retry = now;
    if (process_audio_streams_update())
        audio_streams_update_pending = false;
}

void FusionConnectClient::maybe_start_manager()
{
    const auto now = std::chrono::steady_clock::now();
    if (now - mgr_last_start_attempt < std::chrono::seconds(1)) return;
    mgr_last_start_attempt = now;

    if (!iface_sent) {
        if (!nl_set_eth_iface(client, enet_iface)) {
            SPDLOG_ERROR("Failed to set ETH iface '{}' before manager start", enet_iface);
            return;
        }
        iface_sent = true;
    }

    fusion_cn_ctrl_msg reply{};
    if (!client.send_message(FUSION_CN_CTRL_CMD_START_MANAGER, nullptr, 0, &reply)) {
        mgr_start_failures++;
        SPDLOG_ERROR("FC manager start: netlink send failed (attempt {})", mgr_start_failures);
        return;
    }

    if (reply.err == MGR_START_OK || reply.err == -MGR_START_ERRNO_RUNNING) {
        SPDLOG_INFO("FC manager started (err={})", reply.err);
        mgr_started = true;
        mgr_start_failures = 0;
    } else {
        mgr_start_failures++;
        SPDLOG_ERROR("Failed to start FC manager: err={} (attempt {})", reply.err, mgr_start_failures);
    }

    if (reply.data) free(reply.data);
}

void FusionConnectClient::reset_timing_session(const char *reason)
{
    if (!nl_reset_timing_state(client)) {
        SPDLOG_WARN("Failed to reset GPT timing state during {}", reason);
    }
    if (!set_pps_enable(false)) {
        SPDLOG_WARN("Failed to disable PPS during {}", reason);
    }

    ptp_anchor_pending = false;
    gpt_discipline_ready_logged = false;

    SPDLOG_INFO("Timing state reset due to {}", reason);
}

void FusionConnectClient::start_timing_session()
{
    if (!nl_reset_timing_state(client)) {
        SPDLOG_WARN("Failed to reset GPT timing state before enabling PPS");
    }
    if (!set_pps_enable(true)) {
        SPDLOG_WARN("Failed to enable PPS");
    } else {
        SPDLOG_INFO("Enabled PHC PPS output; waiting for GPT PPS/disciplined timing");
    }

    ptp_anchor_pending = true;
    gpt_discipline_ready_logged = false;
}

void FusionConnectClient::update_ptp_state()
{
    constexpr auto GM_WAIT = std::chrono::seconds(25);
    constexpr long long OFFSET_LOCK_NS = 1000; // 1 us lock window
    constexpr long long OFFSET_LOSS_NS = 10000; // 10 us loss threshold
    constexpr int LOCK_CONSEC = 3;
    constexpr int LOSS_CONSEC = 3;
    const auto now = std::chrono::steady_clock::now();
    constexpr auto STATUS_POLL_PERIOD = std::chrono::seconds(1);

    if (now - ptp_last_poll < std::chrono::milliseconds(period_ms)) return;
    if (now - ptp_last_status_poll < STATUS_POLL_PERIOD) return;
    ptp_last_poll = now;
    ptp_last_status_poll = now;

    bool gm_present = false;
    bool gm_present_valid = false;
    long long master_offset = 0;
    bool master_offset_valid = false;
    if (!poll_time_status_np(&gm_present, &gm_present_valid, &master_offset, &master_offset_valid)) {
        SPDLOG_WARN("PTP status poll failed; keeping previous sync state");
        return;
    }

    if (!gm_present_valid) {
        SPDLOG_DEBUG("PTP status missing gmPresent; keeping previous sync state");
        return;
    }

    if (ptp_state == PtpState::RESET) {
        ptp_sync_good = false;
        ptp_good_streak = 0;
        ptp_bad_streak = 0;
        ptp_anchor_pending = false;
        ptp_role_flag = -1;
        reset_timing_session("reset state");
        ptp_state = PtpState::WAIT_GM;
        ptp_state_since = now;
        SPDLOG_INFO("PTP reset; entering GM detection window");
    }

    for (int i = 0; i < 3; ++i) {
        PtpState prev_state = ptp_state;
        switch (ptp_state) {
        case PtpState::WAIT_GM:
            if (gm_present) {
                ptp_role_flag = 1; // follower
                ptp_sync_good = false;
                ptp_good_streak = 0;
                ptp_bad_streak = 0;
                ptp_anchor_pending = false;
                ptp_state = PtpState::WAIT_LOCK;
                ptp_state_since = now;
                SPDLOG_INFO("GM detected; waiting for lock");
            } else if (now - ptp_state_since >= GM_WAIT) {
                ptp_role_flag = 0; // GM
                ptp_sync_good = true;
                ptp_good_streak = 0;
                ptp_bad_streak = 0;
                ptp_anchor_pending = false;
                ptp_state = PtpState::SYNCED;
                ptp_state_since = now;
                SPDLOG_INFO("No GM after {}s; assuming GM role", GM_WAIT.count());
                start_timing_session();
            }
            break;

        case PtpState::WAIT_LOCK:
            if (!gm_present) {
                ptp_role_flag = -1;
                ptp_sync_good = false;
                ptp_good_streak = 0;
                ptp_bad_streak = 0;
                ptp_anchor_pending = false;
                ptp_state = PtpState::WAIT_GM;
                ptp_state_since = now;
                SPDLOG_INFO("GM lost before lock; restarting GM detection");
                reset_timing_session("GM lost before lock");
                break;
            }
            if (master_offset_valid) {
                long long best_abs = master_offset ? std::llabs(master_offset) : 0;
                if (best_abs <= OFFSET_LOCK_NS) {
                    ptp_good_streak++;
                } else {
                    ptp_good_streak = 0;
                }
                if (ptp_good_streak >= LOCK_CONSEC) {
                    ptp_sync_good = true;
                    ptp_bad_streak = 0;
                    ptp_anchor_pending = false;
                    ptp_state = PtpState::SYNCED;
                    ptp_state_since = now;
                    start_timing_session();
                }
            } else {
                ptp_good_streak = 0;
            }
            break;

        case PtpState::SYNCED:
            if (ptp_role_flag == 0) {
                if (gm_present) {
                    ptp_role_flag = 1;
                    ptp_sync_good = false;
                    ptp_good_streak = 0;
                    ptp_bad_streak = 0;
                    ptp_anchor_pending = false;
                    ptp_state = PtpState::WAIT_LOCK;
                    ptp_state_since = now;
                    SPDLOG_INFO("GM appeared; switching to follower and waiting for lock");
                    reset_timing_session("role transition to follower");
                }
                break;
            }

            if (!gm_present) {
                ptp_state = PtpState::RESET;
                ptp_state_since = now;
                SPDLOG_WARN("GM lost; resetting PTP state");
                reset_timing_session("GM lost");
                break;
            }

            if (master_offset_valid) {
                long long best_abs = master_offset ? std::llabs(master_offset) : 0;
                if (best_abs > OFFSET_LOSS_NS) {
                    ptp_bad_streak++;
                    if (ptp_bad_streak >= LOSS_CONSEC) {
                        if (ptp_sync_good) {
                            SPDLOG_WARN("PTP sync degraded ({}x > {} ns); keeping timing session active",
                                        LOSS_CONSEC, OFFSET_LOSS_NS);
                        } else {
                            SPDLOG_WARN("PTP still out of sync: offset={} ns streak={} (keeping timing session active)",
                                        master_offset, ptp_bad_streak);
                        }
                        ptp_sync_good = false;
                    }
                } else {
                    if (!ptp_sync_good && ptp_bad_streak >= LOSS_CONSEC) {
                        SPDLOG_INFO("PTP sync recovered; resuming in-sync state");
                    }
                    ptp_bad_streak = 0;
                    ptp_sync_good = true;
                }
            } else {
                ptp_bad_streak = 0;
            }
            break;
        default:
            break;
        }

        if (ptp_state == prev_state) break;
    }

    auto state_str = [&](PtpState s) {
        switch (s) {
        case PtpState::RESET: return "RESET";
        case PtpState::WAIT_GM: return "WAIT_GM";
        case PtpState::WAIT_LOCK: return "WAIT_LOCK";
        case PtpState::SYNCED: return "SYNCED";
        }
        return "UNKNOWN";
    };

    SPDLOG_DEBUG("PTP status: state={} gm_present={} role={} master_offset_valid={} master_offset={} good={}",
                 state_str(ptp_state), gm_present,
                 (ptp_role_flag == 0 ? "GM" : (ptp_role_flag == 1 ? "Follower" : "Unknown")),
                 master_offset_valid, master_offset, ptp_sync_good);
}

void FusionConnectClient::maybe_set_phc_anchor()
{
    constexpr uint64_t ONE_SEC_NS = 1000000000ULL;
    constexpr uint64_t MIN_LEAD_NS = 500000000ULL; // 500 ms
    if (!ptp_sync_good) return;

    fc_get_timing_status_reply st{};
    if (!nl_get_timing_status(client, &st)) return;

    if (st.discipline_ready && !gpt_discipline_ready_logged) {
        const uint32_t pps_seq = st.pps_seq;
        SPDLOG_INFO("GPT timing reports discipline ready (pps_seq={})", pps_seq);
        gpt_discipline_ready_logged = true;
    }

    if (!st.discipline_ready) {
        return;
    }

    if (st.epoch_valid) {
        ptp_anchor_pending = false;
        return;
    }

    if (!ptp_anchor_pending) return;

    uint64_t phc_ns = 0;
    if (!read_phc_ns(&phc_ns)) return;

    uint64_t next_pps_ns = ((phc_ns / ONE_SEC_NS) + 1ULL) * ONE_SEC_NS;
    uint64_t delta = next_pps_ns - phc_ns;
    if (delta < MIN_LEAD_NS) {
        SPDLOG_DEBUG("PHC anchor delayed: next PPS in {} ns (< {} ns)", delta, MIN_LEAD_NS);
        return;
    }

    if (nl_set_phc_anchor(client, next_pps_ns)) {
        ptp_anchor_pending = false;
        ptp_last_anchor = std::chrono::steady_clock::now();
        SPDLOG_INFO("Armed PHC anchor for next PPS at {} ns (lead {} ns)", next_pps_ns, delta);
    }
}

void FusionConnectClient::process() { 
    if (system_ip.empty()) {
        system_ip = get_system_ip(enet_iface, false);
        if (system_ip.empty()) return;
        sap_announcer.setSystemIp(system_ip);
        SPDLOG_INFO("Detected system IP: {}", system_ip);
    }

    if (!mgr_started) {
        maybe_start_manager();
        if (!mgr_started) return;
    }

    maybe_retry_audio_streams_update();

    update_ptp_state();
    maybe_set_phc_anchor();
    
    // --- Fusion Connect ---
    for (auto it = fusion_connect_stream_map.begin(); it != fusion_connect_stream_map.end();) {
        const std::string& name = it->first;
        auto              & cfg = it->second;

        auto ps_it = pending_streams.find(name);
        if (ps_it == pending_streams.end()) { ++it; continue; }
        auto &ps = ps_it->second;

        if (ps.state != STREAM_CREATE_PENDING) { ++it; continue; }

        if (create_stream(cfg) == 0) {
            ps.state = STREAM_CREATED;
            SPDLOG_DEBUG("Created Fusion Connect stream {} in process loop", name);
            if (!cfg.is_source && is_ip_mcast(cfg.dest_ip)) {
                join_multicast_group(cfg.dest_ip);
            }
            ++it; // advance normally
        } else {
            SPDLOG_WARN("Retrying create Fusion Connect stream {}", name);
            if (ps.retry_cnt == 0) {
                SPDLOG_ERROR("Failed to create Fusion Connect stream {}", name);
                pending_streams.erase(ps_it);
                it = fusion_connect_stream_map.erase(it);
            } else {
                --ps.retry_cnt;
                ++it; // keep entry, try again later
            }
        }
    }

    // --- AES67 ---
    for (auto it = aes67_stream_map.begin(); it != aes67_stream_map.end();) {
        const std::string& name = it->first;
        auto              & cfg = it->second;

        auto ps_it = pending_streams.find(name);
        if (ps_it == pending_streams.end()) { ++it; continue; }
        auto &ps = ps_it->second;

        if (ps.state != STREAM_CREATE_PENDING) { ++it; continue; }

        if (create_stream(cfg) == 0) {
            ps.state = STREAM_CREATED;
            SPDLOG_DEBUG("Created AES67 stream {} in process loop", name);
            if (!cfg.is_source && is_ip_mcast(cfg.dest_ip)) {
                join_multicast_group(cfg.dest_ip);
            } else if (cfg.is_source) {
                sap_announcer.addAnnouncement(name, cfg.dest_ip, cfg.channels,
                                            cfg.sample_rate, cfg.format, cfg.dest_port,
                                            cfg.payload_type, cfg.stream_handle);
            }
            ++it; // advance normally
        } else {
            SPDLOG_WARN("Retrying create AES67 stream {}", name);
            if (ps.retry_cnt == 0) {
                SPDLOG_ERROR("Failed to create AES67 stream {}", name);
                pending_streams.erase(ps_it);
                it = aes67_stream_map.erase(it);
            } else {
                --ps.retry_cnt;
                ++it; // keep entry, try again later
            }
        }
    }

    // Metrics every second (derived from period_ms)
    static uint32_t metrics_elapsed_ms = 0;
    metrics_elapsed_ms += static_cast<uint32_t>(period_ms);
    if (metrics_elapsed_ms >= 1000) {
        metrics_elapsed_ms -= 1000;
        std::vector<fusion_cn_metrics_record> recs;
        if (get_all_metrics(client, &recs)) {
            for (const auto &r : recs) {
                const auto &s = r.snap;

                const bool tx =
                    is_source_stream(r.stream_handle) || is_source_stream_by_name(r.stream_name);

                if (s.ts_snapshot_ns == 0) {
                    // Cold snapshot: still print so we don’t lose the record
                    SPDLOG_DEBUG("metrics {} stream={} ts=0 (cold, waiting for first snapshot)",
                                tx ? "TX" : "RX", r.stream_name);
                    continue;
                }

                if (tx) {
                    // TX:
                    SPDLOG_DEBUG(
                        "nmetrics TX stream={}: ts={} "
                        "pkts={} bytes={} "
                        "iat_min={}us p50={}us p99={}us "
                        "sched_err_p50={}us max={}us ",
                        r.stream_name, s.ts_snapshot_ns,
                        s.tx_packets_total, s.tx_bytes_total,
                        s.tx_iat_min_ns / 1000,
                        s.tx_iat_p50_ns / 1000,
                        s.tx_iat_p99_ns / 1000,
                        s.tx_sched_err_abs_p50_ns / 1000,
                        s.tx_sched_err_abs_max_ns / 1000
                    );
                } else {
                    // RX
                    SPDLOG_DEBUG(
                        "metrics RX stream={}: ts={} "
                        "pkts={} bytes={} lost={} reo={} dup={} malf={} late_drop={} rxq_drop={} burst_max={} batch_max={} "
                        "iat_min={}us p50={}us p99={}us jitter={}us "
                        "jb: cur={} min={} max={} avg={} "
                        "lat: path={}ns min={}ns max={}ns p50={}ns p99={}ns ",
                        r.stream_name, s.ts_snapshot_ns,
                        s.packets_total, s.bytes_total,
                        s.packets_lost, s.packets_reordered,
                        s.packets_dup, s.malformed_count, 
                        s.late_drop_count, s.rx_queue_drop_count, s.burst_loss_max, s.batch_max,
                        s.iat_min_ns / 1000, s.iat_p50_ns / 1000, s.iat_p99_ns / 1000, s.rfc3550_jitter_ns / 1000,
                        s.jb_depth_cur_samples, s.jb_depth_min_samples,
                        s.jb_depth_max_samples, s.jb_depth_avg_samples,
                        s.path_latency_est_ns, s.path_latency_min_ns, s.path_latency_max_ns,
                        s.path_latency_p50_ns, s.path_latency_p99_ns
                    );
                }
            }
        }
    }

    // SAP announcements every 30 seconds (derived from period_ms)
    static uint32_t sap_elapsed_ms = 0;
    sap_elapsed_ms += static_cast<uint32_t>(period_ms);
    if (sap_elapsed_ms >= 30000) {
        sap_elapsed_ms -= 30000;
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
