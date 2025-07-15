/**
 * @file telemetry_util.h
 * General global data and utility functions.
 */

#pragma once

#include <string>
#include <sys/stat.h>
#include <vector>
#include <fstream>
#include <sys/statvfs.h>
#include <thread>
#include <chrono>
#include <errno.h>
#include <ifaddrs.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <cstring>

#include "nlohmann/json.hpp"
#include <spdlog/spdlog.h>


#define BASE_SERVER_URL "https://entry.xyte.io" // xyte url to test server reachability

#define CMD_STATUS_PENDING    "pending"
#define CMD_STATUS_INPROGRESS "in_progress"
#define CMD_STATUS_DONE       "done"
#define CMD_STATUS_FAILED     "failed"

/** 
 * startsWith - Utility function to check a string for a given prefix.
 *   Since we don't have string_view or C++20...
 */
inline bool startsWith(const char *prefix, const std::string &str)
{
    if (!prefix) {
        return false;
    }
    // Neat STL trick https://stackoverflow.com/a/40441240/443766
    return str.rfind(prefix, 0) == 0;
}

inline bool fileExists(const std::string &name)
{
    struct stat buffer;
    return (stat(name.c_str(), &buffer) == 0);
}

/**
 * readFile - Read the first line of a file in to `readBuffer`.
 */
int readFile(const std::string &fileName, std::string &getsFirstLine);

/**
 * writeFile - Write(overwrite) the data in to a file.
 */
int writeFile(const std::string &fileName, const std::string &writeData);

/**
 * appendFile - Append the data in to a file.
 */
int appendFile(const std::string &fileName, const std::string &writeData);

/**
 * deleteFile - Delete the file.
 */
int deleteFile(const std::string &fileName);

int createFile(const std::string &filePath);

/**
 * getDateTimeString - get Date and Time in String format (%Y-%m-%d-%H-%M-%S)
 */
std::string getDateTimeString();

/**
 * moveFiles - move files
 */
int moveFiles(const std::string &sourcePath, const std::string &destPath);

/**
 * copyFiles - copy files
 */
int copyFiles(const std::string &sourcePath, const std::string &destPath);

/**
 * changeFileOwner - Change user and group of the file
 */
int changeFileOwner(const std::string &fileName, const std::string &userName, const std::string &groupName);

/**
 * changeFileMode - Change the file mode
 */
int changeFileMode(const std::string &fileName, const std::string &mode);

/**
 * escapeJsonCharacters - recursively adds extra backslash to escape chars in a string
 */
std::string escapeJsonCharacters(const std::string &strBase);

/**
 * runSystemCommand - Run a system command and return the result.
 */
int runSystemCommand(const std::string &cmd);

std::string get_serial_id();
int getRAMUsedPercent();
int getSystemLoadPercent();
int getDiskUsagePercent(const std::string& path = "/");
int getCpuUsagePercent();
int getCPUTemperature();
static auto last_sample_time = std::chrono::steady_clock::now();
uint64_t getNetworkRxBytes();
uint64_t getNetworkTxBytes();
void getNetworkRates(double &rx_kbps, double &tx_kbps);
std::string getLocalIPAddress();
void checkDelayElapsed(time_t &endTime, const int delay_seconds);
int createLogs(std::string &output);
int tarFiles(const std::string &sourceFolder, const std::string &sourceFile, const std::string &destPath);
int gZipFile(const std::string &destPath);
int unZipFiles(const std::string &sourcePath, const std::string &destFolder);
