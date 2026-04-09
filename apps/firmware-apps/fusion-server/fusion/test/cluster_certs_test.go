package main

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion/internal/routes"

	json "github.com/goccy/go-json"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const certsServerURL = "http://192.168.2.100:8080"

func certsHelperURL(path string) string {
	return certsServerURL + path
}

// firstDeviceID fetches GET /devices and returns the first device's ID.
func firstDeviceID(t *testing.T) string {
	t.Helper()
	resp, err := http.Get(certsHelperURL(routes.DevicesEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode, "GET /devices failed")

	var devices []api.DeviceInfo
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&devices))
	require.NotEmpty(t, devices, "No devices found in cluster")
	return devices[0].Id
}

// generateSelfSignedCertPEM creates a minimal self-signed X.509 certificate in PEM format.
func generateSelfSignedCertPEM(t *testing.T) []byte {
	t.Helper()
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	require.NoError(t, err)
	serialNumberLimit := new(big.Int).Lsh(big.NewInt(1), 128)
	serialNumber, err := rand.Int(rand.Reader, serialNumberLimit)
	require.NoError(t, err)
	template := x509.Certificate{
		SerialNumber: serialNumber,
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(24 * time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature | x509.KeyUsageKeyEncipherment,
	}
	derBytes, err := x509.CreateCertificate(rand.Reader, &template, &template, &privKey.PublicKey, privKey)
	require.NoError(t, err)
	var buf bytes.Buffer
	err = pem.Encode(&buf, &pem.Block{Type: "CERTIFICATE", Bytes: derBytes})
	require.NoError(t, err)
	return buf.Bytes()
}

// TestGetCSR exercises GET /devices/{id}/csr.
func TestGetCSR(t *testing.T) {
	deviceID := firstDeviceID(t)
	url := certsHelperURL(fmt.Sprintf("%s/%s/csr", routes.DevicesEndpoint, deviceID))
	resp, err := http.Get(url)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /devices/{id}/csr")

	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	assert.NotEmpty(t, body, "Expected non-empty CSR in response body")
}

// TestSetDeviceCertificate exercises POST /devices/{id}/certificate.
func TestSetDeviceCertificate(t *testing.T) {
	deviceID := firstDeviceID(t)
	certPEM := generateSelfSignedCertPEM(t)
	url := certsHelperURL(fmt.Sprintf("%s/%s/certificate", routes.DevicesEndpoint, deviceID))
	req, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(certPEM))
	require.NoError(t, err)
	req.Header.Set("Content-Type", api.TextMIMEType)
	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content from POST /devices/{id}/certificate")
}

// TestResetDeviceCertificate exercises DELETE /devices/{id}/reset.
func TestResetDeviceCertificate(t *testing.T) {
	deviceID := firstDeviceID(t)
	url := certsHelperURL(fmt.Sprintf("%s/%s/reset", routes.DevicesEndpoint, deviceID))
	req, err := http.NewRequest(http.MethodDelete, url, nil)
	require.NoError(t, err)
	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content from DELETE /devices/{id}/reset")
}

// TestCertificateErrorCases groups wrong-method scenarios for certificate endpoints.
func TestCertificateErrorCases(t *testing.T) {
	cases := []struct {
		name       string
		url        string
		method     string
		wantStatus int
	}{
		{
			name:       "GetCSR wrong method",
			url:        certsHelperURL(fmt.Sprintf("%s/%s/csr", routes.DevicesEndpoint, "test-device")),
			method:     http.MethodPost,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "GetCSR non-existent device",
			url:        certsHelperURL(fmt.Sprintf("%s/%s/csr", routes.DevicesEndpoint, "nonexistent")),
			method:     http.MethodGet,
			wantStatus: http.StatusNotFound,
		},
		{
			name:       "SetDeviceCertificate wrong method",
			url:        certsHelperURL(fmt.Sprintf("%s/%s/certificate", routes.DevicesEndpoint, "test-device")),
			method:     http.MethodGet,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "ResetDeviceCertificate wrong method",
			url:        certsHelperURL(fmt.Sprintf("%s/%s/reset", routes.DevicesEndpoint, "test-device")),
			method:     http.MethodPost,
			wantStatus: http.StatusMethodNotAllowed,
		},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			req, err := http.NewRequest(c.method, c.url, nil)
			require.NoError(t, err)
			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()
			assert.Equal(t, c.wantStatus, resp.StatusCode, "Unexpected status for %s %s", c.method, c.url)
		})
	}
}
