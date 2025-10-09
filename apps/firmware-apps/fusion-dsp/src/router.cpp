
#include <bosepro/algorithm.h>
#include <cstdint>
#include <cstring>
#include <cmath>

namespace {
    

    class Router : public bosepro::Algorithm {
    public:
        Router(const bosepro::BlockConfiguration &configuration);
        virtual ~Router() = default;

        virtual void process() override;

    private:
        int num_inputs;
        int num_outputs;
        bosepro::DspSignalMemory<const float *[]> in;
        bosepro::DspSignalMemory<float *[]> out;

        bosepro::DspCoeffMemory<int_fast32_t []> route;

        ALGORITHM_DECLARE(Router);
   };
    
   ALGORITHM_REGISTER(Router, "router");
   
   Router::Router(const bosepro::BlockConfiguration &configuration)
       : bosepro::Algorithm(configuration)
   {
       get_terminal_num_channels("in", num_inputs);
       get_terminal_num_channels("out", num_outputs);

       assign_terminal("in", in);
       assign_terminal("out", out);

       assign_parameter("route", route); // input - output parameter
   }

   void Router::process()
    {
        for (int output = 0; output < num_outputs; output++)
        {
            int_fast32_t input = route[output] - 1; // 0 based indexing
                if (input >= 0 && input < num_inputs)
            {
                std::memcpy(out[output], in[input],
                            get_frame_size() * sizeof(float));
            }
            else
            {
                std::memset(out[output], 0,
                            get_frame_size() * sizeof(float));
            }
        }
    }
}
