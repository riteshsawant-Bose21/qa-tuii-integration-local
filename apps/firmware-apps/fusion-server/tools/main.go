package main

import (
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"os/signal"
	"time"

	"github.com/gorilla/websocket"
)

func main() {
	// Command-line flags
	noiseType := flag.String("type", "white", "Type of noise to generate (white, pink, or brown)")
	sampleRate := flag.Float64("rate", 44100, "Sample rate in Hz")
	frequency := flag.Float64("freq", 60, "Frequency in Hz")
	wsURL := flag.String("url", "ws://localhost:9001/ws", "WebSocket server URL")
	channel := flag.Int("channel", 1, "Channel number (default is 1)")
	flag.Parse()

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

	// Start noise generation and sending
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			noiseValue := generateNoise(*noiseType, *sampleRate, *frequency)
			message := fmt.Sprintf(`{"channel":%d,"volume":%.2f}`, *channel, noiseValue)
			err := c.WriteMessage(websocket.TextMessage, []byte(message))
			if err != nil {
				log.Println("Failed to send message:", err)
				return
			}
			log.Printf("Sent: %s", message)
			time.Sleep(time.Second / time.Duration(*frequency))
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

func generateNoise(noiseType string, sampleRate, frequency float64) float64 {
	switch noiseType {
	case "white":
		return generateWhiteNoise(sampleRate, frequency)
	case "pink":
		return generatePinkNoise(sampleRate, frequency)
	case "brown":
		return generateBrownNoise(sampleRate, frequency)
	default:
		log.Fatalf("Invalid noise type: %s", noiseType)
		return 0
	}
}
