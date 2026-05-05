package main

import (
	"net/http"
	"testing"

	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestHealthEndpoint(t *testing.T) {
	resp, err := http.Get(clusterServerURL + routes.HealthEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Contains(t, []int{http.StatusOK, http.StatusServiceUnavailable}, resp.StatusCode, "Expected /health to return a valid health status code")

	var healthResp model.HealthCheckResponse
	require.NoError(t, decodeProtoBody(resp.Body, &healthResp), "Expected valid protobuf JSON from GET /health")
	require.NotNil(t, healthResp.NodeHealth, "Expected node_health payload")

	assert.NotEmpty(t, healthResp.Status, "health.status should be populated")
	assert.NotEmpty(t, healthResp.NodeHealth.Status, "health.node_health.status should be populated")
}

func TestClusterStatusEndpoint(t *testing.T) {
	resp, err := http.Get(clusterServerURL + routes.ClusterStatusEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /cluster/status")

	var clusterResp model.ClusterInfo
	require.NoError(t, decodeProtoBody(resp.Body, &clusterResp), "Expected valid protobuf JSON from GET /cluster/status")

	assert.NotEmpty(t, clusterResp.LocalNode, "cluster.local_node should be populated")
	assert.NotZero(t, clusterResp.MemberCount, "cluster.member_count should be populated")
}
