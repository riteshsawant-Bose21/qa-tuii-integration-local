package main

import (
	"net/http"
	"testing"

	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestEndpointsEndpoint(t *testing.T) {
	resp, err := http.Get(clusterServerURL + routes.EndpointsEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /endpoints")

	var endpointsResp fusionpb.EndpointListResponse
	require.NoError(t, decodeProtoBody(resp.Body, &endpointsResp), "Expected valid protobuf JSON from GET /endpoints")

	assert.NotEmpty(t, endpointsResp.Routes, "endpoints.routes should be populated")
	assert.Contains(t, endpointsResp.Routes, "GET /version")
	assert.Contains(t, endpointsResp.Routes, "GET /endpoints")
}
