package stresstester

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"slices"
	"strings"
	"time"

	json "github.com/goccy/go-json"
)

const defaultProfilePort = "9090"

type profilerResponse struct {
	Active       bool   `json:"active"`
	Path         string `json:"path"`
	LastHeapPath string `json:"last_heap_path"`
}

func defaultProfileHosts(cfg Config) []string {
	hosts := make([]string, 0, len(cfg.WSListenerHosts)+3)
	hosts = append(hosts, cfg.WriterHost)
	hosts = append(hosts, cfg.WSListenerHosts...)
	if cfg.UDPServerHost != "" {
		hosts = append(hosts, cfg.UDPServerHost)
	}

	out := make([]string, 0, len(hosts))
	seen := make(map[string]struct{}, len(hosts))
	for _, host := range hosts {
		profileHost, ok := profileHostForTarget(host)
		if !ok {
			continue
		}
		if _, exists := seen[profileHost]; exists {
			continue
		}
		seen[profileHost] = struct{}{}
		out = append(out, profileHost)
	}
	slices.Sort(out)
	return out
}

func profileHostForTarget(target string) (string, bool) {
	host, _, err := net.SplitHostPort(target)
	if err != nil {
		if strings.Contains(err.Error(), "missing port in address") && target != "" {
			return net.JoinHostPort(target, defaultProfilePort), true
		}
		return "", false
	}
	if host == "" {
		return "", false
	}
	return net.JoinHostPort(host, defaultProfilePort), true
}

func runProfiling(cfg Config, result *RunResult) func() error {
	if !cfg.EnableProfiling {
		return func() error { return nil }
	}

	hosts := cfg.ProfileHosts
	if len(hosts) == 0 {
		hosts = defaultProfileHosts(cfg)
	}
	result.ProfileResults = make([]ProfileResult, 0, len(hosts))
	if len(hosts) == 0 {
		result.ProfileResults = append(result.ProfileResults, ProfileResult{
			StartError: "profiling enabled but no profile hosts could be inferred",
		})
		return func() error { return nil }
	}

	client := &http.Client{Timeout: 5 * time.Second}
	logNormal(cfg.Verbosity, "Starting CPU profiling on %d target(s)...", len(hosts))
	for _, host := range hosts {
		pr := ProfileResult{Host: host}
		resp, err := postProfiler(client, host, "/debug/profile/start")
		if err != nil {
			pr.StartError = err.Error()
			logNormal(cfg.Verbosity, "  profile start failed for %s: %v", host, err)
		} else {
			pr.Started = true
			pr.Active = resp.Active
			pr.Path = resp.Path
			logVerbose(cfg.Verbosity, "  profile started on %s: %s", host, resp.Path)
		}
		result.ProfileResults = append(result.ProfileResults, pr)
	}

	return func() error {
		var errs []string
		logNormal(cfg.Verbosity, "Stopping CPU profiling...")
		for i := range result.ProfileResults {
			pr := &result.ProfileResults[i]
			if pr.Host == "" {
				continue
			}
			resp, err := postProfiler(client, pr.Host, "/debug/profile/stop")
			if err != nil {
				pr.StopError = err.Error()
				errs = append(errs, fmt.Sprintf("%s: %v", pr.Host, err))
				logNormal(cfg.Verbosity, "  profile stop failed for %s: %v", pr.Host, err)
				continue
			}
			pr.Stopped = true
			pr.Active = resp.Active
			if resp.Path != "" {
				pr.Path = resp.Path
			}
			logVerbose(cfg.Verbosity, "  profile stopped on %s: %s", pr.Host, pr.Path)
		}
		if len(errs) > 0 {
			return fmt.Errorf("stop cpu profiling: %s", strings.Join(errs, "; "))
		}
		return nil
	}
}

func postProfiler(client *http.Client, host, path string) (profilerResponse, error) {
	var out profilerResponse
	u := url.URL{Scheme: "http", Host: host, Path: path}
	req, err := http.NewRequest(http.MethodPost, u.String(), nil)
	if err != nil {
		return out, fmt.Errorf("build request: %w", err)
	}
	resp, err := client.Do(req)
	if err != nil {
		return out, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return out, fmt.Errorf("unexpected status %s", resp.Status)
	}
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return out, fmt.Errorf("decode response: %w", err)
	}
	return out, nil
}
