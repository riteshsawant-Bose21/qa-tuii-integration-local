//go:build integration

package integration

import (
	"context"
	"fmt"

	// "math/rand"
	"testing"
	"time"
)

func TestIntegrationTestReadMe(t *testing.T) {
	//To init test with a cluster
	fc := NewTestCluster(t)
	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
	defer cancel()

	//To check cluster health
	fc.Refresh(ctx)
	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
		t.Fatalf("initial health failed: %v", err)
	}

	//To stop an instance
	primary, err := fc.Primary()
	// someNode, err := fc.Nodes[0]
	if err != nil {
		t.Fatalf("primary not found: %v", err)
	}
	t.Logf("Stopping primary instance: %s addr=%s", primary.MultipassName, primary.FusionAddr)
	if err := StopInstance(ctx, primary.MultipassName); err != nil {
		t.Fatalf("stop primary failed: %v", err)
	}
	fc.Refresh(ctx)

	//To wait for cluster size
	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize-1); err != nil {
		t.Fatalf("cluster did not reach size %d: %v", fc.Env.ClusterSize, err)
	}

	//To start an instance
	if err := StartInstance(ctx, primary.MultipassName); err != nil {
		t.Fatalf("start instance %s failed: %v", primary.MultipassName, err)
	}
	fc.Refresh(ctx)

}

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

// // TestVIPCascadeShutdownRestart exercises repeated VIP holder failure until all nodes are down,
// // then brings all nodes back simultaneously, then tests full shutdown and sequential bring-up.
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

//BELOW TEST CASES ARE AI GENERATED EXAMPLES FOR INTEGRATION TESTING AND NOT REVIEWED

// // // //go:build integration

// // // package integration

// // // import (
// // // 	"context"
// // // 	"fmt"
// // // 	"math/rand"
// // // 	"testing"
// // // 	"time"
// // // )

// // // Assumes helpers exist (as in your examples):
// // // NewTestCluster, CheckClusterHealth, StopInstance, StartInstance,
// // // StartInstancesParallel, StopInstancesParallel, fc.Refresh, fc.Primary,
// // // fc.WaitForClusterSize, fc.Nodes, fc.Env (ClusterSize, Port, MaxWait)

// func TestNonPrimaryRestart(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if err := fc.Refresh(ctx); err != nil {
// 		t.Fatalf("refresh failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}

// 	primary, err := fc.Primary()
// 	if err != nil {
// 		t.Fatalf("primary not found: %v", err)
// 	}

// 	// Pick a non-primary node
// 	var victim *FusionNode
// 	for i := range fc.Nodes {
// 		n := &fc.Nodes[i]
// 		if n.FusionAddr != primary.FusionAddr {
// 			victim = n
// 			break
// 		}
// 	}
// 	if victim == nil {
// 		t.Skip("no non-primary node available (cluster too small?)")
// 	}

// 	t.Logf("Stopping non-primary: %s addr=%s", victim.MultipassName, victim.FusionAddr)
// 	if err := StopInstance(ctx, victim.MultipassName); err != nil {
// 		t.Fatalf("stop non-primary failed: %v", err)
// 	}

// 	if err := fc.WaitForClusterSize(ctx, max(1, fc.Env.ClusterSize-1)); err != nil {
// 		t.Fatalf("wait for size failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, max(1, fc.Env.ClusterSize-1)); err != nil {
// 		t.Fatalf("health degraded failed: %v", err)
// 	}

// 	t.Logf("Starting non-primary: %s", victim.MultipassName)
// 	if err := StartInstance(ctx, victim.MultipassName); err != nil {
// 		t.Fatalf("start non-primary failed: %v", err)
// 	}
// 	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("wait for full size failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("post-recovery health failed: %v", err)
// 	}
// }

// func TestStopTwoNodesThenRecover(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}
// 	if fc.Env.ClusterSize < 3 {
// 		t.Skip("need at least 3 nodes to stop 2 and still have quorum/cluster behavior")
// 	}

// 	if err := fc.Refresh(ctx); err != nil {
// 		t.Fatalf("refresh failed: %v", err)
// 	}

// 	primary, err := fc.Primary()
// 	if err != nil {
// 		t.Fatalf("primary not found: %v", err)
// 	}

// 	// Choose one primary + one non-primary
// 	var other *FusionNode
// 	for i := range fc.Nodes {
// 		n := &fc.Nodes[i]
// 		if n.FusionAddr != primary.FusionAddr {
// 			other = n
// 			break
// 		}
// 	}
// 	if other == nil {
// 		t.Fatalf("no non-primary node found")
// 	}

// 	toStop := []string{primary.MultipassName, other.MultipassName}
// 	t.Logf("Stopping two nodes: %v", toStop)
// 	if err := StopInstancesParallel(ctx, toStop, 2); err != nil {
// 		t.Fatalf("parallel stop failed: %v", err)
// 	}

// 	expected := fc.Env.ClusterSize - 2
// 	if expected < 0 {
// 		expected = 0
// 	}
// 	if err := fc.WaitForClusterSize(ctx, expected); err != nil {
// 		t.Fatalf("wait for size %d failed: %v", expected, err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, expected); err != nil {
// 		t.Fatalf("health after stopping two failed: %v", err)
// 	}

// 	// Recover: start in reverse order
// 	for _, name := range []string{other.MultipassName, primary.MultipassName} {
// 		t.Logf("Starting %s", name)
// 		if err := StartInstance(ctx, name); err != nil {
// 			t.Fatalf("start %s failed: %v", name, err)
// 		}
// 	}

// 	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("wait for full size failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("post-recovery health failed: %v", err)
// 	}
// }

// func TestRollingRestartAllNodes(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}

// 	// Rolling restart each node, always returning to full size before moving on.
// 	if err := fc.Refresh(ctx); err != nil {
// 		t.Fatalf("refresh failed: %v", err)
// 	}

// 	for i := 0; i < len(fc.Nodes); i++ {
// 		n := fc.Nodes[i]
// 		t.Logf("[rolling %d/%d] stopping %s addr=%s", i+1, len(fc.Nodes), n.MultipassName, n.FusionAddr)

// 		if err := StopInstance(ctx, n.MultipassName); err != nil {
// 			t.Fatalf("stop %s failed: %v", n.MultipassName, err)
// 		}
// 		if err := fc.WaitForClusterSize(ctx, max(1, fc.Env.ClusterSize-1)); err != nil {
// 			t.Fatalf("wait for size after stop failed: %v", err)
// 		}
// 		if err := CheckClusterHealth(ctx, fc.Env, max(1, fc.Env.ClusterSize-1)); err != nil {
// 			t.Fatalf("health after stop %s failed: %v", n.MultipassName, err)
// 		}

// 		t.Logf("[rolling %d/%d] starting %s", i+1, len(fc.Nodes), n.MultipassName)
// 		if err := StartInstance(ctx, n.MultipassName); err != nil {
// 			t.Fatalf("start %s failed: %v", n.MultipassName, err)
// 		}
// 		if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 			t.Fatalf("wait for full size after start failed: %v", err)
// 		}
// 		if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 			t.Fatalf("health after start %s failed: %v", n.MultipassName, err)
// 		}
// 	}
// }

// func TestRapidFlapSingleNode(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if err := fc.Refresh(ctx); err != nil {
// 		t.Fatalf("refresh failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}

// 	// Pick any node to flap (prefer non-primary so we don't conflate with election behavior).
// 	primary, err := fc.Primary()
// 	if err != nil {
// 		t.Fatalf("primary not found: %v", err)
// 	}
// 	victim := fc.Nodes[0]
// 	for _, n := range fc.Nodes {
// 		if n.FusionAddr != primary.FusionAddr {
// 			victim = n
// 			break
// 		}
// 	}

// 	const flaps = 3
// 	for i := 0; i < flaps; i++ {
// 		t.Logf("flap %d/%d stopping %s", i+1, flaps, victim.MultipassName)
// 		if err := StopInstance(ctx, victim.MultipassName); err != nil {
// 			t.Fatalf("stop failed: %v", err)
// 		}
// 		if err := fc.WaitForClusterSize(ctx, max(1, fc.Env.ClusterSize-1)); err != nil {
// 			t.Fatalf("wait for size after stop failed: %v", err)
// 		}

// 		time.Sleep(500 * time.Millisecond)

// 		t.Logf("flap %d/%d starting %s", i+1, flaps, victim.MultipassName)
// 		if err := StartInstance(ctx, victim.MultipassName); err != nil {
// 			t.Fatalf("start failed: %v", err)
// 		}
// 		if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 			t.Fatalf("wait for size after start failed: %v", err)
// 		}
// 	}

// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("final health failed: %v", err)
// 	}
// }

// func TestRandomChaosMonkeyShort(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if fc.Env.ClusterSize < 3 {
// 		t.Skip("need >= 3 nodes for meaningful chaos without total outage")
// 	}

// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}

// 	seed := time.Now().UnixNano()
// 	rng := rand.New(rand.NewSource(seed))
// 	t.Logf("chaos seed=%d", seed)

// 	// Do a few random stop/start operations; never allow more than 1 node down at a time.
// 	const ops = 5
// 	for i := 0; i < ops; i++ {
// 		if err := fc.Refresh(ctx); err != nil {
// 			t.Fatalf("refresh failed: %v", err)
// 		}
// 		n := fc.Nodes[rng.Intn(len(fc.Nodes))]

// 		t.Logf("chaos op %d/%d: stop %s", i+1, ops, n.MultipassName)
// 		if err := StopInstance(ctx, n.MultipassName); err != nil {
// 			t.Fatalf("stop failed: %v", err)
// 		}
// 		if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize-1); err != nil {
// 			t.Fatalf("wait for size failed: %v", err)
// 		}
// 		if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize-1); err != nil {
// 			t.Fatalf("health after stop failed: %v", err)
// 		}

// 		time.Sleep(time.Duration(500+rng.Intn(800)) * time.Millisecond)

// 		t.Logf("chaos op %d/%d: start %s", i+1, ops, n.MultipassName)
// 		if err := StartInstance(ctx, n.MultipassName); err != nil {
// 			t.Fatalf("start failed: %v", err)
// 		}
// 		if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 			t.Fatalf("wait for full size failed: %v", err)
// 		}
// 		if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 			t.Fatalf("health after start failed: %v", err)
// 		}
// 	}
// }

// func TestPrimaryFailoverThenWriteReadSmoke(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}

// 	primary, err := fc.Primary()
// 	if err != nil {
// 		t.Fatalf("primary not found: %v", err)
// 	}

// 	t.Logf("Stopping primary VIP holder: %s addr=%s", primary.MultipassName, primary.FusionAddr)
// 	if err := StopInstance(ctx, primary.MultipassName); err != nil {
// 		t.Fatalf("stop primary failed: %v", err)
// 	}

// 	if err := fc.WaitForClusterSize(ctx, max(1, fc.Env.ClusterSize-1)); err != nil {
// 		t.Fatalf("wait for size failed: %v", err)
// 	}
// 	time.Sleep(2 * time.Second) // allow election to settle

// 	// Optional: if you have an HTTP smoke helper, call it here.
// 	// Otherwise we at least validate health on remaining nodes.
// 	if err := CheckClusterHealth(ctx, fc.Env, max(1, fc.Env.ClusterSize-1)); err != nil {
// 		t.Fatalf("health after primary failover failed: %v", err)
// 	}

// 	// Bring original primary back
// 	t.Logf("Starting former primary: %s", primary.MultipassName)
// 	if err := StartInstance(ctx, primary.MultipassName); err != nil {
// 		t.Fatalf("start primary failed: %v", err)
// 	}
// 	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("wait for full size failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("post-recovery health failed: %v", err)
// 	}
// }

// func TestParallelStopStartWithStagger(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}

// 	var names []string
// 	for _, n := range fc.Nodes {
// 		names = append(names, n.MultipassName)
// 	}

// 	// Stop all in parallel, then start all in parallel with a small settle time.
// 	t.Logf("Stopping all nodes (parallel max=3)")
// 	if err := StopInstancesParallel(ctx, names, 3); err != nil {
// 		t.Fatalf("parallel stop failed: %v", err)
// 	}
// 	if err := fc.WaitForClusterSize(ctx, 0); err != nil {
// 		t.Fatalf("wait for size 0 failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, 0); err != nil {
// 		t.Fatalf("health after full stop failed: %v", err)
// 	}

// 	time.Sleep(2 * time.Second)

// 	t.Logf("Starting all nodes (parallel max=3)")
// 	if err := StartInstancesParallel(ctx, names, 3); err != nil {
// 		t.Fatalf("parallel start failed: %v", err)
// 	}
// 	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("wait for full size failed: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("final health failed: %v", err)
// 	}
// }

// func TestClusterSizeEventuallyConsistentAfterRestartStorm(t *testing.T) {
// 	fc := NewTestCluster(t)
// 	ctx, cancel := context.WithTimeout(context.Background(), fc.Env.MaxWait)
// 	defer cancel()

// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("initial health failed: %v", err)
// 	}

// 	// "Storm": restart each node quickly, then assert the cluster converges back to full size.
// 	if err := fc.Refresh(ctx); err != nil {
// 		t.Fatalf("refresh failed: %v", err)
// 	}

// 	var names []string
// 	for _, n := range fc.Nodes {
// 		names = append(names, n.MultipassName)
// 	}

// 	// Stop/start each node with minimal delay (sequential to avoid total outage).
// 	for _, name := range names {
// 		if err := StopInstance(ctx, name); err != nil {
// 			t.Fatalf("stop %s failed: %v", name, err)
// 		}
// 		_ = fc.WaitForClusterSize(ctx, max(1, fc.Env.ClusterSize-1))
// 		if err := StartInstance(ctx, name); err != nil {
// 			t.Fatalf("start %s failed: %v", name, err)
// 		}
// 	}

// 	// Convergence check (size + health)
// 	if err := fc.WaitForClusterSize(ctx, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("cluster did not converge to full size: %v", err)
// 	}
// 	if err := CheckClusterHealth(ctx, fc.Env, fc.Env.ClusterSize); err != nil {
// 		t.Fatalf("cluster not healthy after convergence: %v", err)
// 	}
// }

// /*** helpers ***/

// func max(a, b int) int {
// 	if a > b {
// 		return a
// 	}
// 	return b
// }
