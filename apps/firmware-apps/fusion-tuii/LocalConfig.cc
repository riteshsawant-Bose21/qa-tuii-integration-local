#include <algorithm>
#include <filesystem>
#include <fstream>
#include <memory>
#include <mutex>

#include <boost/asio/post.hpp>
#include <boost/asio/thread_pool.hpp>
#include <json/reader.h>
#include <json/value.h>
#include <json/writer.h>
#include <spdlog/spdlog.h>

#include "LocalConfig.h"

LocalConfig::LocalConfig() : m_writePool{1}
{
}

std::shared_ptr<LocalConfig> LocalConfig::getInstance()
{
    static auto localConfig = [] {
        auto localConfig = std::shared_ptr<LocalConfig>(new LocalConfig());
        localConfig->loadFromDisk();
        return localConfig;
    }();
    return localConfig;
}

int LocalConfig::getBrightness() const
{
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_cachedConfig.brightness;
}

void LocalConfig::setBrightness(int brightness)
{
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_cachedConfig.brightness = std::clamp(brightness, ConfigData::BRIGHTNESS_LOW, ConfigData::BRIGHTNESS_HIGH);
    }
    triggerAsyncSave();
}

bool LocalConfig::loadFromDisk()
{
    if (!std::filesystem::exists(m_configPath))
    {
        spdlog::info("[LocalConfig] Config file not found (first boot?): {}", m_configPath.string());
        return false;
    }

    try
    {
        std::ifstream file{m_configPath, std::ios::binary};
        Json::Value root;
        Json::CharReaderBuilder builder;
        std::string errs;

        if (!Json::parseFromStream(builder, file, &root, &errs))
        {
            spdlog::error("[LocalConfig] Failed to parse {}: {}", m_configPath.string(), errs);
            return false;
        }

        std::lock_guard<std::mutex> lock(m_mutex);
        m_cachedConfig.brightness = root.get("brightness", ConfigData::BRIGHTNESS_DEFAULT).asInt();
        return true;
    }
    catch (const std::exception &e)
    {
        spdlog::error("[LocalConfig] Failed to load {}: {}", m_configPath.string(), e.what());
        return false;
    }
}

void LocalConfig::triggerAsyncSave()
{
    std::string jsonPayload;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        Json::Value root;
        root["brightness"] = m_cachedConfig.brightness;

        Json::StreamWriterBuilder builder;
        jsonPayload = Json::writeString(builder, root);
    }

    boost::asio::post(m_writePool, [payload = std::move(jsonPayload), this]() mutable { executeDiskCommit(payload); });
}

void LocalConfig::executeDiskCommit(const std::string &payload)
{
    try
    {
        if (auto parentDir = m_configPath.parent_path(); !std::filesystem::exists(parentDir))
            std::filesystem::create_directories(parentDir);

        std::ofstream file{m_configPath, std::ios::binary | std::ios::trunc};
        if (!file.is_open())
        {
            spdlog::error("[LocalConfig] Failed to open {} for writing", m_configPath.string());
            return;
        }

        file.write(payload.data(), payload.size());
        file.flush();
    }
    catch (const std::exception &e)
    {
        spdlog::error("[LocalConfig] executeDiskCommit error: {}", e.what());
    }
}
