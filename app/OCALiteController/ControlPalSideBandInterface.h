/**
 * Wall Controller Simulator (C++)
 * 
 * This C++ program simulates a wall controller that connects to the Fusion Server
 * on port 7950 and implements the JSON protocol with identification and wink commands.
 * 
 * Compilation:
 *   g++ -std=c++17 -o wall_controller_simulator wall_controller_simulator.cpp -pthread
 * 
 * Usage:
 *   ./wall_controller_simulator [controller_id] [host] [port]
 * 
 * Protocol:
 * - Server sends: {"action": "identify", "payload": {"timestamp": 123456}}
 * - Controller responds: {"action": "identity", "payload": {"id": "WC001", "deviceType": "WallController", "firmwareVersion": "1.0.0"}}
 * - Server sends: {"action": "performWink", "payload": {"duration": 5000, "timestamp": 123456}}
 * - Controller responds: {"action": "winkResponse", "payload": {"status": "starting"}}
 * - Controller responds: {"action": "winkResponse", "payload": {"status": "done"}}
 */

#include <iostream>
#include <string>
#include <thread>
#include <atomic>
#include <chrono>
#include <sstream>
#include <vector>
#include <signal.h>
#include <unistd.h>
#include <netdb.h>
#include <cstring>
#include <iomanip>
#include "HostInterface/CommandInterface/CommandInterface.h"
#include "ControlPalMsgInterface.h"
#include "OcaServiceDiscovery.h"

#ifndef _CONTROLPAL_SIDEBAND_INTFC_H
#define _CONTROLPAL_SIDEBAND_INTFC_H

class SidebandInterface : public ControlPalMsgInterface<ControllerCmdIntfc>
{
    private:
        std::string controller_id;
        std::string host;
        int port;
        int socket_fd;
        std::atomic<bool> connected;
        std::atomic<bool> identified;
        std::atomic<bool> running;

        struct DeviceInfo {
            std::string id;
            std::string deviceType;
            std::string firmwareVersion;
        } device_info;

        ControllerCmdIntfc msgToUi;


    public:
        SidebandInterface(const std::string& id = "WC001", 
                const std::string& h = "localhost", 
                int p = 7950,
                void *commandQue = NULL) 
            : ControlPalMsgInterface(commandQue),
            controller_id(id), host(h), port(p), socket_fd(-1),
            connected(false), identified(false), running(false) {

                device_info.id = id;
                device_info.deviceType = "WallController";
                device_info.firmwareVersion = "1.0.0";
            }

        ~SidebandInterface() {
            sideBandDisconnect();
        }

        bool sendMessage(const std::string& json);

    private:
        void log(const std::string& level, const std::string& message) {
            auto now = std::chrono::system_clock::now();
            auto time_t = std::chrono::system_clock::to_time_t(now);
            auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                    now.time_since_epoch()) % 1000;

            std::cout << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
            std::cout << "." << std::setfill('0') << std::setw(3) << ms.count();
            std::cout << " - WallController-" << controller_id << " - " 
                << level << " - " << message << std::endl;
        }

        void info(const std::string& message) { log("INFO", message); }
        void error(const std::string& message) { log("ERROR", message); }
        void warning(const std::string& message) { log("WARNING", message); }

        std::string parseJson(const std::string& json, const std::string& key);

        std::string parseJsonObject(const std::string& json, const std::string& key);

        void handleMessage(const std::string& message_str);

        void handleIdentify(const std::string& /* payload */);

        void handleWink(const std::string& payload);

    public:
        void messageHandler();

        bool sideBandDiscovery(OcaServiceDiscovery &discovery);

        bool sideBandConnect();

        void sideBandDisconnect();

        bool IsIdentified()
        {
            return identified;
        }

        void SetUiMsg(ControllerCmdIntfc &msg)
        {
            memset(&msgToUi, 0, sizeof(ControllerCmdIntfc));
            msgToUi = msg;
        }

        void SendValue()
        {
            // Send message to front-end
            PushToMsgQueue(msgToUi);
        }

};

#endif
