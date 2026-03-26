//go:build integration
// +build integration

package integration

import (
	"context"
	"fmt"
	"fusion/internal/api"
	"sort"
	"strings"
	"testing"
	"time"
)

// FusionCluster aggregates discovered nodes with convenience helpers.
type FusionCluster struct {
	Env   Env
	Nodes []FusionNode
}

// FusionNode correlates Multipass instance, Fusion device, and cluster member.
type FusionNode struct {
	MultipassName string
	MultipassIPs  []string
	Device        api.DeviceInfo
}

// NewTestCluster builds, resets, restarts and validates a cluster for tests.
// expectedSize overrides Env.ClusterSize when >0.
func NewTestCluster(t *testing.T, withReset bool) FusionCluster {
	t.Helper()
	env := LoadEnv()
	fmt.Printf("[integration] TestEnv: %+v\n", env)
	if env.ClusterSize <= 0 {
		t.Fatalf("invalid cluster size %d in env", env.ClusterSize)
	}
	ctx, cancel := context.WithTimeout(context.Background(), env.MaxWait)
	defer cancel()
	time.Sleep(5 * time.Second)

	if withReset {
		// Reset & restart for a clean slate
		fmt.Printf("[integration] resetting cluster...\n")
		if err := ResetCluster(ctx, env); err != nil {
			t.Fatalf("cluster reset failed: %v", err)
		}
		fmt.Printf("[integration] restarting cluster...\n")
		RestartCluster(ctx, env, env.ClusterSize)
	}

	fmt.Printf("[integration] building fusion cluster mappings...\n")
	fc, err := buildFusionCluster(ctx)
	if err != nil {
		t.Fatalf("initial build cluster failed: %v", err)
	}
	// fmt.Printf("[integration] discovered cluster nodes:\n")
	// for _, n := range fc.Nodes {
	// 	fmt.Printf(" - multipass=%s ips=%v fusion=%s(%s) member=%s(%s) primary=%v\n",
	// 		n.MultipassName, n.MultipassIPs, n.FusionName, n.FusionAddr,
	// 		n.MemberName, n.MemberAddr, n.IsPrimary)
	// }

	// Refresh mappings after restart stabilization
	time.Sleep(2 * time.Second)
	if err := fc.Refresh(ctx); err != nil {
		t.Fatalf("refresh after restart failed: %v", err)
	}
	// fmt.Printf("[integration] finalized cluster nodes:\n")
	// for _, n := range fc.Nodes {
	// 	fmt.Printf(" - multipass=%s ips=%v fusion=%s(%s) member=%s(%s) primary=%v\n",
	// 		n.MultipassName, n.MultipassIPs, n.FusionName, n.FusionAddr,
	// 		n.MemberName, n.MemberAddr, n.IsPrimary)
	// }
	return fc
}

// // WaitForClusterSize waits until the cluster has at least n members.
// func WaitForClusterSize(ctx context.Context, env Env, n int) error {
// 	return PollUntil(ctx, 1*time.Second, func() (bool, error) {
// 		ms, err := GetDevices(ctx, env.BaseURL())

// 		if err != nil {
// 			return false, nil // keep retrying
// 		}
// 		return len(ms) >= n, nil
// 	})
// }

// Refresh updates the cluster's node mappings.
func (fc *FusionCluster) Refresh(ctx context.Context) error {
	nodes, err := buildNodeMappings(ctx, fc.Env)
	if err != nil {
		return err
	}
	fc.Nodes = nodes
	return nil
}

// // WaitForClusterSize waits until the cluster has at least n members.
// func (fc FusionCluster) WaitForClusterSize(ctx context.Context, env Env, n int) error {
// 	return PollUntil(ctx, 1*time.Second, func() (bool, error) {
// 		ms, err := GetDevices(ctx, env)
// 		if err != nil {
// 			return false, nil // keep retrying
// 		}
// 		return len(ms) >= n, nil
// 	})
// }

// buildFusionCluster loads env, discovers multipass instances, devices, members, and correlates to nodes.
func buildFusionCluster(ctx context.Context) (FusionCluster, error) {
	env := LoadEnv()

	const (
		maxRetries = 10
		retryDelay = 5 * time.Second
	)

	var lastErr error
	for attempt := 1; attempt <= maxRetries; attempt++ {
		nodes, err := buildNodeMappings(ctx, env)
		if err == nil {
			return FusionCluster{Env: env, Nodes: nodes}, nil
		}

		lastErr = err
		if !isTransientMappingError(err) || attempt == maxRetries {
			break
		}

		select {
		case <-ctx.Done():
			return FusionCluster{}, ctx.Err()
		case <-time.After(retryDelay):
		}
	}

	return FusionCluster{}, lastErr
}

func isTransientMappingError(err error) bool {
	if err == nil {
		return false
	}

	errMsg := strings.ToLower(err.Error())
	return strings.Contains(errMsg, "context deadline exceeded") ||
		strings.Contains(errMsg, "client.timeout exceeded") ||
		strings.Contains(errMsg, "timeout")
}

// buildNodeMappings constructs unified mappings from current environment.
func buildNodeMappings(ctx context.Context, env Env) ([]FusionNode, error) {
	ipToInstance, err := GetMultipassInstances(ctx)
	if err != nil {
		return nil, fmt.Errorf("get multipass instances: %w", err)
	}

	// instanceToIPs: instance name -> all its IPs (stable order)
	instanceToIPs := make(map[string][]string)
	for ip, name := range ipToInstance {
		instanceToIPs[name] = append(instanceToIPs[name], ip)
	}
	for name := range instanceToIPs {
		sort.Strings(instanceToIPs[name])
	}

	devices, err := GetDevices(ctx, env.BaseURL())
	if err != nil {
		return nil, fmt.Errorf("get devices: %w", err)
	}

	if len(devices) != len(instanceToIPs) {
		return nil, fmt.Errorf("device count %d != instance count %d", len(devices), len(instanceToIPs))
	}

	var mappings []FusionNode
	for _, d := range devices {
		instName := ipToInstance[d.Address]

		mappings = append(mappings, FusionNode{
			MultipassName: instName,
			MultipassIPs:  instanceToIPs[instName],
			Device:        d,
		})
	}
	sort.Slice(mappings, func(i, j int) bool {
		if mappings[i].Device.IsPrimaryNode && !mappings[j].Device.IsPrimaryNode {
			return true
		}
		if mappings[j].Device.IsPrimaryNode && !mappings[i].Device.IsPrimaryNode {
			return false
		}
		return mappings[i].Device.Address < mappings[j].Device.Address
	})
	return mappings, nil
}

// instanceNames returns multipass instance names in stable order.
func (fc FusionCluster) instanceNames() []string {
	names := make([]string, 0, len(fc.Nodes))
	for _, n := range fc.Nodes {
		if n.MultipassName != "" {
			names = append(names, n.MultipassName)
		}
	}
	sort.Strings(names)
	return names
}

// // NodeURLs returns base HTTP URLs for each node using Env.Port.
func (fc FusionCluster) NodeURLs() []string {
	urls := make([]string, 0, len(fc.Nodes))
	for _, n := range fc.Nodes {
		urls = append(urls, fmt.Sprintf("http://%s:%s", n.Device.Address, fc.Env.Port))
	}
	sort.Strings(urls)
	return urls
}

// Primary fetches devices from the /devices API and returns the single primary node.
// It fails if there is not exactly one primary device.
func (fc FusionCluster) Primary() (FusionNode, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	devices, err := GetDevices(ctx, fc.Env.BaseURL())
	if err != nil {
		return FusionNode{}, fmt.Errorf("get devices: %w", err)
	}

	var primary *api.DeviceInfo
	for i := range devices {
		if devices[i].IsPrimaryNode {
			if primary != nil {
				return FusionNode{}, fmt.Errorf("expected exactly one primary, found multiple")
			}
			primary = &devices[i]
		}
	}
	if primary == nil {
		return FusionNode{}, fmt.Errorf("expected exactly one primary, found none")
	}

	for _, n := range fc.Nodes {
		if n.Device.Address == primary.Address {
			return n, nil
		}
	}
	// Fallback: node not yet in mapping, construct from device info
	return FusionNode{Device: *primary}, nil
}

// // StopAll stops all discovered multipass instances.
// func (fc FusionCluster) StopAll(ctx context.Context, maxParallel int) error {
// 	return StopInstancesParallel(ctx, fc.instanceNames(), maxParallel)
// }

// // StartAll starts all discovered multipass instances and waits for expected size.
// func (fc FusionCluster) StartAll(ctx context.Context, expected int, maxParallel int) error {
// 	if err := StartInstancesParallel(ctx, fc.instanceNames(), maxParallel); err != nil {
// 		return err
// 	}
// 	return WaitForClusterSize(ctx, fc.Env, expected)
// }

// // StopNode stops a single multipass instance by its name.
// func (fc FusionCluster) StopNode(ctx context.Context, name string) error {
// 	return StopInstance(ctx, name)
// }

// // StartNode starts a single multipass instance by its name.
// func (fc FusionCluster) StartNode(ctx context.Context, name string) error {
// 	return StartInstance(ctx, name)
// }

// // Reset resets cluster state via underlying script.
// func (fc FusionCluster) Reset(ctx context.Context) error {
// 	return ResetCluster(ctx, fc.Env)
// }

// // Restart restarts cluster instances and waits for expected size.
// func (fc FusionCluster) Restart(ctx context.Context, expected int) error {
// 	return RestartCluster(ctx, fc.Env, expected)
// }

// // WaitForSize waits until cluster size reaches n.
// func (fc FusionCluster) WaitForSize(ctx context.Context, n int) error {
// 	return WaitForClusterSize(ctx, fc.Env, n)
// }

// // WaitForSizeFromAny waits until any node URL reports size n.
// func (fc FusionCluster) WaitForSizeFromAny(ctx context.Context, n int) error {
// 	return WaitForClusterSizeFromAny(ctx, fc.NodeURLs(), n)
// }

// // CheckHealth wraps global health helper.
// func (fc FusionCluster) CheckHealth(ctx context.Context, expected int) error {
// 	return CheckClusterHealth(ctx, fc.Env, expected)
// }
