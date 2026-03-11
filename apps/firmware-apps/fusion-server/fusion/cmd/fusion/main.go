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
	fusioniot "fusion/internal/iot"
	"fusion/internal/utils"
	"fusion/internal/version"
)

const (
	baseName   = "fusion"
	numberBase = 36
)

// parseFlags parses and validates command-line flags.
func parseFlags() (*api.AppConfig, *fusioniot.Config) {
	versionFlag := flag.Bool("version", false, "Show version information")
	//On the hardware, we no longer pass in the IP address, instead we pass in the interface name
	bindAddr := flag.String("bind-addr", "0.0.0.0", "Bind address for cluster communication")
	bindPort := flag.Int("bind-port", 7946, "Bind port for cluster communication (default 7946)")
	// The local mode for fusion server was not working so we replaced the default interface to en0 which is the default interface for macOS
	// For multipass and on the hardware, it will pick the interface name from the fusion-server.service file
	netIface := flag.String("net-iface", "en0", "Network interface for VRRP monitoring")
	local := flag.Bool("local", false, "Run in local-only mode (no clustering)")
	verbose := flag.Bool("verbose", false, "Enable verbose logging")
	profile := flag.Bool("profile", false, "Enable profile dump")

	// IoT Core flags
	iotEnabled := flag.Bool("iot-enabled", true, "Enable AWS IoT Core metrics publishing")
	iotEndpoint := flag.String("iot-endpoint", "a1a77o9cigolk4-ats.iot.us-east-2.amazonaws.com", "AWS IoT Core endpoint (e.g., xxx-ats.iot.us-east-2.amazonaws.com)")
	iotTopicPrefix := flag.String("iot-topic-prefix", "cluster/", "Topic prefix for IoT messages")
	projectID := flag.String("project-id", "6f93aa8e-b0b2-40e5-a426-1a70540cad2f", "Project ID to include in IoT topic")
	flag.Parse()

	// Read environment overrides
	if envVal := os.Getenv("FUSION_NET_IFACE"); envVal != "" {
		*netIface = envVal
	}

	localIP, err := utils.GetLocalIPByInterface(*netIface)
	if err != nil {
		log.Fatalf("Failed to get local IP: %v", err)
	}
	*bindAddr = localIP

	if envVal := os.Getenv("FUSION_PROFILE"); envVal != "" {
		if envVal == "1" || strings.EqualFold(envVal, "true") {
			*profile = true
		} else if envVal == "0" || strings.EqualFold(envVal, "false") {
			*profile = false
		}
	}

	if *versionFlag {
		// This must be a log.Printf. The server logger is not running yet.
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", version.Version, version.Commit, version.BuildTime)
		os.Exit(0)
	}

	nodeName := createUniqueNodeName(baseName)

	return &api.AppConfig{
			NodeName: nodeName,
			BindAddr: *bindAddr,
			BindPort: *bindPort,
			NetIface: *netIface,
			Local:    *local,
			Verbose:  *verbose,
			Profile:  *profile,
		}, &fusioniot.Config{
			Enabled:     *iotEnabled,
			Endpoint:    *iotEndpoint,
			ClientID:    fmt.Sprintf("%s_instance", nodeName),
			TopicPrefix: *iotTopicPrefix,
			ProjectID:   *projectID,
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

	appConfig, iotConfig := parseFlags()

	if appConfig.Profile {
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

	app := app.NewApp(appConfig, iotConfig)
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
