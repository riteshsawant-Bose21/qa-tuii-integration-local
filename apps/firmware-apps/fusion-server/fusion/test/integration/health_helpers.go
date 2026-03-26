//go:build integration
// +build integration

package integration

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"fusion/internal/api"
	"net/http"
	"sort"
	"time"
)

// CheckClusterHealth performs basic health validation.
// It currently checks that the cluster has at least expectedSize members
// and exactly one primary. If expectedSize is 0, it checks that the VIP is unreachable.

func CheckClusterHealth(ctx context.Context, env Env, expectedSize int) error {
	var errs []error

	if expectedSize <= 0 {
		// Expect VIP to be unreachable. Try a lightweight GET and treat success as failure.
		req, _ := http.NewRequestWithContext(ctx, http.MethodGet, env.BaseURL()+"/cluster/members", nil)
		if req != nil {
			resp, err := httpClient.Do(req)
			if err == nil && resp != nil {
				resp.Body.Close()
				errs = append(errs, errors.New("VIP responded while expectedSize=0"))
			}
		}
		if len(errs) > 0 {
			return combineErrors(errs)
		}
		return nil
	}

	// 1. Node-first reachability (/cluster/status should be 200 on any node; VIP last fallback)
	func() {
		if err := checkClusterStatusNodePreferred(ctx, env); err != nil {
			errs = append(errs, err)
		}
	}()

	// 2. Devices: query nodes directly first; use VIP only as fallback.
	devices, err := GetDevicesNodePreferred(ctx, env)
	if err != nil {
		errs = append(errs, fmt.Errorf("get devices: %w", err))
	} else {
		if len(devices) != expectedSize {
			errs = append(errs, fmt.Errorf("devices count %d != expected %d", len(devices), expectedSize))
		}
		primaries := 0
		for _, d := range devices {
			if d.IsPrimaryNode {
				primaries++
			}
		}
		if primaries != 1 {
			errs = append(errs, fmt.Errorf("primary count %d != 1", primaries))
		}
	}

	// 4. Fast primary election sanity (within small timeout if first node only)
	if expectedSize == 1 {
		// Poll briefly for a single primary if not already detected.
		if !hasSinglePrimary(devices) {
			innerCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
			defer cancel()
			_ = PollUntil(innerCtx, 500*time.Millisecond, func() (bool, error) {
				ds, e := GetDevicesNodePreferred(innerCtx, env)
				if e != nil {
					return false, nil
				}
				if hasSinglePrimary(ds) {
					return true, nil
				}
				return false, nil
			})
			// Re-evaluate after polling.
			ds2, e2 := GetDevicesNodePreferred(ctx, env)
			if e2 != nil || !hasSinglePrimary(ds2) {
				errs = append(errs, errors.New("primary not established for single-node cluster within timeout"))
			}
		}
	}

	if len(errs) > 0 {
		return combineErrors(errs)
	}
	return nil
}

func nodeBaseURLs(ctx context.Context, env Env) []string {
	ipToInstance, err := GetMultipassInstances(ctx)
	if err != nil {
		return nil
	}

	seen := make(map[string]struct{})
	urls := make([]string, 0, len(ipToInstance))
	for ip := range ipToInstance {
		if ip == "" || ip == env.VIP {
			continue
		}
		if _, ok := seen[ip]; ok {
			continue
		}
		seen[ip] = struct{}{}
		urls = append(urls, fmt.Sprintf("http://%s:%s", ip, env.Port))
	}
	sort.Strings(urls)
	return urls
}

func GetDevicesNodePreferred(ctx context.Context, env Env) ([]api.DeviceInfo, error) {
	var firstErr error
	for _, baseURL := range nodeBaseURLs(ctx, env) {
		ds, err := GetDevices(ctx, baseURL)
		if err == nil {
			return ds, nil
		}
		if firstErr == nil {
			firstErr = err
		}
	}

	ds, err := GetDevices(ctx, env.BaseURL())
	if err == nil {
		return ds, nil
	}
	if firstErr != nil {
		return nil, fmt.Errorf("node-first devices query failed (node=%v, vip=%w)", firstErr, err)
	}
	return nil, err
}

func checkClusterStatusNodePreferred(ctx context.Context, env Env) error {
	var firstErr error
	for _, baseURL := range nodeBaseURLs(ctx, env) {
		if err := checkClusterStatus(ctx, baseURL); err == nil {
			return nil
		} else if firstErr == nil {
			firstErr = err
		}
	}

	if err := checkClusterStatus(ctx, env.BaseURL()); err != nil {
		if firstErr != nil {
			return fmt.Errorf("cluster status failed (node=%v, vip=%w)", firstErr, err)
		}
		return err
	}

	return nil
}

func checkClusterStatus(ctx context.Context, baseURL string) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, baseURL+"/cluster/status", nil)
	if err != nil {
		return fmt.Errorf("cluster status request build: %w", err)
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("cluster status request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("%s/cluster/status status=%d", baseURL, resp.StatusCode)
	}

	return nil
}

func hasSinglePrimary(ds []api.DeviceInfo) bool {
	count := 0
	for _, d := range ds {
		if d.IsPrimaryNode {
			count++
		}
	}
	return count == 1
}

func combineErrors(errs []error) error {
	if len(errs) == 0 {
		return nil
	}
	msg := "cluster health violations:"
	for _, e := range errs {
		msg += "\n - " + e.Error()
	}
	return errors.New(msg)
}

// GetDevices fetches devices from the VIP.
func GetDevices(ctx context.Context, baseURL string) ([]api.DeviceInfo, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, baseURL+"/devices", nil)
	if err != nil {
		return nil, err
	}
	resp, err := httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("devices status=%d", resp.StatusCode)
	}
	var ds []api.DeviceInfo
	if err := json.NewDecoder(resp.Body).Decode(&ds); err != nil {
		return nil, err
	}
	return ds, nil
}

func (fc FusionCluster) WaitForClusterSize(ctx context.Context, n int) error {
	return PollUntil(ctx, 1*time.Second, func() (bool, error) {
		devices, err := GetDevicesNodePreferred(ctx, fc.Env)
		if err != nil {
			return false, nil
		}
		if len(devices) >= n {
			return true, nil
		}

		return false, nil
	})
}
