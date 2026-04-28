package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"runtime/debug"
	"strconv"
	"strings"
	"syscall"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/app"
	"fusion/internal/utils"
	"fusion/internal/version"
)

const (
	baseName   = "fusion"
	numberBase = 36
)

// parseFlags parses and validates command-line flags.
func parseFlags() *api.AppConfig {
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
	flag.Parse()
	configUDPDiagnostics := false

	// Read environment overrides
	if envVal := os.Getenv("FUSION_NET_IFACE"); envVal != "" {
		*netIface = envVal
	}

	if *local {
		*bindAddr = "127.0.0.1"
	} else {
		localIP, err := utils.GetLocalIPByInterface(*netIface)
		if err != nil {
			log.Fatalf("Failed to get local IP: %v", err)
		}
		*bindAddr = localIP
	}

	if envVal := os.Getenv("FUSION_PROFILE"); envVal != "" {
		if envVal == "1" || strings.EqualFold(envVal, "true") {
			*profile = true
		} else if envVal == "0" || strings.EqualFold(envVal, "false") {
			*profile = false
		}
	}
	if envVal := os.Getenv("FUSION_UDP_DIAGNOSTICS"); envVal != "" {
		if envVal == "1" || strings.EqualFold(envVal, "true") {
			configUDPDiagnostics = true
		} else if envVal == "0" || strings.EqualFold(envVal, "false") {
			configUDPDiagnostics = false
		}
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
		UDPDiagnostics: configUDPDiagnostics,
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

	app := app.NewApp(config)
	defer app.Close()

	if config.Profile {
		profilePath, err := app.StartCPUProfile()
		if err != nil {
			fmt.Fprintf(os.Stderr, "could not start cpu profile: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Writing CPU profile to %s\n", profilePath)
	}

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
