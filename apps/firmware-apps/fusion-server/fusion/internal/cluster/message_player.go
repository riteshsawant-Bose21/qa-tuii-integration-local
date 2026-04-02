package cluster

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/routes"
	"io"
	"net/http"
	"os"
	"path/filepath"

	"fusion-services-core/logging"

	json "github.com/goccy/go-json"
	hashicorpMemberlist "github.com/hashicorp/memberlist"
)

func (c *Cluster) initialAudioSync() {
	peers := c.memberlist.Members()
	if len(peers) <= 1 {
		return
	}

	var peer *hashicorpMemberlist.Node
	for _, p := range peers {
		if p.Name != c.memberlist.LocalNode().Name {
			peer = p
			break
		}
	}

	if peer != nil {
		_ = c.initialAudioSyncFromPeer(peer)
	}

	c.reconcileLocalAudioState()
}

func (c *Cluster) initialAudioSyncFromPeer(peer *hashicorpMemberlist.Node) error {
	logger := logging.GetLogger()

	url := fmt.Sprintf("http://%s:%s%s", peer.Addr, api.HTTPPort, routes.PAVAMessagesEndpoint)

	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("messages fetch: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("metadata list error: %d %s", resp.StatusCode, string(body))
	}

	var metas []api.AudioMetadata
	if err := json.NewDecoder(resp.Body).Decode(&metas); err != nil {
		return fmt.Errorf("decode metadata: %w", err)
	}

	peerURL := fmt.Sprintf("http://%s:%s", peer.Addr, api.HTTPPort)

	for _, meta := range metas {
		update := api.AudioSyncUpdate{
			Metadata: meta,
			URL:      peerURL,
		}
		if err := c.delegate.persistence.SyncAudioFile(&update); err != nil {
			logger.Error("initial sync failed for %s: %v", meta.Filename, err)
		}
	}

	return nil
}

// reconcileLocalAudioState reconciles audio files and metadata
func (c *Cluster) reconcileLocalAudioState() {
	logger := logging.GetLogger()

	metas, err := c.delegate.persistence.ListAudioMetadata()
	if err != nil {
		logger.Error("Audio reconciliation: failed to list metadata: %v", err)
		return
	}

	metaByFilename := make(map[string]*api.AudioMetadata, len(metas))
	for _, m := range metas {
		metaByFilename[m.Filename] = m
	}

	files, err := os.ReadDir(api.AudioFilesLocation)
	if err != nil {
		logger.Error("Audio reconciliation: failed to read audio directory: %v", err)
		return
	}

	fileSet := make(map[string]bool, len(files))
	for _, f := range files {
		if !f.IsDir() {
			fileSet[f.Name()] = true
		}
	}

	// Remove metadata whose files do not exist on disk
	for _, m := range metas {
		if !fileSet[m.Filename] {
			logger.Warn("Audio reconciliation: removing stale metadata for %s", m.Filename)
			if err := c.delegate.persistence.DeleteAudioMetadata(m.Id); err != nil {
				logger.Error("Failed to delete stale metadata %s: %v", m.Id, err)
			}
		}
	}

	// Remove files on disk with no metadata entry
	for file := range fileSet {
		if _, ok := metaByFilename[file]; !ok {
			full := filepath.Join(api.AudioFilesLocation, file)
			logger.Warn("Audio reconciliation: removing orphaned file %s", file)
			if err := os.Remove(full); err != nil && !os.IsNotExist(err) {
				logger.Error("Failed to delete orphaned file %s: %v", file, err)
			}
		}
	}
}
