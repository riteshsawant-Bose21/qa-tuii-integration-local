package main

import (
	"bytes"
	stdjson "encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"

	json "github.com/goccy/go-json"
	structpb "google.golang.org/protobuf/types/known/structpb"

	"fusion/internal/api"
	fusionpb "fusion/internal/gen/proto/fusion"
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

	base := &fusionpb.DevicePatch{
		Id:       ptrStringValue("test-device"),
		Location: ptrStringValue("RoomB"),
		Name:     ptrStringValue("BaseDevice"),
	}
	bytesBase, err := stdjson.Marshal(base)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPatch, helperAdminURL(routes.DeviceEndpoint), bytes.NewReader(bytesBase))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)
	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)

	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content when setting base device via PATCH")
	// Now PATCH /device to change only the Name.
	patch := &fusionpb.DevicePatch{
		Name: ptrStringValue("RenamedDevice"),
	}
	bytesPatch, err := stdjson.Marshal(patch)
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

	var updated fusionpb.DeviceInfo
	require.NoError(t, stdjson.NewDecoder(resp.Body).Decode(&updated), "Expected valid JSON after patch")
	assert.Equal(t, base.GetId(), updated.Id, "ID should remain unchanged")
	assert.Equal(t, "RenamedDevice", updated.Name, "Name should have been updated")
	assert.Equal(t, base.GetLocation(), updated.Location, "Location should remain unchanged")
}

// TestUpdateDeviceInfoNotFound attempts PATCH /devices/{id} on a non-existent device.
func TestUpdateDeviceInfoNotFound(t *testing.T) {
	patch := &fusionpb.DevicePatch{
		Name: ptrStringValue("ShouldNotExist"),
	}
	bytesPatch, err := stdjson.Marshal(patch)
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

func TestGetDevicesInfo(t *testing.T) {
	resp, err := http.Get(helperURL(routes.DevicesEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusOK, resp.StatusCode)

	var list fusionpb.DeviceListResponse
	require.NoError(t, stdjson.NewDecoder(resp.Body).Decode(&list))
	require.NotEmpty(t, list.Devices)
}

func TestPutDSPDeploymentPackage(t *testing.T) {
	frequencies, err := structpb.NewList([]any{100.0, 200.0, 300.0})
	require.NoError(t, err)

	payload := &fusionpb.DeviceConfigurationPackage{
		DroConditionedOutput: &fusionpb.DroConditionedOutput{
			Devices: []*fusionpb.DroConditionedDevice{
				{
					Id:         "provisioned-device",
					Label:      "Provisioned Device",
					DeviceType: "fusion_c1",
					DspStaticConfig: &fusionpb.StaticConfiguration{
						AudioTasks: []*fusionpb.AudioTask{
							{
								Name: "Main Task",
								Blocks: []*fusionpb.Block{
									{
										Name:      "device_config_eq",
										Algorithm: "eq",
									},
								},
							},
						},
					},
				},
			},
		},
		FusionConnectAdditions: &fusionpb.FusionConnectAdditions{
			AudioStreams: []*fusionpb.FusionConnectAudioStream{
				{
					SourceDeviceUid: "provisioned-device",
					DestDeviceUid:   "sink-device",
					Properties: &fusionpb.FusionConnectAudioStreamProperties{
						Channels:        2,
						IsFusionConnect: true,
					},
				},
			},
			Settings: &fusionpb.FusionConnectAudioSettings{
				Audio: map[string]*fusionpb.AudioBlockSettings{
					"device_config_eq": {
						Parameters: map[string]*structpb.Value{
							"frequencies": structpb.NewListValue(frequencies),
						},
					},
				},
			},
		},
	}

	body, err := stdjson.Marshal(payload)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPut, helperURL(routes.DeviceEndpoint), bytes.NewReader(body))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK on PUT /device")

	getResp, err := http.Get(helperURL(routes.DeviceEndpoint))
	require.NoError(t, err)
	defer getResp.Body.Close()
	assert.Equal(t, http.StatusOK, getResp.StatusCode, "Expected 200 OK on GET /device")

	var got fusionpb.DeviceConfigurationPackage
	require.NoError(t, stdjson.NewDecoder(getResp.Body).Decode(&got), "Expected valid JSON from GET /device")
	require.NotNil(t, got.DroConditionedOutput)
	require.NotNil(t, got.FusionConnectAdditions)
	require.Len(t, got.DroConditionedOutput.Devices, 1)
	require.Len(t, got.FusionConnectAdditions.AudioStreams, 1)
	require.NotNil(t, got.FusionConnectAdditions.Settings)

	assert.Equal(t, "provisioned-device", got.DroConditionedOutput.Devices[0].Id)
	assert.Equal(t, "Provisioned Device", got.DroConditionedOutput.Devices[0].Label)
	assert.Equal(t, "provisioned-device", got.FusionConnectAdditions.AudioStreams[0].SourceDeviceUid)
	assert.Equal(t, "sink-device", got.FusionConnectAdditions.AudioStreams[0].DestDeviceUid)
	require.Contains(t, got.FusionConnectAdditions.Settings.Audio, "device_config_eq")
	assert.Equal(
		t,
		payload.FusionConnectAdditions.Settings.Audio["device_config_eq"].Parameters["frequencies"].AsInterface(),
		got.FusionConnectAdditions.Settings.Audio["device_config_eq"].Parameters["frequencies"].AsInterface(),
	)

	projectedFrequencies, err := getClusterAudioSettingArray(clusterServerURL, "device_config_eq", "frequencies")
	require.NoError(t, err)
	assert.Equal(t, []any{100.0, 200.0, 300.0}, projectedFrequencies)
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
			name:       "GetDSPDeploymentPackage wrong method",
			url:        helperURL(routes.DeviceEndpoint),
			method:     http.MethodPost,
			body:       nil,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "PutDSPDeploymentPackage malformed JSON",
			method:     http.MethodPut,
			url:        helperURL(routes.DeviceEndpoint),
			body:       strings.NewReader("not-json"),
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "PutDSPDeploymentPackage missing required settings",
			method:     http.MethodPut,
			url:        helperURL(routes.DeviceEndpoint),
			body:       strings.NewReader(`{"dro_conditioned_output":{"devices":[{"id":"device-a"}]},"fusion_connect_additions":{}}`),
			wantStatus: http.StatusBadRequest,
		},
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

func ptrStringValue(s string) *string {
	return &s
}

func getClusterAudioSettingArray(baseURL, blockID, param string) ([]any, error) {
	resp, err := http.Get(fmt.Sprintf("%s/settings/audio/%s/%s", baseURL, blockID, param))
	if err != nil {
		return nil, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status code: %d response: %s", resp.StatusCode, string(body))
	}

	var response struct {
		Value any `json:"value"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to decode response: %v", err)
	}

	array, ok := response.Value.([]any)
	if !ok {
		return nil, fmt.Errorf("value is not an array: %T", response.Value)
	}
	return array, nil
}
