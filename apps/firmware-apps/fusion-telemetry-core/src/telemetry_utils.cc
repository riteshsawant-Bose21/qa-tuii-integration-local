#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <iostream>
#include <spdlog/spdlog.h>
#include <spdlog/fmt/ostr.h>

#define TIMESPEC_NSEC(ts)       ((ts)->tv_sec * 1000000000ULL + (ts)->tv_nsec)

uint64_t get_realtime_ns()
{
	struct timespec now_ts;
	clock_gettime(CLOCK_REALTIME, &now_ts);
	return TIMESPEC_NSEC(&now_ts);
}

int open_unix_udp_socket(std::string& path)
{
    struct sockaddr_un ux_socket_addr;
    int ux_socket_fd;
    const char *ux_path = path.c_str();

     // Cleanup
    remove(path.c_str());

     if ((ux_socket_fd = socket(AF_UNIX, SOCK_DGRAM, 0)) < 0) 
     {
         // Report error
         SPDLOG_ERROR("UX Socket Open failed");
         return -1;
     }

    ux_socket_addr.sun_family = AF_UNIX;
    snprintf(ux_socket_addr.sun_path, (strlen(ux_path)+1), "%s", ux_path);

    if ((bind(ux_socket_fd, 
              (struct sockaddr *)&ux_socket_addr, 
              sizeof(struct sockaddr_un))) != 0) 
    {
         // Report error
         SPDLOG_ERROR("UX Socket Bind failed");
         return -1;
    }

    return ux_socket_fd;
}

int open_inet_udp_socket(std::string ip_addr, uint32_t port_num)
{
    struct sockaddr_in inet_socket_addr;

    int sd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sd < 0) {
        //TODO: Report error

        return -1;
    }

    inet_socket_addr.sin_family      = AF_INET;
    inet_socket_addr.sin_port        = htons(port_num);
    inet_socket_addr.sin_addr.s_addr = inet_addr(ip_addr.c_str());

    int one = 1;
    int r = setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, (char *)&one,
            sizeof(one));
    if (r < 0) {
        //TODO: Report error

        return -1;
    }

    one = 1;
    r = setsockopt(sd, SOL_SOCKET, SO_REUSEPORT, (char *)&one, sizeof(one));
    if (r < 0) {
        //TODO: Report error

        return -1;
    }

    if (bind(sd, (struct sockaddr *)&inet_socket_addr, sizeof(inet_socket_addr)) < 0) {
        //TODO: Report error

        return -1;
    }

    return sd;
}
