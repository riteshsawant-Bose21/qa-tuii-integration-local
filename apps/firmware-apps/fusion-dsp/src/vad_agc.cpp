
#include <bosepro/algorithm.h>
#include <bosepro/audio_task.h>

#include <cmath>
#include <cstdint>
#include <iostream> 
#include <chrono>
#include "rnnoise.h"
#include "fft.h"
#include "denoise.h"

// Temporary implementation for RNNoise demo

namespace {


    class VadAgc : public bosepro::Algorithm
    {
        public:
            VadAgc(const bosepro::BlockConfiguration &configuration);
            virtual ~VadAgc() {
                // Signal shutdown to AudioSubtask thread
                shutdown_requested = true;
                
                // Give thread time to see shutdown flag and exit safely
                std::this_thread::sleep_for(std::chrono::milliseconds(20));
                
                if (st) {
                    rnnoise_destroy(st);
                    st = nullptr; // Prevent double-free
                }
                
                #ifdef USE_WEIGHTS_FILE
                if (model) {
                    rnnoise_model_free(model);
                    model = nullptr;
                }
                #endif
            }

            virtual void process() override;

            static void run_rnnoise_task(void *obj)
            {
                VadAgc *vad_agc = static_cast<VadAgc *>(obj);
                vad_agc->rnnoise_process();
            }

        private:
            int_fast32_t channels;

            bosepro::DspSignalMemory<const float *[]> in;
            bosepro::DspSignalMemory<float *[]> out;

            bosepro::DspCoeffMemory<float[]> in_meter;
            bosepro::DspCoeffMemory<float[]> activity_threshold;
            bosepro::DspCoeffMemory<float[]> target_minimum;
            bosepro::DspCoeffMemory<float[]> target_maximum;
            bosepro::DspParamMemory<float[]> cut_rate;
            bosepro::DspParamMemory<float[]> boost_rate;
            bosepro::DspCoeffMemory<float[]> cut_range;
            bosepro::DspCoeffMemory<float[]> boost_range;
            bosepro::DspParamMemory<float[]> cut_hold_time;
            bosepro::DspParamMemory<float[]> boost_hold_time;
            bosepro::DspCoeffMemory<bool[]> channel_bypass;
            float max_total_boost;

            bosepro::DspTelemetryMemory<float[]> current_gain;
            bosepro::DspTelemetryMemory<bool[]> hold_meter;
            float current_total_boost;

            bosepro::DspStateMemory<float[]> smoothed_level;
            bosepro::DspStateMemory<float[]> fast_level;
            bosepro::DspStateMemory<float[]> cut_step;
            bosepro::DspStateMemory<float[]> boost_step;
            bosepro::DspStateMemory<float[]> target_gain;
            bosepro::DspStateMemory<int_fast32_t[]> cut_hold_count;
            bosepro::DspStateMemory<int_fast32_t[]> boost_hold_count;
            bosepro::DspStateMemory<int_fast32_t[]> hold_counter;

            bosepro::DspStateMemory<int_fast32_t[]> vad_hangover_counter;   

            float level_attack_coeff;
            float level_release_coeff;
            float fast_release_coeff;

            void update_cut_rate(int row);
            void update_boost_rate(int row);
            void update_cut_hold(int row);
            void update_boost_hold(int row);

            bool vad_activity;                 
            int vad_hangover_frames;         
            

            bool denoise_frame;
            //bool use_weights_file;
            float vad_threshold;
            int frame_size_rnnoise;
            float alpha;
            int subframe_size;
            float smoothed_vad;
            std::unique_ptr<float[]> in_buffer[2];  // Ping-pong buffers
            std::unique_ptr<float[]> out_buffer[2];  
            int out_buff_ping_pong;           // Which buffer to read from in main process
            int in_buff_ping_pong;              // Which buffer to write to in main process
            int in_buff_ptr;
            // bool initialized;
            // int count;
            DenoiseState *st;
            #ifdef USE_WEIGHTS_FILE
                RNNModel *model;
            #endif
            
            int out_buffer_index;

            std::unique_ptr<fft::Fft> curr_fft;

            // RNNoise processing functions
            void rnnoise_process();
            
            // AudioSubtask for RNNoise processing
            bosepro::AudioSubtask rnnoise_task;
            
            // Shutdown flag for thread safety
            volatile bool shutdown_requested;

            ALGORITHM_DECLARE(VadAgc);
    };

    ALGORITHM_REGISTER(VadAgc, "vadagc");


    VadAgc::VadAgc(const bosepro::BlockConfiguration &configuration)
        : bosepro::Algorithm(configuration),
          rnnoise_task(&VadAgc::run_rnnoise_task, this,
                       get_sample_rate(), 480, get_frame_size())
    {
        get_property("channels", channels);

        assign_terminal("in", in);
        assign_terminal("out", out);

        assign_parameter("activity_threshold", activity_threshold);
        assign_parameter("target_minimum", target_minimum);
        assign_parameter("target_maximum", target_maximum);
        assign_parameter("cut_rate", cut_rate,
                        POST_FUNCTION_VECTOR(update_cut_rate));
        assign_parameter("boost_rate", boost_rate,
                        POST_FUNCTION_VECTOR(update_boost_rate));
        assign_parameter("cut_range", cut_range);
        assign_parameter("boost_range", boost_range);
        assign_parameter("cut_hold", cut_hold_time,
                        POST_FUNCTION_VECTOR(update_cut_hold));
        assign_parameter("boost_hold", boost_hold_time,
                        POST_FUNCTION_VECTOR(update_boost_hold));
        assign_parameter("channel_bypass", channel_bypass);
        assign_parameter("max_total_boost", &max_total_boost);

        assign_parameter("denoise_frame", &denoise_frame);
        assign_parameter("vad_threshold", &vad_threshold);
        assign_parameter("alpha", &alpha);

        assign_telemetry("in_meter", in_meter, bosepro::linear_to_db);
        assign_telemetry("gain_meter", current_gain);
        assign_telemetry("hold_meter", hold_meter);

        smoothed_level.resize(channels);
        fast_level.resize(channels);
        cut_step.resize(channels);
        boost_step.resize(channels);
        target_gain.resize(channels);
        cut_hold_count.resize(channels);
        boost_hold_count.resize(channels);
        hold_counter.resize(channels);
        
        vad_hangover_counter.resize(channels);

        level_attack_coeff = 1.0f - exp(-1.0f / (get_sample_rate() * 0.0005f));
        level_release_coeff = 1.0f - exp(-1.0f / (get_sample_rate() * 0.1f));
        fast_release_coeff = 1.0f - exp(-1.0f / (get_sample_rate() * 0.005f));
        
        vad_hangover_frames = 500;
        vad_activity = false;
        subframe_size = get_frame_size();
        smoothed_vad = 0.0f;
        frame_size_rnnoise = 480;
        // initialized = false;
        // if (!initialized) {
        //     buffer.reserve(frame_size_rnnoise);  
        //     initialized = true;
        // }
        // count = 0;

        out_buffer[0] = std::make_unique<float[]>(frame_size_rnnoise);
        out_buffer[1] = std::make_unique<float[]>(frame_size_rnnoise);
        memset(out_buffer[0].get(), 0, frame_size_rnnoise * sizeof(float));
        memset(out_buffer[1].get(), 0, frame_size_rnnoise * sizeof(float));
        out_buff_ping_pong = 0;
        
        // Initialize input buffers with proper size
        size_t in_buffer_size = frame_size_rnnoise + get_frame_size();
        in_buffer[0] = std::make_unique<float[]>(in_buffer_size);
        in_buffer[1] = std::make_unique<float[]>(in_buffer_size);
        memset(in_buffer[0].get(), 0, in_buffer_size * sizeof(float));
        memset(in_buffer[1].get(), 0, in_buffer_size * sizeof(float));
        in_buff_ping_pong = 0;
        in_buff_ptr = 0;

        curr_fft = std::make_unique<fft::Fft>(WINDOW_SIZE);
        //use_weights_file = true;
        
        #ifdef USE_WEIGHTS_FILE
            model = rnnoise_model_from_filename("src/weights_blob.bin");
            if (!model)
                SPDLOG_ERROR("Error: could not load weights_blob.bin");
                
            st = rnnoise_create(model);
            SPDLOG_INFO("RNNoise model loaded from weights_blob.bin");
        #else
            st = rnnoise_create(NULL);
            SPDLOG_INFO("RNNoise model loaded with default weights");
        #endif
        
        // right now only works when frame_size = FRAME_SIZE = 480,
        // print error if frame_size is different
        if (frame_size_rnnoise != 480)
            SPDLOG_ERROR("Frame size for the RNNoise model can only be 480");

        // For AudioSubtask requirement: task frame size must be multiple of base frame size
        if (frame_size_rnnoise > get_frame_size() && frame_size_rnnoise % get_frame_size() != 0) {
            SPDLOG_ERROR("Frame size for VadAgc must be a multiple of base frame size for RNNoise processing.");
        }

        out_buffer_index = 0;
        
        // Set priority for RNNoise task
        rnnoise_task.set_priority(4);
        shutdown_requested = false;
    }

    void VadAgc::rnnoise_process()
    {
        if (shutdown_requested) {
            return;
        }
        
        // Process the other buffer (not currently being filled)
        float *pbuff = (in_buff_ping_pong == 0) ?
            in_buffer[1].get() : in_buffer[0].get();

        float frame[frame_size_rnnoise];
        float frame_out[frame_size_rnnoise];
        
        // Copy data from the processing buffer
        memcpy(frame, pbuff, sizeof(float) * frame_size_rnnoise);
        
        // SPDLOG_DEBUG("RNNoise processing: using buffer {}, current fill buffer: {}", 
        //             (in_buff_ping_pong == 0) ? 1 : 0, in_buff_ping_pong);
        
        auto start_time = std::chrono::high_resolution_clock::now();
        float vad_prob = rnnoise_process_frame(st, frame_out, frame, curr_fft.get());

        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration_us = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time).count();
        if (duration_us > 10000) { // More than 10ms - this shouldn't happen!
            SPDLOG_ERROR("RNNoise took {}us (exceeds 10ms real-time limit!)", duration_us);
        }
        
        smoothed_vad = alpha * vad_prob + (1.0f - alpha) * smoothed_vad;

        if (denoise_frame) {
            // Write to the buffer that main thread is NOT reading from
            int write_buffer = 1 - out_buff_ping_pong;  // Main thread reads from out_buff_ping_pong
            memcpy(out_buffer[write_buffer].get(), frame_out, 480 * sizeof(float));
        }
        vad_activity = (smoothed_vad >= vad_threshold);
    }

    void VadAgc::process()
    {
        
        float total_boost = 0.0f;

        // Store data (first channel) to input buffer
        float *pbuff = in_buffer[in_buff_ping_pong].get();
        memcpy(&pbuff[in_buff_ptr], in[0], sizeof(float)*get_frame_size());
        in_buff_ptr += get_frame_size();
        
        // When input buffer is filled, mark ready and trigger processing
        if (in_buff_ptr >= frame_size_rnnoise) {
            // Check if need to store remaining samples
            int buff_remain_len = in_buff_ptr - frame_size_rnnoise;
            if (buff_remain_len > 0) {
                memcpy(&pbuff[0], &pbuff[frame_size_rnnoise], sizeof(float)*buff_remain_len);
            }
            // Reset input buffer pointer
            in_buff_ptr = buff_remain_len;
            
            // Switch to other buffer
            in_buff_ping_pong = (in_buff_ping_pong == 0) ? 1 : 0;
        }
        
        rnnoise_task.tick();

        for (int_fast32_t channel = 0; channel < channels; channel++)
        {

            if (!denoise_frame) {
                // Copy input to current buffer (no thread conflict in non-denoise mode)
                for (int_fast32_t sample = 0; sample < get_frame_size(); sample++) {
                    out_buffer[out_buff_ping_pong].get()[out_buffer_index + sample] = in[channel][sample];
                }
            }

            in_meter[channel] = 0.0;
            for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
            {
                float sample_val = out_buffer[out_buff_ping_pong].get()[out_buffer_index + sample];
                float energy = sample_val * sample_val;
                smoothed_level[channel] += (energy - smoothed_level[channel]) *
                    ((energy > smoothed_level[channel])
                    ? level_attack_coeff : level_release_coeff);
                fast_level[channel] += (energy - fast_level[channel]) *
                    ((energy > fast_level[channel])
                    ? level_attack_coeff : fast_release_coeff);
                in_meter[channel] = std::max(in_meter[channel], std::fabs(sample_val));
            }

            float log_level = 10.0f * log10(smoothed_level[channel]) + 20.0f;
            float log_fast_level = 10.0f * log10(fast_level[channel]) + 20.0f;

            if (vad_activity) {
                
                vad_hangover_counter[channel] = vad_hangover_frames;
            } else if (vad_hangover_counter[channel] > 0) {
                
                vad_hangover_counter[channel] -= 1;
            }

            if ((log_fast_level > activity_threshold[channel]) || (hold_counter[channel] <= 0))
            {
                if (log_level > target_maximum[channel])
                {
                    target_gain[channel] =
                        std::max(target_maximum[channel] - log_level,
                                -cut_range[channel]);
                    hold_counter[channel] = cut_hold_count[channel];
                }
                else if (vad_activity && (log_level < target_minimum[channel]))
                {
                    target_gain[channel] =
                        std::min(target_minimum[channel] - log_level,
                                boost_range[channel]);
                    hold_counter[channel] = boost_hold_count[channel];
                }
                else if (vad_hangover_counter[channel] > 0) 
                {

                }
                else if (!vad_activity && (log_level < target_minimum[channel])) 
                {    
                    target_gain[channel] *= 0.995f;
                }
                else
                {
                    target_gain[channel] = 0.0f;
                    hold_counter[channel] = 0;
                }

                hold_meter[channel] = false;
            }
            else
            {
                hold_counter[channel]--;
                hold_meter[channel] = true;
            }

            if ((target_gain[channel] > 0.0f) && !channel_bypass[channel])
            {
                total_boost += target_gain[channel];
            }
        }

        float boost_limit_adjustment = 1.0f;

        if (total_boost > max_total_boost)
        {
            boost_limit_adjustment = max_total_boost / total_boost;
        }

        current_total_boost = std::min(total_boost, max_total_boost);

        for (int_fast32_t channel = 0; channel < channels; channel++)
        {
            float target = target_gain[channel];

            if (target > 0.0f)
            {
                target *= boost_limit_adjustment;
            }

            if (channel_bypass[channel])
            {
                target = 0.0f;
            }

            float g = current_gain[channel];
            float g_step = (target > 0.0f) ? boost_step[channel] : cut_step[channel];

            if (target < g)
            {
                g_step *= -1.0f;
            }

            if (std::abs(target - g) < (g_step * get_frame_size()))
            {
                g = target;
                g_step = 0.0f;
            }

            g = powf(10.0f, g / 20.0f);
            g_step = powf(10.0f, g_step / 20.0f);

            for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
            {
                out[channel][sample] = out_buffer[out_buff_ping_pong].get()[out_buffer_index + sample] * g;
                g *= g_step;
            }

            current_gain[channel] = 20.0f * log10f(g);
            
        }
        
        out_buffer_index += get_frame_size();
        if (out_buffer_index >= frame_size_rnnoise) {
            out_buffer_index = 0;
            // Switch ping-pong buffers when we've consumed the full buffer
            if (denoise_frame) {
                out_buff_ping_pong = 1 - out_buff_ping_pong;
            }
        }
    }


    void VadAgc::update_cut_rate(int row)
    {
        cut_step[row] = cut_rate[row] * get_frame_size() / get_sample_rate();
    }


    void VadAgc::update_boost_rate(int row)
    {
        boost_step[row] = boost_rate[row] * get_frame_size() / get_sample_rate();
    }


    void VadAgc::update_cut_hold(int row)
    {
        cut_hold_count[row] = cut_hold_time[row] * get_sample_rate() /
            get_frame_size();
    }


    void VadAgc::update_boost_hold(int row)
    {
        boost_hold_count[row] = boost_hold_time[row] * get_sample_rate() /
            get_frame_size();
    }

} // namespace

