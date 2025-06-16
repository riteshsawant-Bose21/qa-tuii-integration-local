package main

import (
	"flag"
	"log"
	"os"

	"fusion/internal/api"
	"fusion/internal/app"
	"fusion/internal/version"
)

// parseFlags parses and validates command-line flags.
func parseFlags() *api.AppConfig {
	versionFlag := flag.Bool("version", false, "Show version information")
	nodeName := flag.String("name", "", "Node name (must be unique in cluster)")
	bindAddr := flag.String("bind-addr", "0.0.0.0", "Bind address for cluster communication")
	bindPort := flag.Int("bind-port", 7946, "Bind port for cluster communication (default 7946)")
	local := flag.Bool("local", false, "Run in local-only mode (no clustering)")
	verbose := flag.Bool("verbose", false, "Enable verbose logging")
	flag.Parse()

	if *versionFlag {
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", version.Version, version.Commit, version.BuildTime)
		os.Exit(0)
	}

	if *nodeName == "" {
		log.Fatal("Node name is required")
	}

	return &api.AppConfig{
		NodeName: *nodeName,
		BindAddr: *bindAddr,
		BindPort: *bindPort,
		Local:    *local,
		Verbose:  *verbose,
	}
}

func main() {

	config := parseFlags()

	app := app.NewApp(config)
	defer app.Close()
	app.Start()
}
