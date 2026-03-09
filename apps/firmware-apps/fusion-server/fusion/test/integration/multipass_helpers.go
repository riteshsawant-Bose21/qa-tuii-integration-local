//go:build integration
// +build integration

package integration

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sync"
	"time"
)

const (
	// From fusion/test/integration -> ../../../scripts/multipass (repo root scripts)
	defaultScriptsDir        = "../../../scripts/multipass"
	defaultClearConfigScript = "clear-config.sh"
	defaultRestartScript     = "restart-fusion.sh"
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
	if err := runScript(rctx, resolveScriptPath(defaultRestartScript)); err != nil {
		return err
	}
	// Allow convergence under the parent ctx
	return WaitForClusterSizeFromVIP(ctx, env, expected)
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
	return nil
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
