package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
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
	resp, err := http.Get(helperAdminURL(routes.DeviceEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK on initial GET /device")

	var original model.DeviceInfo
	require.NoError(t, decodeProtoBody(resp.Body, &original), "Expected valid JSON for original device info")

	defer func() {
		restore := &model.DevicePatch{
			Id:       ptrStringValue(original.GetId()),
			Location: ptrStringValue(original.GetLocation()),
			Name:     ptrStringValue(original.GetName()),
		}
		body, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(restore)
		require.NoError(t, err)

		req, err := http.NewRequest(http.MethodPatch, helperAdminURL(routes.DeviceEndpoint), bytes.NewReader(body))
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)

		restoreResp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer restoreResp.Body.Close()
		assert.Equal(t, http.StatusNoContent, restoreResp.StatusCode, "restore PATCH /device should succeed")
	}()
	base := &model.DevicePatch{
		Id:       ptrStringValue("test-device"),
		Location: ptrStringValue("RoomB"),
		Name:     ptrStringValue("BaseDevice"),
	}
	bytesBase, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(base)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPatch, helperAdminURL(routes.DeviceEndpoint), bytes.NewReader(bytesBase))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)
	resp, err = http.DefaultClient.Do(req)
	require.NoError(t, err)

	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content when setting base device via PATCH")
	// Now PATCH /device to change only the Name.
	patch := &model.DevicePatch{
		Name: ptrStringValue("RenamedDevice"),
	}
	bytesPatch, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(patch)
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

	var updated model.DeviceInfo
	require.NoError(t, decodeProtoBody(resp.Body, &updated), "Expected valid JSON after patch")
	assert.Equal(t, base.GetId(), updated.Id, "ID should remain unchanged")
	assert.Equal(t, "RenamedDevice", updated.Name, "Name should have been updated")
	assert.Equal(t, base.GetLocation(), updated.Location, "Location should remain unchanged")
}

// TestUpdateDeviceInfoNotFound attempts PATCH /devices/{id} on a non-existent device.
func TestUpdateDeviceInfoNotFound(t *testing.T) {
	patch := &model.DevicePatch{
		Name: ptrStringValue("ShouldNotExist"),
	}
	bytesPatch, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(patch)
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
	list := getDevicesInfo(t)
	require.NotEmpty(t, list.Devices)
	for _, device := range list.Devices {
		assert.NotEmpty(t, device.GetId(), "device id should be populated")
		assert.NotEmpty(t, device.GetAddress(), "device address should be populated")
		assert.NotEmpty(t, device.GetSoftwareUpdateVersion(), "software_update_version should be populated")
		assert.NotEmpty(t, device.GetFusionMonorepoBranch(), "fusion_monorepo_branch should be populated")
		assert.NotEmpty(t, device.GetFusionMonorepoCommitHash(), "fusion_monorepo_commit_hash should be populated")
		assert.NotEmpty(t, device.GetJenkinsBuildNumber(), "jenkins_build_number should be populated")
		assert.Greater(t, device.GetVrrpPriority(), int32(0), "vrrp_priority should be a positive value")
	}
}

func TestUpdateDeviceInfoSuccess(t *testing.T) {
	list := getDevicesInfo(t)
	require.NotEmpty(t, list.Devices)

	device := list.Devices[0]
	deviceID := device.GetId()
	originalName := device.GetName()
	updatedName := fmt.Sprintf("ProtoDevice-%d", time.Now().UnixNano())

	defer func() {
		restore := &model.DevicePatch{Name: ptrStringValue(originalName)}
		body, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(restore)
		require.NoError(t, err)
		req, err := http.NewRequest(http.MethodPatch, helperURL(routes.DevicesEndpoint)+"/"+deviceID, bytes.NewReader(body))
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusNoContent, resp.StatusCode, "restore PATCH /devices/{id} should succeed")
	}()

	patch := &model.DevicePatch{Name: ptrStringValue(updatedName)}
	body, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(patch)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPatch, helperURL(routes.DevicesEndpoint)+"/"+deviceID, bytes.NewReader(body))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "PATCH /devices/{id} should succeed")

	refreshed := getDevicesInfo(t)
	var found *model.DeviceInfo
	for _, candidate := range refreshed.Devices {
		if candidate.GetId() == deviceID {
			found = candidate
			break
		}
	}
	require.NotNil(t, found, "patched device should still be present in GET /devices")
	assert.Equal(t, updatedName, found.GetName(), "public device patch should be visible via GET /devices")
}

// TestUpdateDeviceInfoRejectsDuplicateID verifies that PATCH /devices/{id} returns
// an error when attempting to set a device ID that is already in use by another node.
func TestUpdateDeviceInfoRejectsDuplicateID(t *testing.T) {
	list := getDevicesInfo(t)
	require.GreaterOrEqual(t, len(list.Devices), 2, "requires at least two visible devices")

	infoA := list.Devices[0]
	infoB := list.Devices[1]

	// Attempt to set node A's device ID to the same value as node B's.
	patch := &model.DevicePatch{Id: ptrStringValue(infoB.GetId())}
	body, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(patch)
	require.NoError(t, err)

	target := helperURL(fmt.Sprintf("%s/%s", routes.DevicesEndpoint, infoA.GetId()))
	req, err := http.NewRequest(http.MethodPatch, target, bytes.NewReader(body))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusConflict, resp.StatusCode,
		"PATCH /devices/{id} with duplicate ID should return 409 Conflict")

	// Verify node A's ID was not changed.
	refreshed := getDevicesInfo(t)
	var afterA *model.DeviceInfo
	for _, candidate := range refreshed.Devices {
		if candidate.GetAddress() == infoA.GetAddress() {
			afterA = candidate
			break
		}
	}
	require.NotNil(t, afterA, "node A device should still be present in GET /devices")
	assert.Equal(t, infoA.GetId(), afterA.GetId(), "node A device ID must remain unchanged")
}

// TestUpdateDeviceInfoRejectsDuplicateName verifies that PATCH /devices/{id} returns
// an error when attempting to set a device name that is already in use by another node.
func TestUpdateDeviceInfoRejectsDuplicateName(t *testing.T) {
	list := getDevicesInfo(t)
	require.GreaterOrEqual(t, len(list.Devices), 2, "requires at least two visible devices")

	infoA := list.Devices[0]
	infoB := list.Devices[1]

	// Attempt to set node A's name to the same value as node B's.
	patch := &model.DevicePatch{Name: ptrStringValue(infoB.GetName())}
	body, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(patch)
	require.NoError(t, err)

	target := helperURL(fmt.Sprintf("%s/%s", routes.DevicesEndpoint, infoA.GetId()))
	req, err := http.NewRequest(http.MethodPatch, target, bytes.NewReader(body))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusConflict, resp.StatusCode,
		"PATCH /devices/{id} with duplicate name should return 409 Conflict")

	// Verify node A's name was not changed.
	refreshed := getDevicesInfo(t)
	var afterA *model.DeviceInfo
	for _, candidate := range refreshed.Devices {
		if candidate.GetAddress() == infoA.GetAddress() {
			afterA = candidate
			break
		}
	}
	require.NotNil(t, afterA, "node A device should still be present in GET /devices")
	assert.Equal(t, infoA.GetName(), afterA.GetName(), "node A device name must remain unchanged")
}

func TestPutDSPDeploymentPackage(t *testing.T) {
	payload, blockID := testDeviceConfigurationPackage(t)

	resp, putResp := putDeviceConfigurationPackage(t, payload)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK on PUT /device")
	assert.Equal(t, "success", putResp.GetStatus())
	require.NotNil(t, putResp.GetUpdates(), "PUT /device should return typed updates on first apply")
	assert.Contains(t, putResp.GetUpdates().GetFields(), "dro_conditioned_output")
	assert.Contains(t, putResp.GetUpdates().GetFields(), "fusion_connect_additions")
	assert.Contains(t, putResp.GetUpdates().GetFields(), "devices")
	assert.Contains(t, putResp.GetUpdates().GetFields(), "audio_streams")
	assert.Contains(t, putResp.GetUpdates().GetFields(), "settings")

	getResp, err := http.Get(helperURL(routes.DeviceEndpoint))
	require.NoError(t, err)
	defer getResp.Body.Close()
	assert.Equal(t, http.StatusOK, getResp.StatusCode, "Expected 200 OK on GET /device")

	var got model.DeviceConfigurationPackage
	require.NoError(t, decodeProtoBody(getResp.Body, &got), "Expected valid JSON from GET /device")
	require.NotNil(t, got.DroConditionedOutput)
	require.NotNil(t, got.FusionConnectAdditions)
	require.Len(t, got.DroConditionedOutput.Devices, 1)
	require.Len(t, got.FusionConnectAdditions.AudioStreams, 1)
	require.NotNil(t, got.FusionConnectAdditions.Settings)

	assert.Equal(t, payload.DroConditionedOutput.Devices[0].Id, got.DroConditionedOutput.Devices[0].Id)
	assert.Equal(t, "Provisioned Device", got.DroConditionedOutput.Devices[0].Label)
	assert.Equal(t, payload.FusionConnectAdditions.AudioStreams[0].SourceDeviceUid, got.FusionConnectAdditions.AudioStreams[0].SourceDeviceUid)
	assert.Equal(t, payload.FusionConnectAdditions.AudioStreams[0].DestDeviceUid, got.FusionConnectAdditions.AudioStreams[0].DestDeviceUid)
	require.Contains(t, got.FusionConnectAdditions.Settings.Audio, blockID)
	require.NotNil(t, got.FusionConnectAdditions.Settings.Audio[blockID].GetPeq())
	assert.Equal(t, payload.FusionConnectAdditions.Settings.Audio[blockID].GetAlgorithm(), got.FusionConnectAdditions.Settings.Audio[blockID].GetAlgorithm())
	assert.Equal(t, payload.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetFrequency(), got.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetFrequency())
	assert.Equal(t, payload.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetBandEnable(), got.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetBandEnable())
	assert.Equal(t, payload.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetGain(), got.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetGain())
	assert.Equal(t, payload.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetQ(), got.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetQ())
	assert.Equal(t, payload.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetType(), got.FusionConnectAdditions.Settings.Audio[blockID].GetPeq().GetType())

	projectedFrequencies, err := getClusterAudioSettingArray(clusterServerURL, blockID, "frequency")
	require.NoError(t, err)
	assert.Equal(t, []any{100.0, 200.0, 300.0}, projectedFrequencies)
}

func TestGetDSPDeploymentPackage(t *testing.T) {
	resp, err := http.Get(helperURL(routes.DeviceEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK on standalone GET /device")

	var got model.DeviceConfigurationPackage
	require.NoError(t, decodeProtoBody(resp.Body, &got), "Expected valid JSON from GET /device")

	// Standalone GET /device should always return a valid typed envelope, even if
	// one or both subtrees are currently absent from state.
	if got.DroConditionedOutput != nil {
		assert.NotNil(t, got.DroConditionedOutput.Devices)
	}
	if got.FusionConnectAdditions != nil {
		assert.NotNil(t, got.FusionConnectAdditions.AudioStreams)
	}
}

func TestPutDSPDeploymentPackageNoop(t *testing.T) {
	payload, _ := testDeviceConfigurationPackage(t)

	resp, _ := putDeviceConfigurationPackage(t, payload)
	resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "first PUT /device should succeed")

	resp, putResp := putDeviceConfigurationPackage(t, payload)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "second PUT /device should succeed")
	assert.Equal(t, "noop", putResp.GetStatus())
	assert.Nil(t, putResp.GetUpdates(), "noop PUT /device should not include updates")
}

func TestDeviceProtoStrictness(t *testing.T) {
	t.Run("PutDSPDeploymentPackage unknown field", func(t *testing.T) {
		body := strings.NewReader(`{"dro_conditioned_output":{"devices":[{"id":"device-a","unknown_field":1}]},"fusion_connect_additions":{"settings":{"audio":{}}}}`)
		req, err := http.NewRequest(http.MethodPut, helperURL(routes.DeviceEndpoint), body)
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("PutDSPDeploymentPackage invalid typed field", func(t *testing.T) {
		body := strings.NewReader(`{"dro_conditioned_output":{"devices":[{"id":"device-a"}]},"fusion_connect_additions":{"audio_streams":[{"source_device_uid":"device-a","dest_device_uid":"device-b","properties":{"channels":"two"}}],"settings":{"audio":{}}}}`)
		req, err := http.NewRequest(http.MethodPut, helperURL(routes.DeviceEndpoint), body)
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("PutDSPDeploymentPackage missing dro_conditioned_output", func(t *testing.T) {
		body := strings.NewReader(`{"fusion_connect_additions":{"settings":{"audio":{}}}}`)
		req, err := http.NewRequest(http.MethodPut, helperURL(routes.DeviceEndpoint), body)
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("PutDSPDeploymentPackage missing fusion_connect_additions", func(t *testing.T) {
		body := strings.NewReader(`{"dro_conditioned_output":{"devices":[{"id":"device-a"}]}}`)
		req, err := http.NewRequest(http.MethodPut, helperURL(routes.DeviceEndpoint), body)
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("PutDSPDeploymentPackage missing fusion_connect_additions.settings", func(t *testing.T) {
		body := strings.NewReader(`{"dro_conditioned_output":{"devices":[{"id":"device-a"}]},"fusion_connect_additions":{}}`)
		req, err := http.NewRequest(http.MethodPut, helperURL(routes.DeviceEndpoint), body)
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("UpdateDeviceInfo unknown field", func(t *testing.T) {
		list := getDevicesInfo(t)
		require.NotEmpty(t, list.Devices)
		body := strings.NewReader(`{"name":"ProtoStrict","unknown_field":"x"}`)
		req, err := http.NewRequest(http.MethodPatch, helperURL(routes.DevicesEndpoint)+"/"+list.Devices[0].GetId(), body)
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("UpdateDeviceInfo invalid typed field", func(t *testing.T) {
		list := getDevicesInfo(t)
		require.NotEmpty(t, list.Devices)
		body := strings.NewReader(`{"name":123}`)
		req, err := http.NewRequest(http.MethodPatch, helperURL(routes.DevicesEndpoint)+"/"+list.Devices[0].GetId(), body)
		require.NoError(t, err)
		req.Header.Set("Content-Type", api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})
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

func getDevicesInfo(t *testing.T) *model.DeviceListResponse {
	t.Helper()
	resp, err := http.Get(helperURL(routes.DevicesEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	var list model.DeviceListResponse
	require.NoError(t, decodeProtoBody(resp.Body, &list))
	return &list
}

func testDeviceConfigurationPackage(t *testing.T) (*model.DeviceConfigurationPackage, string) {
	t.Helper()
	suffix := fmt.Sprintf("%d", time.Now().UnixNano())
	deviceID := "provisioned-device-" + suffix
	sinkID := "sink-device-" + suffix
	blockID := "device_config_eq_" + suffix

	return &model.DeviceConfigurationPackage{
		DroConditionedOutput: &model.DroConditionedOutput{
			Devices: []*model.DroConditionedDevice{
				{
					Id:         deviceID,
					Label:      "Provisioned Device",
					DeviceType: "fusion_c1",
					DspStaticConfig: &model.StaticConfiguration{
						AudioTasks: []*model.AudioTask{
							{
								Name: "Main Task",
								Blocks: []*model.Block{
									{
										Name:      blockID,
										Algorithm: "peq",
									},
								},
							},
						},
					},
				},
			},
		},
		FusionConnectAdditions: &model.FusionConnectAdditions{
			AudioStreams: []*model.FusionConnectAudioStream{
				{
					SourceDeviceUid: deviceID,
					DestDeviceUid:   sinkID,
					Properties: &model.FusionConnectAudioStreamProperties{
						Channels:        2,
						IsFusionConnect: proto.Bool(true),
					},
				},
			},
			Settings: &model.FusionConnectAudioSettings{
				Audio: map[string]*model.AudioBlockSettings{
					blockID: {
						Algorithm: "peq",
						Kind: &model.AudioBlockSettings_Peq{
							Peq: &model.PeqBlockSettings{
								BandEnable: []bool{true, false, true},
								Frequency:  []float64{100.0, 200.0, 300.0},
								Gain:       []float64{1.0, 2.0, 3.0},
								Q:          []float64{0.7, 1.1, 1.5},
								Type:       []string{"peq", "peq", "peq"},
							},
						},
					},
				},
			},
		},
	}, blockID
}

func putDeviceConfigurationPackage(t *testing.T, payload *model.DeviceConfigurationPackage) (*http.Response, *model.DeviceConfigurationPackagePutResponse) {
	t.Helper()
	body, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(payload)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPut, helperURL(routes.DeviceEndpoint), bytes.NewReader(body))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)

	var putResp model.DeviceConfigurationPackagePutResponse
	require.NoError(t, decodeProtoBody(resp.Body, &putResp), "Expected valid JSON from PUT /device")

	return resp, &putResp
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

func decodeProtoBody(body io.Reader, msg proto.Message) error {
	data, err := io.ReadAll(body)
	if err != nil {
		return err
	}
	return protojson.Unmarshal(data, msg)
}

func getLocalDeviceInfoOnInstance(t *testing.T, nodeName string) *model.DeviceInfo {
	t.Helper()
	require.NotNil(t, clusterConfig, "clusterConfig must be initialized")

	var nodeAddr string
	for _, n := range clusterConfig.nodes {
		if n.name == nodeName {
			nodeAddr = n.address
			break
		}
	}
	require.NotEmpty(t, nodeAddr, "node %q not found in cluster config", nodeName)

	parsed, err := url.Parse(nodeAddr)
	require.NoError(t, err)

	adminURL := parsed.Scheme + "://" + parsed.Hostname() + ":9090" + routes.DeviceEndpoint

	resp, err := http.Get(adminURL)
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	var info model.DeviceInfo
	require.NoError(t, decodeProtoBody(resp.Body, &info))
	return &info
}
