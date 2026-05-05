package cluster

import (
	"encoding/json"
	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"os"
	"path/filepath"
	"strings"

	"google.golang.org/protobuf/types/known/timestamppb"
)

// GetAllSwUpdateInfo fetches /etc/swupdate from every cluster node.
func (c *Cluster) GetAllSwUpdateInfo() []*model.SwUpdateInfo {
	return fetchFromAdmin(
		c,
		c.getSwUpdateInfoLocal,
		routes.SoftwareUpdateInfoLocalEndpoint,
	)
}

// getSwUpdateInfoLocal reads /etc/swupdate on the local node.
func (c *Cluster) getSwUpdateInfoLocal() *model.SwUpdateInfo {
	data, err := os.ReadFile(api.SwUpdateInfoPath)
	if err != nil {
		logging.GetLogger().Error("Failed to read %s: %v", api.SwUpdateInfoPath, err)
		return &model.SwUpdateInfo{}
	}
	var info model.SwUpdateInfo
	if err := json.Unmarshal(data, &info); err != nil {
		logging.GetLogger().Error("Failed to parse %s: %v", api.SwUpdateInfoPath, err)
		return &model.SwUpdateInfo{}
	}
	return &info
}

// GetAllSoftwareUpdateList fetches /mnt/ota bundle list from every cluster node
func (c *Cluster) GetAllSoftwareUpdateList() []*model.SoftwareUpdateBundle {
	var all []*model.SoftwareUpdateBundle
	logger := logging.GetLogger()

	for _, addr := range c.getNodeAdminAddresses() {
		if c.hostIsLocal(addr) {
			all = append(all, c.getSoftwareUpdateListLocal()...)
			continue
		}

		url := utils.GetLocalURL(addr, routes.SoftwareUpdateListEndpoint)
		resp, err := getLocalEndpointResponse(c, addr, routes.SoftwareUpdateListEndpoint)
		if err != nil {
			logger.Error("GET %s failed: %v", url, err)
			continue
		}

		var list model.SoftwareUpdateListResponse
		if err := decodeSlice(resp.Body, &list); err != nil {
			logger.Error("Decode %s failed: %v", url, err)
			continue
		}
		all = append(all, list.GetBundles()...)
	}

	return all
}

// getSoftwareUpdateListLocal reads the local /mnt/ota directory and returns all
func (c *Cluster) getSoftwareUpdateListLocal() []*model.SoftwareUpdateBundle {
	logger := logging.GetLogger()
	sourceIP := c.memberlist.LocalNode().Addr.String()

	entries, err := os.ReadDir(api.SoftwareUpdateOTAPath)
	if err != nil {
		if os.IsNotExist(err) {
			return []*model.SoftwareUpdateBundle{}
		}
		logger.Error("SoftwareUpdate list (local): readdir %s: %v", api.SoftwareUpdateOTAPath, err)
		return []*model.SoftwareUpdateBundle{}
	}

	var bundles []*model.SoftwareUpdateBundle
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

		bundles = append(bundles, &model.SoftwareUpdateBundle{
			Filename:  name,
			Checksum:  checksum,
			SizeBytes: info.Size(),
			Uploaded:  timestamppb.New(info.ModTime().UTC().Round(0)),
			SourceIp:  sourceIP,
		})
	}

	return bundles
}
