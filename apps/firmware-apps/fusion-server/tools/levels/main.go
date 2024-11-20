package main

import (
	"encoding/json"
	"flag"
	"log"
	"math"
	"math/rand/v2"
	"net"
	"net/url"
	"os"
	"os/signal"
	"time"

	"github.com/gorilla/websocket"
)

type VolumeMessage struct {
	Type    string  `json:"type"`
	Channel int     `json:"channel"`
	Volume  float64 `json:"volume"`
}

type Client struct {
	url            string
	conn           *websocket.Conn
	done           chan struct{}
	messageTicker  *time.Ticker
	pingTicker     *time.Ticker
	signalType     string
	sampleRate     float64
	frequency      float64
	channel        int
	reconnectDelay time.Duration
}

func NewClient(url string, signalType string, sampleRate, frequency float64, channel int) *Client {
	return &Client{
		url:            url,
		done:           make(chan struct{}),
		messageTicker:  time.NewTicker(time.Second / time.Duration(frequency)),
		pingTicker:     time.NewTicker(30 * time.Second),
		signalType:     signalType,
		sampleRate:     sampleRate,
		frequency:      frequency,
		channel:        channel,
		reconnectDelay: time.Second,
	}
}

func (c *Client) connect() error {
	dialer := websocket.Dialer{
		HandshakeTimeout: 10 * time.Second,
		ReadBufferSize:   1024,
		WriteBufferSize:  1024,
	}

	conn, _, err := dialer.Dial(c.url, nil)
	if err != nil {
		return err
	}

	c.conn = conn
	c.setupHandlers()
	return nil
}

func (c *Client) setupHandlers() {
	c.conn.SetPingHandler(func(message string) error {
		err := c.conn.WriteControl(websocket.PongMessage, []byte(message), time.Now().Add(time.Second))
		if err == websocket.ErrCloseSent {
			return nil
		} else if e, ok := err.(net.Error); ok && e.Temporary() {
			return nil
		}
		return err
	})

	c.conn.SetPongHandler(func(string) error {
		return c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	})
}

func (c *Client) reconnect() error {
	for {
		log.Printf("Attempting to reconnect in %v...", c.reconnectDelay)
		time.Sleep(c.reconnectDelay)

		if err := c.connect(); err != nil {
			log.Printf("Reconnection failed: %v", err)
			c.reconnectDelay *= 2
			if c.reconnectDelay > 1*time.Minute {
				c.reconnectDelay = 1 * time.Minute
			}
			continue
		}

		log.Println("Successfully reconnected")
		c.reconnectDelay = time.Second
		return nil
	}
}

func (c *Client) Run() error {
	if err := c.connect(); err != nil {
		return err
	}
	defer c.Close()

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	var sinPhase float64
	var drumBeat int

	go c.readPump()

	for {
		select {
		case <-c.done:
			return nil
		case <-interrupt:
			return c.Close()
		case <-c.pingTicker.C:
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("Error sending ping: %v", err)
				if err := c.reconnect(); err != nil {
					return err
				}
			}
		case <-c.messageTicker.C:
			volume := 0.0
			switch c.signalType {
			case "drum":
				volume = generateDrum(&drumBeat)
			case "sin":
				volume = generateSin(60, &sinPhase)
			default:
				volume = generateNoise(c.sampleRate, c.frequency)
			}

			msg := VolumeMessage{
				Type:    "volume",
				Channel: c.channel,
				Volume:  math.Round(volume*100) / 100,
			}

			if err := c.sendMessage(msg); err != nil {
				log.Printf("Error sending message: %v", err)
				if err := c.reconnect(); err != nil {
					return err
				}
			}
		}
	}
}

func (c *Client) readPump() {
	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if !websocket.IsCloseError(err, websocket.CloseNormalClosure) {
				log.Printf("[ERROR] Read error: %v", err)
				if err := c.reconnect(); err != nil {
					log.Printf("Failed to reconnect: %v", err)
					close(c.done)
					return
				}
			}
			return
		}
		log.Printf("Received: %s", message)
	}
}

func (c *Client) sendMessage(msg VolumeMessage) error {
	jsonMsg, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	return c.conn.WriteMessage(websocket.TextMessage, jsonMsg)
}

func (c *Client) Close() error {
	c.messageTicker.Stop()
	c.pingTicker.Stop()
	return c.conn.WriteMessage(
		websocket.CloseMessage,
		websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""),
	)
}

func main() {
	signalType := flag.String("type", "white", "Type of signal to generate (white, pink, brown, sin or drum)")
	sampleRate := flag.Float64("rate", 44100, "Sample rate in Hz")
	frequency := flag.Float64("freq", 60, "Frequency in Hz")
	wsURL := flag.String("url", "ws://192.168.64.100:8080/ws", "WebSocket server URL")
	channel := flag.Int("channel", 1, "Channel number (default is 1)")
	flag.Parse()

	*channel = max(0, *channel-1)

	u, err := url.Parse(*wsURL)
	if err != nil {
		log.Fatal("Failed to parse WebSocket URL:", err)
	}

	client := NewClient(u.String(), *signalType, *sampleRate, *frequency, *channel)
	if err := client.Run(); err != nil {
		log.Fatal(err)
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
