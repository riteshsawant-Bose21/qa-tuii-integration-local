#ifndef LOCAL_CONFIG_H
#define LOCAL_CONFIG_H

#include <filesystem>
#include <memory>
#include <mutex>

#include <boost/asio/thread_pool.hpp>

struct ConfigData
{
    static constexpr int BRIGHTNESS_LOW = 10;
    static constexpr int BRIGHTNESS_HIGH = 100;
    static constexpr int BRIGHTNESS_DEFAULT = 50;

    int brightness = ConfigData::BRIGHTNESS_DEFAULT;
};

class LocalConfig
{
  public:
    LocalConfig(LocalConfig const &) = delete;
    LocalConfig &operator=(LocalConfig const &) = delete;
    LocalConfig(LocalConfig &&) = delete;
    LocalConfig &operator=(LocalConfig &&) = delete;

    static std::shared_ptr<LocalConfig> getInstance();

    int getBrightness() const;
    void setBrightness(int brightness);

  private:
    LocalConfig();

    bool loadFromDisk();
    void triggerAsyncSave();
    void executeDiskCommit(const std::string &payload);

    inline static const std::filesystem::path m_configPath{"/persist/fusion/fusion-tuii.json"};

    mutable std::mutex m_mutex;
    ConfigData m_cachedConfig;
    boost::asio::thread_pool m_writePool;
};

#endif /* !LOCAL_CONFIG_H */
