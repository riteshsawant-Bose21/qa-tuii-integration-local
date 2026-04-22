#include "tx_api.h"
#include "FusionProxy.h"

class FusionPlatform : public FusionProxy {
public:
    bool Initialize() override;
    bool SetGain(uint16_t objectNumber, float gain) override;
    bool SetMute(uint16_t objectNumber, bool mute) override;
    bool SetSwitch(uint16_t objectNumber, bool state) override;

private:
    // STM32 specific implementations
};