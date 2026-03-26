//go:build integration
// +build integration

package integration

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"time"
)

const (
	// From fusion/test/integration -> ../../../scripts/multipass (repo root scripts)
	defaultScriptsDir        = "../../../scripts/multipass"
	defaultClearConfigScript = "clear-config.sh"
	defaultRestartPrefix     = "fusion"
)

// MultipassInstance represents an instance entry from `multipass list --format json`.
type MultipassInstance struct {
	Name string   `json:"name"`
	IPv4 []string `json:"ipv4"`
}

func ResetCluster(ctx context.Context, env Env) error {

	rctx, cancel := context.WithTimeout(ctx, 4*time.Minute)
	defer cancel()
	if err := runScript(rctx, resolveScriptPath(defaultClearConfigScript)); err != nil {

		return fmt.Errorf("failed to execute reset script %v", err)

	}
	return nil
}

// RestartCluster restarts fusion-server instances via multipass script and waits for cluster size.
func RestartCluster(ctx context.Context, env Env, expected int) error {
	rctx, cancel := context.WithTimeout(ctx, 4*time.Minute)
	defer cancel()

	names, err := getMultipassInstanceNamesByPrefix(rctx, defaultRestartPrefix)
	if err != nil {
		return err
	}
	if len(names) == 0 {
		return fmt.Errorf("no multipass instances found with prefix %q", defaultRestartPrefix)
	}

	if err := StopInstancesParallel(rctx, names, 3); err != nil {
		fmt.Printf("[integration] warning: stop errors during restart (continuing): %v\n", err)
	}

	if err := StartInstancesParallel(rctx, names, 3); err != nil {
		return err
	}
	// Allow convergence under the parent ctx
	return (FusionCluster{Env: env}).WaitForClusterSize(ctx, expected)
}

func getMultipassInstanceNamesByPrefix(ctx context.Context, prefix string) ([]string, error) {
	cmd := exec.CommandContext(ctx, "multipass", "list", "--format", "json")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("multipass list failed: %v; output: %s", err, string(out))
	}

	var payload struct {
		List []struct {
			Name string `json:"name"`
		} `json:"list"`
	}
	if err := json.Unmarshal(out, &payload); err != nil {
		return nil, fmt.Errorf("parse multipass list json failed: %v", err)
	}

	names := make([]string, 0, len(payload.List))
	for _, inst := range payload.List {
		if inst.Name == "" {
			continue
		}
		if strings.HasPrefix(inst.Name, prefix) {
			names = append(names, inst.Name)
		}
	}

	sort.Strings(names)
	return names, nil
}

// StopInstancesParallel stops instances concurrently up to maxParallel.
func StopInstancesParallel(ctx context.Context, names []string, maxParallel int) error {
	if maxParallel <= 0 {
		maxParallel = 3
	}
	sem := make(chan struct{}, maxParallel) //Why do we have a semaphore here??
	var wg sync.WaitGroup
	errCh := make(chan error, len(names))
	for _, n := range names {
		name := n
		if name == "" {
			continue
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			if err := StopInstance(ctx, name); err != nil {
				errCh <- err
			}
		}()
	}
	wg.Wait()
	close(errCh)
	var errs []error
	for e := range errCh {
		errs = append(errs, e)
	}
	if len(errs) > 0 {
		return fmt.Errorf("parallel stop errors: %v", errs)
	}
	return nil
}

// StartInstancesParallel starts instances concurrently up to maxParallel.
func StartInstancesParallel(ctx context.Context, names []string, maxParallel int) error {
	if maxParallel <= 0 {
		maxParallel = 3
	}
	sem := make(chan struct{}, maxParallel)
	var wg sync.WaitGroup
	errCh := make(chan error, len(names))
	for _, n := range names {
		name := n
		if name == "" {
			continue
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			if err := StartInstance(ctx, name); err != nil {
				errCh <- err
			}
		}()
	}
	wg.Wait()
	close(errCh)
	var errs []error
	for e := range errCh {
		errs = append(errs, e)
	}
	if len(errs) > 0 {
		return fmt.Errorf("parallel start errors: %v", errs)
	}
	return nil
}

// StopInstance stops a specific Multipass instance by name.
func StopInstance(ctx context.Context, name string) error {
	if name == "" {
		return fmt.Errorf("instance name is empty")
	}
	cmd := exec.CommandContext(ctx, "multipass", "stop", name)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("multipass stop %s failed: %v; output: %s", name, err, string(out))
	}
	return nil
}

// StartInstance starts a specific Multipass instance by name.
func StartInstance(ctx context.Context, name string) error {
	if name == "" {
		return fmt.Errorf("instance name is empty")
	}
	cmd := exec.CommandContext(ctx, "multipass", "start", name)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("multipass start %s failed: %v; output: %s", name, err, string(out))
	}

	env := LoadEnv()
	if err := waitForInstanceReady(ctx, name, env); err != nil {
		return fmt.Errorf("instance %s did not become ready after start: %w", name, err)
	}
	return nil
}

func waitForInstanceReady(ctx context.Context, name string, env Env) error {
	var instanceIPs []string

	if err := PollUntil(ctx, 1*time.Second, func() (bool, error) {
		ips, err := getRunningInstanceIPv4(ctx, name)
		if err != nil {
			return false, nil
		}
		if len(ips) == 0 {
			return false, nil
		}
		instanceIPs = prioritizeNodeIPs(ips, env.VIP)
		return true, nil
	}); err != nil {
		return fmt.Errorf("timed out waiting for running state/IP: %w", err)
	}

	if err := PollUntil(ctx, 1*time.Second, func() (bool, error) {
		for _, ip := range instanceIPs {
			ok, err := isNodeServiceReady(ctx, ip, env.Port)
			if err == nil && ok {
				return true, nil
			}
		}
		return false, nil
	}); err != nil {
		return fmt.Errorf("timed out waiting for node service health on %v: %w", instanceIPs, err)
	}

	return nil
}

func getRunningInstanceIPv4(ctx context.Context, name string) ([]string, error) {
	cmd := exec.CommandContext(ctx, "multipass", "info", name, "--format", "json")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("multipass info %s failed: %v; output: %s", name, err, string(out))
	}

	var payload struct {
		Info map[string]struct {
			State string   `json:"state"`
			IPv4  []string `json:"ipv4"`
		} `json:"info"`
	}

	if err := json.Unmarshal(out, &payload); err != nil {
		return nil, fmt.Errorf("parse multipass info for %s failed: %w", name, err)
	}

	entry, ok := payload.Info[name]
	if !ok {
		return nil, fmt.Errorf("instance %s not found in multipass info", name)
	}

	if !strings.EqualFold(entry.State, "running") {
		return nil, fmt.Errorf("instance %s state=%s", name, entry.State)
	}

	return entry.IPv4, nil
}

func prioritizeNodeIPs(ips []string, vip string) []string {
	out := make([]string, 0, len(ips))
	for _, ip := range ips {
		if ip == "" || ip == vip {
			continue
		}
		out = append(out, ip)
	}
	if len(out) == 0 {
		for _, ip := range ips {
			if ip != "" {
				out = append(out, ip)
			}
		}
	}
	sort.Strings(out)
	return out
}

func isNodeServiceReady(ctx context.Context, ip, port string) (bool, error) {
	url := fmt.Sprintf("http://%s:%s/cluster/status", ip, port)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return false, err
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK, nil
}

// GetMultipassInstances returns map from IP -> instance name for quick resolution.
func GetMultipassInstances(ctx context.Context) (map[string]string, error) {
	cmd := exec.CommandContext(ctx, "multipass", "list", "--format", "json")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("multipass list failed: %v; output: %s", err, string(out))
	}
	// fmt.Printf("[integration_tests] multipass list json: %s\n", string(out))
	var payload struct {
		List []MultipassInstance `json:"list"`
	}
	if err := json.Unmarshal(out, &payload); err != nil {
		return nil, fmt.Errorf("parse multipass list json failed: %v", err)
	}
	m := make(map[string]string)
	for _, inst := range payload.List {
		for _, ip := range inst.IPv4 {
			m[ip] = inst.Name
		}
	}
	// If list didn't provide IPs, probe each instance with 'multipass info'
	if len(m) == 0 && len(payload.List) > 0 {
		for _, inst := range payload.List {
			name := inst.Name
			infoCmd := exec.CommandContext(ctx, "multipass", "info", name, "--format", "json")
			infoOut, infoErr := infoCmd.CombinedOutput()
			if infoErr != nil {
				fmt.Printf("[integration] multipass info %s failed: %v; output: %s\n", name, infoErr, string(infoOut))
				continue
			}
			// fmt.Printf("[integration] multipass info %s json: %s\n", name, string(infoOut))
			var info struct {
				Info map[string]struct {
					IPv4 []string `json:"ipv4"`
				} `json:"info"`
			}
			if jsonErr := json.Unmarshal(infoOut, &info); jsonErr != nil {
				fmt.Printf("[integration] parse info json failed for %s: %v\n", name, jsonErr)
				continue
			}
			if entry, ok := info.Info[name]; ok {
				for _, ip := range entry.IPv4 {
					m[ip] = name
				}
			}
		}
	}
	// fmt.Printf("[integration] resolved IP->instance map: %+v\n", m)
	return m, nil
}

func runScript(ctx context.Context, script string) error {

	// Ensure absolute path and existence
	abs, err := filepath.Abs(script)
	if err != nil {
		return err
	}
	if _, statErr := os.Stat(abs); statErr != nil {
		return fmt.Errorf("script not found: %s (%v)", abs, statErr)
	}
	cmd := exec.CommandContext(ctx, "/bin/bash", abs)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("script failed: %s: %v; output: %s", abs, err, string(out))
	}
	return nil
}

// resolveScriptPath builds the script path relative to this file, unless overridden.
func resolveScriptPath(scriptName string) string {

	// Determine this file's directory to safely resolve relative path
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		// Fallback to default relative path
		return filepath.Join(defaultScriptsDir, scriptName)
	}
	base := filepath.Dir(thisFile)
	return filepath.Join(base, defaultScriptsDir, scriptName)
}
