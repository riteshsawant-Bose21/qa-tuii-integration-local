/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : OCA Service Discovery using DNS-SD
 */

#ifndef OCA_SERVICE_DISCOVERY_H
#define OCA_SERVICE_DISCOVERY_H

// ---- Include system wide include files ----
#include <string>
#include <vector>
#include <map>
#include <memory>

#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
#include <functional>

#if defined(__APPLE__) || defined(FUSION)
#include <dns_sd.h>
#else
#include <avahi-compat-libdns_sd/dns_sd.h>
#endif

#endif

// ---- Include local include files ----
// (logging will be included in .cpp file)

// ---- Helper types and constants ----
#define OCA_SERVICE_TYPE "_oca._tcp"
#define OCA_DISCOVERY_TIMEOUT_MS 5000

// ---- Class Definition ----

/**
 * OCA Service Discovery class using DNS-SD (Bonjour/Avahi)
 * Discovers OCA devices on the network and provides their connection information
 */
class OcaServiceDiscovery
{
public:
    /**
     * Structure representing a discovered OCA device
     */
    struct DiscoveredDevice
    {
        std::string name;                              // Service name (e.g., "MixingConsole-Studio1")
        std::string hostname;                          // Resolved hostname/IP
        uint16_t port;                                 // Service port
        std::map<std::string, std::string> txtRecords; // TXT record key-value pairs
        uint32_t protocolVersion;                      // OCA protocol version
        bool isValid;                                  // Whether this is a valid OCA device

        DiscoveredDevice() : port(0), protocolVersion(0), isValid(false) {}
    };

#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
    /**
     * Callback function type for device discovery events
     */
    using DeviceCallback = std::function<void(const DiscoveredDevice &)>;
#endif

    /**
     * Constructor
     */
    OcaServiceDiscovery();

    /**
     * Destructor
     */
    ~OcaServiceDiscovery();

    /**
     * Start DNS-SD service discovery for OCA devices
     * @return true if discovery started successfully
     */
    bool StartDiscovery();

    /**
     * Stop DNS-SD service discovery
     */
    void StopDiscovery();

    /**
     * Check if discovery is currently running
     * @return true if discovery is active
     */
    bool IsDiscovering() const { return m_isDiscovering; }

    /**
     * Get list of currently discovered devices
     * @return vector of discovered devices
     */
    std::vector<DiscoveredDevice> GetDiscoveredDevices() const;

    /**
     * Wait for devices to be discovered (blocking call)
     * @param timeoutMs Maximum time to wait in milliseconds
     * @return number of devices discovered
     */
    size_t WaitForDevices(uint32_t timeoutMs = OCA_DISCOVERY_TIMEOUT_MS);

#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
    /**
     * Set callback for when a new device is found
     * @param callback Function to call when device is discovered
     */
    void SetDeviceFoundCallback(DeviceCallback callback) { m_deviceFoundCallback = callback; }

    /**
     * Set callback for when a device is lost
     * @param callback Function to call when device is lost
     */
    void SetDeviceLostCallback(DeviceCallback callback) { m_deviceLostCallback = callback; }
#endif

    /**
     * Get a specific device by name
     * @param name Service name to search for
     * @return pointer to device if found, nullptr otherwise
     */
    const DiscoveredDevice *GetDeviceByName(const std::string &name) const;

private:
#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
    /**
     * DNS-SD browse callback (static)
     */
    static void DNSSD_API BrowseCallback(DNSServiceRef service,
                                         DNSServiceFlags flags,
                                         uint32_t interfaceIndex,
                                         DNSServiceErrorType errorCode,
                                         const char *serviceName,
                                         const char *regtype,
                                         const char *replyDomain,
                                         void *context);

    /**
     * DNS-SD resolve callback (static)
     */
    static void DNSSD_API ResolveCallback(DNSServiceRef service,
                                          DNSServiceFlags flags,
                                          uint32_t interfaceIndex,
                                          DNSServiceErrorType errorCode,
                                          const char *fullname,
                                          const char *hosttarget,
                                          uint16_t port,
                                          uint16_t txtLen,
                                          const unsigned char *txtRecord,
                                          void *context);

    /**
     * Handle browse callback (instance method)
     */
    void HandleBrowseCallback(DNSServiceFlags flags,
                              uint32_t interfaceIndex,
                              const char *serviceName,
                              const char *regtype,
                              const char *replyDomain);

    /**
     * Handle resolve callback (instance method)
     */
    void HandleResolveCallback(const char *fullname,
                               const char *hosttarget,
                               uint16_t port,
                               uint16_t txtLen,
                               const unsigned char *txtRecord);
#endif

    /**
     * Start resolving a discovered service
     */
    void StartResolve(const std::string &serviceName,
                      const std::string &regtype,
                      const std::string &replyDomain,
                      uint32_t interfaceIndex);

    /**
     * Parse TXT records from DNS-SD response
     */
    std::map<std::string, std::string> ParseTXTRecords(const unsigned char *txtRecord, uint16_t txtLen);

    /**
     * Validate that a discovered device is a proper OCA device
     */
    bool ValidateOCADevice(DiscoveredDevice &device);

    /**
     * Add a discovered device to the list
     */
    void AddDiscoveredDevice(const DiscoveredDevice &device);

    /**
     * Remove a device from the discovered list
     */
    void RemoveDevice(const std::string &serviceName);

    /**
     * Process DNS-SD events (call DNSServiceProcessResult)
     */
    void ProcessEvents();

#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
    /**
     * Resolve hostname to IP address
     * @param hostname The hostname to resolve
     * @return IP address string, or empty string if resolution fails
     */
    std::string ResolveHostnameToIP(const std::string &hostname);
#endif

private:
    bool m_isDiscovering;
    std::vector<DiscoveredDevice> m_discoveredDevices;
#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
    DNSServiceRef m_browseService;
    std::map<std::string, DNSServiceRef> m_resolveServices;

    DeviceCallback m_deviceFoundCallback;
    DeviceCallback m_deviceLostCallback;
#endif
    // Thread safety (basic protection)
    mutable bool m_listLocked;
};

#endif // OCA_SERVICE_DISCOVERY_H
