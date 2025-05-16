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
	nodeName := flag.String("name", "", "Node name")
	bindAddr := flag.String("addr", "0.0.0.0", "Bind address")
	bindPort := flag.Int("port", 7946, "Bind port")
	local := flag.Bool("local", false, "Local mode")
	verbose := flag.Bool("verbose", false, "Verbose output")
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
