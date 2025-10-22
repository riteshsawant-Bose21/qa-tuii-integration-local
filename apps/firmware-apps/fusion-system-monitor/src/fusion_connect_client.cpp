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
#include <array>
#include <map>
#include <set>
#include <fstream>
#include <json/json.h>
#include <sys/ioctl.h>
#include <linux/ptp_clock.h>
#include <cstdio>
#include <climits>
#include <chrono>
#include <thread>
#include <regex>
#include <sys/timex.h>
#include <fcntl.h>
#include <linux/ptp_clock.h>
#include <time.h>
#include <algorithm>
#include <dirent.h>

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
    FUSION_CN_CTRL_CMD_SET_PTP_SYNC,
    FUSION_CN_CTRL_CMD_ADD_STREAM,
    FUSION_CN_CTRL_CMD_REMOVE_STREAM,
    FUSION_CN_CTRL_CMD_GET_METRICS
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

struct fusion_cn_metrics_snapshot
{
    uint64_t ts_snapshot_ns;

    uint64_t packets_total, bytes_total;
    uint64_t packets_lost, packets_reordered, packets_dup;
    uint64_t packets_marked, malformed_count;
    uint64_t late_drop_count, early_drop_count;
    uint64_t burst_loss_max;

    uint32_t rfc3550_jitter_ns;
    uint32_t iat_min_ns, iat_p50_ns, iat_p99_ns;

    uint32_t jb_target_samples;
    uint32_t jb_depth_cur_samples, jb_depth_min_samples, jb_depth_max_samples, jb_depth_avg_samples;
    uint64_t deadline_miss_count;
    uint32_t resync_count;
    uint64_t concealment_frames;

    int32_t  skew_ppb, ptp_offset_ns, rtp_to_phc_err_ns;
    uint32_t path_latency_est_ns, e2e_playout_latency_ns;

    uint8_t  audio_present;
    int16_t  level_fast_dbfs, level_slow_dbfs;
    uint8_t  silence_ratio_pct;

    /* TX totals */
    uint64_t tx_packets_total;
    uint64_t tx_bytes_total;

    /* NEW: TX timing EMAs (exported from m->win by the kernel) */
    uint32_t tx_iat_min_ns;
    uint32_t tx_iat_p50_ns;
    uint32_t tx_iat_p99_ns;
    uint32_t tx_sched_err_abs_p50_ns;
} __attribute__((packed));

struct fusion_cn_metrics_record {
    uint64_t stream_handle;
    char stream_name[32];
    struct fusion_cn_metrics_snapshot snap;
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

static bool nl_set_ptp_sync_raw(NetlinkClient& c, bool sync) {
    fusion_cn_ctrl_msg reply{};
    uint8_t v = sync ? 1 : 0;
    if (!c.send_message(FUSION_CN_CTRL_CMD_SET_PTP_SYNC, &v, sizeof(v), &reply)) return false;
    if (reply.err != 0) SPDLOG_ERROR("SET_PTP_SYNC({}) err={}", (int)sync, reply.err);
    if (reply.data) free(reply.data);
    return reply.err == 0;
}

static std::string ptp_for_interface(const std::string& ifname) {
    if (ifname.empty()) return {};
    char base[256];
    // base is bounded by interface name length + constant; ifname is under kernel limit
    std::snprintf(base, sizeof(base), "/sys/class/net/%s/device/ptp", ifname.c_str());

    DIR* d = opendir(base);
    if (!d) return {};

    std::string dev;
    for (dirent* de; (de = readdir(d)) != nullptr; ) {
        // ignore . and ..
        if (de->d_name[0] == '.' && (de->d_name[1] == '\0' ||
                                     (de->d_name[1] == '.' && de->d_name[2] == '\0')))
            continue;

        // entries here are "ptpX"
        if (std::strncmp(de->d_name, "ptp", 3) == 0) {
            std::string cand = "/dev/";
            cand += de->d_name;                  // no fixed-size buffer → no truncation
            if (access(cand.c_str(), R_OK | W_OK) == 0) {
                dev = std::move(cand);
                break;
            }
        }
    }
    closedir(d);
    return dev;
}

static std::string first_present_ptp() {
    for (int i = 0; i < 16; ++i) {
        std::string path = "/dev/ptp" + std::to_string(i);
        if (access(path.c_str(), R_OK | W_OK) == 0) return path;
    }
    return {};
}

static std::string choose_ptp_device(const std::string& ifname) {
    if (auto s = ptp_for_interface(ifname); !s.empty()) return s;
    return first_present_ptp();
}

// Use legacy-safe PTP_SYS_OFFSET (available everywhere) to estimate offset.
// Returns median(system_time - phc_time) in *ns_out.
static bool sys_phc_offset_ns(const char* ptp_dev, long long* ns_out) {
    if (!ptp_dev || !ns_out) return false;
    int fd = open(ptp_dev, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return false;

    // 5 measurements = 11 timestamps (sys, phc, sys)*5 → enough for a robust median
    struct ptp_sys_offset req{};
    req.n_samples = 5;

    bool ok = false;
    if (ioctl(fd, PTP_SYS_OFFSET, &req) == 0) {
        // For each sample k:
        //   sys1 = ts[3k], phc = ts[3k+1], sys2 = ts[3k+2]
        // Approx offset ≈ ((sys1 + sys2)/2) - phc
        long long offs[5]; int m = 0;
        for (unsigned k = 0; k < req.n_samples; ++k) {
            const long long sys1 = req.ts[3*k].sec  * 1000000000LL + req.ts[3*k].nsec;
            const long long phc  = req.ts[3*k+1].sec* 1000000000LL + req.ts[3*k+1].nsec;
            const long long sys2 = req.ts[3*k+2].sec* 1000000000LL + req.ts[3*k+2].nsec;
            const long long sys_mid = (sys1/2 + sys2/2) + ((sys1&1) && (sys2&1)); // avoid overflow
            offs[m++] = sys_mid - phc;
        }
        std::nth_element(offs, offs + m/2, offs + m);
        *ns_out = offs[m/2];
        ok = true;
    }
    close(fd);
    return ok;
}

static bool set_ptp_sync(NetlinkClient& c)
{
    // --- pick PHC (unchanged) ---
    std::string ptp_dev = choose_ptp_device("lan3");
    if (ptp_dev.empty() && access("/dev/ptp1", R_OK | W_OK) == 0) ptp_dev = "/dev/ptp1";
    if (ptp_dev.empty()) ptp_dev = first_present_ptp();
    if (ptp_dev.empty()) { SPDLOG_WARN("PTP: no PHC found (lan3/ptp1/first-present)"); return false; }

    const char* pmc = access("/usr/sbin/pmc", X_OK) == 0 ? "/usr/sbin/pmc" : "pmc";
    auto trim = [](std::string s){ const char* ws=" \t\r\n"; size_t a=s.find_first_not_of(ws); size_t b=s.find_last_not_of(ws); return a==std::string::npos?std::string():s.substr(a,b-a+1); };

    // gmPresent poller: returns 1 if true, 0 if false, -1 if unknown/error
    auto poll_gm_present = [&](void) -> int {
        char cmd[256];
        std::snprintf(cmd, sizeof(cmd), "%s -u -b 0 -f /etc/linuxptp/ptp4l.conf 'GET TIME_STATUS_NP' 2>/dev/null", pmc);
        FILE* fp = popen(cmd, "r");
        if (!fp) return -1;

        char buf[512];
        int result = -1;
        while (fgets(buf, sizeof(buf), fp)) {
            std::string line(buf);
            auto pos = line.find("gmPresent");
            if (pos != std::string::npos) {
                std::string v = trim(line.substr(pos + strlen("gmPresent")));
                for (char& ch : v) ch = (char)tolower((unsigned char)ch);
                if (v.find("true")  != std::string::npos) result = 1;
                else if (v.find("false") != std::string::npos) result = 0;
                break;
            }
        }
        pclose(fp);
        return result;
    };

    // --- Decide role using only gmPresent (unchanged) ---
    constexpr int GM_FALSE_CONSEC = 25; 
    constexpr int SAMPLE_MS       = 500;
    constexpr int MAX_DECIDE_MS   = 15000;

    int false_streak = 0;
    int role_flag = -1; // 1=Follower, 0=GM, -1=unknown
    for (int elapsed = 0; elapsed < MAX_DECIDE_MS; elapsed += SAMPLE_MS) {
        const int r = poll_gm_present();
        if (r == 1) { role_flag = 1; break; }                 // Follower on first TRUE
        if (r == 0) { if (++false_streak >= GM_FALSE_CONSEC) { role_flag = 0; break; } }
        std::this_thread::sleep_for(std::chrono::milliseconds(SAMPLE_MS));
    }
    if (role_flag == -1) role_flag = 1; // safer default → Follower
    SPDLOG_INFO("PTP: startup role by gmPresent-only: {} false_streak {}", role_flag == 0 ? "GM" : "Follower", false_streak);

    // --- Main wait loop ---
    const auto start = std::chrono::steady_clock::now();
    auto last_reprobe = start;

    // follower pre-step grace: allow escape if we’ve been near-TAI “too long” with small corrected error
    constexpr long long OFFSET_OK_NS        = 200000;      // 200 µs (unchanged)
    constexpr long long NEAR_TAI_TOL_NS     = 200000000LL; // ±200 ms band around whole seconds in [30..40]
    constexpr int       PRESTEP_GRACE_MS    = 15000;       // after this many ms near-TAI, allow bypass if small
    constexpr int       PRESTEP_GOOD_NEED   = 6;           // small best_abs samples required to bypass
    int good_small_while_near_tai = 0;
    bool in_near_tai             = false;
    auto near_tai_enter          = start;

    int good = 0;

    for (;;)
    {
        // Re-probe gmPresent periodically (role can change)
        if (std::chrono::steady_clock::now() - last_reprobe > std::chrono::seconds(3)) {
            const int r = poll_gm_present();
            if (r == 1) { role_flag = 1; false_streak = 0; }
            else if (r == 0) { if (role_flag != 0 && ++false_streak >= GM_FALSE_CONSEC) role_flag = 0; }
            last_reprobe = std::chrono::steady_clock::now();
        }
        const bool i_am_gm = (role_flag == 0);

        // --- Measure REALTIME↔PHC ---
        long long med_ns = 0;
        const bool have = sys_phc_offset_ns(ptp_dev.c_str(), &med_ns);

        // TAI from kernel if present (for corrected offset calc)
        int tai_sec = 0; bool have_tai = false;
        { struct timex tx{}; if (adjtimex(&tx) >= 0) { tai_sec = tx.tai; have_tai = (tx.tai >= 10); } }

        // Heuristic TAI guess if raw is near 30..40 s within ±200 ms
        long long raw_abs = LLONG_MAX;
        int tai_guess_sec = 0; bool have_guess = false;
        if (have) {
            raw_abs = std::llabs(med_ns);
            const long long nearest_sec = (raw_abs + 500000000LL) / 1000000000LL;
            if (nearest_sec >= 30 && nearest_sec <= 40) {
                const long long nearest_ns = nearest_sec * 1000000000LL;
                const long long err        = std::llabs(raw_abs - nearest_ns);
                if (err <= NEAR_TAI_TOL_NS) { tai_guess_sec = (int)nearest_sec; have_guess = true; }
            }
        }

        // Best corrected offset: min(raw, ±TAI, ±guess)
        long long best_abs = LLONG_MAX;
        if (have) {
            long long best = raw_abs;
            if (have_tai) {
                const long long corr = (long long)tai_sec * 1000000000LL;
                const long long a = std::llabs(med_ns - corr);
                const long long b = std::llabs(med_ns + corr);
                if (a < best) best = a;
                if (b < best) best = b;
            }
            if (have_guess) {
                const long long corr = (long long)tai_guess_sec * 1000000000LL;
                const long long a = std::llabs(med_ns - corr);
                const long long b = std::llabs(med_ns + corr);
                if (a < best) best = a;
                if (b < best) best = b;
            }
            best_abs = best;
        }

        // Detailed log
        SPDLOG_DEBUG("REALTIME-PHC({}) med={} ns, raw_abs={} ns, TAI={} s ({}), guess={} s ({}), best_abs={} ns, role={}",
                     ptp_dev, med_ns, raw_abs,
                     tai_sec, have_tai ? "have" : "n/a",
                     tai_guess_sec, have_guess ? "used" : "n/a",
                     best_abs, i_am_gm ? "GM" : "Follower");

        // Compute near-TAI band (whole seconds 30..40 ±200ms)
        bool near_tai_now = false;
        long long sec_err = 0;
        if (have) {
            const long long sec     = (raw_abs + 500000000LL) / 1000000000LL;
            const long long nearest = sec * 1000000000LL;
            sec_err = std::llabs(raw_abs - nearest);
            near_tai_now = (sec >= 30 && sec <= 40 && sec_err <= NEAR_TAI_TOL_NS);
        }

        // Track how long we’ve been continuously in the near-TAI band.
        if (!i_am_gm) {
            if (near_tai_now) {
                if (!in_near_tai) { in_near_tai = true; near_tai_enter = std::chrono::steady_clock::now(); good_small_while_near_tai = 0; }
                if (best_abs != LLONG_MAX && best_abs <= OFFSET_OK_NS) ++good_small_while_near_tai;

                const auto near_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                                         std::chrono::steady_clock::now() - near_tai_enter).count();

                // If we’ve lingered near-TAI for PRESTEP_GRACE_MS and we’ve seen enough small corrected offsets,
                // bypass the pre-step block and proceed to the normal good>=3 gate.
                const bool bypass_prestep = (near_ms >= PRESTEP_GRACE_MS) && (good_small_while_near_tai >= PRESTEP_GOOD_NEED);

                if (!bypass_prestep) {
                    // Still in pre-step; keep blocking and do not accumulate 'good'
                    good = 0;
                    // (optional one-liner log if you want it back:)
                    // SPDLOG_DEBUG("PTP gate: raw_abs={} ns, sec_err={} ns, near_tai=true ({} ms), best_abs={} ns, bypass={} -> holding",
                    //              raw_abs, sec_err, (int)near_ms, best_abs, bypass_prestep?"yes":"no");
                    std::this_thread::sleep_for(std::chrono::milliseconds(500));
                    continue;
                }
                // else: fall through → allow normal good accumulation
            } else {
                in_near_tai = false;
                good_small_while_near_tai = 0;
            }
        }

        // Tight corrected-offset gate (same as before)
        const bool good_now = (best_abs != LLONG_MAX) && (best_abs <= OFFSET_OK_NS);
        good = good_now ? (good + 1) : 0;

        if (good >= 3) {
            SPDLOG_INFO("PTP: enabling in kernel (role={}, best_abs={} ns)", i_am_gm ? "GM" : "Follower", best_abs);
            if (!nl_set_ptp_sync_raw(c, true)) {
                SPDLOG_ERROR("PTP: criteria met but kernel refused SET_PTP_SYNC(true)");
                return false;
            }
            SPDLOG_INFO("PTP: kernel accepted SET_PTP_SYNC(true)");
            return true;
        }

        if (std::chrono::steady_clock::now() - start > std::chrono::seconds(120)) {
            SPDLOG_WARN("PTP: criteria not met within 120 s (role={}, last best_abs={} ns).",
                        i_am_gm ? "GM" : "Follower", best_abs);
            return false;
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

static bool get_all_metrics(NetlinkClient &client,
                            std::vector<fusion_cn_metrics_record> *out)
{
    fusion_cn_ctrl_msg reply{};
    if (!client.send_message(FUSION_CN_CTRL_CMD_GET_METRICS, nullptr, 0, &reply)) {
        SPDLOG_ERROR("GET_METRICS: send_message failed");
        return false;
    }

    // SPDLOG_DEBUG("GET_METRICS: err={} payload={}B sizeof(record)={}B sizeof(snapshot)={}B",
    //              reply.err, reply.data_size,
    //              sizeof(fusion_cn_metrics_record),
    //              sizeof(fusion_cn_metrics_snapshot));

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

    // SPDLOG_DEBUG("GET_METRICS: {} record(s)", n);
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
    std::map<std::string, struct fc_stream_state> pending_streams;
    std::string network_interface;
    SAPAnnouncer sap_announcer;
    uint32_t announce_counter;

    std::string audio_streams_update;

    bool is_source_stream(uint64_t stream_handle);
    int create_stream(fusion_cn_stream_config& config);
    int remove_stream(uint64_t stream_handle);
    void join_multicast_group(uint32_t multicast_ip);
    void audio_streams_update_func();

    MODULE_DECLARE(FusionConnectClient);
};

MODULE_REGISTER(FusionConnectClient, "fusion_connect_client");

FusionConnectClient::FusionConnectClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration), ptp_synchronized(0), mgr_started(false), device_id(""),
      network_interface("lan3"), sap_announcer(get_system_ip()), announce_counter(0) {
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

    int ifindex = if_nametoindex(network_interface.c_str());
    if (!ifindex) {
        SPDLOG_ERROR("Failed to get interface index for {}: {}", network_interface, strerror(errno));
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

    SPDLOG_DEBUG("Joining multicast group {} on interface {}", ip_to_string(multicast_ip), network_interface);

    if (sendto(sock, buf.data(), nlh->nlmsg_len, 0, reinterpret_cast<sockaddr*>(&nladdr), sizeof(nladdr)) < 0) {
        SPDLOG_ERROR("Failed to send netlink message for IGMP join: {}", strerror(errno));
        close(sock);
        return;
    }

    close(sock);
    SPDLOG_INFO("Successfully joined multicast group {} on interface {}", ip_to_string(multicast_ip), network_interface);
}

void FusionConnectClient::audio_streams_update_func() {
    if (audio_streams_update.empty()) {
        SPDLOG_DEBUG("audio_streams_update is empty, exiting");
        return;
    }

    SPDLOG_DEBUG("Received audio_streams_update: {}", audio_streams_update);

    // --- Crucial pre-reqs -----------------------------------------------------
    if (device_id.empty()) {
        device_id = get_device_id(system_ip);
        if (device_id.empty()) {
            SPDLOG_ERROR("Failed to get device_id after audio_streams update!");
            return;
        }
        SPDLOG_INFO("Initialized device_id: {}, system_ip: {}", device_id, system_ip);
    }

    Json::Value root;
    Json::Reader reader;
    if (!reader.parse(audio_streams_update, root) || !root.isArray()) {
        SPDLOG_ERROR("Failed to parse audio_streams_update JSON or not an array: {}", audio_streams_update);
        return;
    }

    auto ip_to_be32 = [](const std::string& s) -> uint32_t {
        if (s.empty()) return 0;
        return inet_addr(s.c_str()); // returns INADDR_NONE on invalid
    };

    auto local_ip_be = ip_to_be32(system_ip);
    if (local_ip_be == INADDR_NONE || local_ip_be == 0) {
        SPDLOG_ERROR("Invalid system_ip '{}'", system_ip);
        return;
    }

    std::set<std::string> json_stream_names;

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

                // Resolve peer (dest device) IP (no default to local)
                uint32_t dest_ip = 0;
                for (int retry = 0; retry < 100 && (dest_ip == 0 || dest_ip == INADDR_NONE); ++retry) {
                    dest_ip = ip_to_be32(query_device_ip(dest_device_uid, system_ip));
                    if (dest_ip == 0 || dest_ip == INADDR_NONE) usleep(500000);
                }
                config.dest_ip = dest_ip;

                if (config.dest_ip == 0 || config.dest_ip == INADDR_NONE) {
                    SPDLOG_ERROR("Failed to resolve destination IP for {}", config.stream_name);
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

                // Resolve peer (source device) IP (no default to local)
                uint32_t src_ip = 0;
                for (int retry = 0; retry < 100 && (src_ip == 0 || src_ip == INADDR_NONE); ++retry) {
                    src_ip = ip_to_be32(query_device_ip(source_device_uid, system_ip));
                    if (src_ip == 0 || src_ip == INADDR_NONE) usleep(500000);
                }
                sink_cfg.source_ip = src_ip;

                if (sink_cfg.source_ip == 0 || sink_cfg.source_ip == INADDR_NONE) {
                    SPDLOG_ERROR("Failed to resolve source IP for {}", sink_cfg.stream_name);
                } else if (!fusion_connect_stream_map.count(sink_cfg.stream_name)) {
                    fusion_connect_stream_map[sink_cfg.stream_name] = sink_cfg;
                    pending_streams[sink_cfg.stream_name].state = STREAM_CREATE_PENDING;
                    pending_streams[config.stream_name].retry_cnt = STREAM_RETRY_CNT;
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
}

void FusionConnectClient::process() { 
    if (!ptp_synchronized) {
        if (set_ptp_sync(client)) {
            ptp_synchronized = 1;
        } else {
            // Not synced yet—bail early, we’ll try again next tick
            return;
        }
    }

    if (ptp_synchronized && !mgr_started) {
        fusion_cn_ctrl_msg reply{};
        if (client.send_message(FUSION_CN_CTRL_CMD_START_MANAGER, nullptr, 0, &reply)) {
            if (reply.err == MGR_START_OK || reply.err == -MGR_START_ERRNO_RUNNING) {
                mgr_started = true;
            } else if (reply.err == -MGR_START_ERRNO_PTP) {
                ptp_synchronized = 0;
                if (reply.data) free(reply.data);
                return;
            }
        }
        if (reply.data) free(reply.data);
    }

    if (!(ptp_synchronized && mgr_started)) return;

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
            } else {
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

    // Metrics every second
    static uint32_t metrics_tick = 0;
    if ((metrics_tick++ % 5) == 0) {
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

                // if (tx) {
                //     // TX: totals + TX timing EMAs (ns -> us)
                //     SPDLOG_DEBUG(
                //         "metrics TX stream={} ts={} "
                //         "tx: pkts={} bytes={} iat_min={}us p50={}us p99={}us sched_err_p50={}us",
                //         r.stream_name, s.ts_snapshot_ns,
                //         s.tx_packets_total, s.tx_bytes_total,
                //         s.tx_iat_min_ns / 1000,
                //         s.tx_iat_p50_ns / 1000,
                //         s.tx_iat_p99_ns / 1000,
                //         s.tx_sched_err_abs_p50_ns / 1000
                //     );
                // } else {
                //     // RX
                //     SPDLOG_DEBUG(
                //         "metrics RX stream={} ts={} "
                //         "rx: pkts={} bytes={} lost={} reo={} dup={} marked={} malf={} late_drop={} early_drop={} burst_max={} "
                //         "iat_min={}us p50={}us p99={}us jitter={}us "
                //         "jb: target={} cur={} min={} max={} avg={} "
                //         "sync: skew_ppb={} ptp_off={}ns rtp->phc={}ns "
                //         "lat: path={}ns e2e_playout={}ns "
                //         "audio: present={} fast_dbfs={} slow_dbfs={} silence={}%",
                //         r.stream_name, s.ts_snapshot_ns,
                //         s.packets_total, s.bytes_total,
                //         s.packets_lost, s.packets_reordered,
                //         s.packets_dup, s.packets_marked,
                //         s.malformed_count, s.late_drop_count,
                //         s.early_drop_count, s.burst_loss_max,
                //         s.iat_min_ns / 1000, s.iat_p50_ns / 1000, s.iat_p99_ns / 1000, s.rfc3550_jitter_ns / 1000,
                //         s.jb_target_samples, s.jb_depth_cur_samples, s.jb_depth_min_samples,
                //         s.jb_depth_max_samples, s.jb_depth_avg_samples,
                //         s.skew_ppb, s.ptp_offset_ns, s.rtp_to_phc_err_ns,
                //         s.path_latency_est_ns, s.e2e_playout_latency_ns,
                //         s.audio_present, s.level_fast_dbfs, s.level_slow_dbfs, s.silence_ratio_pct
                //     );
                // }
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
