package vipmonitor

import (
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	fusionpb "fusion/internal/gen/proto/fusion"

	json "github.com/goccy/go-json"
	"github.com/hashicorp/memberlist"
)

var initTestLogger sync.Once

func ensureTestLogger() {
	initTestLogger.Do(func() {
		logging.InitLogger(logging.LogConfig{
			NodeName:    "test",
			LogDir:      "/tmp",
			MaxFileSize: 1,
			MaxFiles:    1,
			LogLevel:    logging.ERROR,
		})
	})
}

type stubClusterTransport struct {
	local   *memberlist.Node
	members []*memberlist.Node
}

func (s *stubClusterTransport) LocalNode() *memberlist.Node { return s.local }

func (s *stubClusterTransport) MemberListMembers() []*memberlist.Node { return s.members }

func (s *stubClusterTransport) SendReliable(node *memberlist.Node, msg []byte) error { return nil }

func (s *stubClusterTransport) PostGenericToAdmin(endpoint string, localFn func() error) error {
	return nil
}

func (s *stubClusterTransport) FetchGenericWithTargetDevice(deviceID string, endpointTemplate string, localFn func() ([]byte, error), remoteFn func(url string) ([]byte, error)) ([]byte, error) {
	return nil, nil
}

func (s *stubClusterTransport) DoGenericToTargetDevice(deviceID, endpointTemplate string, payload []byte, localFn func(payload []byte) error, remoteFn func(payload []byte, url string) error) error {
	return nil
}

func (s *stubClusterTransport) GetAllDevicesInfo() []fusionpb.DeviceInfo { return nil }

func (s *stubClusterTransport) GetDeviceInfoLocal() fusionpb.DeviceInfo { return fusionpb.DeviceInfo{} }

func (s *stubClusterTransport) UpdateDeviceInfo(deviceID string, patch *fusionpb.DevicePatch) error {
	return nil
}

func (s *stubClusterTransport) UpdateDeviceInfoLocal(patch *fusionpb.DevicePatch) error { return nil }

func TestHandleReloadVIPReturnsAcceptedOperation(t *testing.T) {
	ensureTestLogger()
	transport := &stubClusterTransport{}
	monitor := NewVIPMonitor("lo0", false, transport)

	configDir := t.TempDir()
	configPath := filepath.Join(configDir, "keepalived.conf")
	config := "vrrp_instance VI_1 {\n    virtual_ipaddress {\n        192.168.2.100\n    }\n}\n"
	if err := os.WriteFile(configPath, []byte(config), 0o644); err != nil {
		t.Fatalf("write config: %v", err)
	}
	monitor.configPath = configPath

	req := httptest.NewRequest(http.MethodPost, "/device/reload/vip", nil)
	rec := httptest.NewRecorder()

	monitor.HandleReloadVIP(rec, req)

	resp := rec.Result()
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted {
		t.Fatalf("status = %d, want %d", resp.StatusCode, http.StatusAccepted)
	}
	if got := resp.Header.Get(api.ContentType); got != api.JsonMIMEType {
		t.Fatalf("content-type = %q, want %q", got, api.JsonMIMEType)
	}

	var op VIPOperationStatus
	if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if op.ID == "" {
		t.Fatal("expected operation ID in response")
	}
	if op.DesiredVIP != "192.168.2.100" {
		t.Fatalf("desired VIP = %q, want %q", op.DesiredVIP, "192.168.2.100")
	}
}

func TestHandleReloadVIPRejectsActiveOperation(t *testing.T) {
	ensureTestLogger()
	transport := &stubClusterTransport{}
	monitor := NewVIPMonitor("lo0", false, transport)
	op := monitor.createVIPOperation("192.168.2.100")
	monitor.setVIPOperationPhase(op.ID, VIPOperationPhaseReloading, "reload in progress")

	req := httptest.NewRequest(http.MethodPost, "/device/reload/vip", nil)
	rec := httptest.NewRecorder()

	monitor.HandleReloadVIP(rec, req)

	resp := rec.Result()
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusConflict {
		t.Fatalf("status = %d, want %d", resp.StatusCode, http.StatusConflict)
	}
}

func TestHandleReloadVIPReturnsInternalServerErrorWhenConfigReadFails(t *testing.T) {
	ensureTestLogger()
	transport := &stubClusterTransport{}
	monitor := NewVIPMonitor("lo0", false, transport)
	monitor.configPath = filepath.Join(t.TempDir(), "missing-keepalived.conf")

	req := httptest.NewRequest(http.MethodPost, "/device/reload/vip", nil)
	rec := httptest.NewRecorder()

	monitor.HandleReloadVIP(rec, req)

	resp := rec.Result()
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", resp.StatusCode, http.StatusInternalServerError)
	}
}

func TestWaitForReloadPhaseDoesNotTreatIdleAsSuccess(t *testing.T) {
	ensureTestLogger()
	local := &memberlist.Node{
		Name:  "node-a",
		Addr:  net.ParseIP("127.0.0.1"),
		State: memberlist.StateAlive,
	}
	transport := &stubClusterTransport{
		local:   local,
		members: []*memberlist.Node{local},
	}
	monitor := NewVIPMonitor("lo0", false, transport)
	op := monitor.createVIPOperation("192.168.2.100")
	targets := monitor.adminTargets()

	resultCh := make(chan error, 1)
	go func() {
		resultCh <- monitor.waitForReloadPhase(op.ID, targets)
	}()

	select {
	case err := <-resultCh:
		t.Fatalf("waitForReloadPhase returned early while status was idle: %v", err)
	case <-time.After(200 * time.Millisecond):
	}

	now := time.Now().UTC()
	monitor.setVIPApplyStatus(VIPApplyStatus{
		DesiredVIP:  "192.168.2.100",
		Phase:       VIPApplyPhaseComplete,
		Message:     "configured VIP applied",
		StartedAt:   &now,
		CompletedAt: &now,
	})

	select {
	case err := <-resultCh:
		if err != nil {
			t.Fatalf("waitForReloadPhase returned error: %v", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("waitForReloadPhase did not complete after apply status became complete")
	}
}

func TestWaitForReloadPhaseUsesSnapshotTargets(t *testing.T) {
	ensureTestLogger()
	local := &memberlist.Node{
		Name:  "node-a",
		Addr:  net.ParseIP("127.0.0.1"),
		State: memberlist.StateAlive,
	}
	transport := &stubClusterTransport{
		local:   local,
		members: []*memberlist.Node{local},
	}
	monitor := NewVIPMonitor("lo0", false, transport)
	op := monitor.createVIPOperation("192.168.2.100")
	targets := monitor.adminTargets()

	newPeer := &memberlist.Node{
		Name:  "node-b",
		Addr:  net.ParseIP("127.0.0.2"),
		State: memberlist.StateAlive,
	}
	transport.members = []*memberlist.Node{local, newPeer}

	resultCh := make(chan error, 1)
	go func() {
		resultCh <- monitor.waitForReloadPhase(op.ID, targets)
	}()

	now := time.Now().UTC()
	monitor.setVIPApplyStatus(VIPApplyStatus{
		DesiredVIP:  "192.168.2.100",
		Phase:       VIPApplyPhaseComplete,
		Message:     "configured VIP applied",
		StartedAt:   &now,
		CompletedAt: &now,
	})

	select {
	case err := <-resultCh:
		if err != nil {
			t.Fatalf("waitForReloadPhase returned error: %v", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("waitForReloadPhase did not complete using snapshot targets")
	}
}

func TestAdminTargetsIncludeOnlyAliveMembersAndSkipDuplicates(t *testing.T) {
	ensureTestLogger()
	local := &memberlist.Node{
		Name:  "node-a",
		Addr:  net.ParseIP("127.0.0.1"),
		State: memberlist.StateAlive,
	}
	alivePeer := &memberlist.Node{
		Name:  "node-b",
		Addr:  net.ParseIP("127.0.0.2"),
		State: memberlist.StateAlive,
	}
	duplicateLocal := &memberlist.Node{
		Name:  "node-a-dup",
		Addr:  net.ParseIP("127.0.0.1"),
		State: memberlist.StateAlive,
	}
	suspectPeer := &memberlist.Node{
		Name:  "node-c",
		Addr:  net.ParseIP("127.0.0.3"),
		State: memberlist.StateSuspect,
	}
	deadPeer := &memberlist.Node{
		Name:  "node-d",
		Addr:  net.ParseIP("127.0.0.4"),
		State: memberlist.StateDead,
	}

	transport := &stubClusterTransport{
		local:   local,
		members: []*memberlist.Node{duplicateLocal, alivePeer, suspectPeer, deadPeer},
	}
	monitor := NewVIPMonitor("lo0", false, transport)

	targets := monitor.adminTargets()
	if len(targets) != 2 {
		t.Fatalf("target count = %d, want 2", len(targets))
	}
	if targets[0].Host != "127.0.0.1" || targets[1].Host != "127.0.0.2" {
		t.Fatalf("unexpected targets: %#v", targets)
	}
}

func TestRecordSkippedAdminTargetsAddsReadableSkippedResults(t *testing.T) {
	ensureTestLogger()
	local := &memberlist.Node{
		Name:  "node-a",
		Addr:  net.ParseIP("127.0.0.1"),
		State: memberlist.StateAlive,
	}
	suspectPeer := &memberlist.Node{
		Name:  "node-c",
		Addr:  net.ParseIP("127.0.0.3"),
		State: memberlist.StateSuspect,
	}
	deadPeer := &memberlist.Node{
		Name:  "node-d",
		Addr:  net.ParseIP("127.0.0.4"),
		State: memberlist.StateDead,
	}
	transport := &stubClusterTransport{
		local:   local,
		members: []*memberlist.Node{local, suspectPeer, deadPeer},
	}
	monitor := NewVIPMonitor("lo0", false, transport)
	op := monitor.createVIPOperation("192.168.2.100")

	monitor.recordSkippedAdminTargets(op.ID, VIPOperationPhaseReloading)

	status := monitor.getVIPOperation(op.ID)
	if len(status.NodeResults) != 2 {
		t.Fatalf("node result count = %d, want 2", len(status.NodeResults))
	}
	if got := status.NodeResults["127.0.0.3"].Error; got != "skipped non-alive member (state=SUSPECT)" {
		t.Fatalf("suspect error = %q", got)
	}
	if got := status.NodeResults["127.0.0.4"].Error; got != "skipped non-alive member (state=DEAD)" {
		t.Fatalf("dead error = %q", got)
	}
}

func TestRunAdminPhaseRecordsSkippedNonAliveMembers(t *testing.T) {
	ensureTestLogger()
	local := &memberlist.Node{
		Name:  "node-a",
		Addr:  net.ParseIP("127.0.0.1"),
		State: memberlist.StateAlive,
	}
	suspectPeer := &memberlist.Node{
		Name:  "node-c",
		Addr:  net.ParseIP("127.0.0.3"),
		State: memberlist.StateSuspect,
	}
	transport := &stubClusterTransport{
		local:   local,
		members: []*memberlist.Node{local, suspectPeer},
	}
	monitor := NewVIPMonitor("lo0", false, transport)
	op := monitor.createVIPOperation("192.168.2.100")
	targets := monitor.adminTargets()

	if err := monitor.runAdminPhase(op.ID, targets, VIPOperationPhaseWritingConfig, "/unused", func() error {
		return nil
	}); err != nil {
		t.Fatalf("runAdminPhase returned error: %v", err)
	}

	status := monitor.getVIPOperation(op.ID)
	if len(status.NodeResults) != 2 {
		t.Fatalf("node result count = %d, want 2", len(status.NodeResults))
	}
	if !status.NodeResults["127.0.0.1"].Success {
		t.Fatal("expected local writing-config result to succeed")
	}
	if got := status.NodeResults["127.0.0.3"].Error; got != "skipped non-alive member (state=SUSPECT)" {
		t.Fatalf("suspect error = %q", got)
	}
}
