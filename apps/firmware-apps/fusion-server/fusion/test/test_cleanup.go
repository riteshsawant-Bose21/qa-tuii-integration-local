package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	json "github.com/goccy/go-json"
)

var testArtifactPrefixes = map[string][]string{
	"snapshots": {
		"test_snapshot_",
		"test_snapshot_propagation_",
		"epoch_test_",
		"old_epoch_reject_",
		"epoch_updates_apply_",
		"exact_state_",
		"nested_state_",
		"active_snap_",
		"persist_snap_",
		"persist_data_",
		"ooom_",
		"delete_active_",
		"update_test_",
		"update_epoch_",
		"update_active_",
		"scheduled_snap_",
	},
	"snapshot_definitions": {
		"snap-def-post-",
		"snap-def-patch-",
		"snap-def-activate-",
		"snap-def-clobber-",
	},
	"scene_sets": {
		"set-post-",
		"set-notmember-",
		"set-activate-",
		"set-current-before-",
		"set-current-after-",
		"set-current-update-",
		"set-list-scenes-",
		"set-list-",
	},
}

func cleanupPersistentTestArtifacts(cfg *ClusterConfig) error {
	for _, node := range cfg.nodes {
		if err := cleanupPersistentTestArtifactsOnNode(node.address); err != nil {
			return fmt.Errorf("cleanup on %s failed: %w", node.address, err)
		}
	}
	return nil
}

func cleanupPersistentTestArtifactsOnNode(nodeAddress string) error {
	adminBase, err := adminBaseURL(nodeAddress)
	if err != nil {
		return err
	}

	exportURL := adminBase + "/data"
	resp, err := http.Get(exportURL)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		return fmt.Errorf("export returned %d: %s", resp.StatusCode, string(body))
	}

	var export map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&export); err != nil {
		return fmt.Errorf("decode export: %w", err)
	}

	changed := false
	for bucket, prefixes := range testArtifactPrefixes {
		rawBucket, ok := export[bucket]
		if !ok {
			continue
		}
		entries, ok := rawBucket.(map[string]any)
		if !ok {
			continue
		}

		for key := range entries {
			if hasAnyPrefix(key, prefixes) {
				delete(entries, key)
				changed = true
			}
		}
	}

	if !changed {
		return nil
	}

	payload, err := json.Marshal(export)
	if err != nil {
		return fmt.Errorf("marshal filtered export: %w", err)
	}

	importResp, err := http.Post(exportURL, "application/json", bytes.NewBuffer(payload))
	if err != nil {
		return fmt.Errorf("import filtered export: %w", err)
	}
	defer importResp.Body.Close()

	if importResp.StatusCode < 200 || importResp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(importResp.Body, 1024))
		return fmt.Errorf("import returned %d: %s", importResp.StatusCode, string(body))
	}

	return nil
}

func adminBaseURL(nodeAddress string) (string, error) {
	parsed, err := url.Parse(nodeAddress)
	if err != nil {
		return "", fmt.Errorf("parse node address %q: %w", nodeAddress, err)
	}
	host := parsed.Hostname()
	if host == "" {
		return "", fmt.Errorf("missing host in node address %q", nodeAddress)
	}
	scheme := parsed.Scheme
	if scheme == "" {
		scheme = "http"
	}
	return scheme + "://" + host + ":9090", nil
}

func hasAnyPrefix(value string, prefixes []string) bool {
	for _, prefix := range prefixes {
		if strings.HasPrefix(value, prefix) {
			return true
		}
	}
	return false
}
