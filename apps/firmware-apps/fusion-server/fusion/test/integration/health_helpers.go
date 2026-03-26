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

	// 1. VIP reachability (/cluster/status should be 200)
	func() {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, env.BaseURL()+"/cluster/status", nil)
		if err != nil {
			errs = append(errs, fmt.Errorf("cluster status request build: %w", err))
			return
		}
		resp, err := httpClient.Do(req)
		if err != nil {
			errs = append(errs, fmt.Errorf("cluster status request: %w", err))
			return
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			errs = append(errs, fmt.Errorf("/cluster/status status=%d", resp.StatusCode))
		}
	}()

	// 2. Devices: exact count == expectedSize, exactly one primary
	devices, err := GetDevices(ctx, env.BaseURL())
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
				ds, e := GetDevices(innerCtx, env.BaseURL())
				if e != nil {
					return false, nil
				}
				if hasSinglePrimary(ds) {
					return true, nil
				}
				return false, nil
			})
			// Re-evaluate after polling.
			ds2, e2 := GetDevices(ctx, env.BaseURL())
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
		devices, err := GetDevices(ctx, fc.Env.BaseURL())
		if err != nil {
			// logging.GetLogger().Info("WaitForClusterSize: GetDevices error from %s: %v", env.BaseURL(), err)
			return false, err
		}
		if len(devices) >= n {
			return true, nil
		}

		return false, nil
	})
}
