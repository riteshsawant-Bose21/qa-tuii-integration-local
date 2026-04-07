//go:build integration

package integration

import (
	"context"
	"fmt"
	"testing"
	"time"
)

func TestPrimaryRestart(t *testing.T) {
	fc := NewTestCluster(t)

	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
	defer cancel()

	// Identify primary
	primary, err := fc.Primary()
	if err != nil {
		t.Fatalf("primary not found: %v", err)
	}
	t.Logf("Stopping primary instance: %s addr=%s", primary.MultipassName, primary.FusionAddr)
	if err := StopInstance(ctx, primary.MultipassName); err != nil {
		t.Fatalf("stop primary failed: %v", err)
	}

	// Refresh non-primary node URLs
	if err := fc.Refresh(ctx); err != nil {
		t.Fatalf("refresh after stop failed: %v", err)
	}
	var otherURLs []string
	for _, n := range fc.Nodes {
		if n.FusionAddr == primary.FusionAddr {
			continue
		}
		otherURLs = append(otherURLs, fmt.Sprintf("http://%s:%s", n.FusionAddr, fc.Env.Port))
	}
	if len(otherURLs) == 0 {
		t.Fatalf("no other nodes to query")
	}

	// Expect cluster size to be at least size-1
	target := fc.Env.ClusterSize - 1
	if target < 1 {
		target = 1
	}
	if err := fc.WaitForClusterSize(ctx, target); err != nil {
		t.Fatalf("wait for cluster size %d failed: %v", target, err)
	}

	if err := fc.Refresh(ctx); err != nil {
		t.Fatalf("refresh after stop failed: %v", err)
	}

	// Restart primary
	if err := StartInstance(ctx, primary.MultipassName); err != nil {
		t.Fatalf("start primary failed: %v", err)
	}
	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
		t.Fatalf("wait for cluster size %d failed: %v", fc.Env.ClusterSize, err)
	}

	if err := fc.Refresh(ctx); err != nil {
		t.Fatalf("refresh after stop failed: %v", err)
	}
	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("post-recovery health failed: %v", err)
	}
}

func TestPrimaryCascadeShutdownRestart(t *testing.T) {
	fc := NewTestCluster(t)
	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
	defer cancel()
	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("initial health failed: %v", err)
	}

	// Cascade stop primary holders until all down
	var shutdownOrder []string
	remaining := fc.Env.ClusterSize
	for remaining > 0 {
		if err := fc.Refresh(ctx); err != nil {
			t.Fatalf("refresh failed (remaining %d): %v", remaining, err)
		}
		primary, err := fc.Primary()
		if err != nil {
			t.Fatalf("primary not found (remaining %d): %v", remaining, err)
		}
		t.Logf("Stopping VIP holder: %s addr=%s remaining_before=%d", primary.MultipassName, primary.FusionAddr, remaining)
		shutdownOrder = append(shutdownOrder, primary.MultipassName)
		if err := StopInstance(ctx, primary.MultipassName); err != nil {
			t.Fatalf("stop primary %s failed: %v", primary.MultipassName, err)
		}
		remaining--
		if remaining > 0 {

			if err := fc.WaitForClusterSize(ctx, remaining); err != nil {
				t.Fatalf("wait for size %d failed after stopping %s: %v", remaining, primary.MultipassName, err)
			}
			if err := CheckClusterHealth(ctx, fc.Env, remaining); err != nil {
				t.Fatalf("health after stopping %s failed: %v", primary.MultipassName, err)
			}
			time.Sleep(2 * time.Second) // allow new election
		} else {
			if err := CheckClusterHealth(ctx, fc.Env, 0); err != nil {
				t.Fatalf("health with all nodes down failed: %v", err)
			}
		}
	}

	// Parallel start all
	t.Logf("Starting all nodes simultaneously (parallel, max=3): %v", shutdownOrder)
	if err := StartInstancesParallel(ctx, shutdownOrder, 3); err != nil {
		t.Fatalf("parallel start failed: %v", err)
	}
	time.Sleep(2 * time.Second)
	fc.Refresh(ctx)
	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
		fc.Refresh(ctx)
		if err1 := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err1 != nil {
			t.Fatalf("cluster did not recover to %d: %v %v", fc.Env.ClusterSize, err, err1)
		}
	}
	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("health after simultaneous start failed: %v", err)
	}

	// Full shutdown again
	t.Logf("Shutting down all nodes again (parallel, max=3)")
	if err := StopInstancesParallel(ctx, shutdownOrder, 3); err != nil {
		t.Fatalf("parallel stop failed: %v", err)
	}
	if err := CheckClusterHealth(ctx, fc.Env, 0); err != nil {
		t.Fatalf("health after full shutdown failed: %v", err)
	}

	// Sequential bring-up
	t.Logf("Sequential bring-up of nodes")
	for i, name := range shutdownOrder {
		if err := StartInstance(ctx, name); err != nil {
			t.Fatalf("start instance %s failed: %v", name, err)
		}
		expected := i + 1
		if err := fc.WaitForClusterSize(ctx, expected); err != nil {
			fc.Refresh(ctx)
			if err1 := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err1 != nil {
				t.Fatalf("cluster did not recover to %d: %v %v", fc.Env.ClusterSize, err, err1)
			}
			// t.Fatalf("wait for size %d failed after starting %s: %v", expected, name, err)
		}
		if err := CheckClusterHealth(ctx, fc.Env, expected); err != nil {
			t.Fatalf("health after starting %s failed: %v", name, err)
		}
	}
	t.Logf("Sequential bring-up complete; cluster size=%d", fc.Env.ClusterSize)
}
