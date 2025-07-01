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
    string xyteId; // Unique ID for the device
    string accessKey; // Access key for the device
    string hubUrl; // URL of the hub for the device
    string cloudId; // Cloud ID for the device
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

    std::unique_ptr<WebClient> wc;
    Device device;
    string ca_cert_path = "/mnt/cfg/cert/cacert.pem"; // Path to the CA certificate bundle
    string reg_url = "https://entry.xyte.io/v1/devices"; // Registration URL
    string partner_id = "5bPj"; // Partner ID
    string hardwareKey = "a4dfe376-81a9-44bf-b3bd-f7c6c3c2dc67"; // Hardware Key
    int regRetry = 5; // Retry interval for registration in seconds
    string firmwareVersion = "1.0.0"; // Firmware Version
    string serialId = "my-serial-id"; // Serial ID
    string deviceName = "Fusion-Test-Device"; // Device Name
    string log_config_path = "/mnt/cfg/log.cfg";
    string xyte_devices_path = "/mnt/cfg/xyte-devices.json"; // Path to the device info file
    string tel_delay_seconds = "10"; // Delay for telemetry in seconds
};