package main

import (
	"flag"
	"fmt"
	"log"
	"math"
	"math/rand/v2"
	"net/url"
	"os"
	"os/signal"
	"time"

	"github.com/gorilla/websocket"
)

func main() {
	// Command-line flags
	signalType := flag.String("type", "white", "Type of signal to generate (white, pink, brown, sin or drum)")
	sampleRate := flag.Float64("rate", 44100, "Sample rate in Hz")
	frequency := flag.Float64("freq", 60, "Frequency in Hz")
	wsURL := flag.String("url", "ws://localhost:9001/ws", "WebSocket server URL")
	channel := flag.Int("channel", 1, "Channel number (default is 1)")
	flag.Parse()

	*channel = max(0, *channel-1)

	// Parse the WebSocket URL
	u, err := url.Parse(*wsURL)
	if err != nil {
		log.Fatal("Failed to parse WebSocket URL:", err)
	}

	// Connect to the WebSocket server
	log.Printf("Connecting to %s", u.String())
	c, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
	if err != nil {
		log.Fatal("Failed to connect to WebSocket server:", err)
	}
	defer c.Close()

	// Set up a channel to handle OS signals for graceful shutdown
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	const sinRate = 60
	var sinPhase float64
	var drumBeat int

	// Create a ticker for all signal types
	var ticker *time.Ticker
	if *signalType == "drum" {
		const bpm = 120 // Beats per minute
		beatDuration := time.Minute / time.Duration(bpm)
		ticker = time.NewTicker(beatDuration)
	} else {
		ticker = time.NewTicker(time.Second / time.Duration(*frequency))
	}
	defer ticker.Stop()

	// Start noise generation and sending
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			volume := 0.0
			switch *signalType {
			case "drum":
				volume = generateDrum(&drumBeat)
			case "sin":
				volume = generateSin(sinRate, &sinPhase)
			default:
				volume = generateNoise(*sampleRate, *frequency)
			}

			message := fmt.Sprintf(`{"channel":%d,"volume":%.2f}`, *channel, volume)
			err := c.WriteMessage(websocket.TextMessage, []byte(message))
			if err != nil {
				return
			}

			// Wait for the next tick instead of using time.Sleep
			<-ticker.C
		}
	}()

	// Wait for interrupt signal or error
	for {
		select {
		case <-done:
			return
		case <-interrupt:
			log.Println("Interrupt received, closing connection...")
			err := c.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			if err != nil {
				log.Println("Error during closing websocket:", err)
				return
			}
			select {
			case <-done:
			case <-time.After(time.Second):
			}
			return
		}
	}
}

// generateNoise generates white noise and produces a floating-point value
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
func generateNoise(sampleRate, frequency float64) float64 {

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

func generateSin(rate float64, phase *float64) float64 {
	const frequency = 0.5
	// Generate a sine wave value between 0 and 1
	volume := (math.Sin(*phase) + 1) / 2 // This transforms the sine wave to range 0-1
	*phase += frequency * 2 * math.Pi / rate
	if *phase > 2*math.Pi {
		*phase -= 2 * math.Pi // Keep phase within 0-2π
	}
	return volume
}

func generateDrum(beat *int) float64 {
	const beatsPerMeasure = 4 // 4/4 time signature
	var volume float64

	// Base drum on every beat
	volume = 0.2

	// Snare on beats 2 and 4
	if *beat == 1 || *beat == 3 {
		volume += 0.1
	}

	// Move to the next beat
	*beat = (*beat + 1) % beatsPerMeasure

	return volume
}
