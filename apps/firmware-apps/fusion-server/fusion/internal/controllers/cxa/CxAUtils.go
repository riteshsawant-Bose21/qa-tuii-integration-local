package cxa

// AnalogValues represents the normalized volume and input selection
type AnalogControllerValues struct {
	Volume      float64 // Normalized volume (0.0 to 1.0)
	InputSelect int     // Selected input (1-based index)
}

// MapAnalogValues converts raw analog values to normalized volume and input selection
// based on the controller type
func MapAnalogValues(analogValues []uint32, ctrlType ControllerType) AnalogControllerValues {
	result := AnalogControllerValues{
		Volume:      0.0,
		InputSelect: 1, // Default to first input
	}

	if len(analogValues) < 5 {
		return result
	}

	switch ctrlType {
	case CC1:
		// CC1 only has volume control on the first channel
		result.Volume = normalizeCC1Volume(analogValues[0])

	case CC2:
		// Get volume from first channel
		result.Volume = normalizeCC2Volume(analogValues[0], 1)

		// Check input selection on channel 3
		if analogValues[3] >= REMOTE_CC2_SEL_VOLUME_B {
			result.InputSelect = 2
			// Update volume normalization based on selected input
			result.Volume = normalizeCC2Volume(analogValues[0], 2)
		}

	case CC3:
		// Get volume from first channel (inverted for CC3)
		result.Volume = normalizeCC3Volume(analogValues[0])

		// Determine input selection from channels 1-4
		// Input is selected when its value is below the threshold
		for i := 1; i <= 4; i++ {
			if analogValues[i] < REMOTE_CC3_SEL_INPUT {
				result.InputSelect = i
				break
			}
		}
	}

	return result
}

// NormalizeVolume converts a raw voltage value to a normalized volume (0.0 to 1.0)
// for the specified controller type and input selection
func NormalizeVolume(voltage uint32, ctrlType ControllerType, input int) float64 {
	switch ctrlType {
	case CC1:
		return normalizeCC1Volume(voltage)
	case CC2:
		return normalizeCC2Volume(voltage, input)
	case CC3:
		return normalizeCC3Volume(voltage)
	default:
		return 0.0
	}
}

// DenormalizeVolume converts a normalized volume (0.0 to 1.0) to the appropriate
// voltage value for the specified controller type and input selection
func DenormalizeVolume(normalizedVol float64, ctrlType ControllerType, input int) uint32 {
	switch ctrlType {
	case CC1:
		return denormalizeCC1Volume(normalizedVol)
	case CC2:
		return denormalizeCC2Volume(normalizedVol, input)
	case CC3:
		return denormalizeCC3Volume(normalizedVol)
	default:
		return 0
	}
}

// Helper functions for CC1
func normalizeCC1Volume(voltage uint32) float64 {
	if voltage <= REMOTE_CC1_MIN_VOLUME {
		return 0.0
	}
	if voltage >= REMOTE_CC1_MAX_VOLUME {
		return 1.0
	}
	return float64(voltage-REMOTE_CC1_MIN_VOLUME) / float64(REMOTE_CC1_MAX_VOLUME-REMOTE_CC1_MIN_VOLUME)
}

func denormalizeCC1Volume(normalizedVol float64) uint32 {
	voltage := float64(REMOTE_CC1_MIN_VOLUME) +
		float64(REMOTE_CC1_MAX_VOLUME-REMOTE_CC1_MIN_VOLUME)*normalizedVol
	return uint32(voltage)
}

// Helper functions for CC2
func normalizeCC2Volume(voltage uint32, input int) float64 {
	minVol := float64(REMOTE_CC2_MIN_VOLUME)
	var maxVol float64
	if input == 2 {
		maxVol = float64(REMOTE_CC2_MAX_VOLUME_B)
	} else {
		maxVol = float64(REMOTE_CC2_MAX_VOLUME_A)
	}

	if voltage <= uint32(minVol) {
		return 0.0
	}
	if voltage >= uint32(maxVol) {
		return 1.0
	}
	return (float64(voltage) - minVol) / (maxVol - minVol)
}

func denormalizeCC2Volume(normalizedVol float64, input int) uint32 {
	var maxVol float64
	if input == 2 {
		maxVol = float64(REMOTE_CC2_MAX_VOLUME_B)
	} else {
		maxVol = float64(REMOTE_CC2_MAX_VOLUME_A)
	}

	voltage := float64(REMOTE_CC2_MIN_VOLUME) +
		(maxVol-float64(REMOTE_CC2_MIN_VOLUME))*normalizedVol
	return uint32(voltage)
}

// Helper functions for CC3 (note: CC3 works in reverse)
func normalizeCC3Volume(voltage uint32) float64 {
	if voltage >= REMOTE_CC3_MIN_VOLUME {
		return 0.0
	}
	if voltage <= REMOTE_CC3_MAX_VOLUME {
		return 1.0
	}
	return (float64(REMOTE_CC3_MIN_VOLUME) - float64(voltage)) /
		float64(REMOTE_CC3_MIN_VOLUME-REMOTE_CC3_MAX_VOLUME)
}

func denormalizeCC3Volume(normalizedVol float64) uint32 {
	voltage := float64(REMOTE_CC3_MIN_VOLUME) -
		float64(REMOTE_CC3_MIN_VOLUME-REMOTE_CC3_MAX_VOLUME)*normalizedVol
	return uint32(voltage)
}
