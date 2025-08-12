#pragma once

namespace servo {

class Servo {
public:
    Servo()
        : offset_integral(0.0), kp(1.0e-5), ki(1.0e-4)
    {
    }

    void reset()
    {
        offset_integral = 0.0;
    }

    double update(double error)
    {
        offset_integral += error;
        return kp * (error + ki * offset_integral);
    }

private:
    double offset_integral;
    double kp;
    double ki;
};

} // namespace servo

