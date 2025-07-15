

#include "fusion-edge-gateway.h"

// This will move to file_utils.cpp
void FusionEdgeGateway::addDeviceInfo(const Device &device) {
    std::ofstream deviceFile(xyte_devices_path, std::ios::app);
    if (!device.xyteId.empty() && !device.accessKey.empty() && deviceFile.is_open()) {
        json deviceJson = {
            {"xyte_id", device.xyteId},
            {"access_key", device.accessKey},
            {"hub_url", device.hubUrl},
            {"cloud_id", device.cloudId}
        };
        deviceFile << deviceJson.dump() << std::endl;
        deviceFile.close();
    } else {
        SPDLOG_WARN("Skipping invalid device data write to file {}: xyte_id={}, access_key={}, hub_url={}, cloud_id={}",
                    xyte_devices_path, device.xyteId, device.accessKey, device.hubUrl, device.cloudId);
    }
}

/* Register device to xyte; call only when xyte-devices.json file is not created (created at first registration)
 * device registration data ex:
 * {"hardware_key": "2a3db46d-1c2e-408d-84b0-e9b059afc1aa", "cloud_id": "5bPj*16 to 32 char*", "firmware_version": "1.0.0", "sn": "<UNIQUE-ID>", "name": "<UNIQUE-NAME>"}
 */
int FusionEdgeGateway::registerDevice() {
    string reg_cb_buf;

    // cloudId - Unique id for a each device; starts with our partner "short code" ID: "5bPj".
    string cloudId = makeCloudId(partner_id);

    json reg_json = {
        {"hardware_key", hardwareKey},
        {"cloud_id", cloudId},
        {"firmware_version", firmwareVersion},
        {"sn", serialId},
        {"name", device.deviceName}
    };

    string reg_str = reg_json.dump();

    SPDLOG_INFO("Registration Data: {}", reg_str);
    SPDLOG_DEBUG("Registration URL: {}", reg_url);

    int ret = wc->SendRequest(reg_url, "", reg_str, &reg_cb_buf, "POST");

    if (reg_cb_buf.empty()) {
        SPDLOG_ERROR("Empty response from server during registration");
        return -1;
    }

    try {
        reg_json = json::parse(reg_cb_buf);
    } catch (const json::parse_error& e) {
        SPDLOG_ERROR("JSON error parsing register response: {}", e.what());
    }

    if(ret == WEB_CLIENT_OK){
        /* registraion response;
        * ex:
        * {"id":"xxxxxx-xxxxxx-xxxx-xxxxxxxxx", "access_key":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "hub_url":"https://eu-1.endpoints.xyte.io", "hub_url_static_cert":"https://eu-1.cssl.endpoints.xyte.io", "mqtt_hub_url":"mqtts://mqtt-us-1.endpoints.xyte.io:8883"}
        */

        //parse response and get id, access_key and hub_url
        device.xyteId = reg_json.value("id", "");

        if (device.xyteId == "null") {
            string strError = reg_json.value("error", "unknown error");
            SPDLOG_ERROR("Error: {}", strError);
            ret = -1;
        }
        else {
            device.accessKey = reg_json.value("access_key", "");
            device.hubUrl = reg_json.value("hub_url", "");
            device.cloudId = cloudId;
            SPDLOG_DEBUG("Parsed Response; Id: {}, Hub_URL: {}", device.xyteId, device.hubUrl);
            addDeviceInfo(device);
            device.claimed = false; // each registration needs a fresh claim with new cloudId
        }
    }
    else {
        string strError = reg_json.value("error", "unknown error");
        if (strError.find("already") != string::npos) {
            SPDLOG_INFO("Delete old {} device from the Server or replace it", serialId);
        }
        ret = -1;
    }
    return ret;
}

/* Send telemetrics data to xyte
 */
int FusionEdgeGateway::sendTelemetry(json telJson)
{
    static string tel_cb_buf; // Static to avoid constant reallocation while sending telemetry.
    tel_cb_buf.clear();

    int ret = 0;
    string hub_url; // to store hub_url returned from registering the device
    string tel_url; // xyte url to send telemetry data
    string tel_str;

    bool isCommandRcvd;
    bool st_sts;

    // Get the URL to send telemetic data to.
    hub_url = device.hubUrl;
    tel_url = hub_url + "/v1/devices/" + device.xyteId + "/telemetry";

    tel_str = telJson.dump();
    SPDLOG_DEBUG("tel_data: {}", tel_str);
    SPDLOG_DEBUG("Telemetry URL: {}", tel_url);
    ret = wc->SendRequest(tel_url, device.accessKey, tel_str, &tel_cb_buf, "POST");

    if(ret == WEB_CLIENT_OK){
        /* telemetric response; refer: https://dev.xyte.io/reference/send-telemetry
        * ex:
        * {"config_version": 0, "command": false, "info_version": 0, "new_licenses": true, "latest_fw_version": "1.3.4", "latest_fw_file_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "space_data_version": 4, "success": true}
        */

        size_t errorFound = tel_cb_buf.find("\"error\":\"Not found\""); 

        json tel_response;
        std::string error;
        try {
            tel_response = json::parse(tel_cb_buf);
        } catch (const json::parse_error& e) {
            error = e.what();
            SPDLOG_ERROR("JSON error parsing telemetry response: {}", error.c_str());
            ret = -1;
        }

        if (errorFound != string::npos) {
            if(deleteFile(xyte_devices_path) == 0) {
                SPDLOG_INFO("xyte-devices.json deleted successfully.");
                return 0;
            }
            else {
                SPDLOG_ERROR("Failed to delete: {}", xyte_devices_path);
            }
        }

        int claimed_sts = tel_response.value("space_data_version", 0);
        device.claimed = (claimed_sts != 0);
        st_sts = tel_response.value("success", false);
        isCommandRcvd = tel_response.value("command", false);

        if(st_sts){
            SPDLOG_INFO("Sent Status: {}", st_sts);
        }
        else{
            SPDLOG_ERROR("Failed to send telemetric data: {}", tel_cb_buf);
            ret = -1;
        }

        if(isCommandRcvd){
            processDeviceCommand();
        }
    }
    else if (ret != WEB_CLIENT_OK) {
        // Handle {"error":"Not authorized"}
        if (tel_cb_buf.find("Not authorized") != string::npos) {
            if(deleteFile(xyte_devices_path) == 0) {
                SPDLOG_INFO("xyte-devices.json file deleted successfully.");
            }
        }
    }
    // Implement error handling
    return ret;
}

int FusionEdgeGateway::sendFile(string &output1, const string &mimeType) {
  string cmd_cb_buf;
  string uploadURL = device.hubUrl + "/v1/devices/" + device.xyteId + "/dumps/" + mimeType + "/" + output1;
  string fileUploadPath = "/tmp/"+ output1;

  SPDLOG_DEBUG("File Upload URL: {}", uploadURL);
  SPDLOG_DEBUG("File Upload Path: {}", fileUploadPath);

  auto ret = wc->SendFile(uploadURL, device.accessKey, fileUploadPath, &cmd_cb_buf);
  if(ret == WEB_CLIENT_OK) {
    SPDLOG_DEBUG("Received data: {}", cmd_cb_buf);
  }
  else{
    SPDLOG_ERROR("Uploading file failed: {}", cmd_cb_buf);
  }
  return ret;
}

void FusionEdgeGateway::processDeviceCommand(){
    int result;
    string getCmdURL = device.hubUrl + "/v1/devices/" + device.xyteId + "/command";
    string cmd_cb_buf;
    string output1;
    string mimeType;
    result = wc->GetRequest(getCmdURL, device.accessKey, &cmd_cb_buf);

    json cmd_json;
    string cmdUpdStr;
    if (result != WEB_CLIENT_OK) {
        return;
    }

    cmd_json = json::parse(cmd_cb_buf);

    if (cmd_json.is_discarded()) {
        SPDLOG_ERROR("deserializeJson() failed for cmd_json: {}", cmd_cb_buf);
        return;
    }

    string cmdId = cmd_json["id"];
    string commandStatus = cmd_json["status"];
    if(cmd_json["status"] == CMD_STATUS_DONE) {
        SPDLOG_INFO("Command already processed.");
        return;
    }
    else if(cmd_json["status"] == CMD_STATUS_PENDING){
        cmd_json["status"] = CMD_STATUS_INPROGRESS;
        cmd_json["id"] = cmdId.c_str();

        cmdUpdStr = cmd_json.dump();
        result = wc->SendRequest(getCmdURL, device.accessKey, cmdUpdStr, &cmd_cb_buf, "POST");//update command status to in_progress

        if(result == WEB_CLIENT_OK){
            SPDLOG_DEBUG("Received data: {}", cmd_cb_buf);
        }
    }
    else if(cmd_json["status"] == CMD_STATUS_INPROGRESS) {
        SPDLOG_INFO("Command is being processed.");
    }

    string commandResponse;
    string commandName = cmd_json["name"];

    int retCode = 0;
    commandResponse = "Command success";
    if (commandName == "reboot") {
        if (commandStatus == CMD_STATUS_INPROGRESS){
            //pass
        }
        else{
            SPDLOG_INFO("Received command: {}", commandName);
            std::string rebootCmd = "reboot";
            if (runSystemCommand(rebootCmd) != 0) {
                commandResponse = "Command failed";
                retCode = 1;
            }
        }
    }
    else if (commandName == "dump") {
        mimeType = "application%2Fgzip";
        if(createLogs(output1) != 0){
            commandResponse = "Error creating the logs";
            retCode = 1;
        }
        else {
            retCode = 0;
        }
        if(sendFile(output1, mimeType) != WEB_CLIENT_OK){
            retCode = 1;
            commandResponse = "Error uploading files";
        }
    }

    if(retCode != 0) {
        SPDLOG_ERROR("command failed: {}", commandName);
        cmd_json["status"] = CMD_STATUS_FAILED;
    }
    else {
        cmd_json["status"] = CMD_STATUS_DONE;
    }
    cmd_json["message"] = commandResponse.c_str();
    cmd_json["id"] = cmdId.c_str();
    cmdUpdStr = cmd_json.dump();
    result = wc->SendRequest(getCmdURL, device.accessKey, cmdUpdStr, &cmd_cb_buf, "POST");//update command status
}

bool FusionEdgeGateway::waitForServer() {
    while (wc->CheckServer(BASE_SERVER_URL) != WEB_CLIENT_OK) {
        SPDLOG_WARN("Server not reachable. Retrying in 10 seconds...");
        std::this_thread::sleep_for(std::chrono::seconds(10));
    }
    return true;
}

void FusionEdgeGateway::getDeviceInfoFromFusionServer() {
    string devicesInfo;

    SPDLOG_DEBUG("Get devices URL: {}", fusionDeviceInfoUrl);

    int ret = wc->GetRequest(fusionDeviceInfoUrl, "", &devicesInfo);

    if (ret == WEB_CLIENT_OK) {
        nlohmann::json j = nlohmann::json::parse(devicesInfo);
        if (j.is_array()) {
            for (const auto& item : j) {
                string serverSerialIdValue = item.value("serial_number", "");
                string serverIpAddressValue = item.value("address", "");
                string serverDeviceName = item.value("name", "");
                if(serverSerialIdValue == serialId || serverIpAddressValue == device.ipAddress) {
                    device.deviceName = serverDeviceName;
                    device.droId = item.value("id", "");
                    serverCloudIdValue = item.value("xyte_cloud_id", "");
                    serverIsClaimedValue = item.value("is_claimed", false);

                    SPDLOG_DEBUG("This device: name={}, serial number={}, IP Address={}, cloudId={}, claimed={}", device.deviceName, serverSerialIdValue, serverIpAddressValue, serverCloudIdValue, serverIsClaimedValue);
                }
                else{
                    SPDLOG_DEBUG("Other Devices in the network: name={}, serial number={}, IP Address={}", serverDeviceName, serverSerialIdValue, serverIpAddressValue);
                }
            }
            if(device.deviceName.empty()) {
                SPDLOG_ERROR("Device with serial ID {} not found in Fusion Server, retry next time...", serialId);
            }
        } else {
            SPDLOG_ERROR("Failed to parse device response: {}", devicesInfo);
        }
    } else {
        SPDLOG_ERROR("Failed to get Device Name from Fusion Server");
    }
}

void FusionEdgeGateway::sendXyteUpdateToFusionServer() {
    json xyteInfoJson = {
        {"is_claimed", device.claimed},
        {"xyte_cloud_id", device.cloudId}
    };

    string updateDeviceInfoUrl = fusionDeviceInfoUrl + "/" + device.droId;
    string response;

    SPDLOG_DEBUG("xyte_data: {}", xyteInfoJson.dump());
    SPDLOG_DEBUG("patch devices URL: {}", updateDeviceInfoUrl);

    int ret = wc->SendRequest(updateDeviceInfoUrl, "", xyteInfoJson.dump(), &response, "PATCH");

    if (ret == WEB_CLIENT_OK) {
        SPDLOG_INFO("Sent XYTE info to Fusion Server successfully");
    } else {
        SPDLOG_ERROR("Failed to send XYTE info to Fusion Server: {}", response);
    }
}

int FusionEdgeGateway::run() {
    // Initialize logging
    spdlog::set_level(spdlog::level::debug);
    SPDLOG_INFO("Fusion Edge Gateway starting...");

    // Create the WebClient after logging is configured.
    wc = std::make_unique<WebClient>();

    //wc->SetCertificateChain(ca_cert_path);

    waitForServer();

    device.ipAddress = getLocalIPAddress();

    if(fileExists(xyte_devices_path)) {
        SPDLOG_INFO("Device already registered, loading device info...");
        // Load existing device info from file
        std::ifstream deviceFile(xyte_devices_path);
        if (deviceFile.is_open()) {
            json deviceJson;
            try {
                deviceFile >> deviceJson;
            } catch (const std::exception& e) {
                SPDLOG_ERROR("Failed to parse xyte-devices.json: {}", e.what());
                return 1;
            }
            device.xyteId = deviceJson.value("xyte_id", "");
            device.accessKey = deviceJson.value("access_key", "");
            device.hubUrl = deviceJson.value("hub_url", "");
            device.cloudId = deviceJson.value("cloud_id", "");
            SPDLOG_DEBUG("Loaded Device Info: ID: {}, Hub URL: {}, Cloud ID: {}",
                        device.xyteId, device.hubUrl, device.cloudId);
        } else {
            SPDLOG_ERROR("Failed to open xyte-devices.json for reading");
            return 1;
        }
    }

    while(1){

        getDeviceInfoFromFusionServer();

        if (! fileExists(xyte_devices_path)) {
            SPDLOG_INFO("xyte-devices.json not found, registering device...");
            while(registerDevice() != 0){
                SPDLOG_ERROR("Device Registration Failed. Retry in {} seconds", regRetry);
                std::this_thread::sleep_for(std::chrono::seconds(regRetry));
            }
        }

        getNetworkRates(rx_kbps, tx_kbps);

        json telemetryJson;
        telemetryJson["status"] = "online";
        telemetryJson["telemetries"] = json{
            {"ram_used", getRAMUsedPercent()},
            {"disk_used", getDiskUsagePercent()},
            {"cpu_temp", getCPUTemperature()},
            {"system_load", getSystemLoadPercent()},
            {"cpu_usage", getCpuUsagePercent()},
            {"net_rx", rx_kbps},
            {"net_tx", tx_kbps},
        };

        checkDelayElapsed(endTime, tel_delay_seconds);

        if (sendTelemetry(telemetryJson) != 0) {
            SPDLOG_ERROR("Send Telemetry Failed. Retry in {} seconds", tel_delay_seconds);
        }

        if(! device.deviceName.empty() && (serverIsClaimedValue != device.claimed || serverCloudIdValue != device.cloudId)) {
            sendXyteUpdateToFusionServer();
        }

        endTime = time(nullptr);
    }

    return 0;
}