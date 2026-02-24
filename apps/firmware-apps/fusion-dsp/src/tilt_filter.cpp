
#include "iir.h"

#include <bosepro/algorithm.h>

#include <boost/property_tree/json_parser.hpp>
#include <boost/property_tree/ptree.hpp>

#include <spdlog/spdlog.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

struct TiltProfile
{
    std::string name;
    int sample_rate = 48000;
    std::vector<std::array<double, 6>> sos;
};

struct TiltMappingEntry
{
    double tilt_db_per_octave = 0.0;
    const TiltProfile *profile = nullptr;
};

struct ProfileLibrary
{
    std::unordered_map<std::string, TiltProfile> profiles;
    int max_sections = 0;
    std::string default_profile_name;
    std::vector<TiltMappingEntry> tilt_map;

    const TiltProfile *find_closest_profile(double tilt) const;
};

const TiltProfile *ProfileLibrary::find_closest_profile(double tilt) const
{
    if (tilt_map.empty())
    {
        return nullptr;
    }

    const auto closest = std::min_element(
        tilt_map.begin(), tilt_map.end(),
        [tilt](const TiltMappingEntry &lhs, const TiltMappingEntry &rhs) {
            const double lhs_distance = std::abs(lhs.tilt_db_per_octave - tilt);
            const double rhs_distance = std::abs(rhs.tilt_db_per_octave - tilt);
            if (std::abs(lhs_distance - rhs_distance) < 1e-9)
            {
                return lhs.tilt_db_per_octave < rhs.tilt_db_per_octave;
            }
            return lhs_distance < rhs_distance;
        });

    return closest != tilt_map.end() ? closest->profile : nullptr;
}

std::shared_ptr<ProfileLibrary> load_profile_library(const std::string &path)
{
    static std::mutex cache_mutex;
    static std::unordered_map<std::string, std::weak_ptr<ProfileLibrary>> cache;

    std::lock_guard<std::mutex> lock(cache_mutex);

    auto cached = cache[path].lock();
    if (cached)
    {
        return cached;
    }

    auto library = std::make_shared<ProfileLibrary>();

    try
    {
        boost::property_tree::ptree root;
        boost::property_tree::read_json(path, root);

        auto coefficients = root.get_child_optional("coefficients");
        if (!coefficients)
        {
            SPDLOG_ERROR("Tilt filter coefficient file '{}' is missing the 'coefficients' object.",
                         path);
            return nullptr;
        }

        for (auto &kv : *coefficients)
        {
            TiltProfile profile;
            profile.name = kv.first;
            profile.sample_rate = kv.second.get<int>("sample_rate", 48000);

            auto sos_nodes = kv.second.get_child_optional("sos");
            if (!sos_nodes)
            {
                SPDLOG_WARN("Tilt filter profile '{}' is missing SOS data; skipping.",
                            profile.name);
                continue;
            }

            for (auto &section_node : *sos_nodes)
            {
                std::array<double, 6> section{};
                size_t idx = 0;
                for (auto &coeff_node : section_node.second)
                {
                    if (idx < section.size())
                    {
                        section[idx++] = coeff_node.second.get_value<double>();
                    }
                }

                if (idx == section.size())
                {
                    profile.sos.push_back(section);
                }
                else
                {
                    SPDLOG_WARN("Skipping incomplete SOS entry '{}'[{}] ({} coefficients, expected 6).",
                                profile.name, profile.sos.size(), idx);
                }
            }

            if (!profile.sos.empty())
            {
                library->max_sections =
                    std::max(library->max_sections,
                             static_cast<int>(profile.sos.size()));
                if (library->default_profile_name.empty())
                {
                    library->default_profile_name = profile.name;
                }
                library->profiles.emplace(profile.name, std::move(profile));
            }
            else
            {
                SPDLOG_WARN("Tilt filter profile '{}' did not contain any valid SOS sections; skipping.",
                            profile.name);
            }
        }
        auto tilt_mapping = root.get_child_optional("tilt_mapping");
        if (tilt_mapping)
        {
            for (const auto &entry : *tilt_mapping)
            {
                try
                {
                    const double tilt_value = entry.second.get<double>("tilt_db_per_octave");
                    const auto profile_name = entry.second.get<std::string>("profile");
                    auto profile_iter = library->profiles.find(profile_name);
                    if (profile_iter == library->profiles.end())
                    {
                        SPDLOG_WARN("Tilt mapping references unknown profile '{}' in '{}'.",
                                    profile_name, path);
                        continue;
                    }

                    TiltMappingEntry mapping_entry;
                    mapping_entry.tilt_db_per_octave = tilt_value;
                    mapping_entry.profile = &profile_iter->second;
                    library->tilt_map.push_back(mapping_entry);
                }
                catch (const std::exception &ex)
                {
                    SPDLOG_WARN("Skipping malformed tilt mapping entry in '{}': {}",
                                path, ex.what());
                }
            }

            std::sort(library->tilt_map.begin(), library->tilt_map.end(),
                      [](const TiltMappingEntry &lhs, const TiltMappingEntry &rhs) {
                          if (lhs.tilt_db_per_octave == rhs.tilt_db_per_octave)
                          {
                              return lhs.profile->name < rhs.profile->name;
                          }
                          return lhs.tilt_db_per_octave < rhs.tilt_db_per_octave;
                      });
        }
        else
        {
            SPDLOG_WARN("Tilt filter coefficient file '{}' is missing the 'tilt_mapping' array.",
                        path);
        }
    }
    catch (const std::exception &ex)
    {
        SPDLOG_ERROR("Failed to load tilt filter coefficients from '{}': {}",
                     path, ex.what());
        return nullptr;
    }

    if (library->profiles.empty())
    {
        SPDLOG_ERROR("Tilt filter coefficient file '{}' contained no usable profiles.", path);
        return nullptr;
    }

    if (library->max_sections == 0)
    {
        library->max_sections = 1;
    }

    cache[path] = library;
    return library;
}

class TiltFilter : public bosepro::Algorithm
{
public:
    TiltFilter(const bosepro::BlockConfiguration &configuration);
    virtual ~TiltFilter() = default;

    virtual void process() override;

private:
    void update_profile();
    void set_identity_sections();

    int_fast32_t channels = 1;
    std::string coefficients_path;
    int section_count = 1;

    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspStateMemory<filter::IirFilter> iir;

    float tilt_db_per_octave = 0.0f;
    const TiltProfile *active_profile = nullptr;
    std::shared_ptr<ProfileLibrary> library;

    ALGORITHM_DECLARE(TiltFilter);
};

ALGORITHM_REGISTER(TiltFilter, "tilt_filter");

TiltFilter::TiltFilter(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);
    get_property("coefficients_file", coefficients_path);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("tilt", &tilt_db_per_octave,
                     POST_FUNCTION_SCALAR(update_profile));

    library = load_profile_library(coefficients_path);
    section_count = 1;
    if (library)
    {
        section_count = std::max(1, library->max_sections);
    }

    new (iir.get()) filter::IirFilter(section_count, channels);
    set_identity_sections();
}

void TiltFilter::process()
{
    iir->process(out.get(), in.get(), get_frame_size());
}

void TiltFilter::update_profile()
{
    if (!library)
    {
        SPDLOG_ERROR("No tilt filter profiles available (file '{}').", coefficients_path);
        active_profile = nullptr;
        set_identity_sections();
        return;
    }

    const TiltProfile *selected_profile =
        library->find_closest_profile(static_cast<double>(tilt_db_per_octave));

    if (selected_profile == nullptr)
    {
        auto fallback_iter = library->profiles.find(library->default_profile_name);
        if (fallback_iter != library->profiles.end())
        {
            selected_profile = &fallback_iter->second;
            SPDLOG_WARN(
                "Falling back to default tilt filter profile '{}' for tilt {} dB/oct.",
                selected_profile->name, tilt_db_per_octave);
        }
    }

    if (selected_profile == nullptr)
    {
        SPDLOG_ERROR("Unable to map tilt {} dB/oct to a profile in '{}'.",
                     tilt_db_per_octave, coefficients_path);
        active_profile = nullptr;
        set_identity_sections();
        return;
    }

    active_profile = selected_profile;

    SPDLOG_DEBUG("Tilt filter mapped {} dB/oct to profile '{}'.", tilt_db_per_octave,
                 active_profile->name);

    if (active_profile->sample_rate != get_sample_rate())
    {
        SPDLOG_WARN("Tilt filter profile '{}' designed for {} Hz is running at {} Hz.",
                    active_profile->name, active_profile->sample_rate, get_sample_rate());
    }

    set_identity_sections();

    const int sections_to_program =
        std::min(section_count,
                 static_cast<int>(active_profile->sos.size()));
    for (int section = 0; section < sections_to_program; ++section)
    {
        const auto &coefficients = active_profile->sos[section];
        const double b0 = coefficients[0];
        const double b1 = coefficients[1];
        const double b2 = coefficients[2];
        const double a0 = coefficients[3];
        const double a1 = coefficients[4];
        const double a2 = coefficients[5];

        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
}

void TiltFilter::set_identity_sections()
{
    for (int section = 0; section < section_count; ++section)
    {
        iir->set_section_coeffs(section, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    }
}

} // namespace
