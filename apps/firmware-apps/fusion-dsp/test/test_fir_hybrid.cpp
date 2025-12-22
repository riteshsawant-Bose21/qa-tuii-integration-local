#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/session.h>

#include <doctest/doctest.h>
#include <json/json.h>

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace {
constexpr int SampleRate = 48000;
constexpr int FrameSize = 256;
constexpr int WarmupFrames = 220;
constexpr int WarmupSamples = FrameSize * WarmupFrames;
constexpr float Tolerance = 1e-4f;
constexpr float Pi = 3.14159265f;

struct SignalGeneratorSettings {
    std::string signal_type = "noise";
    float sine_frequency = 1000.0f;
    std::string noise_type = "pink";
    std::string sweep_rate = "slow";
    bool sweep_run = false;
};

void apply_parameter_settings(bosepro::Session &session,
                              const bosepro::Configuration &configuration)
{
    if (!configuration.has_parameter_settings()) {
        return;
    }

    for (auto &entry : configuration.get_parameter_settings()) {
        const auto &setting = reinterpret_cast<const bosepro::ParameterSetting &>(entry.second);
        session.process_parameter_setting(setting);
    }
}
std::string build_signal_generator_config_json(const SignalGeneratorSettings &settings)
{
    Json::Value root;

    Json::Value session;
    session["name"] = "signal_generator_test";
    Json::Value session_props(Json::arrayValue);
    Json::Value frame_prop;
    frame_prop["name"] = "frame_size";
    frame_prop["value"] = FrameSize;
    session_props.append(frame_prop);
    Json::Value sample_prop;
    sample_prop["name"] = "sample_rate";
    sample_prop["value"] = SampleRate;
    session_props.append(sample_prop);
    session["property_settings"] = session_props;
    root["session"] = session;

    Json::Value task;
    task["name"] = "test_task";

    Json::Value task_props(Json::arrayValue);
    Json::Value jack_prop;
    jack_prop["name"] = "is_jack_client";
    jack_prop["value"] = false;
    task_props.append(jack_prop);
    Json::Value task_frame_prop;
    task_frame_prop["name"] = "frame_size";
    task_frame_prop["value"] = FrameSize;
    task_props.append(task_frame_prop);
    Json::Value task_sample_prop;
    task_sample_prop["name"] = "sample_rate";
    task_sample_prop["value"] = SampleRate;
    task_props.append(task_sample_prop);
    task["property_settings"] = task_props;

    Json::Value block;
    block["name"] = "signal_generator_block";
    block["algorithm"] = "signal_generator";
    block["property_settings"] = Json::arrayValue;

    Json::Value blocks(Json::arrayValue);
    blocks.append(block);
    task["blocks"] = blocks;
    task["block_connections"] = Json::arrayValue;

    Json::Value audio_tasks(Json::arrayValue);
    audio_tasks.append(task);
    root["audio_tasks"] = audio_tasks;

    auto make_param = [](const std::string &name, const Json::Value &value) {
        Json::Value param;
        param["target"] = "signal_generator_block";
        param["name"] = name;
        param["value"] = value;
        return param;
    };

    Json::Value params(Json::arrayValue);
    params.append(make_param("signal_type", settings.signal_type));
    params.append(make_param("sine_frequency", settings.sine_frequency));
    params.append(make_param("noise_type", settings.noise_type));
    params.append(make_param("sweep_rate", settings.sweep_rate));
    params.append(make_param("sweep_run", settings.sweep_run));

    Json::Value gain_param = make_param("out_gain", 0.0);
    Json::Value gain_index(Json::arrayValue);
    gain_index.append(1);
    gain_param["index"] = gain_index;
    params.append(gain_param);

    Json::Value mute_param = make_param("out_mute", false);
    Json::Value mute_index(Json::arrayValue);
    mute_index.append(1);
    mute_param["index"] = mute_index;
    params.append(mute_param);

    root["parameter_settings"] = params;

    Json::StreamWriterBuilder builder;
    builder["indentation"] = "  ";
    return Json::writeString(builder, root);
}

std::vector<float> generate_signal(size_t total_samples, const SignalGeneratorSettings &settings)
{
    const std::string config_json = build_signal_generator_config_json(settings);
    std::stringstream config_stream;
    config_stream << config_json;

    bosepro::Configuration configuration(config_stream);
    bosepro::Definition definition("config/algorithm-definitions.json");
    bosepro::Session session(configuration.get_session(), definition);
    session.create_audio_tasks(configuration);

    apply_parameter_settings(session, configuration);

    auto *task = session.get_task("test_task");
    REQUIRE(task != nullptr);
    auto *block = task->get_block("signal_generator_block");
    REQUIRE(block != nullptr);
    auto &out_terminal = block->get_terminal("out");

    std::vector<float> output;
    output.reserve(total_samples);

    const int total_frames = (static_cast<int>(total_samples) + FrameSize - 1) / FrameSize;
    size_t samples_generated = 0;
    for (int frame = 0; frame < total_frames; ++frame) {
        session.process();
        float *out_buffer = static_cast<float *>(out_terminal.get_buffer(0));
        const int samples_this_frame =
            std::min(FrameSize, static_cast<int>(total_samples - samples_generated));
        for (int i = 0; i < samples_this_frame; ++i) {
            output.push_back(out_buffer[i]);
        }
        samples_generated += static_cast<size_t>(samples_this_frame);
    }

    return output;
}

std::vector<float> make_lowpass_coefficients(int num_taps, float cutoff_hz)
{
    std::vector<float> coeffs(num_taps);
    const float normalized_cutoff = cutoff_hz / static_cast<float>(SampleRate);
    const int center = num_taps / 2;

    float sum = 0.0f;
    for (int i = 0; i < num_taps; ++i) {
        const int n = i - center;
        float sinc;
        if (n == 0) {
            sinc = 2.0f * normalized_cutoff;
        } else {
            sinc = std::sin(2.0f * Pi * normalized_cutoff * static_cast<float>(n)) /
                   (Pi * static_cast<float>(n));
        }

        // Hamming window for nicer sidelobes
        const float window = 0.54f - 0.46f *
            std::cos(2.0f * Pi * static_cast<float>(i) / static_cast<float>(num_taps - 1));

        coeffs[i] = sinc * window;
        sum += coeffs[i];
    }

    for (auto &c : coeffs) {
        c /= sum;
    }

    return coeffs;
}

std::vector<float> make_test_coefficients()
{
    return make_lowpass_coefficients(32, 8000.0f);
}

std::vector<float> make_step_signal(size_t total_samples, size_t step_start)
{
    std::vector<float> signal(total_samples, 0.0f);
    for (size_t i = step_start; i < total_samples; ++i) {
        signal[i] = 1.0f;
    }
    return signal;
}

std::vector<float> make_white_noise_signal(size_t total_samples)
{
    SignalGeneratorSettings settings;
    settings.signal_type = "noise";
    settings.noise_type = "white";
    return generate_signal(total_samples, settings);
}

std::vector<float> make_sine_sweep_signal(size_t total_samples,
                                          float start_freq,
                                          float end_freq)
{
    REQUIRE(start_freq == 20.0f);
    REQUIRE(end_freq == 20000.0f);

    SignalGeneratorSettings settings;
    settings.signal_type = "sweep";
    settings.sweep_rate = "fast";
    settings.sweep_run = true;
    return generate_signal(total_samples, settings);
}

float compute_rms(const std::vector<float> &signal, size_t start_idx)
{
    if (start_idx >= signal.size()) {
        return 0.0f;
    }
    double sum_sq = 0.0;
    size_t count = 0;
    for (size_t i = start_idx; i < signal.size(); ++i) {
        sum_sq += static_cast<double>(signal[i]) * static_cast<double>(signal[i]);
        ++count;
    }
    return count == 0 ? 0.0f : static_cast<float>(std::sqrt(sum_sq / static_cast<double>(count)));
}

float compute_max_abs_difference(const std::vector<float> &a,
                                 const std::vector<float> &b,
                                 size_t start_idx)
{
    REQUIRE(a.size() == b.size());
    float max_error = 0.0f;
    for (size_t i = start_idx; i < a.size(); ++i) {
        max_error = std::max(max_error, std::abs(a[i] - b[i]));
    }
    return max_error;
}

std::vector<float> run_fir_algorithm(const std::string &algorithm_name,
                                     const std::string &block_name,
                                     const std::vector<float> &input,
                                     const std::vector<float> &coefficients,
                                     int direct_taps_override = -1);

float compute_rms_difference(const std::vector<float> &a,
                             const std::vector<float> &b,
                             size_t start_idx)
{
    REQUIRE(a.size() == b.size());
    if (start_idx >= a.size()) {
        return 0.0f;
    }
    double sum_sq = 0.0;
    size_t count = 0;
    for (size_t i = start_idx; i < a.size(); ++i) {
        const double diff = static_cast<double>(a[i]) - static_cast<double>(b[i]);
        sum_sq += diff * diff;
        ++count;
    }
    return count == 0 ? 0.0f : static_cast<float>(std::sqrt(sum_sq / static_cast<double>(count)));
}

float compute_energy_range(const std::vector<float> &signal,
                           size_t start_idx,
                           size_t end_idx)
{
    REQUIRE(start_idx <= end_idx);
    REQUIRE(end_idx <= signal.size());
    double sum_sq = 0.0;
    for (size_t i = start_idx; i < end_idx; ++i) {
        sum_sq += static_cast<double>(signal[i]) * static_cast<double>(signal[i]);
    }
    return static_cast<float>(sum_sq);
}

float compute_max_abs_range(const std::vector<float> &signal,
                            size_t start_idx,
                            size_t end_idx)
{
    REQUIRE(start_idx <= end_idx);
    REQUIRE(end_idx <= signal.size());
    float max_value = 0.0f;
    for (size_t i = start_idx; i < end_idx; ++i) {
        max_value = std::max(max_value, std::abs(signal[i]));
    }
    return max_value;
}

struct FirOutputs {
    std::vector<float> hybrid;
    std::vector<float> direct;
};

FirOutputs run_fir_pair(const std::vector<float> &input,
                        const std::vector<float> &coefficients,
                        int hybrid_direct_taps = -1)
{
    FirOutputs outputs;
    outputs.hybrid = run_fir_algorithm("fir_hybrid",
                                       "fir_hybrid_under_test",
                                       input,
                                       coefficients,
                                       hybrid_direct_taps);
    outputs.direct = run_fir_algorithm("fir_direct", "fir_direct_reference", input, coefficients);
    REQUIRE(outputs.hybrid.size() == outputs.direct.size());
    return outputs;
}

    struct PartitionWindow {
        std::string label;
        size_t start;
        size_t end;
    };

    int resolve_direct_taps(int num_taps, int direct_taps_override)
    {
        if (direct_taps_override > 0) {
            return direct_taps_override;
        }
        return std::min(128, num_taps);
    }

    std::vector<PartitionWindow> build_partition_windows(int num_taps,
                                                         int direct_taps_override)
    {
        REQUIRE(num_taps > 0);
        const int direct_taps = resolve_direct_taps(num_taps, direct_taps_override);
        int base_partition_size = std::max(direct_taps / 2, 2 * FrameSize);
        const int max_partition_size = 65536;

        std::vector<PartitionWindow> windows;
        windows.reserve(12);

        const int direct_length = std::min(2 * base_partition_size, num_taps);
        windows.push_back({"partition 0 (direct)", 0u, static_cast<size_t>(direct_length)});

        size_t position = static_cast<size_t>(direct_length);
        int partition_index = 1;
        int current_partition_size = base_partition_size;

        while (position < static_cast<size_t>(num_taps)) {
            for (int pair = 0; pair < 2 && position < static_cast<size_t>(num_taps); ++pair) {
                const size_t remaining = static_cast<size_t>(num_taps) - position;
                const size_t length = std::min(static_cast<size_t>(current_partition_size), remaining);
                std::ostringstream label;
                label << "partition " << partition_index;
                windows.push_back({label.str(), position, position + length});
                position += length;
                ++partition_index;
            }
            current_partition_size = std::min(current_partition_size * 2, max_partition_size);
        }

        REQUIRE(!windows.empty());
        REQUIRE(windows.back().end == static_cast<size_t>(num_taps));
        return windows;
    }

    void check_partition_energy_distribution(const std::vector<float> &hybrid,
                                             const std::vector<float> &direct,
                                             size_t response_start,
                                             const std::vector<PartitionWindow> &windows)
    {
        REQUIRE(hybrid.size() == direct.size());
        const size_t response_end = response_start + windows.back().end;
        REQUIRE(response_end <= hybrid.size());

        struct PartitionStats {
            PartitionWindow window;
            float hybrid_energy;
            float direct_energy;
            float hybrid_max;
            float direct_max;
        };

        std::vector<PartitionStats> stats;
        stats.reserve(windows.size());

        double total_hybrid_energy = 0.0;
        double total_direct_energy = 0.0;

        for (const auto &window : windows) {
            const size_t window_start_idx = response_start + window.start;
            const size_t window_end_idx = response_start + window.end;
            const float hybrid_energy = compute_energy_range(hybrid, window_start_idx, window_end_idx);
            const float direct_energy = compute_energy_range(direct, window_start_idx, window_end_idx);
            const float hybrid_max = compute_max_abs_range(hybrid, window_start_idx, window_end_idx);
            const float direct_max = compute_max_abs_range(direct, window_start_idx, window_end_idx);

            stats.push_back({window, hybrid_energy, direct_energy, hybrid_max, direct_max});
            total_hybrid_energy += hybrid_energy;
            total_direct_energy += direct_energy;
        }

        REQUIRE(total_direct_energy > 0.0);

    constexpr float AbsoluteMinEnergyForRatio = 1e-5f;
    constexpr float MinEnergyFractionForRatio = 1e-3f;   // 0.1% of total direct energy
    constexpr float ResidualEnergyBudget = 5e-4f;
    constexpr float ResidualMaxBudget = 2e-3f;
        constexpr float MaxRatio = 1.2f;
        constexpr float MinRatio = 0.8f;

        for (const auto &stat : stats) {
            INFO("partition=" << stat.window.label << ", hybrid_energy=" << stat.hybrid_energy
                               << ", direct_energy=" << stat.direct_energy);
            const float direct_fraction = static_cast<float>(stat.direct_energy / total_direct_energy);
            const bool has_significant_energy = stat.direct_energy >= AbsoluteMinEnergyForRatio &&
                                                direct_fraction >= MinEnergyFractionForRatio;

            if (has_significant_energy) {
                const float safe_direct_energy = std::max(stat.direct_energy, 1e-8f);
                const float ratio = stat.hybrid_energy / safe_direct_energy;
                CHECK_GT(ratio, MinRatio);
                CHECK_LT(ratio, MaxRatio);

                const float safe_direct_max = std::max(stat.direct_max, 1e-7f);
                const float max_ratio = stat.hybrid_max / safe_direct_max;
                CHECK_GT(max_ratio, 0.6f);
                CHECK_LT(max_ratio, 1.4f);
            } else {
                CHECK_LT(stat.hybrid_energy, stat.direct_energy + ResidualEnergyBudget);
                CHECK_LT(stat.hybrid_max, stat.direct_max + ResidualMaxBudget);
            }
        }

        const float total_ratio = static_cast<float>(total_hybrid_energy / total_direct_energy);
        CHECK_LT(std::abs(total_ratio - 1.0f), 0.1f);

    constexpr float ZeroFrameDirectThreshold = 1e-2f;
    constexpr float ZeroFrameResidual = 1e-2f;
        const size_t window_size = FrameSize;
        for (size_t offset = 0; offset < windows.back().end; offset += window_size) {
            const size_t start_idx = response_start + offset;
            const size_t end_idx = std::min(response_start + windows.back().end, start_idx + window_size);
            const float direct_max = compute_max_abs_range(direct, start_idx, end_idx);
            const float hybrid_max = compute_max_abs_range(hybrid, start_idx, end_idx);
            INFO("zero-check offset=" << offset << ", max_abs=" << hybrid_max);
            if (direct_max >= ZeroFrameDirectThreshold) {
                const float ratio = hybrid_max / std::max(direct_max, 1e-7f);
                CHECK_GT(ratio, 0.5f);
                CHECK_LT(ratio, 1.5f);
            } else {
                CHECK_LT(hybrid_max, ZeroFrameResidual);
            }
        }
    }

    void verify_partition_energy_for_impulse(int num_taps, int direct_taps_override)
    {
        const auto coefficients = make_lowpass_coefficients(num_taps, 8000.0f);
        const size_t total_samples = WarmupSamples + coefficients.size() + FrameSize;
        std::vector<float> impulse(total_samples, 0.0f);
        impulse[WarmupSamples] = 1.0f;

        const auto outputs = run_fir_pair(impulse, coefficients, direct_taps_override);
        const size_t response_start = WarmupSamples;
        const auto windows = build_partition_windows(num_taps, direct_taps_override);
        check_partition_energy_distribution(outputs.hybrid, outputs.direct, response_start, windows);
    }

void verify_impulse_response(const std::vector<float> &coefficients,
                             int direct_taps_override = -1,
                             float tolerance = Tolerance)
{
    const size_t total_samples = WarmupSamples + coefficients.size() + FrameSize;
    std::vector<float> impulse(total_samples, 0.0f);
    impulse[WarmupSamples] = 1.0f;

    const auto hybrid_output = run_fir_algorithm("fir_hybrid",
                                                 "fir_hybrid_under_test",
                                                 impulse,
                                                 coefficients,
                                                 direct_taps_override);
    const auto direct_output = run_fir_algorithm("fir_direct",
                                                 "fir_direct_reference",
                                                 impulse,
                                                 coefficients);

    REQUIRE(hybrid_output.size() == direct_output.size());

    float max_error = 0.0f;
    for (size_t tap = 0; tap < coefficients.size(); ++tap) {
        const size_t idx = WarmupSamples + tap;
        REQUIRE(idx < hybrid_output.size());

        const float error = std::abs(hybrid_output[idx] - direct_output[idx]);
        max_error = std::max(max_error, error);
    }

    CHECK_LT(max_error, tolerance);
}

void run_high_tap_smoke_test(int num_taps)
{
    const auto coefficients = make_lowpass_coefficients(num_taps, 8000.0f);
    const size_t total_samples = WarmupSamples + coefficients.size() + FrameSize;
    std::vector<float> impulse(total_samples, 0.0f);
    impulse[WarmupSamples] = 1.0f;

    const int direct_taps_override = num_taps >= 1024 ? 1024 : -1;
    const auto hybrid_output = run_fir_algorithm("fir_hybrid",
                                                 "fir_hybrid_large_tap_test",
                                                 impulse,
                                                 coefficients,
                                                 direct_taps_override);

    REQUIRE(hybrid_output.size() == total_samples);
    const size_t response_start = WarmupSamples;
    const size_t response_end = response_start + coefficients.size();
    REQUIRE(response_end <= hybrid_output.size());

    const float max_abs = compute_max_abs_range(hybrid_output, response_start, response_end);
    CHECK_GT(max_abs, 1e-5f);
}

std::string build_fir_config_json(const std::string &block_name,
                                  const std::string &algorithm_name,
                                  const std::vector<float> &coefficients,
                                  int direct_taps_override)
{
    const int num_taps = static_cast<int>(coefficients.size());
    const int default_direct_taps = std::min(128, num_taps);
    const int direct_taps = direct_taps_override > 0 ? direct_taps_override : default_direct_taps;

    auto append_property = [](Json::Value &array, const std::string &name, const Json::Value &value) {
        Json::Value entry;
        entry["name"] = name;
        entry["value"] = value;
        array.append(entry);
    };

    Json::Value root;
    root["session"]["name"] = "fir_test";
    append_property(root["session"]["property_settings"], "frame_size", FrameSize);
    append_property(root["session"]["property_settings"], "sample_rate", SampleRate);

    Json::Value task;
    task["name"] = "test_task";
    append_property(task["property_settings"], "is_jack_client", false);
    append_property(task["property_settings"], "frame_size", FrameSize);
    append_property(task["property_settings"], "sample_rate", SampleRate);

    Json::Value block;
    block["name"] = block_name;
    block["algorithm"] = algorithm_name;
    append_property(block["property_settings"], "channels", 1);
    append_property(block["property_settings"], "num_taps", num_taps);
    append_property(block["property_settings"], "frame_size", FrameSize);
    append_property(block["property_settings"], "sample_rate", SampleRate);
    if (algorithm_name == "fir_hybrid") {
        append_property(block["property_settings"], "direct_taps", direct_taps);
    }
    task["blocks"].append(block);
    task["block_connections"] = Json::arrayValue;

    root["audio_tasks"].append(task);

    for (int i = 0; i < num_taps; ++i) {
        Json::Value param;
        param["target"] = block_name;
        param["name"] = "coefficients";
        Json::Value index(Json::arrayValue);
        index.append(i + 1);
        param["index"] = index;
        param["value"] = static_cast<double>(coefficients[i]);
        root["parameter_settings"].append(param);
    }

    Json::StreamWriterBuilder writer;
    writer["indentation"] = "  ";
    return Json::writeString(writer, root);
}

std::vector<float> run_fir_algorithm(const std::string &algorithm_name,
                                     const std::string &block_name,
                                     const std::vector<float> &input,
                                     const std::vector<float> &coefficients,
                                     int direct_taps_override)
{

    const std::string config_json = build_fir_config_json(block_name,
                                                         algorithm_name,
                                                         coefficients,
                                                         direct_taps_override);
    std::stringstream config_stream;
    config_stream << config_json;

    bosepro::Configuration configuration(config_stream);
    bosepro::Definition definition("config/algorithm-definitions.json");
    bosepro::Session session(configuration.get_session(), definition);
    session.create_audio_tasks(configuration);

    apply_parameter_settings(session, configuration);

    auto *task = session.get_task("test_task");
    REQUIRE(task != nullptr);
    auto *block = task->get_block(block_name);
    REQUIRE(block != nullptr);

    auto &in_terminal = block->get_terminal("in");
    auto &out_terminal = block->get_terminal("out");

    std::vector<float> output;
    output.reserve(input.size());

    const int total_frames = (static_cast<int>(input.size()) + FrameSize - 1) / FrameSize;
    for (int frame = 0; frame < total_frames; ++frame) {
        float *in_buffer = static_cast<float *>(in_terminal.get_buffer(0));
        const int frame_start = frame * FrameSize;
        const int samples_this_frame = std::min(FrameSize, static_cast<int>(input.size()) - frame_start);

        for (int i = 0; i < samples_this_frame; ++i) {
            in_buffer[i] = input[frame_start + i];
        }
        std::fill_n(in_buffer + samples_this_frame, FrameSize - samples_this_frame, 0.0f);

        session.process();

        float *out_buffer = static_cast<float *>(out_terminal.get_buffer(0));
        for (int i = 0; i < samples_this_frame; ++i) {
            output.push_back(out_buffer[i]);
        }
    }

    return output;
}

} // namespace

TEST_SUITE_BEGIN("FIR Hybrid POC");

TEST_CASE("fir_hybrid impulse response matches fir_direct")
{
    verify_impulse_response(make_test_coefficients());
}

TEST_CASE("fir_hybrid impulse response scales across tap lengths")
{
    const std::vector<int> strict_tap_lengths = {32, 128, 1024};
    for (int taps : strict_tap_lengths) {
        CAPTURE(taps);
        const auto coeffs = make_lowpass_coefficients(taps, 8000.0f);
        const int direct_taps_override = taps >= 1024 ? 1024 : -1;
        verify_impulse_response(coeffs, direct_taps_override);
    }

}

TEST_CASE("fir_hybrid handles 4096 tap impulse responses (smoke)")
{
    run_high_tap_smoke_test(4096);
}

TEST_CASE("fir_hybrid handles 8192 tap impulse responses (smoke)")
{
    run_high_tap_smoke_test(8192);
}

TEST_CASE("fir_hybrid handles 16384 tap impulse responses (smoke)")
{
    run_high_tap_smoke_test(16384);
}

TEST_CASE("fir_hybrid handles 32768 tap impulse responses (smoke)")
{
    run_high_tap_smoke_test(32768);
}

TEST_CASE("fir_hybrid step response preserves DC gain")
{
    const auto coefficients = make_test_coefficients();
    const size_t total_samples = WarmupSamples + FrameSize * 8;
    const auto step = make_step_signal(total_samples, WarmupSamples);

    const auto outputs = run_fir_pair(step, coefficients);
    const size_t analysis_start = WarmupSamples + coefficients.size();

    const float max_error = compute_max_abs_difference(outputs.hybrid, outputs.direct, analysis_start);
    CHECK_LT(max_error, Tolerance);

    const size_t tail_start = outputs.hybrid.size() - FrameSize;
    float hybrid_mean = 0.0f;
    float direct_mean = 0.0f;
    for (size_t i = tail_start; i < outputs.hybrid.size(); ++i) {
        hybrid_mean += outputs.hybrid[i];
        direct_mean += outputs.direct[i];
    }
    hybrid_mean /= static_cast<float>(FrameSize);
    direct_mean /= static_cast<float>(FrameSize);

    CHECK_LT(std::abs(hybrid_mean - 1.0f), 1e-3f);
    CHECK_LT(std::abs(direct_mean - 1.0f), 1e-3f);
}

TEST_CASE("fir_hybrid matches white noise output")
{
    const auto coefficients = make_test_coefficients();
    const size_t total_samples = WarmupSamples + FrameSize * 32;
    const auto noise = make_white_noise_signal(total_samples);

    const auto outputs = run_fir_pair(noise, coefficients);
    const size_t analysis_start = WarmupSamples;

    const float rms_diff = compute_rms_difference(outputs.hybrid, outputs.direct, analysis_start);
    CHECK_LT(rms_diff, 5e-5f);

    const float hybrid_rms = compute_rms(outputs.hybrid, analysis_start);
    const float direct_rms = compute_rms(outputs.direct, analysis_start);
    CHECK_LT(std::abs(hybrid_rms - direct_rms), 1e-4f);
}

TEST_CASE("fir_hybrid tracks sine sweep response")
{
    const auto coefficients = make_test_coefficients();
    const size_t total_samples = WarmupSamples + FrameSize * 64;
    const auto sweep = make_sine_sweep_signal(total_samples, 20.0f, 20000.0f);

    const auto outputs = run_fir_pair(sweep, coefficients);
    const size_t analysis_start = WarmupSamples;

    const float max_error = compute_max_abs_difference(outputs.hybrid, outputs.direct, analysis_start);
    CHECK_LT(max_error, 2e-4f);

    const float rms_diff = compute_rms_difference(outputs.hybrid, outputs.direct, analysis_start);
    CHECK_LT(rms_diff, 5e-5f);
}

TEST_CASE("fir_hybrid partitions preserve energy distribution")
{
    verify_partition_energy_for_impulse(4096, 1024);
}

TEST_CASE("fir_hybrid high tap partitions preserve energy distribution")
{
    const std::vector<int> tap_lengths = {8192, 16384, 32768};
    for (int taps : tap_lengths) {
        CAPTURE(taps);
        verify_partition_energy_for_impulse(taps, 1024);
    }
}

TEST_SUITE_END();