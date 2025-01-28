#pragma once

#include <stdlib.h>
#include <unistd.h>

uint64_t get_realtime_ns();
int open_unix_udp_socket(std::string& path);
int open_inet_udp_socket(std::string ip_addr, uint32_t port_num);
