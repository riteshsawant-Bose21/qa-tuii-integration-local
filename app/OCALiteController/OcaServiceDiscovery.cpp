/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : OCA Service Discovery implementation using DNS-SD
 */

// ---- Include system wide include files ----
#include <cstring>
#include <chrono>
#include <thread>
#include <iostream>
#include <algorithm>
#include <sys/select.h>
#include <unistd.h>

// ---- Include local include files ----

#include <sys/socket.h>
#include <arpa/inet.h>

#ifndef STM32H7S7xx
#include <netdb.h>
#include <netinet/in.h>
#else
#include "dnssd.h"
#include "PlatformInterface/stm32/OcaPlatformSTM32.h"
#endif

#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include <HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.h>
#include "OcaServiceDiscovery.h"
// ---- Helper functions ----

/**
 * Convert DNS-SD error code to string
 */
#ifndef STM32H7S7xx
static const char *DNSServiceErrorToString(DNSServiceErrorType error)
{
    switch (error)
    {
    case kDNSServiceErr_NoError:
        return "No Error";
    case kDNSServiceErr_Unknown:
        return "Unknown Error";
    case kDNSServiceErr_NoSuchName:
        return "No Such Name";
    case kDNSServiceErr_NoMemory:
        return "No Memory";
    case kDNSServiceErr_BadParam:
        return "Bad Parameter";
    case kDNSServiceErr_BadReference:
        return "Bad Reference";
    case kDNSServiceErr_BadState:
        return "Bad State";
    case kDNSServiceErr_BadFlags:
        return "Bad Flags";
    case kDNSServiceErr_Unsupported:
        return "Unsupported";
    case kDNSServiceErr_NotInitialized:
        return "Not Initialized";
    case kDNSServiceErr_AlreadyRegistered:
        return "Already Registered";
    case kDNSServiceErr_NameConflict:
        return "Name Conflict";
    case kDNSServiceErr_Invalid:
        return "Invalid";
    case kDNSServiceErr_Firewall:
        return "Firewall";
    case kDNSServiceErr_Incompatible:
        return "Incompatible";
    case kDNSServiceErr_BadInterfaceIndex:
        return "Bad Interface Index";
    case kDNSServiceErr_Refused:
        return "Refused";
    case kDNSServiceErr_NoSuchRecord:
        return "No Such Record";
    case kDNSServiceErr_NoAuth:
        return "No Auth";
    case kDNSServiceErr_NoSuchKey:
        return "No Such Key";
    case kDNSServiceErr_NATTraversal:
        return "NAT Traversal";
    case kDNSServiceErr_DoubleNAT:
        return "Double NAT";
    case kDNSServiceErr_BadTime:
        return "Bad Time";
    default:
        return "Unknown DNS-SD Error";
    }
}
#endif

// ---- Class Implementation ----

OcaServiceDiscovery::OcaServiceDiscovery()
#ifndef STM32H7S7xx
    : m_isDiscovering(false), m_browseService(nullptr), m_listLocked(false)
#else
    : m_isDiscovering(false), m_listLocked(false)
#endif
{
    OCA_LOG_INFO("OcaServiceDiscovery created");
}

OcaServiceDiscovery::~OcaServiceDiscovery()
{
    StopDiscovery();
    OCA_LOG_INFO("OcaServiceDiscovery destroyed");
}

bool OcaServiceDiscovery::StartDiscovery()
{
    if (m_isDiscovering)
    {
        OCA_LOG_WARNING("Discovery already running");
        return false;
    }

    OCA_LOG_INFO("Starting OCA service discovery...");

    // Clear any previous discoveries
    m_discoveredDevices.clear();

#ifndef STM32H7S7xx
    // Start browsing for _oca._tcp services
    DNSServiceErrorType error = DNSServiceBrowse(&m_browseService,
                                                 0, // flags
                                                 kDNSServiceInterfaceIndexAny,
                                                 OCA_SERVICE_TYPE,
                                                 nullptr, // domain (nullptr = local)
                                                 BrowseCallback,
                                                 this); // context

    if (error != kDNSServiceErr_NoError)
    {
        OCA_LOG_ERROR_PARAMS("Failed to start DNS-SD browse: %s",
                                    DNSServiceErrorToString(error));
        return false;
    }
#else
    send_oca_service_discovery();
#endif

    m_isDiscovering = true;
    OCA_LOG_INFO_PARAMS("Successfully started browsing for %s services", OCA_SERVICE_TYPE);

    return true;
}

void OcaServiceDiscovery::StopDiscovery()
{
#ifndef STM32H7S7xx
    if (!m_isDiscovering)
    {
        return;
    }

    OCA_LOG_INFO("Stopping OCA service discovery...");

    // Stop browse service
    if (m_browseService)
    {
        DNSServiceRefDeallocate(m_browseService);
        m_browseService = nullptr;
    }

    // Stop all resolve services
    for (auto &pair : m_resolveServices)
    {
        if (pair.second)
        {
            DNSServiceRefDeallocate(pair.second);
        }
    }
    m_resolveServices.clear();

    // Clear any previous discoveries
    m_discoveredDevices.clear();

    m_isDiscovering = false;
    OCA_LOG_INFO("Service discovery stopped");
#endif
}

std::vector<OcaServiceDiscovery::DiscoveredDevice> OcaServiceDiscovery::GetDiscoveredDevices() const
{
#ifndef STM32H7S7xx
    while (m_listLocked)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
#endif
    return m_discoveredDevices;
}

size_t OcaServiceDiscovery::WaitForDevices(uint32_t timeoutMs)
{
    if (!m_isDiscovering)
    {
        OCA_LOG_WARNING("Discovery not running, cannot wait for devices");
        return 0;
    }

    OCA_LOG_INFO_PARAMS("Waiting for OCA devices (timeout: %u ms)...", timeoutMs);

    auto startTime = std::chrono::steady_clock::now();
    auto timeoutDuration = std::chrono::milliseconds(timeoutMs);

    size_t deviceCount = 0;
    while (std::chrono::steady_clock::now() - startTime < timeoutDuration)
    {
#ifndef STM32H7S7xx
        ProcessEvents();
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
#else
        ProcessUDPData();

        // TODO: Check if discovered
        if (is_oca_service_discovery_complete())
        {
            // TODO: This has to be cleaned up and more cleanly integrated
            DiscoveredDevice newDevice;
            oca_service_info_t serviceInfo;

            get_oca_service_info(&serviceInfo);

            newDevice.name = serviceInfo.service_name;
            //newDevice.name = std::string(serviceInfo.service_name);
            newDevice.hostname = serviceInfo.ip_address;
            newDevice.port = serviceInfo.port;
            newDevice.protocolVersion = 1;
            newDevice.isValid = true;

            AddDiscoveredDevice(newDevice);
            deviceCount = 1; // Currently, only single device is handled.

            break;
        }

       // Not found. Retry.
        if (ERR_OK != send_oca_service_discovery())
        {
            std::cout << "Failed to send Discovery Messagea ERR: " << std::endl;
        }
        OcaPlatform::Sleep(100);
#endif
    }

#ifndef STM32H7S7xx
    deviceCount = m_discoveredDevices.size();
#endif
    OCA_LOG_INFO_PARAMS("Discovery completed. Found %zu OCA device(s)", deviceCount);

    return deviceCount;
}

#ifndef STM32H7S7xx
const OcaServiceDiscovery::DiscoveredDevice *OcaServiceDiscovery::GetDeviceByName(const std::string &name) const
{
    auto it = std::find_if(m_discoveredDevices.begin(), m_discoveredDevices.end(),
                           [&name](const DiscoveredDevice &device)
                           {
                               return device.name == name;
                           });

    return (it != m_discoveredDevices.end()) ? &(*it) : nullptr;
}

void DNSSD_API OcaServiceDiscovery::BrowseCallback(DNSServiceRef service,
                                                   DNSServiceFlags flags,
                                                   uint32_t interfaceIndex,
                                                   DNSServiceErrorType errorCode,
                                                   const char *serviceName,
                                                   const char *regtype,
                                                   const char *replyDomain,
                                                   void *context)
{
    OcaServiceDiscovery *discovery = static_cast<OcaServiceDiscovery *>(context);

    if (errorCode != kDNSServiceErr_NoError)
    {
        OCA_LOG_ERROR_PARAMS("DNS-SD browse error: %s", DNSServiceErrorToString(errorCode));
        return;
    }

    discovery->HandleBrowseCallback(flags, interfaceIndex, serviceName, regtype, replyDomain);
}

void DNSSD_API OcaServiceDiscovery::ResolveCallback(DNSServiceRef service,
                                                    DNSServiceFlags flags,
                                                    uint32_t interfaceIndex,
                                                    DNSServiceErrorType errorCode,
                                                    const char *fullname,
                                                    const char *hosttarget,
                                                    uint16_t port,
                                                    uint16_t txtLen,
                                                    const unsigned char *txtRecord,
                                                    void *context)
{
    OcaServiceDiscovery *discovery = static_cast<OcaServiceDiscovery *>(context);

    if (errorCode != kDNSServiceErr_NoError)
    {
        OCA_LOG_ERROR_PARAMS("DNS-SD resolve error: %s", DNSServiceErrorToString(errorCode));
        return;
    }

    discovery->HandleResolveCallback(fullname, hosttarget, port, txtLen, txtRecord);
}

void OcaServiceDiscovery::HandleBrowseCallback(DNSServiceFlags flags,
                                               uint32_t interfaceIndex,
                                               const char *serviceName,
                                               const char *regtype,
                                               const char *replyDomain)
{
    if (flags & kDNSServiceFlagsAdd)
    {
        OCA_LOG_INFO_PARAMS("Found OCA service: %s.%s%s", serviceName, regtype, replyDomain);
        StartResolve(serviceName, regtype, replyDomain, interfaceIndex);
    }
    else
    {
        OCA_LOG_INFO_PARAMS("Lost OCA service: %s.%s%s", serviceName, regtype, replyDomain);
        RemoveDevice(serviceName);
    }
}

void OcaServiceDiscovery::HandleResolveCallback(const char *fullname,
                                                const char *hosttarget,
                                                uint16_t port,
                                                uint16_t txtLen,
                                                const unsigned char *txtRecord)
{
    DiscoveredDevice device;
    device.name = fullname;
    device.hostname = hosttarget;
    // Remove trailing dot from hostname if present
    if (!device.hostname.empty() && device.hostname.back() == '.')
    {
        device.hostname.pop_back();
    }

    // Convert hostname to IP address for better connectivity
    std::string ipAddress = ResolveHostnameToIP(device.hostname);
    if (!ipAddress.empty())
    {
        OCA_LOG_INFO_PARAMS("Resolved hostname %s to IP %s", device.hostname.c_str(), ipAddress.c_str());
        device.hostname = ipAddress; // Use IP instead of hostname
    }

    device.port = ntohs(port);
    device.txtRecords = ParseTXTRecords(txtRecord, txtLen);

    OCA_LOG_INFO_PARAMS("Resolved OCA service: %s -> %s:%d",
                        fullname, hosttarget, device.port);

    // Validate and add device
    if (ValidateOCADevice(device))
    {
        AddDiscoveredDevice(device);
    }
    else
    {
        OCA_LOG_WARNING_PARAMS("Invalid OCA device: %s", fullname);
    }
}

void OcaServiceDiscovery::StartResolve(const std::string &serviceName,
                                       const std::string &regtype,
                                       const std::string &replyDomain,
                                       uint32_t interfaceIndex)
{
    DNSServiceRef resolveService;
    DNSServiceErrorType error = DNSServiceResolve(&resolveService,
                                                  0, // flags
                                                  interfaceIndex,
                                                  serviceName.c_str(),
                                                  regtype.c_str(),
                                                  replyDomain.c_str(),
                                                  ResolveCallback,
                                                  this);

    if (error != kDNSServiceErr_NoError)
    {
        OCA_LOG_ERROR_PARAMS("Failed to start resolve for %s: %s",
                             serviceName.c_str(), DNSServiceErrorToString(error));
        return;
    }

    m_resolveServices[serviceName] = resolveService;
}
#endif

std::map<std::string, std::string> OcaServiceDiscovery::ParseTXTRecords(const unsigned char *txtRecord, uint16_t txtLen)
{
    std::map<std::string, std::string> records;

    const unsigned char *ptr = txtRecord;
    const unsigned char *end = txtRecord + txtLen;

    while (ptr < end)
    {
        uint8_t len = *ptr++;
        if (ptr + len > end)
            break;

        std::string record(reinterpret_cast<const char *>(ptr), len);
        ptr += len;

        // Find the '=' separator
        size_t equalPos = record.find('=');
        if (equalPos != std::string::npos)
        {
            std::string key = record.substr(0, equalPos);
            std::string value = record.substr(equalPos + 1);
            records[key] = value;

            OCA_LOG_TRACE_PARAMS("TXT record: %s = %s", key.c_str(), value.c_str());
        }
        else
        {
            // Key without value
            records[record] = "";
            OCA_LOG_TRACE_PARAMS("TXT record: %s", record.c_str());
        }
    }

    return records;
}

bool OcaServiceDiscovery::ValidateOCADevice(DiscoveredDevice &device)
{
    // Check for required TXT records
    auto txtVersIt = device.txtRecords.find("txtvers");
    auto protoVersIt = device.txtRecords.find("protovers");

    if (txtVersIt == device.txtRecords.end())
    {
        OCA_LOG_WARNING_PARAMS("Device %s missing txtvers TXT record", device.name.c_str());
        return false;
    }

    if (protoVersIt == device.txtRecords.end())
    {
        OCA_LOG_WARNING_PARAMS("Device %s missing protovers TXT record", device.name.c_str());
        return false;
    }

    // Parse protocol version
    try
    {
        device.protocolVersion = std::stoul(protoVersIt->second);
    }
    catch (const std::exception &e)
    {
        OCA_LOG_WARNING_PARAMS("Device %s has invalid protovers: %s",
                               device.name.c_str(), protoVersIt->second.c_str());
        return false;
    }

    // Check protocol version compatibility (support versions 1 and above)
    if (device.protocolVersion < 1)
    {
        OCA_LOG_WARNING_PARAMS("Device %s has unsupported protocol version: %u",
                               device.name.c_str(), device.protocolVersion);
        return false;
    }

    device.isValid = true;

    OCA_LOG_INFO_PARAMS("Valid OCA device: %s (protocol v%u)",
                        device.name.c_str(), device.protocolVersion);

    return true;
}

void OcaServiceDiscovery::AddDiscoveredDevice(const DiscoveredDevice &device)
{
    m_listLocked = true;

    // Check if device already exists (update it)
    auto it = std::find_if(m_discoveredDevices.begin(), m_discoveredDevices.end(),
                           [&device](const DiscoveredDevice &existing)
                           {
                               return existing.name == device.name;
                           });

    if (it != m_discoveredDevices.end())
    {
        *it = device;
        OCA_LOG_INFO_PARAMS("Updated device: %s", device.name.c_str());
    }
    else
    {
        m_discoveredDevices.push_back(device);
        OCA_LOG_INFO_PARAMS("Added new device: %s", device.name.c_str());
    }

    m_listLocked = false;

#ifndef STM32H7S7xx
    // Call callback if set
    if (m_deviceFoundCallback)
    {
        m_deviceFoundCallback(device);
    }
#endif
}

#ifndef STM32H7S7xx
void OcaServiceDiscovery::RemoveDevice(const std::string &serviceName)
{
    m_listLocked = true;

    auto it = std::find_if(m_discoveredDevices.begin(), m_discoveredDevices.end(),
                           [&serviceName](const DiscoveredDevice &device)
                           {
                               return device.name == serviceName;
                           });

    if (it != m_discoveredDevices.end())
    {
        DiscoveredDevice removedDevice = *it;
        m_discoveredDevices.erase(it);

        OCA_LOG_INFO_PARAMS("Removed device: %s", serviceName.c_str());

        m_listLocked = false;

        // Call callback if set
        if (m_deviceLostCallback)
        {
            m_deviceLostCallback(removedDevice);
        }
    }
    else
    {
        m_listLocked = false;
    }

    // Clean up resolve service
    auto resolveIt = m_resolveServices.find(serviceName);
    if (resolveIt != m_resolveServices.end())
    {
        if (resolveIt->second)
        {
            DNSServiceRefDeallocate(resolveIt->second);
        }
        m_resolveServices.erase(resolveIt);
    }
}

void OcaServiceDiscovery::ProcessEvents()
{
    if (!m_isDiscovering || !m_browseService)
    {
        return;
    }

    // Process browse service events
    int fd = DNSServiceRefSockFD(m_browseService);
    if (fd >= 0)
    {
        fd_set readfs;
        FD_ZERO(&readfs);
        FD_SET(fd, &readfs);

        struct timeval timeout;
        timeout.tv_sec = 0;
        timeout.tv_usec = 0; // Non-blocking

        if (select(fd + 1, &readfs, nullptr, nullptr, &timeout) > 0)
        {
            if (FD_ISSET(fd, &readfs))
            {
                DNSServiceProcessResult(m_browseService);
            }
        }
    }

    // Process resolve service events
    for (auto &pair : m_resolveServices)
    {
        if (pair.second)
        {
            int resolveFd = DNSServiceRefSockFD(pair.second);
            if (resolveFd >= 0)
            {
                fd_set readfs;
                FD_ZERO(&readfs);
                FD_SET(resolveFd, &readfs);

                struct timeval timeout;
                timeout.tv_sec = 0;
                timeout.tv_usec = 0; // Non-blocking

                if (select(resolveFd + 1, &readfs, nullptr, nullptr, &timeout) > 0)
                {
                    if (FD_ISSET(resolveFd, &readfs))
                    {
                        DNSServiceProcessResult(pair.second);
                    }
                }
            }
        }
    }
}

std::string OcaServiceDiscovery::ResolveHostnameToIP(const std::string &hostname)
{
    struct addrinfo hints, *result;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET; // IPv4
    hints.ai_socktype = SOCK_STREAM;

    int status = getaddrinfo(hostname.c_str(), nullptr, &hints, &result);
    if (status != 0)
    {
        OCA_LOG_WARNING_PARAMS("Failed to resolve hostname %s: %s", hostname.c_str(), gai_strerror(status));
        return "";
    }

    if (result == nullptr)
    {
        OCA_LOG_WARNING_PARAMS("No address found for hostname %s", hostname.c_str());
        return "";
    }

    struct sockaddr_in *addr_in = (struct sockaddr_in *)result->ai_addr;
    std::string ipAddress = inet_ntoa(addr_in->sin_addr);

    freeaddrinfo(result);

    OCA_LOG_TRACE_PARAMS("Resolved %s to %s", hostname.c_str(), ipAddress.c_str());
    return ipAddress;
}
#endif
