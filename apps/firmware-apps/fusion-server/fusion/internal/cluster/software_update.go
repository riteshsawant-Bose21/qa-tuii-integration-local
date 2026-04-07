package cluster

import (
	"encoding/json"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"os"
	"path/filepath"
	"strings"
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

// GetAllSoftwareUpdateList fetches /mnt/ota bundle list from every cluster node and
// returns the de-duplicated union (by filename) so the WebSocket caller always sees
// the full cluster inventory, not just what the VIP holds.
func (c *Cluster) GetAllSoftwareUpdateList() []api.SoftwareUpdateSync {
	return fetchAllFromAdmin(
		c,
		c.getSoftwareUpdateListLocal,
		routes.SoftwareUpdateListEndpoint,
	)
}

// getSoftwareUpdateListLocal reads the local /mnt/ota directory and returns all
// complete (non-.part) bundles with their metadata.
func (c *Cluster) getSoftwareUpdateListLocal() []api.SoftwareUpdateSync {
	logger := logging.GetLogger()
	sourceIP := c.memberlist.LocalNode().Addr.String()

	entries, err := os.ReadDir(api.SoftwareUpdateOTAPath)
	if err != nil {
		if os.IsNotExist(err) {
			return []api.SoftwareUpdateSync{}
		}
		logger.Error("SoftwareUpdate list (local): readdir %s: %v", api.SoftwareUpdateOTAPath, err)
		return []api.SoftwareUpdateSync{}
	}

	var bundles []api.SoftwareUpdateSync
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if strings.HasSuffix(name, ".part") {
			continue
		}
		fullPath := filepath.Join(api.SoftwareUpdateOTAPath, name)

		info, err := entry.Info()
		if err != nil {
			logger.Warn("SoftwareUpdate list (local): stat %s: %v — skipping", fullPath, err)
			continue
		}

		checksum, err := utils.FileChecksum(fullPath)
		if err != nil {
			logger.Warn("SoftwareUpdate list (local): checksum %s: %v — skipping", fullPath, err)
			continue
		}

		bundles = append(bundles, api.SoftwareUpdateSync{
			Filename:  name,
			Checksum:  checksum,
			SizeBytes: info.Size(),
			Uploaded:  info.ModTime().UTC(),
			SourceIP:  sourceIP,
		})
	}

	return bundles
}
