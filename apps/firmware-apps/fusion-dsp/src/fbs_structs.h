// parameters, constants, and structs for the feedback 
// suppression algorithm


// Number of spectral bands for the algorithm
const int NUM_MULTI_BANDS = 4;

// Classification of different spectral bands
enum MultibandFrequencyClassification { LOW = 0, MID, HIGH, SUPER_HIGH };

// Represents harmonic parameters for one spectral band. There are NUM_MULTI_BANDS 
// different spectral bands.
// In implementation, each band stored based on "MultibandFrequencyClassification" 
// enum lookup - 0 is low, 1 is mid...
struct HarmonicAnalysisParameters 
{
    //Harmonics
    int SECOND_HARMONIC_COMPARISON_LEVEL;
	int THIRD_HARMONIC_COMPARISON_LEVEL;
	int FOURTH_HARMONIC_COMPARISON_LEVEL;
    int FIFTH_HARMONIC_COMPARISON_LEVEL;

    //Sub-harmonics
	int HALF_HARMONIC_COMPARISON_LEVEL;
	int THREE_HALVES_HARMONIC_COMPARISON_LEVEL;
	int TWO_THIRDS_HARMONIC_COMPARISON_LEVEL;
};

// sensitivity
enum {
    FBS_SENSITIVITY_MUSIC = 0,
    FBS_SENSITIVITY_SPEECH,
    FBS_SENSITIVITY_NUM
};

// preset harmonics analysis constants given 
// sensitivity and the spectral band
// - sensitivity: 0-music, 1-speech
// - spectral bands: 0-low, 1-mid, 2-high, 3-superhigh
const HarmonicAnalysisParameters harmonics_params[FBS_SENSITIVITY_NUM][NUM_MULTI_BANDS] =
{
    // Music
    {
        //LOW
        {50, 50, 42, 42, //second, third, fourth, fifth
            0, 0, 0 }, //half, 3/2, 2/3

        //MID
        {59, 59, 40, 40, //second, third, fourth, fifth
            0, 0, 0 }, //half, 3/2, 2/3

        //HIGH
        {55, 55, 55, 55, //second, third, fourth, fifth
            12, 12, 12 }, //half, 3/2, 2/3

        //SUPER-HIGH
        {44, 44, 0, 0, //second, third, fourth, fifth
            12, 12, 12 } //half, 3/2, 2/3
    },
    // Speech
    {
        //LOW
        {42, 42, 42, 42, //second, third, fourth, fifth
            0, 0, 0 }, //half, 3/2, 2/3

        //MID
        {42, 42, 0, 0, //second, third, fourth, fifth
            0, 0, 0 }, //half, 3/2, 2/3

        //HIGH
        {40, 40, 0, 0, //second, third, fourth, fifth
            8, 8, 8 }, //half, 3/2, 2/3

        //SUPER-HIGH
        {36, 36, 0, 0, //second, third, fourth, fifth
            8, 8, 8 } //half, 3/2, 2/3
    }
};

//Parameters for operation of risefactor analysis
struct RiseFactorAnalysisParameters
{
    //Represents cutoff between feedback and musical signals for growth. 
    //Anything > threshold will be declared non-feedback!
    int RISE_FACTOR_MAXIMUM_CUTOFF_THRESHOLD;
    //Represents minimum RiseFactor for FIRST filter to be instantiated at 
    //this frequency. Why would feedback diminish w/o our filter?
    int RISE_FACTOR_MINIMUM_CUTOFF_THRESHOLD;
};

//Struct for info of one potential feedback peak
struct PotentialFeedbackPeak
{
    float frequency;
    int fft_index;
    float frequency_error_margin_in_octaves;
    MultibandFrequencyClassification multi_band_classification;
};

// constants for panic gain control
const int PANIC_RELEASE_TIME = 30;
const float PANIC_RECENT_FILTER_DECAY = 0.1f;
const float PANIC_RECENT_FILTER_THRESHOLD = 8.0f;
const float INITIAL_PANIC_GAIN = -3.0f;
const float INCREMENTAL_PANIC_GAIN_STEP = -1.0f;
const float MAX_PANIC_GAIN = -9.0f;