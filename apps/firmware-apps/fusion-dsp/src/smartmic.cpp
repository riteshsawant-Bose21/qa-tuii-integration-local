
#include "SmartMicDrvTsk_Ccode.h"

#include <bosepro/algorithm.h>
#include <bosepro/task.h>

#include <cstring>


namespace {


class SmartMic : public bosepro::Algorithm {
public:
    SmartMic(const bosepro::BlockConfiguration &configuration);
    virtual ~SmartMic() = default;
    virtual void process() override;

    static void run_main_step(void *obj)
    {
        SmartMic *smart_mic = (SmartMic *)obj;
        smart_mic->smart_mic_drv.Periodic_TSK_Main_step();
    }

    static void run_2_step(void *obj)
    {
        SmartMic *smart_mic = (SmartMic *)obj;
        smart_mic->smart_mic_drv.Periodic_TSK_2_step();
    }

    static void run_discrete_1_step(void *obj)
    {
        SmartMic *smart_mic = (SmartMic *)obj;
        smart_mic->smart_mic_drv.Discrete1_step();
    }

    static void run_spkdelay_step(void *obj)
    {
        SmartMic *smart_mic = (SmartMic *)obj;
        smart_mic->smart_mic_drv.Periodic_TSK_SpkDelay_step();
    }

private:
    const float * mic_in;
    const float * ref_in;
    float * mic_out;

    SmartMicDrvTsk_Ccode smart_mic_drv;
    SmartMicDrvTsk_Ccode::ExtU smart_mic_drv_U;

    bosepro::PeriodicTask task_main_step;
    bosepro::PeriodicTask task_2_step;
    bosepro::PeriodicTask task_discrete_1_step;
    bosepro::PeriodicTask task_spkdelay_step;

    ALGORITHM_DECLARE(SmartMic);
};

ALGORITHM_REGISTER(SmartMic, "smart_mic");


SmartMic::SmartMic(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration),
      task_main_step(&SmartMic::run_main_step, this, get_sample_rate(),
                     get_frame_size(), get_frame_size()),
      task_2_step(&SmartMic::run_2_step, this, get_sample_rate(),
                  get_frame_size(), get_frame_size()),
      task_discrete_1_step(&SmartMic::run_discrete_1_step, this,
                           get_sample_rate(), get_frame_size(),
                           get_frame_size()),
      task_spkdelay_step(&SmartMic::run_spkdelay_step, this, get_sample_rate(),
                         get_frame_size() * 50, get_frame_size())
{
    assign_terminal("mic_in", &mic_in);
    assign_terminal("ref_in", &ref_in);
    assign_terminal("mic_out", &mic_out);

    task_main_step.set_priority(9);
    task_2_step.set_priority(9);
    task_discrete_1_step.set_priority(9);
    task_spkdelay_step.set_priority(8);

    smart_mic_drv.initialize();
}


void SmartMic::process()
{
    std::memcpy(smart_mic_drv_U.MicIn, mic_in, sizeof(smart_mic_drv_U.MicIn));
    std::memcpy(smart_mic_drv_U.FE, ref_in, sizeof(smart_mic_drv_U.FE));

    smart_mic_drv.setExternalInputs(&smart_mic_drv_U);

    task_main_step.tick();
    task_2_step.tick();
    task_discrete_1_step.tick();
    task_spkdelay_step.tick();

    const SmartMicDrvTsk_Ccode::ExtY &smart_mic_drv_Y =
        smart_mic_drv.getExternalOutputs();

    std::memcpy(mic_out, smart_mic_drv_Y.toFE, sizeof(smart_mic_drv_Y.toFE));
}


} // namespace
