package main

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestClusterRebootLocal exercises POST /cluster/reboot in local mode.
func TestClusterRebootLocal(t *testing.T) {
	url := "http://127.0.0.1:8080/cluster/reboot"

	resp, err := http.Post(url, "application/json", nil)
	require.NoError(t, err, "POST /cluster/reboot should not error")
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content for reboot in local mode")
}