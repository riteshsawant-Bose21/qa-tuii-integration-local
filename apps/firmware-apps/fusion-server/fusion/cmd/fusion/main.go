package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"os"
	"runtime/debug"
	"strconv"
	"time"

	"fusion/internal/api"
	"fusion/internal/app"
	"fusion/internal/logging"
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
	local := flag.Bool("local", false, "Run in local-only mode (no clustering)")
	verbose := flag.Bool("verbose", false, "Enable verbose logging")
	flag.Parse()

	if *versionFlag {
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", version.Version, version.Commit, version.BuildTime)
		os.Exit(0)
	}

	return &api.AppConfig{
		NodeName: createUniqueNodeName(baseName),
		BindAddr: *bindAddr,
		BindPort: *bindPort,
		Local:    *local,
		Verbose:  *verbose,
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
		// Log panics with a stack trace and exit
		if r := recover(); r != nil {
			logging.GetLogger().Fatal("PANIC: %v\n%s", r, debug.Stack())
		}
	}()

	config := parseFlags()

	app := app.NewApp(config)
	defer app.Close()
	app.Start()
}
