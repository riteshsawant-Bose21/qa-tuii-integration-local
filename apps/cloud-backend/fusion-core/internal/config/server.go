package config

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
)

// Server holds the configuration settings for server binding.
type Server struct {
	APIHost  string
	APIPort  string
	SyncPort string
}

const (
	keySyncPort string = "SYNC_PORT"
)

// Server retrieves the server configuration from the store.
func (p *Service) Server() (*Server, error) {
	fmt.Printf("[DEBUG] Retrieving server configuration...\n")

	fmt.Printf("[DEBUG] Looking up API_HOST...\n")
	apiHost, err := p.store.ReqString(environment.API.Host)
	if err != nil {
		fmt.Printf("[ERROR] Failed to get API_HOST: %v\n", err)
		return nil, fmt.Errorf("API_HOST environment variable is required")
	}
	fmt.Printf("[DEBUG] API_HOST = '%s'\n", apiHost)

	fmt.Printf("[DEBUG] Looking up API_PORT...\n")
	apiPort, err := p.store.ReqString(environment.API.Port)
	if err != nil {
		fmt.Printf("[ERROR] Failed to get API_PORT: %v\n", err)
		return nil, fmt.Errorf("API_PORT environment variable is required")
	}
	fmt.Printf("[DEBUG] API_PORT = '%s'\n", apiPort)

	fmt.Printf("[DEBUG] Looking up SYNC_PORT...\n")
	syncPort, err := p.store.ReqString(keySyncPort)
	if err != nil {
		fmt.Printf("[ERROR] Failed to get SYNC_PORT: %v\n", err)
		return nil, fmt.Errorf("SYNC_PORT environment variable is required")
	}
	fmt.Printf("[DEBUG] SYNC_PORT = '%s'\n", syncPort)

	server := &Server{
		APIHost:  apiHost,
		APIPort:  apiPort,
		SyncPort: syncPort,
	}

	fmt.Printf("[DEBUG] Server configuration retrieved successfully\n")
	return server, nil
}
