package main

import (
	"math"
	"math/rand"
	"time"
)

// generateWhiteNoise generates white noise and produces a floating-point value
// representing volume at the specified frequency.
//
// This function works as follows:
// 1. Initialize the random number generator with the current time as a seed.
// 2. Calculate the number of samples per cycle based on the sample rate and frequency.
// 3. Generate white noise by summing random values between -1 and 1 for one complete cycle.
// 4. Normalize the noise to a range of 0 to 1.
// 5. Ensure the result is clamped between 0 and 1.
//
// Parameters:
//
//	sampleRate: The number of samples per second (e.g., 44100 for standard audio)
//	frequency: The desired frequency in Hz (e.g., 60 for 60Hz)
//
// Returns:
//
//	A float64 value between 0 and 1, representing the volume of white noise at the specified frequency.
func generateWhiteNoise(sampleRate, frequency float64) float64 {
	// Initialize random number generator
	rand.Seed(time.Now().UnixNano())

	// Calculate the number of samples per cycle
	samplesPerCycle := sampleRate / frequency

	// Generate white noise
	noise := 0.0
	for i := 0; i < int(samplesPerCycle); i++ {
		noise += rand.Float64()*2 - 1 // Generate random value between -1 and 1
	}

	// Normalize the noise to a range of 0 to 1
	noise = (noise/samplesPerCycle + 1) / 2

	return math.Max(0, math.Min(1, noise)) // Ensure the result is between 0 and 1
}

// generatePinkNoise generates pink noise and produces a floating-point value
// representing volume at the specified frequency.
//
// This function works as follows:
// 1. Initialize the random number generator and pink noise state.
// 2. Calculate the number of samples per cycle based on the sample rate and frequency.
// 3. Generate pink noise using the Voss-McCartney algorithm.
// 4. Normalize the noise to a range of 0 to 1.
// 5. Ensure the result is clamped between 0 and 1.
//
// Parameters:
//
//	sampleRate: The number of samples per second (e.g., 44100 for standard audio)
//	frequency: The desired frequency in Hz (e.g., 60 for 60Hz)
//
// Returns:
//
//	A float64 value between 0 and 1, representing the volume of pink noise at the specified frequency.
func generatePinkNoise(sampleRate, frequency float64) float64 {
	// Initialize random number generator
	rand.Seed(time.Now().UnixNano())

	// Initialize pink noise state
	const numGenerators = 16
	var generators [numGenerators]float64
	for i := range generators {
		generators[i] = rand.Float64()*2 - 1
	}

	// Calculate the number of samples per cycle
	samplesPerCycle := int(sampleRate / frequency)

	// Generate pink noise using Voss-McCartney algorithm
	noise := 0.0
	for i := 0; i < samplesPerCycle; i++ {
		pinkSample := 0.0
		lastIndex := 0
		for j := 0; j < numGenerators; j++ {
			if i&(1<<j) == 0 {
				generators[j] = rand.Float64()*2 - 1
			}
			pinkSample += generators[j]
			lastIndex = j
		}
		pinkSample /= float64(lastIndex + 1)
		noise += pinkSample
	}

	// Normalize the noise to a range of 0 to 1
	noise = (noise/float64(samplesPerCycle) + 1) / 2

	return math.Max(0, math.Min(1, noise)) // Ensure the result is between 0 and 1
}

// generateBrownNoise generates brown noise and produces a floating-point value
// representing volume at the specified frequency.
//
// This function works as follows:
// 1. Initialize the random number generator and set the initial state.
// 2. Calculate the number of samples per cycle based on the sample rate and frequency.
// 3. Generate brown noise using a first-order low-pass filter on white noise.
// 4. Normalize the noise to a range of 0 to 1.
// 5. Ensure the result is clamped between 0 and 1.
//
// Parameters:
//
//	sampleRate: The number of samples per second (e.g., 44100 for standard audio)
//	frequency: The desired frequency in Hz (e.g., 60 for 60Hz)
//
// Returns:
//
//	A float64 value between 0 and 1, representing the volume of brown noise at the specified frequency.
func generateBrownNoise(sampleRate, frequency float64) float64 {
	// Initialize random number generator
	rand.Seed(time.Now().UnixNano())

	// Calculate the number of samples per cycle
	samplesPerCycle := int(sampleRate / frequency)

	// Initialize state
	lastValue := 0.0

	// Parameters for the low-pass filter
	alpha := 0.05 // Smoothing factor

	// Generate brown noise
	noise := 0.0
	for i := 0; i < samplesPerCycle; i++ {
		// Generate white noise
		whiteNoise := rand.Float64()*2 - 1

		// Apply first-order low-pass filter
		lastValue = lastValue + alpha*(whiteNoise-lastValue)

		noise += lastValue
	}

	// Normalize the noise to a range of 0 to 1
	minNoise := math.Inf(1)
	maxNoise := math.Inf(-1)
	for i := 0; i < samplesPerCycle; i++ {
		minNoise = math.Min(minNoise, noise)
		maxNoise = math.Max(maxNoise, noise)
	}
	normalizedNoise := (noise - minNoise) / (maxNoise - minNoise)

	return math.Max(0, math.Min(1, normalizedNoise)) // Ensure the result is between 0 and 1
}
