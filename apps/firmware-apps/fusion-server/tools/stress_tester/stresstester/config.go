package stresstester

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

// WriterMode selects the transport used to send patch updates.
type WriterMode string

const (
	WriterModeWS   WriterMode = "ws"
	WriterModeHTTP WriterMode = "http"
)

// Verbosity controls console output level.
type Verbosity string

const (
	VerbosityQuiet   Verbosity = "quiet"
	VerbosityNormal  Verbosity = "normal"
	VerbosityVerbose Verbosity = "verbose"
)

// Config holds all tunables for a stress-test run.
type Config struct {
	// Writer
	WriterMode WriterMode `json:"writer_mode"`
	WriterHost string     `json:"writer_host"` // e.g. "192.168.2.131:8080"

	// Profiling
	EnableProfiling bool     `json:"enable_profiling"`
	ProfileHosts    []string `json:"profile_hosts"` // host:port targets for /debug/profile endpoints

	// WebSocket listeners
	WSListenerHosts []string `json:"ws_listener_hosts"` // one entry per distinct host; listeners are spread round-robin
	WSListenerCount int      `json:"ws_listener_count"`

	// UDP listeners
	UDPListenerBindIPs []string `json:"udp_listener_bind_ips"` // local IPs to bind (default ["0.0.0.0"])
	UDPListenerCount   int      `json:"udp_listener_count"`
	UDPPort            int      `json:"udp_port"`        // remote server port (default 7947)
	UDPServerHost      string   `json:"udp_server_host"` // IP:port or host of the fusion-server UDP endpoint

	// Send rate
	UpdatesPerSecond int     `json:"updates_per_second"`
	BurstMode        bool    `json:"burst_mode"`
	BurstMultiplier  float64 `json:"burst_multiplier"` // e.g. 5.0 = send at 5x rate then pause

	// Run boundaries
	TotalUpdates int           `json:"total_updates"` // bounded mode count (ignored in soak mode)
	SoakMode     bool          `json:"soak_mode"`
	SoakDuration time.Duration `json:"soak_duration"`
	StartGain    int           `json:"start_gain"`

	// Grace / timeouts
	GracePeriod            time.Duration `json:"grace_period"`
	AdaptiveGrace          bool          `json:"adaptive_grace"`
	ListenerStartupTimeout time.Duration `json:"listener_startup_timeout"`

	// Output
	OutputPath string    `json:"output_path"`
	Verbosity  Verbosity `json:"verbosity"`
}

// DefaultConfig returns a Config with sensible defaults for same-node testing.
func DefaultConfig() Config {
	return Config{
		WriterMode: WriterModeWS,
		WriterHost: "localhost:8080",

		EnableProfiling: true,
		ProfileHosts:    nil,

		WSListenerHosts: []string{"localhost:8080"},
		WSListenerCount: 3,

		UDPListenerBindIPs: []string{"0.0.0.0"},
		UDPListenerCount:   5,
		UDPPort:            7947,
		UDPServerHost:      "localhost:7947",

		UpdatesPerSecond: 100,
		BurstMode:        false,
		BurstMultiplier:  5.0,

		TotalUpdates: 3000,
		SoakMode:     false,
		SoakDuration: 30 * time.Minute,
		StartGain:    1,

		GracePeriod:            5 * time.Minute,
		AdaptiveGrace:          true,
		ListenerStartupTimeout: 10 * time.Second,

		OutputPath: "report/stress_test_report.json",
		Verbosity:  VerbosityNormal,
	}
}

// LoadConfigFromFile reads a JSON config file and merges it on top of defaults.
func LoadConfigFromFile(path string) (Config, error) {
	cfg := DefaultConfig()
	data, err := os.ReadFile(path)
	if err != nil {
		return cfg, fmt.Errorf("read config: %w", err)
	}
	if err := json.Unmarshal(data, &cfg); err != nil {
		return cfg, fmt.Errorf("parse config: %w", err)
	}
	return cfg, nil
}

// Validate checks that the configuration is internally consistent.
func (c *Config) Validate() error {
	if c.WriterHost == "" {
		return fmt.Errorf("writer_host is required")
	}
	if c.WriterMode != WriterModeWS && c.WriterMode != WriterModeHTTP {
		return fmt.Errorf("writer_mode must be %q or %q", WriterModeWS, WriterModeHTTP)
	}
	if c.WSListenerCount < 0 {
		return fmt.Errorf("ws_listener_count must be >= 0")
	}
	if c.WSListenerCount > 0 && len(c.WSListenerHosts) == 0 {
		return fmt.Errorf("ws_listener_hosts required when ws_listener_count > 0")
	}
	if c.UDPListenerCount < 0 {
		return fmt.Errorf("udp_listener_count must be >= 0")
	}
	if c.UDPListenerCount > 0 && c.UDPServerHost == "" {
		return fmt.Errorf("udp_server_host required when udp_listener_count > 0")
	}
	if c.UpdatesPerSecond <= 0 {
		return fmt.Errorf("updates_per_second must be > 0")
	}
	if c.BurstMode && c.BurstMultiplier <= 1.0 {
		return fmt.Errorf("burst_multiplier must be > 1.0 when burst_mode is enabled")
	}
	if !c.SoakMode && c.TotalUpdates <= 0 {
		return fmt.Errorf("total_updates must be > 0 in bounded mode")
	}
	if c.SoakMode && c.SoakDuration <= 0 {
		return fmt.Errorf("soak_duration must be > 0 in soak mode")
	}
	if c.StartGain < 0 {
		return fmt.Errorf("start_gain must be >= 0")
	}
	if c.GracePeriod <= 0 {
		return fmt.Errorf("grace_period must be > 0")
	}
	for _, host := range c.ProfileHosts {
		if host == "" {
			return fmt.Errorf("profile_hosts must not contain empty values")
		}
	}
	return nil
}
