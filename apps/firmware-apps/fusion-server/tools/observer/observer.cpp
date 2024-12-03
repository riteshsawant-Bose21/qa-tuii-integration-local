#include "observer.h"

int main(int argc, char *argv[]) {
  try {
    if (argc < 4) {
      std::cerr << "Usage: " << argv[0]
                << " <server_ip> <port> <path1> [path2 ...]\n";
      std::cerr
          << "Example: " << argv[0]
          << " 127.0.0.1 7947 audio.settings.peq1.* audio.settings.peq2.*\n";
      return 1;
    }

    const std::string serverIP = argv[1];
    const int port = std::stoi(argv[2]);
    std::vector<std::string> targetPaths;
    for (int i = 3; i < argc; i++) {
      targetPaths.push_back(argv[i]);
    }

    std::cout << "Starting UDPValueMonitor\n";
    std::cout << "Server: " << serverIP << ":" << port << "\n";
    std::cout << "Monitoring paths:\n";
    for (const auto &path : targetPaths) {
      std::cout << "  " << path << "\n";
    }

    UDPValueMonitor client(serverIP, port, targetPaths);
    std::cin.get();
    client.stop();
  } catch (const std::exception &e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
