#pragma once

/// These functions are used for simple conversions between user-facing values
/// (such as dB) and values used internally by algorithm (such as linear gain).

namespace bosepro {


/// Convert a value in dB to a linear value.
float db_to_linear(float db);


/// Convert a linear value to a value in dB.
float linear_to_db(float linear);

}
