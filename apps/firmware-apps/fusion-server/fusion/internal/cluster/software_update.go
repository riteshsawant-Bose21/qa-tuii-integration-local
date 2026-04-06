package cluster

import (
	"encoding/json"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"os"
)

// GetAllSwUpdateInfo fetches /etc/swupdate from every cluster node.
func (c *Cluster) GetAllSwUpdateInfo() []api.SwUpdateInfo {
	return fetchFromAdmin(
		c,
		c.getSwUpdateInfoLocal,
		routes.SoftwareUpdateInfoLocalEndpoint,
	)
}

// getSwUpdateInfoLocal reads /etc/swupdate on the local node.
func (c *Cluster) getSwUpdateInfoLocal() api.SwUpdateInfo {
	data, err := os.ReadFile(api.SwUpdateInfoPath)
	if err != nil {
		logging.GetLogger().Error("Failed to read %s: %v", api.SwUpdateInfoPath, err)
		return api.SwUpdateInfo{}
	}
	var info api.SwUpdateInfo
	if err := json.Unmarshal(data, &info); err != nil {
		logging.GetLogger().Error("Failed to parse %s: %v", api.SwUpdateInfoPath, err)
		return api.SwUpdateInfo{}
	}
	return info
}
