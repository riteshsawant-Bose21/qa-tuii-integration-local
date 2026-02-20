//
// fir_hybrid.cpp
// Partitioned convolution for zero-latency FIR filtering
//
// Partition structure:
// - h₀: Direct-form (2N taps, zero latency)
// - h₁+: FFT partitions in doubling pairs (N, N, 2N, 2N, 4N, 4N, ...)
//

#include <bosepro/algorithm.h>
#include "fft.h"
#include "fir.h"

#include <algorithm>
#include <memory>
#include <vector>
#include <cstring>
#include <cmath>
#include <complex>
#include <utility>

namespace {

// Complex multiplication in PFFFT frequency domain format
inline void complex_multiply_pffft(float* result, const float* signal, const float* impulse, int fft_size)
{
    result[0] = signal[0] * impulse[0];  // DC component
    result[1] = signal[1] * impulse[1];  // Nyquist component
    
    // Complex bins: (a + bi)(c + di) = (ac - bd) + (ad + bc)i
    for (int i = 1; i < fft_size / 2; ++i) {
        int real_idx = 2 * i;
        int imag_idx = 2 * i + 1;
        
        float sig_real = signal[real_idx];
        float sig_imag = signal[imag_idx];
        float imp_real = impulse[real_idx];
        float imp_imag = impulse[imag_idx];
        
        result[real_idx] = sig_real * imp_real - sig_imag * imp_imag;
        result[imag_idx] = sig_real * imp_imag + sig_imag * imp_real;
    }
}

// DFT-odd optimization for partitioned convolution
// computes a 2N-point FFT from two N-point FFTs
inline std::complex<float> fetch_half_fft_bin(const float* spectrum,
                                             int half_size,
                                             int bin)
{
    const int nyquist = half_size / 2;

    if (bin == 0) {
        return {spectrum[0], 0.0f};
    }

    if (bin == nyquist) {
        return {spectrum[1], 0.0f};
    }

    if (bin < nyquist) {
        return {spectrum[2 * bin], spectrum[2 * bin + 1]};
    }

    int mirror = half_size - bin;
    if (mirror == 0) {
        return {spectrum[0], 0.0f};
    }
    if (mirror == nyquist) {
        return {spectrum[1], 0.0f};
    }
    return {spectrum[2 * mirror], -spectrum[2 * mirror + 1]};
}

inline void combine_half_size_spectra(float* full_spectrum, 
                                      const float* even_spec, 
                                      const float* odd_spec,
                                      int half_size,
                                      const float* twiddle_real,
                                      const float* twiddle_imag)
{
    std::fill(full_spectrum, full_spectrum + 2 * half_size, 0.0f);

    const int full_nyquist = half_size;
    for (int k = 0; k <= full_nyquist; ++k) {
        std::complex<float> even_bin = fetch_half_fft_bin(even_spec, half_size, k);
        std::complex<float> odd_bin = fetch_half_fft_bin(odd_spec, half_size, k);
        std::complex<float> twiddle(twiddle_real[k], twiddle_imag[k]);
        std::complex<float> combined = even_bin + twiddle * odd_bin;

        if (k == 0) {
            full_spectrum[0] = combined.real();
        } else if (k == full_nyquist) {
            full_spectrum[1] = combined.real();
        } else {
            const int idx = 2 * k;
            full_spectrum[idx] = combined.real();
            full_spectrum[idx + 1] = combined.imag();
        }
    }
}

struct Partition {
    int index;
    int start_position;
    int length;
    int fft_size;
    bool is_direct;
    
    // --- FFT state ---
    std::unique_ptr<fft::Fft> fft_processor;
    bosepro::DspStateMemory<float[]> fft_impulse_response;
    
    //  --- per-channel buffers ---
    bosepro::DspStateMemory<float*[]> input_buffers;
    bosepro::DspStateMemory<float*[]> output_buffers;
    bosepro::DspStateMemory<float*[]> delay_buffers;
    bosepro::DspStateMemory<int[]> delay_write_positions;
    
    // --- block accumulation ---
    bosepro::DspStateMemory<float*[]> input_accumulator;
    bosepro::DspStateMemory<int[]> samples_accumulated;
    bosepro::DspStateMemory<float*[]> block_output_buffer;
    bosepro::DspStateMemory<int[]> output_samples_remaining;
    bosepro::DspStateMemory<int[]> output_read_position;
    
    
    //  --- spectral reuse ---
    bool can_reuse_fft;
    int reuse_from_partition;
    int delay_buffer_size;
    int delay_compensation;
    bosepro::DspStateMemory<float*[]> fft_cache;
    
    // --- DFT-odd optimization
    bool use_half_size_combine;
    std::unique_ptr<fft::Fft> half_fft_processor;
    bosepro::DspStateMemory<float*[]> half_fft_buffer1;
    bosepro::DspStateMemory<float*[]> half_fft_buffer2;
    bosepro::DspTableMemory<float[]> twiddle_real;
    bosepro::DspTableMemory<float[]> twiddle_imag;
    int num_twiddles;
    
    // --- pre-allocated working buffers ---
    bosepro::DspStateMemory<float*[]> fft_signal_buffer;
    bosepro::DspStateMemory<float*[]> fft_product_buffer;
    bosepro::DspStateMemory<float*[]> time_result_buffer;

    // --- coefficient initialization workspace ---
    bosepro::DspTempMemory<float[]> coefficient_workspace;
    bosepro::DspTempMemory<float[]> half_even_time_workspace;
    bosepro::DspTempMemory<float[]> half_odd_time_workspace;
    bosepro::DspTempMemory<float[]> half_fft_workspace1;
    bosepro::DspTempMemory<float[]> half_fft_workspace2;
    
    // --- direct-form state ---
    std::vector<std::unique_ptr<filter::FirFilter>> direct_filters;
    
    Partition(int idx, int start, int len, int frame_sz, int n_channels, bool direct = false)
        : index(idx)
        , start_position(start)
        , length(len)
        , is_direct(direct)
        , can_reuse_fft(false)
        , reuse_from_partition(-1)
        , delay_buffer_size(0)
        , delay_compensation(0)
        , use_half_size_combine(false)
        , num_twiddles(0)
    {
        if (is_direct) {
            fft_size = 0;
            direct_filters.reserve(n_channels);
            output_buffers.resize(n_channels, frame_sz);
            
        } else {
            // Calculate FFT size
            int min_fft_size = 2 * length;
            fft_size = 32;
            while (fft_size < min_fft_size) {
                fft_size *= 2;
            }
            
            fft_processor = std::make_unique<fft::Fft>(fft_size);
            fft_impulse_response.resize(fft_size);
            
            // Allocate buffers
            input_buffers.resize(n_channels, fft_size);
            for (int ch = 0; ch < n_channels; ++ch) {
                std::fill(&input_buffers[ch][0], &input_buffers[ch][fft_size], 0.0f);
            }
            output_buffers.resize(n_channels, frame_sz);
            
            input_accumulator.resize(n_channels, length);
            samples_accumulated.resize(n_channels);
            std::fill(&samples_accumulated[0], &samples_accumulated[n_channels], 0);
            block_output_buffer.resize(n_channels, length);
            output_samples_remaining.resize(n_channels);
            output_read_position.resize(n_channels);
            std::fill(&output_samples_remaining[0], &output_samples_remaining[n_channels], 0);
            std::fill(&output_read_position[0], &output_read_position[n_channels], 0);
            
            
            // Spectral reuse
            if (idx > 0) {
                if (idx % 2 == 1) {
                    fft_cache.resize(n_channels, fft_size);
                    
                    // use half-size FFT combining (DFT-odd optimization)
                    if (idx >= 3) {
                        use_half_size_combine = true;
                        int half_size = fft_size / 2;
                            half_even_time_workspace.resize(half_size);
                            half_odd_time_workspace.resize(half_size);
                            half_fft_workspace1.resize(half_size);
                            half_fft_workspace2.resize(half_size);
                        half_fft_processor = std::make_unique<fft::Fft>(half_size);
                        half_fft_buffer1.resize(n_channels, half_size);
                        half_fft_buffer2.resize(n_channels, half_size);
                        
                        // Precompute twiddle factors
                        num_twiddles = half_size + 1;
                        twiddle_real.resize(num_twiddles);
                        twiddle_imag.resize(num_twiddles);
                        
                        constexpr float PI = 3.14159265f;
                        for (int k = 0; k <= half_size; ++k) {
                            float angle = -PI * static_cast<float>(k) / static_cast<float>(half_size);
                            twiddle_real[k] = std::cos(angle);
                            twiddle_imag[k] = std::sin(angle);
                        }
                    }
                } else {
                    can_reuse_fft = true;
                    reuse_from_partition = idx - 1;
                }
            }
            
            // Pre-allocate working buffers
            fft_signal_buffer.resize(n_channels, fft_size);
            fft_product_buffer.resize(n_channels, fft_size);
            time_result_buffer.resize(n_channels, fft_size);
            coefficient_workspace.resize(fft_size);
            
            const int block_latency = std::max(0, length - frame_sz);
            delay_compensation = std::max(0, start_position - block_latency);
            
            delay_buffer_size = delay_compensation + 2 * frame_sz;
            delay_buffers.resize(n_channels, delay_buffer_size);
            for (int ch = 0; ch < n_channels; ++ch) {
                std::fill(&delay_buffers[ch][0], &delay_buffers[ch][delay_buffer_size], 0.0f);
            }
            delay_write_positions.resize(n_channels);
            std::fill(&delay_write_positions[0], &delay_write_positions[n_channels], delay_compensation);
            
        }
    }
    
    ~Partition() = default;
};

class HybridFir : public bosepro::Algorithm
{
public:
    HybridFir(const bosepro::BlockConfiguration &configuration);
    virtual ~HybridFir() {
        partitions.clear();
    }

    virtual void process() override;

private:
    int_fast32_t channels;
    int_fast32_t num_taps;
    int_fast32_t base_partition_size;
    // --- terminals ---
    bosepro::DspSignalMemory<const float*[]> in;
    bosepro::DspSignalMemory<float*[]> out;

    // --- filter coefficients ---
    bosepro::DspParamMemory<float[]> parameter_coefficients;
    bosepro::DspCoeffMemory<float[]> coefficients;

    // --- partitions ---
    std::vector<std::unique_ptr<Partition>> partitions;

    // --- scheduling workspaces ---
    bosepro::DspTempMemory<int[]> ready_partitions_workspace;
    bosepro::DspTempMemory<int[]> process_partitions_workspace;
    bosepro::DspTempMemory<int[]> remaining_partitions_workspace;
    bosepro::DspTempMemory<std::pair<int, int>[]> partition_pair_workspace;
    bosepro::DspTempMemory<bool[]> selection_flags_workspace;

    // --- coefficient tracking ---
    bool coefficients_changed;
    
    bosepro::DspStateMemory<float[]> output_accumulators;

    // --- processing functions ---
    void create_partitions();
    void allocate_scheduling_workspaces();
    void initialize_partition_coefficients();
    void on_coefficients_updated(int row);
    void process_direct_partition(Partition& partition, int channel);
    void process_fft_partition_block(Partition& partition, int channel);

    ALGORITHM_DECLARE(HybridFir);
};

ALGORITHM_REGISTER(HybridFir, "fir_hybrid");

HybridFir::HybridFir(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
    , coefficients_changed(true)
{
    get_property("channels", channels);
    get_property("num_taps", num_taps);

    int_fast32_t direct_taps_property = 128;
    get_property("direct_taps", direct_taps_property);
    
    int frame_sz = get_frame_size();
    
    base_partition_size = direct_taps_property / 2;
    
    // Ensure partitions take at least 2 frames to fill to prevent monopolization
    if (base_partition_size < 2 * frame_sz) {
        base_partition_size = 2 * frame_sz;
    }
    
    assign_terminal("in", in);
    assign_terminal("out", out);

    if (num_taps <= 0) {
        num_taps = 1;
    }

    coefficients.resize(num_taps);
    assign_parameter("coefficients", parameter_coefficients,
                     POST_FUNCTION_VECTOR(on_coefficients_updated));

    output_accumulators.resize(channels * get_frame_size());

    create_partitions();
    allocate_scheduling_workspaces();
}

void HybridFir::create_partitions()
{
    int position = 0;
    int partition_idx = 0;
    
    
    // Direct-form partition
    int direct_length = std::min(static_cast<int>(2 * base_partition_size), 
                                static_cast<int>(num_taps));
    
    auto direct_partition = std::make_unique<Partition>(
        partition_idx++, position, direct_length, get_frame_size(), channels, true
    );
    
    for (int ch = 0; ch < channels; ++ch) {
        direct_partition->direct_filters.push_back(
            std::make_unique<filter::FirFilter>(direct_length, get_frame_size(), get_sample_rate())
        );
    }
    
    partitions.push_back(std::move(direct_partition));
    position += direct_length;
    
    // FFT partitions in doubling pairs
    int current_partition_size = base_partition_size;
    
    // cap maximum partition size to prevent big spikes
    const int MAX_PARTITION_SIZE = 65536;
    
    
    while (position < num_taps) {
        for (int pair = 0; pair < 2 && position < num_taps; ++pair) {
            int partition_length = std::min(static_cast<int>(current_partition_size), 
                                           static_cast<int>(num_taps - position));
            
            auto fft_partition = std::make_unique<Partition>(
                partition_idx, position, partition_length, get_frame_size(), channels, false
            );
            
            
            partitions.push_back(std::move(fft_partition));
            position += partition_length;
            partition_idx++;
        }
        
        int next_size = current_partition_size * 2;
        current_partition_size = std::min(next_size, MAX_PARTITION_SIZE);
    }
}

void HybridFir::allocate_scheduling_workspaces()
{
    const size_t partition_count = partitions.size();
    ready_partitions_workspace.resize(partition_count);
    process_partitions_workspace.resize(partition_count);
    remaining_partitions_workspace.resize(partition_count);
    partition_pair_workspace.resize(partition_count);
    selection_flags_workspace.resize(partition_count);
}

void HybridFir::initialize_partition_coefficients()
{
    for (auto& partition : partitions) {
        if (partition->is_direct) {
            for (int ch = 0; ch < channels; ++ch) {
                partition->direct_filters[ch]->with_coefficients(&coefficients[partition->start_position]);
            }
        } else {
            float *partition_coeffs = partition->coefficient_workspace.get();
            std::fill(partition_coeffs, partition_coeffs + partition->fft_size, 0.0f);
            std::memcpy(partition_coeffs, 
                       &coefficients[partition->start_position],
                       partition->length * sizeof(float));
            
            // DFT-odd optimization, compute coefficient FFT the same way
            if (partition->use_half_size_combine) {
                int half_size = partition->fft_size / 2;
                float *half_fft1 = partition->half_fft_workspace1.get();
                float *half_fft2 = partition->half_fft_workspace2.get();
                float *even_time = partition->half_even_time_workspace.get();
                float *odd_time = partition->half_odd_time_workspace.get();

                std::fill(even_time, even_time + half_size, 0.0f);
                std::fill(odd_time, odd_time + half_size, 0.0f);
                
                for (int n = 0; n < half_size; ++n) {
                    even_time[n] = partition_coeffs[2 * n];
                    odd_time[n] = partition_coeffs[2 * n + 1];
                }
                
                partition->half_fft_processor->forward(half_fft1, even_time);
                partition->half_fft_processor->forward(half_fft2, odd_time);
                
                combine_half_size_spectra(&partition->fft_impulse_response[0],
                                         half_fft1,
                                         half_fft2,
                                         half_size,
                                         &partition->twiddle_real[0],
                                         &partition->twiddle_imag[0]);
                
            } else {
                partition->fft_processor->forward(
                    &partition->fft_impulse_response[0],
                    partition_coeffs
                );
            }
        }
    }
}

void HybridFir::on_coefficients_updated(int row)
{
    if (row >= 0 && row < num_taps) {
        coefficients[row] = parameter_coefficients[row];
    }
    coefficients_changed = true;
}

void HybridFir::process_direct_partition(Partition& partition, int channel)
{
    partition.direct_filters[channel]->process(
        partition.output_buffers[channel], 
        in[channel]
    );
}

void HybridFir::process_fft_partition_block(Partition& partition, int channel)
{
    const int M = partition.length;
    const int overlap_size = M - 1;
    
    // Prepare input buffer (overlap-save)
    std::memmove(partition.input_buffers[channel],
                &partition.input_buffers[channel][M],
                overlap_size * sizeof(float));
    
    std::memcpy(&partition.input_buffers[channel][overlap_size],
               partition.input_accumulator[channel],
               M * sizeof(float));
    
    std::fill(&partition.input_buffers[channel][overlap_size + M],
             &partition.input_buffers[channel][partition.fft_size], 0.0f);

    // Forward FFT (with spectral reuse)
    float* fft_signal = partition.fft_signal_buffer[channel];
    
    if (partition.can_reuse_fft && partition.reuse_from_partition >= 0) {
        const auto& source_partition = partitions[partition.reuse_from_partition];
        std::memcpy(fft_signal, 
                   source_partition->fft_cache[channel],
                   partition.fft_size * sizeof(float));
    } else {
        partition.fft_processor->forward(fft_signal, partition.input_buffers[channel]);
        // Only odd partitions store to cache
        if (partition.index > 0 && partition.index % 2 == 1) {
            std::memcpy(partition.fft_cache[channel],
                       fft_signal,
                       partition.fft_size * sizeof(float));
        }
    }
    float* fft_result = partition.fft_product_buffer[channel];
    complex_multiply_pffft(fft_result, fft_signal,
                          &partition.fft_impulse_response[0], partition.fft_size);
    float* time_result = partition.time_result_buffer[channel];
    partition.fft_processor->inverse(time_result, fft_result);
    
    const float scale_factor = 1.0f / partition.fft_size;
    for (int i = 0; i < partition.fft_size; ++i) {
        time_result[i] *= scale_factor;
    }
    
    std::memcpy(partition.block_output_buffer[channel],
               &time_result[overlap_size],
               M * sizeof(float));
}

void HybridFir::process()
{
    if (coefficients_changed) {
        initialize_partition_coefficients();
        coefficients_changed = false;
    }

    const int frame_sz = get_frame_size();
    
    
    for (int_fast32_t channel = 0; channel < channels; ++channel) {
        float* channel_output = &output_accumulators[channel * frame_sz];
        std::fill(channel_output, channel_output + frame_sz, 0.0f);
        
        // --- Step 1: Always process direct-form partition ---
        for (auto& partition : partitions) {
            if (partition->is_direct) {
                process_direct_partition(*partition, channel);
                
                for (int i = 0; i < frame_sz; ++i) {
                    channel_output[i] += partition->output_buffers[channel][i];
                }
                
                break;
            }
        }
        
        // --- Step 2: Accumulate samples for all FFT partitions ---
        for (auto& partition : partitions) {
            if (partition->is_direct) continue;
            
            int space_remaining = partition->length - partition->samples_accumulated[channel];
            int samples_to_accumulate = std::min(frame_sz, space_remaining);
            
            if (samples_to_accumulate > 0) {
                std::memcpy(&partition->input_accumulator[channel][partition->samples_accumulated[channel]],
                           in[channel],
                           samples_to_accumulate * sizeof(float));
                partition->samples_accumulated[channel] += samples_to_accumulate;
                
            }
        }
        
        // --- Step 3: Priority Scheduling for Spectral Reuse Correctness ---
        // Process UP TO 3 FFT partitions per frame
        // Priority: Complete pairs first (guarantee spectral reuse), then smallest singles
        const int MAX_PARTITIONS_PER_FRAME = 3;
        if (!partitions.empty()) {
            int *ready_indices = ready_partitions_workspace.get();
            int *process_indices = process_partitions_workspace.get();
            int *remaining_indices = remaining_partitions_workspace.get();
            auto *pair_indices = partition_pair_workspace.get();
            bool *selected = selection_flags_workspace.get();

            int ready_count = 0;
            for (auto &partition : partitions) {
                if (partition->is_direct) {
                    continue;
                }
                if (partition->samples_accumulated[channel] >= partition->length) {
                    ready_indices[ready_count++] = partition->index;
                }
            }

            std::fill(selected, selected + partitions.size(), false);

            int pair_count = 0;
            for (int i = 0; i < ready_count; ++i) {
                int idx = ready_indices[i];
                Partition *partition = partitions[idx].get();
                if (selected[partition->index]) {
                    continue;
                }

                if (partition->index > 0 && partition->index % 2 == 1) {
                    int even_partner_idx = partition->index + 1;
                    if (even_partner_idx < static_cast<int>(partitions.size())) {
                        Partition *even_partner = nullptr;
                        for (int j = 0; j < ready_count; ++j) {
                            Partition *candidate = partitions[ready_indices[j]].get();
                            if (candidate->index == even_partner_idx) {
                                even_partner = candidate;
                                break;
                            }
                        }

                        if (even_partner != nullptr) {
                            pair_indices[pair_count++] = {partition->index, even_partner->index};
                            selected[partition->index] = true;
                            selected[even_partner->index] = true;
                        }
                    }
                }
            }

            std::sort(pair_indices, pair_indices + pair_count,
                      [this](const std::pair<int, int> &a, const std::pair<int, int> &b) {
                          return partitions[a.first]->length < partitions[b.first]->length;
                      });

            int process_count = 0;
            for (int i = 0; i < pair_count && process_count + 2 <= MAX_PARTITIONS_PER_FRAME; ++i) {
                process_indices[process_count++] = pair_indices[i].first;
                process_indices[process_count++] = pair_indices[i].second;
            }

            int remaining_count = 0;
            for (int i = 0; i < ready_count; ++i) {
                int idx = ready_indices[i];
                if (!selected[partitions[idx]->index]) {
                    remaining_indices[remaining_count++] = idx;
                }
            }

            std::sort(remaining_indices, remaining_indices + remaining_count,
                      [this](int a, int b) {
                          return partitions[a]->length < partitions[b]->length;
                      });

            for (int i = 0; i < remaining_count && process_count < MAX_PARTITIONS_PER_FRAME; ++i) {
                int idx = remaining_indices[i];
                process_indices[process_count++] = idx;
                selected[partitions[idx]->index] = true;
            }

            for (int i = 0; i < process_count; ++i) {
                Partition &partition = *partitions[process_indices[i]];
                process_fft_partition_block(partition, channel);
                partition.samples_accumulated[channel] = 0;
                partition.output_samples_remaining[channel] = partition.length;
                partition.output_read_position[channel] = 0;
            }
        }
        
        // --- Step 4: Output mixing from all partitions with available data ---
        for (auto& partition : partitions) {
            if (partition->is_direct) continue;
                
            if (partition->output_samples_remaining[channel] > 0) {
                int samples_to_read = std::min(frame_sz, partition->output_samples_remaining[channel]);
                
                int delay_size = partition->delay_buffer_size;
                int write_pos = partition->delay_write_positions[channel];
                
                
                // Write to delay buffer
                for (int i = 0; i < samples_to_read; ++i) {
                    float val = partition->block_output_buffer[channel][partition->output_read_position[channel] + i];
                    partition->delay_buffers[channel][(write_pos + i) % delay_size] = val;
                }
                
                int read_pos = write_pos - partition->delay_compensation;
                if (read_pos < 0) read_pos += delay_size;
                
                
                for (int i = 0; i < samples_to_read; ++i) {
                    channel_output[i] += partition->delay_buffers[channel][(read_pos + i) % delay_size];
                }
                
                
                partition->delay_write_positions[channel] = (write_pos + samples_to_read) % delay_size;
                partition->output_read_position[channel] += samples_to_read;
                partition->output_samples_remaining[channel] -= samples_to_read;
            }
        }
        
        std::memcpy(out[channel], channel_output, frame_sz * sizeof(float));
    }
}

} // namespace