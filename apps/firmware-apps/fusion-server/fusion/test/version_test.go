package main

import (
	"net/http"
	"testing"

	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestVersionEndpoint(t *testing.T) {
	resp, err := http.Get(clusterServerURL + routes.VersionEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /version")

	var versionResp model.VersionResponse
	require.NoError(t, decodeProtoBody(resp.Body, &versionResp), "Expected valid protobuf JSON from GET /version")

	assert.NotEmpty(t, versionResp.Name, "version.name should be populated")
	assert.NotEmpty(t, versionResp.Version, "version.version should be populated")
	assert.NotEmpty(t, versionResp.Commit, "version.commit should be populated")
	assert.NotEmpty(t, versionResp.BuildTime, "version.build_time should be populated")
}
