package main

import (
	"fmt"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestClusterReboot exercises POST /cluster/reboot on the public API.
func TestClusterRebootLocal(t *testing.T) {
	url := fmt.Sprintf("%s/cluster/reboot", clusterConfig.vip)

	resp, err := http.Post(url, "application/json", nil)
	require.NoError(t, err, "POST /cluster/reboot should not error")
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content for public reboot request")
}
