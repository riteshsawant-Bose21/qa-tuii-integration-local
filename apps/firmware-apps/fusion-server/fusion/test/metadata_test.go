package main

import (
	"net/http"
	"testing"

	"fusion/internal/routes"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestGetDatabaseMetadataEndpoint(t *testing.T) {
	resp, err := http.Get(clusterServerURL + routes.MetadataEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /metadata")

	var metadataResp model.DatabaseMetadataResponse
	require.NoError(t, decodeProtoBody(resp.Body, &metadataResp), "Expected valid protobuf JSON from GET /metadata")
	require.NotNil(t, metadataResp.Metadata, "Expected metadata payload")
	require.NotNil(t, metadataResp.Metadata.Version, "Expected metadata.version payload")

	assert.NotEmpty(t, metadataResp.Metadata.Version.NodeId, "metadata.version.node_id should be populated")
	assert.NotEmpty(t, metadataResp.Metadata.Hash, "metadata.hash should be populated")
}
