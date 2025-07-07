#pragma once

#include <iostream>
#include <fstream>
#include <string>
#include <unistd.h>
#include <thread>
#include <chrono>

#include "curl/curl.h"
#include "json.hpp"
#include "spdlog/spdlog.h"
#include "cloud_id.h"
#include "webclient.h"
#include "file_util.h"

using std::string;
using std::cout;
using std::endl;
using json = nlohmann::json;

struct Device{
    string deviceId; // Unique ID for fusion device from fusion server
    string xyteId; // Unique ID for the device from XYTE after registration
    string accessKey; // Access key for the device to communicate with XYTE
    string hubUrl; // URL of the hub for the devices to communicate with XYTE
    string cloudId; // Unique ID for the device to send to the cloud
    bool claimed = false; // Status of the device claim in XYTE
}; // Global device object

class FusionEdgeGateway {
public:
    int run();

private:
    void addDeviceInfo(const Device& device);
    int registerDevice();
    bool waitForServer();
    int sendTelemetry();
    void processDeviceCommand(const string hub_url);
    int sendTelemetry(json telJson);
    void sendXyteUpdateToFusionServer();
    void getDeviceInfoFromFusionServer();

    std::unique_ptr<WebClient> wc;
    Device device;
    const char* home = std::getenv("HOME");
    string ca_cert_path = "/etc/ssl/certs/ca-certificates.crt"; // Path to the CA certificate bundle
    string reg_url = "https://entry.xyte.io/v1/devices"; // Registration URL
    string partner_id = "5bPj"; // Partner ID
    string hardwareKey = "a4dfe376-81a9-44bf-b3bd-f7c6c3c2dc67"; // Hardware Key
    int regRetry = 5; // Retry interval for registration in seconds
    string firmwareVersion = "1.0.0"; // Firmware Version
    string serialId = get_serial_id(); // Serial ID
    string deviceName = "Fusion-Test-Device"; // Device Name
    std::string xyte_devices_path = home ? std::string(home) + "/xyte-devices.json" : "/tmp/xyte-devices.json"; // Path to the xyte device info file
    int tel_delay_seconds = 10; // Delay for telemetry in seconds
    string serverCloudIdValue; // Cloud ID value from the server to update live status
    bool serverIsClaimedValue; // Claim status from the server to update live status
    string localServerUrl = "http://localhost:8080"; // Local server URL for device info
    string fusionDeviceInfoUrl = localServerUrl + "/devices"; // Fusion server info URL
};