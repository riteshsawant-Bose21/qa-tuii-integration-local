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
	"gateway/internal/api"
	"gateway/internal/app"
	"gateway/internal/version"
)

const (
	baseName   = "fusion-gateway"
	numberBase = 36
)

// parseFlags parses and validates command-line flags.
func parseFlags() *api.AppConfig {
	versionFlag := flag.Bool("version", false, "Show version information")
	bindAddr := flag.String("bind-addr", "0.0.0.0", "Bind address for cluster communication")
	bindPort := flag.Int("bind-port", 7946, "Bind port for cluster communication (default 7946)")
	publicPort := flag.String("public-port", "18080", "Listen port for public HTTP API")
	adminPort := flag.String("admin-port", "19090", "Listen port for private/admin HTTP API")
	netIface := flag.String("net-iface", "eth0", "Network interface for VRRP monitoring")
	local := flag.Bool("local", false, "Run in local-only mode (no clustering)")
	verbose := flag.Bool("verbose", false, "Enable verbose logging")
	profile := flag.Bool("profile", false, "Enable profile dump")
	publicUpstream := flag.String("public-upstream", "http://127.0.0.1:8080", "Upstream URL for public HTTP proxy")
	privateUpstream := flag.String("private-upstream", "http://127.0.0.1:9090", "Upstream URL for private/admin HTTP proxy")
	publicUpstreamFromVRRP := flag.Bool("public-upstream-from-vrrp", false, "Discover public upstream VIP from VRRP advertisements")
	publicUpstreamVRRPTimeoutSec := flag.Int("public-upstream-vrrp-timeout-sec", 3, "Seconds to wait for a VRRP advertisement when discovering upstream VIP")
	flag.Parse()

	// Read environment overrides
	if envVal := os.Getenv("FUSION_NET_IFACE"); envVal != "" {
		*netIface = envVal
	}
	if envVal := os.Getenv("FUSION_PUBLIC_PORT"); envVal != "" {
		*publicPort = envVal
	}
	if envVal := os.Getenv("FUSION_ADMIN_PORT"); envVal != "" {
		*adminPort = envVal
	}

	if envVal := os.Getenv("FUSION_PROFILE"); envVal != "" {
		if envVal == "1" || strings.EqualFold(envVal, "true") {
			*profile = true
		} else if envVal == "0" || strings.EqualFold(envVal, "false") {
			*profile = false
		}
	}
	if envVal := os.Getenv("FUSION_PUBLIC_UPSTREAM"); envVal != "" {
		*publicUpstream = envVal
	}
	if envVal := os.Getenv("FUSION_PRIVATE_UPSTREAM"); envVal != "" {
		*privateUpstream = envVal
	}
	if envVal := os.Getenv("FUSION_PUBLIC_UPSTREAM_FROM_VRRP"); envVal != "" {
		if envVal == "1" || strings.EqualFold(envVal, "true") {
			*publicUpstreamFromVRRP = true
		} else if envVal == "0" || strings.EqualFold(envVal, "false") {
			*publicUpstreamFromVRRP = false
		}
	}
	if envVal := os.Getenv("FUSION_PUBLIC_UPSTREAM_VRRP_TIMEOUT_SEC"); envVal != "" {
		if parsed, err := strconv.Atoi(envVal); err == nil && parsed > 0 {
			*publicUpstreamVRRPTimeoutSec = parsed
		}
	}

	if *versionFlag {
		// This must be a log.Printf. The server logger is not running yet.
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", version.Version, version.Commit, version.BuildTime)
		os.Exit(0)
	}

	return &api.AppConfig{
		NodeName:                     createUniqueNodeName(baseName),
		BindAddr:                     *bindAddr,
		BindPort:                     *bindPort,
		PublicPort:                   *publicPort,
		AdminPort:                    *adminPort,
		NetIface:                     *netIface,
		Local:                        *local,
		Verbose:                      *verbose,
		Profile:                      *profile,
		PublicUpstreamFromVRRP:       *publicUpstreamFromVRRP,
		PublicUpstreamVRRPTimeoutSec: *publicUpstreamVRRPTimeoutSec,
		UpstreamPublicURL:            *publicUpstream,
		UpstreamPrivateURL:           *privateUpstream,
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
		profilePath := filepath.Join("/tmp", fmt.Sprintf("fusion_gateway_cpu_%s.prof", timestamp))

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
