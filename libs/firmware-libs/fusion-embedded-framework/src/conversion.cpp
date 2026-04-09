#include <bosepro/conversion.h>

#include <cmath>

namespace bosepro {

float db_to_linear(float db)
{
    return pow(10.0f, db * 0.05f);
}


float linear_to_db(float linear)
{
    return 20.0f * log10(linear);
}

}
