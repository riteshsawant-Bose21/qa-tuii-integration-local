package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"path/filepath"
	"runtime/debug"
	"runtime/pprof"
	"strconv"
	"strings"
	"syscall"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/app"
	"fusion/internal/version"
)

const (
	baseName   = "fusion"
	numberBase = 36
)

// parseFlags parses and validates command-line flags.
func parseFlags() *api.AppConfig {
	versionFlag := flag.Bool("version", false, "Show version information")
	bindAddr := flag.String("bind-addr", "0.0.0.0", "Bind address for cluster communication")
	bindPort := flag.Int("bind-port", 7946, "Bind port for cluster communication (default 7946)")
	netIface := flag.String("net-iface", "eth0", "Network interface for VRRP monitoring")
	local := flag.Bool("local", false, "Run in local-only mode (no clustering)")
	verbose := flag.Bool("verbose", false, "Enable verbose logging")
	profile := flag.Bool("profile", false, "Enable profile dump")

	// IoT Core flags
	iotEnabled := flag.Bool("iot-enabled", false, "Enable AWS IoT Core metrics publishing")
	iotEndpoint := flag.String("iot-endpoint", "", "AWS IoT Core endpoint (e.g., xxx-ats.iot.us-east-2.amazonaws.com)")
	iotClientID := flag.String("iot-client-id", "", "AWS IoT Core client ID")
	iotTopicPrefix := flag.String("iot-topic-prefix", "logs/", "Topic prefix for IoT messages")
	flag.Parse()

	// Read environment overrides
	if envVal := os.Getenv("FUSION_NET_IFACE"); envVal != "" {
		*netIface = envVal
	}

	if envVal := os.Getenv("FUSION_PROFILE"); envVal != "" {
		if envVal == "1" || strings.EqualFold(envVal, "true") {
			*profile = true
		} else if envVal == "0" || strings.EqualFold(envVal, "false") {
			*profile = false
		}
	}

	// IoT environment overrides
	if envVal := os.Getenv("FUSION_IOT_ENABLED"); envVal != "" {
		if envVal == "1" || strings.EqualFold(envVal, "true") {
			*iotEnabled = true
		}
	}
	if envVal := os.Getenv("FUSION_IOT_ENDPOINT"); envVal != "" {
		*iotEndpoint = envVal
	}
	if envVal := os.Getenv("FUSION_IOT_CLIENT_ID"); envVal != "" {
		*iotClientID = envVal
	}
	if envVal := os.Getenv("FUSION_IOT_TOPIC_PREFIX"); envVal != "" {
		*iotTopicPrefix = envVal
	}

	if *versionFlag {
		// This must be a log.Printf. The server logger is not running yet.
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", version.Version, version.Commit, version.BuildTime)
		os.Exit(0)
	}

	return &api.AppConfig{
		NodeName:       createUniqueNodeName(baseName),
		BindAddr:       *bindAddr,
		BindPort:       *bindPort,
		NetIface:       *netIface,
		Local:          *local,
		Verbose:        *verbose,
		Profile:        *profile,
		IoTEnabled:     *iotEnabled,
		IoTEndpoint:    *iotEndpoint,
		IoTClientID:    *iotClientID,
		IoTTopicPrefix: *iotTopicPrefix,
	}
}

// createUniqueNodeName creates a unique name using current time and a random number
func createUniqueNodeName(baseName string) string {
	timeStamp := strconv.FormatInt(time.Now().UnixNano(), numberBase)
	suffix := strconv.FormatInt(rand.Int63n(1e6), numberBase)
	return fmt.Sprintf("%s_%s_%s", baseName, timeStamp, suffix)
}

func main() {

	defer func() {
		if r := recover(); r != nil {
			logging.GetLogger().Fatal("PANIC: %v\n%s", r, debug.Stack())
		}
	}()

	config := parseFlags()

	if config.Profile {
		// Create profile dump
		timestamp := time.Now().Format("20060102_150405")
		profilePath := filepath.Join("/tmp", fmt.Sprintf("fusion_server_cpu_%s.prof", timestamp))

		f, err := os.Create(profilePath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "failed to create profile file: %v\n", err)
			os.Exit(1)
		}
		defer f.Close()

		// Start CPU profiling
		fmt.Printf("Writing CPU profile to %s\n", profilePath)
		if err := pprof.StartCPUProfile(f); err != nil {
			fmt.Fprintf(os.Stderr, "could not start CPU profile: %v\n", err)
			os.Exit(1)
		}
		defer pprof.StopCPUProfile()
	}

	app := app.NewApp(config)
	defer app.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Listen for SIGINT/SIGTERM
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	done := make(chan struct{})

	go func() {
		app.Start(ctx)
		close(done)
	}()

	logger := logging.GetLogger()

	select {
	case <-sigs:
		logger.Info("Shutdown signal received")
	case <-done:
		logger.Info("Exited normally")
	}
}
