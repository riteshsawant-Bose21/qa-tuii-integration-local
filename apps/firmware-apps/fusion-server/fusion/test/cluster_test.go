package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/routes"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	clusterServerURL      = "http://192.168.64.100:8080"
	clusterServerAdminURL = "http://192.168.64.100:9090"
)

func helperURL(path string) string {
	return clusterServerURL + path
}

func helperAdminURL(path string) string {
	return clusterServerAdminURL + path
}

// TestUpdateDeviceInfoLocal exercises PATCH /device (UpdateDeviceInfoLocal).
func TestUpdateDeviceInfoLocal(t *testing.T) {

	base := persistence.DeviceInfo{
		Id:       "test-device",
		Location: "RoomB",
		Name:     "BaseDevice",
	}
	bytesBase, err := json.Marshal(base)
	require.NoError(t, err)

	resp, err := http.Post(helperAdminURL(routes.DeviceEndpoint), api.JsonMIMEType, bytes.NewReader(bytesBase))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content when setting base device")

	// Now PATCH /device to change only the Name.
	patch := persistence.DevicePatch{
		Name: ptrString("RenamedDevice"),
	}
	bytesPatch, err := json.Marshal(patch)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPatch, helperAdminURL(routes.DeviceEndpoint), bytes.NewReader(bytesPatch))
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

	var updated persistence.DeviceInfo
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&updated), "Expected valid JSON after patch")
	assert.Equal(t, base.Id, updated.Id, "ID should remain unchanged")
	assert.Equal(t, "RenamedDevice", updated.Name, "Name should have been updated")
	assert.Equal(t, base.Location, updated.Location, "Location should remain unchanged")
	assert.Equal(t, base.Address, updated.Address, "Address should remain unchanged")
}

// TestUpdateDeviceInfoNotFound attempts PATCH /devices/{id} on a non-existent device.
func TestUpdateDeviceInfoNotFound(t *testing.T) {
	patch := persistence.DevicePatch{
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
