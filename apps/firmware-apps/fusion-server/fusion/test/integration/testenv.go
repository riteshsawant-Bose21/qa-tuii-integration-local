//go:build integration
// +build integration

package integration

import (
	"context"
	"net/http"
	"os"
	"strconv"
	"time"
)

// Env holds shared configuration for integration tests.
type Env struct {
	VIP       string
	Port      string
	AdminPort string
	// Timeouts
	MaxWait time.Duration
	// Desired cluster size for tests
	ClusterSize int
}

func LoadEnv() Env {
	return Env{
		VIP:         getenv("FUSION_VIP", "192.168.2.100"),
		Port:        getenv("FUSION_PORT", "8080"),
		AdminPort:   getenv("FUSION_ADMIN_PORT", "9090"),
		MaxWait:     300 * time.Second,
		ClusterSize: getenvInt("FUSION_CLUSTER_SIZE", 3),
	}
}

func (e Env) BaseURL() string  { return "http://" + e.VIP + ":" + e.Port }
func (e Env) AdminURL() string { return "http://" + e.VIP + ":" + e.AdminPort }

func getenv(k, d string) string {
	v := os.Getenv(k)
	if v == "" {
		return d
	}
	return v
}

func getenvDuration(k string, d time.Duration) time.Duration {
	v := os.Getenv(k)
	if v == "" {
		return d
	}
	// Parse as seconds if provided as integer
	if secs, err := time.ParseDuration(v); err == nil {
		return secs
	}
	return d
}

func getenvInt(k string, d int) int {
	v := os.Getenv(k)
	if v == "" {
		return d
	}
	if n, err := strconv.Atoi(v); err == nil {
		return n
	}
	return d
}

// HTTP client with sane timeout used across integration tests.
var httpClient = &http.Client{Timeout: 5 * time.Second}

// PollUntil polls fn until it returns true or context cancellation.
func PollUntil(ctx context.Context, interval time.Duration, fn func() (bool, error)) error {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			ok, err := fn()
			if ok {
				return nil
			}
			if err != nil {
				return err
			}
		}
	}
}
