package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
	"github.com/gorilla/websocket"

	"fusion/internal/api"
	"fusion/internal/routes"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	clusterServerURL      = "http://192.168.2.100:8080"
	clusterServerAdminURL = "http://192.168.2.100:9090"
)

func helperURL(path string) string {
	return clusterServerURL + path
}

func helperAdminURL(path string) string {
	return clusterServerAdminURL + path
}

// TestUpdateDeviceInfoLocal exercises PATCH /device (UpdateDeviceInfoLocal).
func TestUpdateDeviceInfoLocal(t *testing.T) {

	base := api.DevicePatch{
		Id:       ptrString("test-device"),
		Location: ptrString("RoomB"),
		Name:     ptrString("BaseDevice"),
	}
	bytesBase, err := json.Marshal(base)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPatch, helperAdminURL(routes.DeviceEndpoint), bytes.NewReader(bytesBase))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)
	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)

	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content when setting base device via PATCH")
	// Now PATCH /device to change only the Name.
	patch := api.DevicePatch{
		Name: ptrString("RenamedDevice"),
	}
	bytesPatch, err := json.Marshal(patch)
	require.NoError(t, err)

	req, err = http.NewRequest(http.MethodPatch, helperAdminURL(routes.DeviceEndpoint), bytes.NewReader(bytesPatch))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)

	resp, err = http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content on PATCH /device")

	// Verify via GET /device that only Name changed.
	resp, err = http.Get(helperAdminURL(routes.DeviceEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK on GET /device after patch")

	var updated api.DeviceInfo
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&updated), "Expected valid JSON after patch")
	assert.Equal(t, *base.Id, updated.Id, "ID should remain unchanged")
	assert.Equal(t, "RenamedDevice", updated.Name, "Name should have been updated")
	assert.Equal(t, *base.Location, updated.Location, "Location should remain unchanged")
}

// TestUpdateDeviceInfoNotFound attempts PATCH /devices/{id} on a non-existent device.
func TestUpdateDeviceInfoNotFound(t *testing.T) {
	patch := api.DevicePatch{
		Name: ptrString("ShouldNotExist"),
	}
	bytesPatch, err := json.Marshal(patch)
	require.NoError(t, err)

	target := helperURL(fmt.Sprintf("%s/%s", routes.DevicesEndpoint, "nonexistent"))
	req, err := http.NewRequest(http.MethodPatch, target, bytes.NewReader(bytesPatch))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	// Expect 404 since no device with ID "nonexistent" is stored.
	assert.Equal(t, http.StatusNotFound, resp.StatusCode, "PATCH /devices/nonexistent should return 404")
}

// TestDeviceInfoErrorCases groups wrong-method and malformed-JSON scenarios.
func TestDeviceInfoErrorCases(t *testing.T) {
	cases := []struct {
		name       string
		url        string
		method     string
		body       io.Reader
		wantStatus int
	}{
		{
			name:       "GetDevicesInfo wrong method",
			url:        helperURL(routes.DevicesEndpoint),
			method:     http.MethodPost,
			body:       nil,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "UpdateDeviceInfo wrong method",
			method:     http.MethodGet,
			url:        helperURL(routes.DevicesEndpoint) + "/test-device",
			body:       nil,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "UpdateDeviceInfo missing ID in URL",
			method:     http.MethodPatch,
			url:        helperURL(routes.DevicesEndpoint),
			body:       strings.NewReader(`{"name":"X"}`),
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "UpdateDeviceInfo malformed JSON",
			method:     http.MethodPatch,
			url:        helperURL(routes.DevicesEndpoint) + "/test-device",
			body:       strings.NewReader("not-json"),
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "UpdateDeviceInfoLocal wrong method",
			method:     http.MethodPut,
			url:        helperAdminURL(routes.DeviceEndpoint),
			body:       nil,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "UpdateDeviceInfoLocal malformed JSON",
			method:     http.MethodPatch,
			url:        helperAdminURL(routes.DeviceEndpoint),
			body:       strings.NewReader("not-json"),
			wantStatus: http.StatusBadRequest,
		},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			req, err := http.NewRequest(c.method, c.url, c.body)
			require.NoError(t, err)
			if c.body != nil {
				req.Header.Set("Content-Type", api.JsonMIMEType)
			}
			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()
			assert.Equal(t, c.wantStatus, resp.StatusCode, "Unexpected status for %s %s", c.method, c.url)
		})
	}
}

// ptrString is a helper that returns a pointer to the given string.
func ptrString(s string) *string {
	return &s
}

func TestDeviceIDUpdate_UDPStaysLocal_WebSocketSeesCluster(t *testing.T) {
	if len(clusterConfig.nodes) < 2 {
		t.Skip("requires at least two cluster nodes")
	}

	nodeA := clusterConfig.nodes[0]
	nodeB := clusterConfig.nodes[1]
	var nodeC *clusterNode
	if len(clusterConfig.nodes) > 2 {
		nodeC = &clusterConfig.nodes[2]
	}

	originalA := getLocalDeviceInfoOnInstance(t, nodeA.name)
	originalB := getLocalDeviceInfoOnInstance(t, nodeB.name)
	var originalC api.DeviceInfo
	if nodeC != nil {
		originalC = getLocalDeviceInfoOnInstance(t, nodeC.name)
	}

	restoreDeviceInfo := func(nodeName string, original api.DeviceInfo) {
		patchLocalDeviceInfoOnInstance(t, nodeName, api.DevicePatch{
			Id:       ptrString(original.Id),
			Name:     ptrString(original.Name),
			Location: ptrString(original.Location),
		})
	}
	defer restoreDeviceInfo(nodeA.name, originalA)
	defer restoreDeviceInfo(nodeB.name, originalB)
	if nodeC != nil {
		defer restoreDeviceInfo(nodeC.name, originalC)
	}

	wsConn := connectWebSocket(t, getTestURL())
	defer wsConn.Close()
	readWebSocketResponse(t, wsConn, wsTestTimeout) // welcome
	sendWebSocketRequest(t, wsConn, &api.WebSocketRequest{
		ID:      "cluster-device-subscribe",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	})
	readWebSocketResponse(t, wsConn, wsTestTimeout) // subscription response

	targetIDA := fmt.Sprintf("%s-local-udp-a-%d", originalA.Id, time.Now().UnixNano())
	targetIDB := fmt.Sprintf("%s-local-udp-b-%d", originalB.Id, time.Now().UnixNano())

	probeNodes := []string{nodeA.name, nodeB.name}
	if nodeC != nil {
		probeNodes = append(probeNodes, nodeC.name)
	}
	probePath := deployDeviceIDProbeToInstances(t, probeNodes)

	observerA := startDeviceIDProbeOnInstance(t, nodeA.name, probePath, targetIDA, 8*time.Second)
	observerB := startDeviceIDProbeOnInstance(t, nodeB.name, probePath, targetIDA, 8*time.Second)
	var observerC *deviceIDProbeProcess
	if nodeC != nil {
		observerC = startDeviceIDProbeOnInstance(t, nodeC.name, probePath, targetIDA, 8*time.Second)
	}
	patchLocalDeviceInfoOnInstance(t, nodeA.name, api.DevicePatch{Id: &targetIDA})

	waitForProbeMatch(t, observerA, targetIDA)
	assertProbesTimedOut(t, targetIDA, observerB, observerC)

	wsUpdateA := awaitWebSocketDeviceUpdate(t, wsConn, targetIDA, 10*time.Second)
	require.Equal(t, targetIDA, websocketDeviceID(t, wsUpdateA), "websocket should receive node A device ID update")

	observerAFromB := startDeviceIDProbeOnInstance(t, nodeA.name, probePath, targetIDB, 8*time.Second)
	observerBFromB := startDeviceIDProbeOnInstance(t, nodeB.name, probePath, targetIDB, 8*time.Second)
	var observerCFromB *deviceIDProbeProcess
	if nodeC != nil {
		observerCFromB = startDeviceIDProbeOnInstance(t, nodeC.name, probePath, targetIDB, 8*time.Second)
	}
	patchLocalDeviceInfoOnInstance(t, nodeB.name, api.DevicePatch{Id: &targetIDB})

	waitForProbeMatch(t, observerBFromB, targetIDB)
	assertProbesTimedOut(t, targetIDB, observerAFromB, observerCFromB)

	wsUpdateB := awaitWebSocketDeviceUpdate(t, wsConn, targetIDB, 10*time.Second)
	require.Equal(t, targetIDB, websocketDeviceID(t, wsUpdateB), "websocket should receive node B device ID update")
}

func getLocalDeviceInfoOnInstance(t *testing.T, nodeName string) api.DeviceInfo {
	t.Helper()

	output, err := runMultipassCommandOnInstance(t, nodeName, "curl -sS http://127.0.0.1:9090/device")
	require.NoError(t, err, "failed to read local device info on %s: %s", nodeName, output)

	var info api.DeviceInfo
	require.NoError(t, json.Unmarshal([]byte(output), &info))
	return info
}

func patchLocalDeviceInfoOnInstance(t *testing.T, nodeName string, patch api.DevicePatch) {
	t.Helper()

	body, err := json.Marshal(patch)
	require.NoError(t, err)

	command := fmt.Sprintf(
		"curl -sS -X PATCH -H 'Content-Type: application/json' --data %q -o /dev/null -w '%%{http_code}' http://127.0.0.1:9090/device",
		string(body),
	)
	output, err := runMultipassCommandOnInstance(t, nodeName, command)
	require.NoError(t, err, "failed to patch local device info on %s: %s", nodeName, output)
	require.Equal(t, "204", strings.TrimSpace(output), "PATCH /device failed on %s", nodeName)
}

func awaitWebSocketDeviceUpdate(t *testing.T, conn *websocket.Conn, targetDeviceID string, timeout time.Duration) *api.WebSocketResponse {
	t.Helper()

	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		response := readWebSocketResponse(t, conn, time.Until(deadline))
		if response.Type == api.WSMsgTypeDeviceUpdate && websocketDeviceID(t, response) == targetDeviceID {
			return response
		}
	}

	t.Fatalf("timed out waiting for websocket device update")
	return nil
}

func websocketDeviceID(t *testing.T, response *api.WebSocketResponse) string {
	t.Helper()

	payload, ok := response.Data.(map[string]any)
	require.True(t, ok, "websocket device update payload had unexpected type %T", response.Data)
	id, ok := payload["id"].(string)
	require.True(t, ok, "websocket device update missing id field: %#v", payload)
	return id
}

type udpObserverResult struct {
	Status         string `json:"status"`
	DeviceID       string `json:"device_id,omitempty"`
	ExpectedDevice string `json:"expected_device_id,omitempty"`
	LastSeen       string `json:"last_seen,omitempty"`
}

type deviceIDProbeProcess struct {
	nodeName string
	targetID string
	done     chan probeExecutionResult
}

type probeExecutionResult struct {
	result udpObserverResult
	err    error
	raw    string
}

func deployDeviceIDProbeToInstances(t *testing.T, nodeNames []string) string {
	t.Helper()

	remotePath := "/tmp/device_id_probe"
	localBinary := filepath.Join(t.TempDir(), "device_id_probe")
	buildDeviceIDProbe(t, localBinary)

	for _, nodeName := range nodeNames {
		runHostMultipassCommand(t, "transfer", localBinary, fmt.Sprintf("%s:%s", nodeName, remotePath))
		_, err := runMultipassCommandOnInstance(t, nodeName, fmt.Sprintf("chmod +x %q", remotePath))
		require.NoError(t, err, "chmod probe on %s failed", nodeName)
	}

	return remotePath
}

func buildDeviceIDProbe(t *testing.T, outputPath string) {
	t.Helper()

	sourcePath, err := filepath.Abs("../../tools/device_id_probe/main.go")
	require.NoError(t, err, "resolve device_id_probe source path")

	cmd := exec.Command("go", "build", "-o", outputPath, sourcePath)
	cmd.Env = append(os.Environ(),
		"GOOS=linux",
		"GOARCH=arm64",
		"CGO_ENABLED=0",
	)
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, "cross-compile device_id_probe failed: %s", string(out))
}

func startDeviceIDProbeOnInstance(t *testing.T, nodeName, remotePath, targetDeviceID string, timeout time.Duration) *deviceIDProbeProcess {
	t.Helper()

	command := fmt.Sprintf("%q 127.0.0.1 7947 %q %d", remotePath, targetDeviceID, int(timeout.Seconds()))
	args := []string{"exec", nodeName, "--", "bash", "-lc", command}
	cmd := exec.Command("multipass", args...)
	stdout, err := cmd.StdoutPipe()
	require.NoError(t, err)
	stderr, err := cmd.StderrPipe()
	require.NoError(t, err)
	require.NoError(t, cmd.Start())

	readyCh := make(chan error, 1)
	done := make(chan probeExecutionResult, 1)

	go func() {
		scanner := bufio.NewScanner(stdout)
		readySeen := false
		var result udpObserverResult
		var rawLines []string
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line == "" {
				continue
			}
			rawLines = append(rawLines, line)
			if !readySeen {
				if line != "ready" {
					readyCh <- fmt.Errorf("unexpected probe readiness output on %s: %q", nodeName, line)
					return
				}
				readySeen = true
				readyCh <- nil
				continue
			}
			if err := json.Unmarshal([]byte(line), &result); err == nil {
				break
			}
		}
		if !readySeen {
			if err := scanner.Err(); err != nil {
				readyCh <- err
			} else {
				readyCh <- fmt.Errorf("probe on %s exited before signaling ready", nodeName)
			}
		}
		errOut, _ := io.ReadAll(stderr)
		waitErr := cmd.Wait()
		done <- probeExecutionResult{
			result: result,
			err:    waitErr,
			raw:    strings.Join(append(rawLines, strings.TrimSpace(string(errOut))), "\n"),
		}
	}()

	require.NoError(t, <-readyCh)
	return &deviceIDProbeProcess{
		nodeName: nodeName,
		targetID: targetDeviceID,
		done:     done,
	}
}

func waitForProbeMatch(t *testing.T, probe *deviceIDProbeProcess, targetDeviceID string) {
	t.Helper()

	execResult := <-probe.done
	require.NoError(t, execResult.err, "probe on %s failed:\n%s", probe.nodeName, execResult.raw)
	require.Equal(t, "matched", execResult.result.Status, "probe on %s did not match target %q:\n%s", probe.nodeName, targetDeviceID, execResult.raw)
	require.Equal(t, targetDeviceID, execResult.result.DeviceID, "probe on %s matched wrong device ID", probe.nodeName)
}

func assertProbeTimedOut(t *testing.T, probe *deviceIDProbeProcess, forbiddenDeviceID string) {
	t.Helper()

	execResult := <-probe.done
	require.NoError(t, execResult.err, "probe on %s failed:\n%s", probe.nodeName, execResult.raw)
	if execResult.result.Status != "timeout" {
		t.Fatalf("probe on %s unexpectedly saw forbidden device ID %q:\n%s", probe.nodeName, forbiddenDeviceID, execResult.raw)
	}
}

func assertProbesTimedOut(t *testing.T, forbiddenDeviceID string, probes ...*deviceIDProbeProcess) {
	t.Helper()

	var failures []string
	for _, probe := range probes {
		if probe == nil {
			continue
		}
		execResult := <-probe.done
		if execResult.err != nil {
			failures = append(failures, fmt.Sprintf("probe on %s failed:\n%s", probe.nodeName, execResult.raw))
			continue
		}
		if execResult.result.Status != "timeout" {
			failures = append(failures, fmt.Sprintf(
				"probe on %s unexpectedly saw forbidden device ID %q:\n%s",
				probe.nodeName,
				forbiddenDeviceID,
				execResult.raw,
			))
		}
	}
	if len(failures) > 0 {
		t.Fatalf(strings.Join(failures, "\n\n"))
	}
}

func runHostMultipassCommand(t *testing.T, args ...string) string {
	t.Helper()

	cmd := exec.Command("multipass", args...)
	output, err := cmd.CombinedOutput()
	require.NoError(t, err, "multipass %s failed: %s", strings.Join(args, " "), string(output))
	return string(output)
}
