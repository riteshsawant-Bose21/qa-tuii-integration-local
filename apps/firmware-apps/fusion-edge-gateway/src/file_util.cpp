#include "file_util.h"

int readFile(const std::string &fileName, std::string &getsFirstLine) {
  std::ifstream fd(fileName);

  if (!fd) {
    SPDLOG_ERROR("[readFile] Cannot open '{}' for reading", fileName);
    return -1;
  }

  std::getline(fd, getsFirstLine);
  fd.close();

  return 0;
}

int writeFile(const std::string &fileName, const std::string &writeData){
  std::ofstream fd(fileName, std::ofstream::trunc);

  if (!fd) {
    SPDLOG_ERROR("[writeFile] Cannot open '{}' for writing", fileName);
    return -1;
  }

  fd << writeData;
  if (!fd) {
    SPDLOG_ERROR("[writeFile] Failed to write to '{}'", fileName);
    return -1;
  }
  fd.close();
  return 0;
}

int appendFile(const std::string &fileName, const std::string &writeData){
  std::ofstream fd(fileName, std::ios::app);

  if (!fd) {
    SPDLOG_ERROR("[appendFile] Cannot open '{}' for appending", fileName);
    return -1;
  }

  fd << writeData;
  if (!fd) {
    SPDLOG_ERROR("[appendFile] Failed to write to '{}'", fileName);
    return -1;
  }
  fd.close();
  return 0;
}

int deleteFile(const std::string &fileName) {
  if (std::remove(fileName.c_str()) != 0) {
    if (errno == ENOENT)
    {
      SPDLOG_DEBUG("File has been already deleted: {}", fileName);
      return 0;
    }
    else
    {
      SPDLOG_ERROR("Error deleting file {}: {}", fileName, std::strerror(errno));
      return -1;
    }
  }
  return 0;
}

// Make sure a file exists, return 0 if the file exits, or was created. 
// return -1 otherwise.
int createFile(const std::string &filePath)
{
  if (fileExists(filePath)) {
    return 0;
  }

  std::ofstream fOut(filePath.c_str());
  if (fOut.is_open()) {
    fOut.close();
    return 0;
  }
  else {
    SPDLOG_ERROR("Unable to create file: {}", filePath);
    return -1;
  }
}

std::string getDateTimeString(){
  time_t now = time(0);
  char timestr [32];

  tm *tmp = localtime(&now);
  strftime(timestr,32,"%Y-%m-%d-%H-%M-%S",tmp);
  return timestr;
}

int tarFiles(const std::string &sourceFolder, const std::string &sourceFile, const std::string &destPath){
  std::string tarCmd = "tar -cf " + destPath + " -C " + sourceFolder + " " + sourceFile;
  return runSystemCommand(tarCmd);
}

int gZipFile(const std::string &destPath){
  std::string gzipCmd = "gzip -f " + destPath;
  return runSystemCommand(gzipCmd);
}

int moveFiles(const std::string &sourcePath, const std::string &destPath){
  std::string moveCmd = "mv " + sourcePath + " " + destPath;
  return runSystemCommand(moveCmd);
}

int unZipFiles(const std::string &sourcePath, const std::string &destFolder){
  std::string unZipCmd = "gzip -df " + sourcePath;
  std::string tarName = sourcePath.substr(0, sourcePath.length()-3);
  std::string unTarCmd = "tar -xf " + tarName + " -C " + destFolder;
  std::string rmTarCmd = "rm -f " + tarName;

  int result = runSystemCommand(unZipCmd);
  if(result == 0){
    result = runSystemCommand(unTarCmd);
    if(result == 0){
      result = runSystemCommand(rmTarCmd);
    }
  }
  return result;
}

int copyFiles(const std::string &sourcePath, const std::string &destPath){
  std::string copyCmd = "cp " + sourcePath + " " + destPath;
  return runSystemCommand(copyCmd);
}

int changeFileOwner(const std::string &fileName, const std::string &userName, const std::string &groupName){
  std::string changeOwnerCmd = "chown -R " + userName + ":" + groupName + " " + fileName;
  return runSystemCommand(changeOwnerCmd);
}

int changeFileMode(const std::string &fileName, const std::string &mode){
  std::string changeFileMode = "chmod -R " + mode + " " + fileName;
  return runSystemCommand(changeFileMode);
}

std::string escapeJsonCharacters(const std::string &strBase)
{
  std::string outputString;
  for (char ch : strBase) {
    if (ch == '\\' || ch == '\"') {
      outputString += '\\';
    }
    outputString += ch;
  }
  return outputString;
}

int runSystemCommand(const std::string &cmd)
{
    int result = system(cmd.c_str());
    if(result !=0) {
      SPDLOG_ERROR("Command ({}) failed with error code : {}", cmd, result);
      return 1;
    }
    return 0;
}

std::string get_serial_id()
{
    std::ifstream file("/sys/firmware/devicetree/base/serial-number", std::ios::in | std::ios::binary);
    if (!file) {
        SPDLOG_ERROR("Error: Cannot open serial-number file.");
        return "SERIAL_ID_NOT_SET";
    }

    std::string serial;
    std::getline(file, serial, '\0');  // Read until null terminator
    return serial.empty() ? "SERIAL_ID_NOT_SET" : serial;
}

int getRAMUsedPercent()
{
    std::ifstream meminfo("/proc/meminfo");
    std::string line;
    long totalMem = 0, availableMem = -1;

    while (std::getline(meminfo, line)) {
        std::istringstream iss(line);
        std::string key;
        long value;
        std::string unit;
        iss >> key >> value >> unit;

        if (key == "MemTotal:") totalMem = value;
        else if (key == "MemAvailable:") availableMem = value;
    }

    if (totalMem <= 0 || availableMem < 0) return -1;

    long usedMem = totalMem - availableMem;
    return (int)((usedMem * 100) / totalMem);
}

int getSystemLoadPercent()
{
    std::ifstream loadavg("/proc/loadavg");
    float load1min = 0;
    loadavg >> load1min;

    int cores = std::thread::hardware_concurrency();
    if (cores == 0) cores = 1;

    return (int)((load1min / cores) * 100);
}

int getDiskUsagePercent(const std::string& path)
{
    struct statvfs stat;
    if (statvfs(path.c_str(), &stat) != 0) return -1;

    unsigned long long total = stat.f_blocks * stat.f_frsize;
    unsigned long long free = stat.f_bfree * stat.f_frsize;
    unsigned long long used = total - free;

    return (int)((used * 100) / total);
}

int getCpuUsagePercent()
{
    auto readCpuStat = []() -> std::vector<unsigned long long> {
        std::ifstream file("/proc/stat");
        std::string cpu;
        unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
        file >> cpu >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;
        return {user, nice, system, idle, iowait, irq, softirq, steal};
    };

    auto prev = readCpuStat();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    auto curr = readCpuStat();

    unsigned long long prevIdle = prev[3] + prev[4];
    unsigned long long currIdle = curr[3] + curr[4];

    unsigned long long prevTotal = std::accumulate(prev.begin(), prev.end(), 0ULL);
    unsigned long long currTotal = std::accumulate(curr.begin(), curr.end(), 0ULL);

    unsigned long long totald = currTotal - prevTotal;
    unsigned long long idled = currIdle - prevIdle;

    return (int)(((totald - idled) * 100) / totald);
}

int getCPUTemperature()
{
    std::ifstream file("/sys/class/thermal/thermal_zone0/temp");
    int tempMilliC = 0;
    file >> tempMilliC;
    return tempMilliC / 1000; // Convert to °C
}

uint64_t getNetworkRxBytes()
{
    std::ifstream file("/sys/class/net/eth0/statistics/rx_bytes");
    uint64_t rxBytes = 0;
    file >> rxBytes;
    return rxBytes;
}

uint64_t getNetworkTxBytes()
{
    std::ifstream file("/sys/class/net/eth0/statistics/tx_bytes");
    uint64_t txBytes = 0;
    file >> txBytes;
    return txBytes;
}

void getNetworkRates(double &rx_kbps, double &tx_kbps)
{
    uint64_t curr_rx = getNetworkRxBytes();
    uint64_t curr_tx = getNetworkTxBytes();
    auto now = std::chrono::steady_clock::now();
    double elapsed = std::chrono::duration<double>(now - last_sample_time).count();

    if (elapsed > 0.0) {
        rx_kbps = (curr_rx - prev_rx_bytes) / elapsed / 1024.0;
        tx_kbps = (curr_tx - prev_tx_bytes) / elapsed / 1024.0;
    } else {
        rx_kbps = tx_kbps = 0.0;
    }

    prev_rx_bytes = curr_rx;
    prev_tx_bytes = curr_tx;
    last_sample_time = now;
}

