package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
	"time"
)

func main() {
	// CLI flags — all override the config file / defaults.
	configFile := flag.String("config", "", "Path to JSON config file (optional)")
	writerMode := flag.String("writer-mode", "", "Writer transport: ws or http")
	writerHost := flag.String("writer-host", "", "Writer target host:port")
	wsHosts := flag.String("ws-hosts", "", "Comma-separated WS listener hosts")
	wsCount := flag.Int("ws-count", -1, "Number of WebSocket listeners")
	udpBindIPs := flag.String("udp-bind-ips", "", "Comma-separated UDP bind IPs")
	udpCount := flag.Int("udp-count", -1, "Number of UDP listeners")
	udpPort := flag.Int("udp-port", -1, "UDP server port")
	udpServerHost := flag.String("udp-server-host", "", "UDP server host:port")
	rate := flag.Int("rate", -1, "Updates per second")
	burst := flag.Bool("burst", false, "Enable burst mode")
	burstMult := flag.Float64("burst-multiplier", -1, "Burst rate multiplier")
	total := flag.Int("total", -1, "Total updates (bounded mode)")
	soak := flag.Bool("soak", false, "Enable soak mode")
	soakDur := flag.Duration("soak-duration", 0, "Soak duration")
	startGain := flag.Int("start-gain", -1, "Starting gain value")
	grace := flag.Duration("grace", 0, "Grace period after last send")
	adaptiveGrace := flag.Bool("adaptive-grace", true, "End grace early when all listeners received final value")
	output := flag.String("output", "", "JSON report output path")
	verbosity := flag.String("verbosity", "", "quiet, normal, or verbose")
	startupTimeout := flag.Duration("startup-timeout", 0, "Listener startup timeout")

	flag.Parse()

	// Load config
	var cfg Config
	if *configFile != "" {
		var err error
		cfg, err = LoadConfigFromFile(*configFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error loading config: %v\n", err)
			os.Exit(1)
		}
	} else {
		cfg = DefaultConfig()
	}

	// Apply CLI overrides
	if *writerMode != "" {
		cfg.WriterMode = WriterMode(*writerMode)
	}
	if *writerHost != "" {
		cfg.WriterHost = *writerHost
	}
	if *wsHosts != "" {
		cfg.WSListenerHosts = splitCSV(*wsHosts)
	}
	if *wsCount >= 0 {
		cfg.WSListenerCount = *wsCount
	}
	if *udpBindIPs != "" {
		cfg.UDPListenerBindIPs = splitCSV(*udpBindIPs)
	}
	if *udpCount >= 0 {
		cfg.UDPListenerCount = *udpCount
	}
	if *udpPort >= 0 {
		cfg.UDPPort = *udpPort
	}
	if *udpServerHost != "" {
		cfg.UDPServerHost = *udpServerHost
	}
	if *rate > 0 {
		cfg.UpdatesPerSecond = *rate
	}
	if *burst {
		cfg.BurstMode = true
	}
	if *burstMult > 0 {
		cfg.BurstMultiplier = *burstMult
	}
	if *total > 0 {
		cfg.TotalUpdates = *total
	}
	if *soak {
		cfg.SoakMode = true
	}
	if *soakDur > 0 {
		cfg.SoakDuration = *soakDur
	}
	if *startGain >= 0 {
		cfg.StartGain = *startGain
	}
	if *grace > 0 {
		cfg.GracePeriod = *grace
	}
	cfg.AdaptiveGrace = *adaptiveGrace
	if *output != "" {
		cfg.OutputPath = *output
	}
	if *verbosity != "" {
		cfg.Verbosity = Verbosity(*verbosity)
	}
	if *startupTimeout > 0 {
		cfg.ListenerStartupTimeout = *startupTimeout
	}

	// Validate
	if err := cfg.Validate(); err != nil {
		fmt.Fprintf(os.Stderr, "Invalid config: %v\n", err)
		os.Exit(1)
	}

	// Print config summary
	logNormal(cfg.Verbosity, "")
	logNormal(cfg.Verbosity, "╔═══════════════════════════════════════════════╗")
	logNormal(cfg.Verbosity, "║       Fusion Server Stress Tester             ║")
	logNormal(cfg.Verbosity, "╚═══════════════════════════════════════════════╝")
	logNormal(cfg.Verbosity, "")
	logNormal(cfg.Verbosity, "  Writer:     %s → %s", cfg.WriterMode, cfg.WriterHost)
	logNormal(cfg.Verbosity, "  WS hosts:   %v (%d listeners)", cfg.WSListenerHosts, cfg.WSListenerCount)
	logNormal(cfg.Verbosity, "  UDP server: %s (%d listeners)", cfg.UDPServerHost, cfg.UDPListenerCount)
	if cfg.SoakMode {
		logNormal(cfg.Verbosity, "  Mode:       soak (%s)", cfg.SoakDuration)
	} else {
		logNormal(cfg.Verbosity, "  Mode:       bounded (%d updates)", cfg.TotalUpdates)
	}
	logNormal(cfg.Verbosity, "  Rate:       %d/sec  burst=%v", cfg.UpdatesPerSecond, cfg.BurstMode)
	logNormal(cfg.Verbosity, "  Grace:      %s  adaptive=%v", cfg.GracePeriod, cfg.AdaptiveGrace)
	logNormal(cfg.Verbosity, "")

	// Run
	start := time.Now()
	result, err := Run(cfg)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Test failed: %v\n", err)
		os.Exit(1)
	}

	// Summary
	printSummary(result)

	// JSON report
	if cfg.OutputPath != "" {
		if err := writeJSONReport(cfg.OutputPath, result); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to write report: %v\n", err)
			os.Exit(1)
		}
		logNormal(cfg.Verbosity, "\nJSON report written to: %s", cfg.OutputPath)
	}

	logNormal(cfg.Verbosity, "Total wall time: %s", time.Since(start).Truncate(time.Millisecond))

	// Exit code: non-zero if latest value was missed by any listener
	if result.Aggregate.LatestMissedCount > 0 {
		os.Exit(2)
	}
}

func splitCSV(s string) []string {
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}
