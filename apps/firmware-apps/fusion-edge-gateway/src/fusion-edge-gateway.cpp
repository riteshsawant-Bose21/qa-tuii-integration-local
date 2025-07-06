

#include "fusion-edge-gateway.h"

// This will move to file_utils.cpp
void FusionEdgeGateway::addDeviceInfo(const Device &device) {
    spdlog::info("Device Info Added: ID: {}, Access Key: {}, Hub URL: {}, Cloud ID: {}",
                 device.xyteId, device.accessKey, device.hubUrl, device.cloudId);

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
        spdlog::warn("Skipping invalid device data write");
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
        {"name", deviceName}
    };

    string reg_str = reg_json.dump();

    spdlog::info("Registration Data: {}", reg_str);
    spdlog::debug("Registration URL: {}", reg_url);

    int ret = wc->SendRequest(reg_url, "", reg_str, &reg_cb_buf, "POST");

    spdlog::debug("Received data: {}", reg_cb_buf);

    if (reg_cb_buf.empty()) {
        spdlog::error("Empty response from server during registration");
        return -1;
    }

    try {
        reg_json = json::parse(reg_cb_buf);
    } catch (const json::parse_error& e) {
        spdlog::error("JSON error parsing register response: {}", e.what());
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
            spdlog::error("Error: {}", strError);
            ret = -1;
        }
        else {
            device.accessKey = reg_json.value("access_key", "");
            device.hubUrl = reg_json.value("hub_url", "");
            device.cloudId = cloudId;
            spdlog::debug("Parsed Response; Id: {}, Access_Key: {}, Hub_URL: {}", device.xyteId, device.accessKey, device.hubUrl);
            addDeviceInfo(device);
        }
    }
    else {
        string strError = reg_json.value("error", "unknown error");
        if (strError.find("already") != string::npos) {
            spdlog::info("Delete old {} device from the Server or replace it", serialId);
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
    spdlog::debug("tel_data: {}", tel_str);
    spdlog::debug("Telemetry URL: {}", tel_url);
    ret = wc->SendRequest(tel_url, device.accessKey, tel_str, &tel_cb_buf, "POST");

    if(ret == WEB_CLIENT_OK){
        /* telemetric response; refer: https://dev.xyte.io/reference/send-telemetry
        * ex:
        * {"config_version": 0, "command": false, "info_version": 0, "new_licenses": true, "latest_fw_version": "1.3.4", "latest_fw_file_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "space_data_version": 4, "success": true}
        */
        spdlog::debug("Received data: {}", tel_cb_buf);

        size_t errorFound = tel_cb_buf.find("\"error\":\"Not found\""); 

        json tel_response;
        std::string error;
        try {
            tel_response = json::parse(tel_cb_buf);
        } catch (const json::parse_error& e) {
            error = e.what();
            spdlog::error("JSON error parsing telemetry response: {}", error.c_str());
            ret = -1;
        }

        if (errorFound != string::npos) {
            if(deleteFile(xyte_devices_path) == 0) {
                spdlog::debug("xyte-devices.json deleted successfully.");
                return 0;
            }
            else {
                spdlog::error("Failed to delete: {}", xyte_devices_path);
            }
        }

        int claimed_sts = tel_response.value("space_data_version", 0);
        bool claimed = (claimed_sts != 0);// to send to fusion server?
        st_sts = tel_response.value("success", false);
        isCommandRcvd = tel_response.value("command", false);

        if(st_sts){
            spdlog::info("Sent Status: {}", st_sts);
        }
        else{
            spdlog::error("Failed to send telemetric data: {}", tel_cb_buf);
            ret = -1;
        }

        if(isCommandRcvd){
            processDeviceCommand(hub_url);
        }
    }
    else if (ret != WEB_CLIENT_OK) {
        // Handle {"error":"Not authorized"}
        if (tel_cb_buf.find("Not authorized") != string::npos) {
            if(deleteFile(xyte_devices_path) == 0) {
                spdlog::info("xyte-devices.json file deleted successfully.");
            }
        }
    }
    // Implement error handling
    return ret;
}

void FusionEdgeGateway::processDeviceCommand(const string hub_url){
    int result;
    string getCmdURL = hub_url + "/v1/devices/" + device.xyteId + "/command";
    string cmd_cb_buf;
    string output1;
    string mimeType;
    result = wc->GetRequest(getCmdURL, device.accessKey, &cmd_cb_buf);

    json cmd_json;
    string cmdUpdStr;
    if (result != WEB_CLIENT_OK) {
        return;
    }

    spdlog::debug("Received data: {}", cmd_cb_buf);
    cmd_json = json::parse(cmd_cb_buf);

    if (cmd_json.is_discarded()) {
        spdlog::error("deserializeJson() failed for cmd_json: {}", cmd_cb_buf);
        return;
    }

    string cmdId = cmd_json["id"];
    string commandStatus = cmd_json["status"];
    if(cmd_json["status"] == CMD_STATUS_DONE) {
        spdlog::info("Command already processed.");
        return;
    }
    else if(cmd_json["status"] == CMD_STATUS_PENDING){
        cmd_json["status"] = CMD_STATUS_INPROGRESS;
        cmd_json["id"] = cmdId.c_str();

        cmdUpdStr = cmd_json.dump();
        result = wc->SendRequest(getCmdURL, device.accessKey, cmdUpdStr, &cmd_cb_buf, "POST");//update command status to in_progress

        if(result == WEB_CLIENT_OK){
            spdlog::debug("Received data: {}", cmd_cb_buf);
        }
    }
    else if(cmd_json["status"] == CMD_STATUS_INPROGRESS) {
        spdlog::info("Command is being processed.");
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
            spdlog::info("Received command: {}", commandName);
            std::string rebootCmd = "reboot";
            if (runSystemCommand(rebootCmd) != 0) {
                commandResponse = "Command failed";
                retCode = 1;
            }
        }
    }

    if(retCode != 0) {
        spdlog::error("command failed: {}", commandName);
        cmd_json["status"] = CMD_STATUS_FAILED;
    }
    else {
        cmd_json["status"] = CMD_STATUS_DONE;
    }
    cmd_json["message"] = commandResponse.c_str();
    cmd_json["id"] = cmdId.c_str();
    cmdUpdStr = cmd_json.dump();
    result = wc->SendRequest(getCmdURL, device.accessKey, cmdUpdStr, &cmd_cb_buf, "POST");//update command status to done

    if(result == WEB_CLIENT_OK){
        spdlog::debug("Received data: {}", cmd_cb_buf);
    }
}

bool FusionEdgeGateway::waitForServer() {
    while (wc->CheckServer(BASE_SERVER_URL) != WEB_CLIENT_OK) {
        spdlog::warn("Server not reachable. Retrying in 10 seconds...");
        std::this_thread::sleep_for(std::chrono::seconds(10));
    }
    return true;
}

int FusionEdgeGateway::run() {
    // Initialize logging
    spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%l] [fusion-edge-gateway] %v");
    spdlog::set_level(spdlog::level::debug);
    spdlog::info("Fusion Edge Gateway starting...");

    // Create the WebClient after logging is configured.
    wc = std::make_unique<WebClient>();

    waitForServer();

    if(fileExists(xyte_devices_path)) {
        spdlog::info("Device already registered, loading device info...");
        // Load existing device info from file
        std::ifstream deviceFile(xyte_devices_path);
        if (deviceFile.is_open()) {
            json deviceJson;
            deviceFile >> deviceJson;
            device.xyteId = deviceJson.value("xyte_id", "");
            device.accessKey = deviceJson.value("access_key", "");
            device.hubUrl = deviceJson.value("hub_url", "");
            device.cloudId = deviceJson.value("cloud_id", "");
            spdlog::info("Loaded Device Info: ID: {}, Access Key: {}, Hub URL: {}, Cloud ID: {}",
                        device.xyteId, device.accessKey, device.hubUrl, device.cloudId);
        } else {
            spdlog::error("Failed to open xyte-devices.json for reading");
            return 1;
        }
    }

    while(1){

        if (! fileExists(xyte_devices_path)) {
            spdlog::info("xyte-devices.json not found, registering device...");
            while(registerDevice() != 0){
                spdlog::error("Device Registration Failed. Retry in {} seconds", regRetry);
                std::this_thread::sleep_for(std::chrono::seconds(regRetry));
            }
        }

        json telemetryJson;
        telemetryJson["status"] = "online";
        telemetryJson["telemetries"] = json{
            {"ram_used", getRAMUsedPercent()},
            {"disk_used", getDiskUsagePercent()},
            {"cpu_temp", getCPUTemperature()},
            {"system_load", getSystemLoadPercent()},
            {"cpu_usage", getCpuUsagePercent()},
        };

        if (sendTelemetry(telemetryJson) != 0) {
            spdlog::error("Send Telemetry Failed. Retry in {} seconds", tel_delay_seconds);
        }

        std::this_thread::sleep_for(std::chrono::seconds(stoi(tel_delay_seconds)));
    }

    return 0;
}