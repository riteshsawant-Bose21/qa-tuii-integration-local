#include "observer.h"

int main(int argc, char *argv[])
{
  try
  {
    if (argc < 4)
    {
      std::cerr << "Usage: " << argv[0]
                << " <server_ip> <port> <path1> [path2 ...]\n";
      std::cerr << "Example: " << argv[0]
                << " 127.0.0.1 7947 settings.audio.peq1.* "
                   "settings.audio.peq2.* --verbose\n";
      return 1;
    }

    const std::string serverIP = argv[1];
    const int port = std::stoi(argv[2]);

    std::vector<std::string> targetPaths;
    for (int i = 3; i < argc; i++)
    {
      targetPaths.push_back(argv[i]);
    }

    std::cout << "Starting Value Observer\n";
    std::cout << "Server: " << serverIP << ":" << port << "\n";
    std::cout << "Monitoring paths:\n";
    for (const auto &path : targetPaths)
    {
      std::cout << "  " << path << "\n";
    }

    UDPValueMonitor client(serverIP, port);

    // Register device ID change callback
    client.watchDeviceID([](const std::string &deviceID)
                         { SPDLOG_INFO("Device ID changed to: {}", deviceID); });

    for (const auto &path : targetPaths)
    {
      if (path.find('*') != std::string::npos)
      {

        // Register pattern path change callback
        client.watchPattern(path, [](const std::string &p,
                                     const Json::Value &old_val,
                                     const Json::Value &new_val)
                            { 
                              SPDLOG_INFO("Configuration pattern update received at {}", p);
                              SPDLOG_INFO("Configuration pattern update from {} to {}", old_val.toStyledString(), new_val.toStyledString()); });
      }
      else
      {
        // Register path change callback
        client.watch(path, [](const std::string &p,
                              const Json::Value &old_val,
                              const Json::Value &new_val)
                     {
                       SPDLOG_INFO("Value update received at {}", p);
                       SPDLOG_INFO("Value update from {} to {}", old_val.toStyledString(), new_val.toStyledString()); });
      }
    }
    std::cin.get();
    client.stop();
  }
  catch (const std::exception &e)
  {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
