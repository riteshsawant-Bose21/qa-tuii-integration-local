//go:build integration
// +build integration

package integration

import (
	"context"
	"fmt"
	"fusion/internal/api"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"testing"
	"time"
)

func TestVIPMasterPriorityDemotesCurrentPrimary(t *testing.T) {
	fc := NewTestCluster(t, false)
	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
	defer cancel()

	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("initial health failed: %v", err)
	}

	devices, err := GetDevices(ctx, fc.Env.BaseURL())
	if err != nil {
		t.Fatalf("failed to get devices baseline: %v", err)
	}

	ordered := sortedDeviceIDs(devices)
	if err := setAllMasterDefault(ctx, fc.Env.BaseURL(), ordered); err != nil {
		t.Fatalf("failed to set all nodes default: %v", err)
	}
	defer func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 45*time.Second)
		defer cleanupCancel()
		for _, id := range ordered {
			_ = setMasterPriority(cleanupCtx, fc.Env.BaseURL(), id, true)
		}
	}()

	primaryNode, err := fc.Primary()
	if err != nil {
		t.Fatalf("failed to identify primary: %v", err)
	}
	primary := primaryNode.Device

	for _, d := range devices {
		if d.Id == primary.Id {
			continue
		}
		if err := setMasterPriority(ctx, fc.Env.BaseURL(), d.Id, true); err != nil {
			t.Fatalf("failed to normalize follower id=%s to mode=high: %v", d.Id, err)
		}
	}

	t.Logf("demoting current primary id=%s addr=%s priority=%d", primary.Id, primary.Address, primary.VrrpPriority)
	if err := setMasterPriority(ctx, fc.Env.BaseURL(), primary.Id, false); err != nil {
		t.Fatalf("set master priority low failed: %v", err)
	}
	settled, err := waitForDevices(ctx, fc.Env.BaseURL(), func(ds []api.DeviceInfo) bool {
		if len(ds) != len(devices) {
			return false
		}
		if !hasSinglePrimary(ds) {
			return false
		}

		currentPrimary, pErr := findPrimary(ds)
		if pErr != nil {
			return false
		}
		if currentPrimary.Id == primary.Id {
			return false
		}

		demoted, found := findDeviceByID(ds, primary.Id)
		if !found {
			return false
		}
		if demoted.IsPrimaryNode {
			return false
		}

		newPrimary, npErr := findPrimary(ds)
		if npErr != nil {
			return false
		}
		return demoted.VrrpPriority < newPrimary.VrrpPriority
	})
	if err != nil {
		t.Fatalf("cluster did not settle after demoting current primary: %v", err)
	}

	demoted, found := findDeviceByID(settled, primary.Id)
	if !found {
		t.Fatalf("demoted node %s disappeared from devices payload", primary.Id)
	}
	if demoted.IsPrimaryNode {
		t.Fatalf("demoted node remained primary: %+v", demoted)
	}

	newPrimary, err := findPrimary(settled)
	if err != nil {
		t.Fatalf("no primary after demotion: %v", err)
	}
	if newPrimary.Id == primary.Id {
		t.Fatalf("expected primary handover, still primary=%s", primary.Id)
	}
	if demoted.VrrpPriority >= newPrimary.VrrpPriority {
		t.Fatalf("expected demoted priority lower than new primary: demoted=%d primary=%d", demoted.VrrpPriority, newPrimary.VrrpPriority)
	}
}

func TestVIPMasterPrioritySinglePreferredNodeBecomesPrimary(t *testing.T) {
	fc := NewTestCluster(t, false)
	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
	defer cancel()

	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("initial health failed: %v", err)
	}

	baseline, err := GetDevices(ctx, fc.Env.BaseURL())
	if err != nil {
		t.Fatalf("failed to get baseline devices: %v", err)
	}

	ordered := sortedDeviceIDs(baseline)
	if err := setAllMasterDefault(ctx, fc.Env.BaseURL(), ordered); err != nil {
		t.Fatalf("failed to set all nodes default: %v", err)
	}

	currentPrimaryNode, err := fc.Primary()
	if err != nil {
		t.Fatalf("failed to identify current primary: %v", err)
	}
	currentPrimary := currentPrimaryNode.Device

	target, err := pickNonPrimaryTarget(baseline)
	if err != nil {
		t.Fatalf("failed to pick target device: %v", err)
	}
	if target.Id == currentPrimary.Id {
		t.Fatalf("target should be non-primary, got current primary id=%s", target.Id)
	}

	for _, id := range ordered {
		modeValue := "default"
		if id == target.Id {
			modeValue = "high"
		}
		if err := setMasterPriorityByMode(ctx, fc.Env.BaseURL(), id, modeValue); err != nil {
			t.Fatalf("set master priority id=%s mode=%q failed: %v", id, modeValue, err)
		}
	}

	defer func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 45*time.Second)
		defer cleanupCancel()
		for _, id := range ordered {
			_ = setMasterPriority(cleanupCtx, fc.Env.BaseURL(), id, true)
		}
	}()

	settled, err := waitForDevices(ctx, fc.Env.BaseURL(), func(ds []api.DeviceInfo) bool {
		if len(ds) != len(baseline) {
			return false
		}
		if !hasSinglePrimary(ds) {
			return false
		}

		targetAfter, found := findDeviceByID(ds, target.Id)
		if !found {
			return false
		}
		if !targetAfter.IsPrimaryNode {
			return false
		}

		for _, d := range ds {
			if d.Id == target.Id {
				continue
			}
			if targetAfter.VrrpPriority <= d.VrrpPriority {
				return false
			}
		}
		return true
	})
	if err != nil {
		t.Fatalf("cluster did not settle to single preferred primary: %v", err)
	}

	finalPrimary, err := findPrimary(settled)
	if err != nil {
		t.Fatalf("failed to determine final primary: %v", err)
	}
	if finalPrimary.Id != target.Id {
		t.Fatalf("expected target %s to become primary, got %s", target.Id, finalPrimary.Id)
	}

	for _, d := range settled {
		if d.Id == "" || d.Address == "" {
			t.Fatalf("invalid devices payload for node: %+v", d)
		}
		if d.VrrpPriority < 1 {
			t.Fatalf("expected positive vrrp_priority for %s, got %d", d.Id, d.VrrpPriority)
		}
	}
}

func TestVIPMasterPriorityInvalidModeValues(t *testing.T) {
	fc := NewTestCluster(t, false)
	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
	defer cancel()

	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("initial health failed: %v", err)
	}

	devices, err := GetDevices(ctx, fc.Env.BaseURL())
	if err != nil {
		t.Fatalf("failed to get devices: %v", err)
	}
	deviceID := devices[0].Id

	testCases := []struct {
		modeValue     string
		expectedCode  int
		errorContains string
	}{
		{modeValue: "", expectedCode: http.StatusNotFound},
		{modeValue: "1", expectedCode: http.StatusBadRequest, errorContains: "invalid mode value"},
		{modeValue: "0", expectedCode: http.StatusBadRequest, errorContains: "invalid mode value"},
		{modeValue: "fusion", expectedCode: http.StatusBadRequest, errorContains: "invalid mode value"},
		{modeValue: "yes", expectedCode: http.StatusBadRequest, errorContains: "invalid mode value"},
		{modeValue: "-1", expectedCode: http.StatusBadRequest, errorContains: "invalid mode value"},
		{modeValue: "HIGHH", expectedCode: http.StatusBadRequest, errorContains: "invalid mode value"},
		{modeValue: "defaultd", expectedCode: http.StatusBadRequest, errorContains: "invalid mode value"},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("mode=%q", tc.modeValue), func(t *testing.T) {
			status, body, reqErr := postMasterPriorityRaw(ctx, fc.Env.BaseURL(), deviceID, tc.modeValue)
			if reqErr != nil {
				t.Fatalf("request failed: %v", reqErr)
			}
			if status != tc.expectedCode {
				t.Fatalf("expected status=%d for mode=%q, got status=%d body=%q", tc.expectedCode, tc.modeValue, status, body)
			}
			if tc.errorContains != "" && !strings.Contains(strings.ToLower(body), tc.errorContains) {
				t.Fatalf("expected error body to contain %q, got: %q", tc.errorContains, body)
			}
		})
	}
}

func TestVIPMasterPriorityAcceptedModeValueVariants(t *testing.T) {
	fc := NewTestCluster(t, false)
	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
	defer cancel()

	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("initial health failed: %v", err)
	}

	devices, err := GetDevices(ctx, fc.Env.BaseURL())
	if err != nil {
		t.Fatalf("failed to get devices: %v", err)
	}

	target, err := pickNonPrimaryTarget(devices)
	if err != nil {
		t.Fatalf("failed to pick non-primary target: %v", err)
	}

	accepted := []string{"high", "HIGH", "Low", "default", "DEFAULT"}
	for _, modeValue := range accepted {
		t.Run(fmt.Sprintf("mode=%q", modeValue), func(t *testing.T) {
			status, body, reqErr := postMasterPriorityRaw(ctx, fc.Env.BaseURL(), target.Id, modeValue)
			if reqErr != nil {
				t.Fatalf("request failed: %v", reqErr)
			}
			if status != http.StatusNoContent {
				t.Fatalf("expected status=204 for mode=%q, got status=%d body=%q", modeValue, status, body)
			}
		})
	}

	cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cleanupCancel()
	if err := setMasterPriority(cleanupCtx, fc.Env.BaseURL(), target.Id, true); err != nil {
		t.Fatalf("cleanup failed for target id=%s: %v", target.Id, err)
	}
}

func setMasterPriority(ctx context.Context, baseURL, deviceID string, high bool) error {
	modeValue := "low"
	if high {
		modeValue = "high"
	}
	return setMasterPriorityByMode(ctx, baseURL, deviceID, modeValue)
}

func setMasterPriorityByMode(ctx context.Context, baseURL, deviceID, modeValue string) error {
	status, body, err := postMasterPriorityRaw(ctx, baseURL, deviceID, modeValue)
	if err != nil {
		return err
	}
	if status != http.StatusNoContent {
		return fmt.Errorf("unexpected status %d for mode=%q body=%q", status, modeValue, body)
	}
	return nil
}

func setMasterPriorityDefault(ctx context.Context, baseURL, deviceID string) error {
	return setMasterPriorityByMode(ctx, baseURL, deviceID, "default")
}

func setAllMasterDefault(ctx context.Context, baseURL string, deviceIDs []string) error {
	for _, id := range deviceIDs {
		if err := setMasterPriorityDefault(ctx, baseURL, id); err != nil {
			return fmt.Errorf("set master priority id=%s mode=default failed: %w", id, err)
		}
	}
	return nil
}

func postMasterPriorityRaw(ctx context.Context, baseURL, deviceID, modeValue string) (int, string, error) {
	endpoint := fmt.Sprintf("%s/devices/%s/vip/master-priority/%s", baseURL, url.PathEscape(deviceID), url.PathEscape(modeValue))
	return doPostNoBody(ctx, endpoint)
}

func doPostNoBody(ctx context.Context, endpoint string) (int, string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, nil)
	if err != nil {
		return 0, "", err
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return 0, "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	return resp.StatusCode, string(body), nil
}

func waitForDevices(ctx context.Context, baseURL string, predicate func([]api.DeviceInfo) bool) ([]api.DeviceInfo, error) {
	var latest []api.DeviceInfo
	err := PollUntil(ctx, 2*time.Second, func() (bool, error) {
		ds, err := GetDevices(ctx, baseURL)
		if err != nil {
			return false, nil
		}
		latest = ds
		return predicate(ds), nil
	})
	if err != nil {
		return latest, err
	}
	return latest, nil
}

func findPrimary(ds []api.DeviceInfo) (api.DeviceInfo, error) {
	count := 0
	var primary api.DeviceInfo
	for _, d := range ds {
		if d.IsPrimaryNode {
			count++
			primary = d
		}
	}
	if count != 1 {
		return api.DeviceInfo{}, fmt.Errorf("expected exactly one primary, got %d", count)
	}
	return primary, nil
}

func findDeviceByID(ds []api.DeviceInfo, id string) (api.DeviceInfo, bool) {
	for _, d := range ds {
		if d.Id == id {
			return d, true
		}
	}
	return api.DeviceInfo{}, false
}

func pickNonPrimaryTarget(ds []api.DeviceInfo) (api.DeviceInfo, error) {
	candidates := make([]api.DeviceInfo, 0, len(ds))
	for _, d := range ds {
		if !d.IsPrimaryNode {
			candidates = append(candidates, d)
		}
	}
	if len(candidates) == 0 {
		return api.DeviceInfo{}, fmt.Errorf("no non-primary device available")
	}
	sort.Slice(candidates, func(i, j int) bool { return candidates[i].Id < candidates[j].Id })
	return candidates[0], nil
}

func sortedDeviceIDs(ds []api.DeviceInfo) []string {
	ids := make([]string, 0, len(ds))
	for _, d := range ds {
		ids = append(ids, d.Id)
	}
	sort.Strings(ids)
	return ids
}
