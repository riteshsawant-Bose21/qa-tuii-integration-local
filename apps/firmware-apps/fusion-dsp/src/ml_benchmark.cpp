// ml_benchmark
//
// Given an onnx model (without dynamic shapes), run a test inference, 
// track the amount of time spent, and estimate MIPS required 
// for the operation.
// ONNXRuntime is limited to run on one thread here.
//
// Uses the same MIPS estimation process adopted from
// profile.h, except it runs only within 
// this algorithm block, and uses CLOCK_PROCESS_CPUTIME_ID
// for time tracking.
//
// When testing:
// - change CPU_MIPS accordingly
// - use max_input_time in config to set the length of input to process
//	(will stop doing any inference to get MIPS estimation result 
//	after max_input_time of input is processed)
// - change model_path in config to test different operations

#include <bosepro/algorithm.h>
#include <onnxruntime_cxx_api.h>

#include <numeric>
#include <vector>

namespace {


class ML_Benchmark : public bosepro::Algorithm
{
public:
	ML_Benchmark(const bosepro::BlockConfiguration &configuration);
	virtual ~ML_Benchmark() = default;

	virtual void process() override;

private:
	// --- constants and terminals ---
	int_fast32_t channels;
	int_fast32_t frame_size;

	std::vector<const float *> in;
	std::vector<float *> out;
	
	// --- user controls ---
	// onnx model path
	std::string model_path;
	// for benchmarking: stop processing at how many secs of input
	int_fast32_t max_input_time; 

	// --- processing variables ---
	// current frame number
	int num_frames;
	// how many frames to process
	int max_frames;
	// time tracking
	timespec start_time;
	timespec finish_time;
	timespec max_time;
	timespec total_time;
	const float CPU_MIPS = 1800.0;
	const long NSEC_MAX = 1000000000L;
	double inv_period;

	// ORT related
	// ORT Environment
	std::shared_ptr<Ort::Env> ort_env;
	// Session
	std::shared_ptr<Ort::Session> ort_session;
	// Inputs
	size_t input_count;
	std::vector<Ort::AllocatedStringPtr> input_name_allocated_strs;
	std::vector<const char*> input_names;
	std::vector<std::vector<int_fast32_t>> input_dims;
	std::vector<size_t> input_tensor_sizes;
	std::vector<std::vector<float>> input_tensor_values;
	// Outputs
	size_t output_count;   
	std::vector<Ort::AllocatedStringPtr> output_name_allocated_strs;
	std::vector<const char*> output_names;
	std::vector<std::vector<int_fast32_t>> output_dims;
	std::vector<size_t> output_tensor_sizes;
	std::vector<std::vector<float>> output_tensor_values;
	
	// --- processing functions ---
	template <typename T> T vector_product(const std::vector<T>& v);
	double timespec_to_seconds(const timespec &ts);
	void set_period(double period);
	double get_max_mips();
	double get_average_mips();

	// --- user control parameters processing functions ---
	void update_model();
	void update_max_input_time();

	ALGORITHM_DECLARE(ML_Benchmark);
};

ALGORITHM_REGISTER(ML_Benchmark, "ml_benchmark");


ML_Benchmark::ML_Benchmark(const bosepro::BlockConfiguration &configuration)
	: bosepro::Algorithm(configuration)
{
	get_constant("channels", channels);
	get_constant("frame_size", frame_size);

	assign_terminal("in", &in);
	assign_terminal("out", &out);
	assign_control("model_path", &model_path, POST_FUNCTION_SCALAR(update_model));
	assign_control("max_input_time", &max_input_time, POST_FUNCTION_SCALAR(update_max_input_time));

	set_period((double)get_frame_size() / get_sample_rate());
}

// get the number of frames that corresponds to the test length (in sec) given.
// E.g. If test length is 10s, we will only run the inference for 10s of input 
// signal for MIPS estimation. This returns the number
// of frames that matches 10s of audio in the current run.
void ML_Benchmark::update_max_input_time()
{
	max_frames = std::floor( (double)get_sample_rate() / get_frame_size() * max_input_time ); 
}

// set up ORT
void ML_Benchmark::update_model()
{
	// Reset timers
	num_frames = 0;
	max_time = {0, 0};
	total_time = {0, 0};
	
	//******* Create ORT environment *******/
	std::string instance_name{model_path.c_str()};
	ort_env = std::make_shared<Ort::Env>(OrtLoggingLevel::ORT_LOGGING_LEVEL_WARNING,
		instance_name.c_str());
	//******* Create ORT session *******/
	Ort::SessionOptions session_options;
	// Set thread limit
	session_options.SetIntraOpNumThreads(1);
	// Sets graph optimization level (Here, enable all possible optimizations)
	session_options.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
	// Create session by loading the onnx model
	ort_session = std::make_shared<Ort::Session>(*ort_env, model_path.c_str(), session_options);

	//******* Create allocator *******/
	// Allocator is used to get model information
	Ort::AllocatorWithDefaultOptions allocator;
	input_count = ort_session->GetInputCount();
	output_count = ort_session->GetOutputCount();
	// Clean up and refill
	input_name_allocated_strs.clear();
	input_names.clear();
	input_dims.clear();
	input_tensor_sizes.clear();
	output_name_allocated_strs.clear();
	output_names.clear();
	output_dims.clear();
	output_tensor_sizes.clear();
	input_tensor_values.clear();
	output_tensor_values.clear();
	for (size_t i=0; i<input_count; i++)
	{
		//******* Inputs *******/
		// Name of input
		Ort::AllocatedStringPtr input_name = ort_session->GetInputNameAllocated(i, allocator);
		input_name_allocated_strs.push_back(std::move(input_name));
		input_names.push_back(input_name_allocated_strs.back().get());
		// Input type
		Ort::TypeInfo input_type_info = ort_session->GetInputTypeInfo(i);
		auto input_tensor_info = input_type_info.GetTensorTypeAndShapeInfo();
		// Input shape
		input_dims.push_back(input_tensor_info.GetShape());
		// Assume shape is [1 x frame_num x feat_dim] then output_dims[i][1] * output_dims[i][2];
		input_tensor_sizes.push_back(vector_product(input_dims[i]));
		// Create input tensor buffer filled with ones
		input_tensor_values.push_back(std::vector<float>(input_tensor_sizes[i], 1.0f));
	}
	for (size_t i=0; i<output_count; i++)
	{
		//******* Outputs *******/
		// Name of output
		Ort::AllocatedStringPtr output_name = ort_session->GetOutputNameAllocated(i, allocator);
		output_name_allocated_strs.push_back(std::move(output_name));
		output_names.push_back(output_name_allocated_strs.back().get());
		// Output type
		Ort::TypeInfo output_type_info = ort_session->GetOutputTypeInfo(i);
		auto output_tensor_info = output_type_info.GetTensorTypeAndShapeInfo();
		// Output shape
		output_dims.push_back(output_tensor_info.GetShape());
		// Assume shape is [1 x frame_num x feat_dim] then output_dims[i][1] * output_dims[i][2];
		output_tensor_sizes.push_back(vector_product(output_dims[i])); 
		// Create output tensor buffer
		output_tensor_values.push_back(std::vector<float>(output_tensor_sizes[i]));
	}
}

double ML_Benchmark::timespec_to_seconds(const timespec &ts)
{
	return ts.tv_nsec / (double)NSEC_MAX + ts.tv_sec;
}

// Set the period of the process being timed.  This allows the timing
// results to be reported in terms of MIPS.
void ML_Benchmark::set_period(double period)
{
	inv_period = 1.0 / period;
}

// Return the number of MIPS consumed by the longest timing run (excluding
// the first).
double ML_Benchmark::get_max_mips()
{
	return timespec_to_seconds(max_time) * CPU_MIPS * inv_period;
}

// Return the number of MIPS consumed by the average of all timing runs
// (excluding the first).
double ML_Benchmark::get_average_mips()
{
	return timespec_to_seconds(total_time) / max_frames * CPU_MIPS * inv_period;
}

// Return the product of the input vector
template <typename T> T ML_Benchmark::vector_product(const std::vector<T>& v)
{
    return accumulate(v.begin(), v.end(), 1, std::multiplies<T>());
}


void ML_Benchmark::process()
{
	// keep running till we reach long enough input data
	if (num_frames < max_frames)
	{ 
		// Record time spent each inference
		clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &start_time);

		// Set inputs and outputs
		Ort::MemoryInfo memory_info = Ort::MemoryInfo::CreateCpu(OrtAllocatorType::OrtArenaAllocator, 
			OrtMemType::OrtMemTypeDefault);
		std::vector<Ort::Value> input_tensors;
		std::vector<Ort::Value> output_tensors;
		for (size_t i=0; i<input_count; i++)
		{
			// Create input tensors of ORT::Value, which is a tensor format used by ONNX Runtime
			input_tensors.push_back(Ort::Value::CreateTensor<float>(memory_info,input_tensor_values[i].data(),
				input_tensor_sizes[i],input_dims[i].data(),input_dims[i].size()));
		}
		for (size_t i=0; i<output_count; i++)
		{
			// Create output tensors of ORT::Value
			output_tensors.push_back(Ort::Value::CreateTensor<float>(memory_info, output_tensor_values[i].data(), 
				output_tensor_sizes[i],output_dims[i].data(), output_dims[i].size()));
		}

		// Run inference
		ort_session->Run(Ort::RunOptions{nullptr}, input_names.data(), input_tensors.data(), input_count, 
			output_names.data(), output_tensors.data(), output_count);

		// // Get the inference result output1 - uncomment if to use the results
		// // for debugging and model verification
		// float* outputs = output_tensors.front().GetTensorMutableData<float>();
		// SPDLOG_DEBUG("outputs {}", outputs[0]);

		// Calculate the time since `start()` was called.
		clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &finish_time);
		timespec diff_time;
		diff_time.tv_sec = finish_time.tv_sec - start_time.tv_sec;
		diff_time.tv_nsec = finish_time.tv_nsec - start_time.tv_nsec;
		if (diff_time.tv_nsec < 0)
		{
			diff_time.tv_sec--;
			diff_time.tv_nsec += NSEC_MAX;
		}
		// Track the maximum execution time 
		if (diff_time.tv_sec > max_time.tv_sec
			|| (diff_time.tv_sec == max_time.tv_sec
				&& diff_time.tv_nsec > max_time.tv_nsec))
		{
			max_time.tv_sec = diff_time.tv_sec;
			max_time.tv_nsec = diff_time.tv_nsec;
		}
		// Accumulate the total time, for reporting the average execution time.
		total_time.tv_sec += diff_time.tv_sec;
		total_time.tv_nsec += diff_time.tv_nsec;

		num_frames += 1;
	}

	// get profiling result
	if (num_frames == max_frames)
	{
		// get max and avg MIPs
		double max_mips = get_max_mips();
		double avg_mips =  get_average_mips();
		SPDLOG_DEBUG("total_time= {}s {}ns for processing {}s of input ",
			total_time.tv_sec, total_time.tv_nsec, max_input_time);
		SPDLOG_DEBUG("{} MIPs: {} max, {} avg.", model_path.c_str(), max_mips, avg_mips);
		// increment to stop processing
		num_frames += 1;
	}
}


}
