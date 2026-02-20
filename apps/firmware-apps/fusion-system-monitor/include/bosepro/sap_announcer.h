#pragma once

#include <string>
#include <map>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <cstdio>
#include <regex>
#include <spdlog/spdlog.h>
#include <chrono>

struct SAPAnnouncement {
    std::string stream_name;
    uint32_t multicast_ip; // Network byte order
    uint8_t channels;
    uint32_t sample_rate;
    int32_t format; // Matches fusion_cn_stream_config
    uint16_t sink_port;
    uint8_t payload_type;
    uint64_t stream_handle; // For SDP session ID
    bool is_deleted;
    uint32_t num_delete_pending;
    uint32_t ntp_ts;
};

class SAPAnnouncer {
private:
    std::string system_ip;
    std::string ptp_clock_id;
    int sock_fd;
    std::map<std::string, SAPAnnouncement> announcements;

    static uint64_t getNtpTimestamp()
    {
        using namespace std::chrono;

        auto now = system_clock::now();
        auto duration = now.time_since_epoch();
        uint64_t seconds = duration_cast<std::chrono::seconds>(duration).count();
        uint64_t fraction = ((duration_cast<std::chrono::nanoseconds>(duration).count() % 1'000'000'000ULL) * (1ULL << 32)) / 1'000'000'000ULL;

        return ((seconds + 2208988800ULL) << 32) | (fraction & 0xFFFFFFFF);
    }

    static std::string getPTPClockID() {
        FILE* fp = popen("/usr/sbin/pmc -u -b 0 -f /etc/linuxptp/ptp4l.conf 'GET TIME_STATUS_NP'", "r");
        if (!fp)
        {
            SPDLOG_ERROR("Failed to run pmc: {}", strerror(errno));
            return "";
        }

        char buf[256];
        std::string gmIdentity;
        std::string full_output;

        while (fgets(buf, sizeof(buf), fp))
        {
            std::string line(buf);
            full_output += line;

            auto pos = line.find("gmIdentity");
            if (pos != std::string::npos)
            {
                gmIdentity = line.substr(pos + strlen("gmIdentity"));
                gmIdentity.erase(0, gmIdentity.find_first_not_of(" \t")); // Trim leading whitespace
                gmIdentity.erase(gmIdentity.find_last_not_of(" \n\r\t") + 1); // Trim trailing whitespace
                SPDLOG_TRACE("Extracted gmIdentity: {}", gmIdentity);
                break;
            }
        }

        pclose(fp);

        if (gmIdentity.empty())
        {
            SPDLOG_ERROR("Failed to parse gmIdentity from pmc output");
            return "";
        }

        // Remove dots and validate total length
        std::string cleaned;
        for (char c : gmIdentity)
        {
            if (c == '.') continue;
            if (!isxdigit(c))
            {
                SPDLOG_ERROR("gmIdentity contains invalid character: {}", c);
                return "";
            }
            cleaned += c;
        }

        if (cleaned.length() != 16)
        {
            SPDLOG_ERROR("gmIdentity should be 8 bytes (16 hex chars), got '{}'", cleaned);
            return "";
        }

        // Format as XX-XX-XX-XX-XX-XX-XX-XX (uppercase)
        std::string clock_id;
        for (size_t i = 0; i < 16; i += 2)
        {
            if (i > 0) clock_id += "-";
            clock_id += std::toupper(cleaned[i]);
            clock_id += std::toupper(cleaned[i + 1]);
        }

        return clock_id;
    }


    static std::string ipToString(uint32_t ip) {
        struct in_addr addr;
        addr.s_addr = ip;
        return std::string(inet_ntoa(addr));
    }

    static uint16_t hashString(const std::string& str) {
        unsigned long hash = 5381;
        for (char c : str) {
            hash = ((hash << 5) + hash) + c; // hash * 33 + c
        }
        return static_cast<uint16_t>(hash & 0xFFFF);
    }

public:
    SAPAnnouncer(const std::string& sys_ip) : system_ip(sys_ip), sock_fd(-1) {
        sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
        if (sock_fd < 0) {
            SPDLOG_ERROR("Failed to create SAP socket: {}", strerror(errno));
            return;
        }
        unsigned char ttl = 255;
        setsockopt(sock_fd, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl));
    }

    inline void setSystemIp(const std::string& sys_ip) {
        system_ip = sys_ip;
    }

    ~SAPAnnouncer() {
        if (sock_fd >= 0) {
            close(sock_fd);
        }
    }

    inline const std::map<std::string, SAPAnnouncement>& getAnnouncements() const {
        return announcements;
    }

    inline void addAnnouncement(const std::string& stream_name, uint32_t multicast_ip, uint8_t channels,
                               uint32_t sample_rate, int32_t format, uint16_t sink_port,
                               uint8_t payload_type, uint64_t stream_handle) {
        if (announcements.find(stream_name) != announcements.end()) {
            SPDLOG_ERROR("SAP stream '{}' already exists", stream_name);
            return;
        }
        SAPAnnouncement ann = {
            stream_name, multicast_ip, channels, sample_rate, format, sink_port,
            payload_type, stream_handle, false, 2, (uint32_t)(getNtpTimestamp() >> 32)
        };
        announcements[stream_name] = ann;
        SPDLOG_INFO("Added announcement for '{}'", stream_name);
    }

    inline void removeAnnouncement(const std::string& stream_name) {
        auto it = announcements.find(stream_name);
        if (it != announcements.end()) {
            if (!it->second.is_deleted) {
                it->second.is_deleted = true;
                sendAnnouncement(it->second);
                SPDLOG_INFO("Marked '{}' for deletion", stream_name);
            }
        }
    }

    inline void sendAnnouncement(const SAPAnnouncement& ann) {
        ptp_clock_id = getPTPClockID();
        if (ptp_clock_id.empty()) {
            SPDLOG_ERROR("Skipping SAP for '{}': No PTP clock ID", ann.stream_name);
            return;
        }
        // Build SDP
        std::string sdp;
        std::string name = ann.stream_name;
        if (name.find("AES67_") == 0) {
            name = name.substr(6); // Remove AES67_ prefix
        }
        std::string channels_str;
        for (uint8_t i = 1; i <= ann.channels; ++i) {
            channels_str += "ch" + std::to_string(i);
            if (i < ann.channels) channels_str += ",";
        }

        // Build SAP header
        std::string payload_type = "application/sdp";
        struct in_addr origin_ip;
        uint8_t sap_header[8 + payload_type.size() + 1] = {0};
        sap_header[0] = 0x20; // Version=1, IPv4
        if (ann.is_deleted) sap_header[0] |= 0x04; // Deletion flag
        sap_header[1] = 0x00; // No auth
        uint16_t msgID = hashString(ann.stream_name);
        sap_header[2] = (msgID >> 8) & 0xFF;
        sap_header[3] = msgID & 0xFF;
        inet_pton(AF_INET, system_ip.c_str(), &origin_ip);
        memcpy(&sap_header[4], &origin_ip, sizeof(origin_ip));
        memcpy(&sap_header[8], payload_type.c_str(), payload_type.size() + 1);

        char sdp_buf[512];
        snprintf(sdp_buf, sizeof(sdp_buf),
                 "v=0\r\n"
                 "o=- %u %u IN IP4 %s\r\n"
                 "s=%s\r\n"
                 "c=IN IP4 %s/32\r\n"
                 "t=0 0\r\n"
                 "m=audio %u RTP/AVP %u\r\n"
                 "i=%u channels: %s\r\n"
                 "a=recvonly\r\n"
                 "a=rtpmap:%u L24/%u/%u\r\n"
                 "a=ptime:1\r\n"
                 "a=ts-refclk:ptp=IEEE1588-2008:%s:0\r\n"
                 "a=mediaclk:direct=0\r\n",
                 msgID + 16, msgID + 16, system_ip.c_str(),
                 name.c_str(), ipToString(ann.multicast_ip).c_str(),
                 ann.sink_port, ann.payload_type,
                 (unsigned int)ann.channels, channels_str.c_str(),
                 ann.payload_type, ann.sample_rate, (unsigned int)ann.channels,
                 ptp_clock_id.c_str());
        sdp = sdp_buf;

        // Combine and send
        std::string packet(reinterpret_cast<char*>(sap_header), sizeof(sap_header));
        packet.append(sdp);
        sockaddr_in dest = {};
        dest.sin_family = AF_INET;
        dest.sin_port = htons(9875);
        inet_pton(AF_INET, "239.255.255.255", &dest.sin_addr);
        if (sendto(sock_fd, packet.c_str(), packet.size(), 0, (struct sockaddr*)&dest, sizeof(dest)) < 0) {
            SPDLOG_ERROR("Failed to send SAP for '{}': {}", ann.stream_name, strerror(errno));
        } else {
            SPDLOG_TRACE("{} {} (from {})", (ann.is_deleted ? "[SAP DELETE]" : "[SAP ANNOUNCE]"), ann.stream_name, system_ip);
        }
    }

    inline void handleDeletion(const std::string& stream_name) {
        auto it = announcements.find(stream_name);
        if (it != announcements.end() && it->second.is_deleted && it->second.num_delete_pending > 0) {
            it->second.num_delete_pending--;
            if (it->second.num_delete_pending == 0) {
                SPDLOG_INFO("SAP CLEANUP Removing '{}'", stream_name);
                announcements.erase(stream_name);
            }
        }
    }

    inline void announceAll() {
        for (auto& pair : announcements) {
            if (!pair.second.is_deleted) {
                sendAnnouncement(pair.second);
            }
        }
    }
};
