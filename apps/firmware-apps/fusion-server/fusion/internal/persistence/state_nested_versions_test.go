package persistence

import (
	"testing"

	"fusion/internal/api"

	"github.com/stretchr/testify/require"
)

func newTestStateManager() *StateManager {
	return NewStateManager(&api.AppConfig{NodeName: "local-node"})
}

func TestApplyUpdate_AllowsNewNestedPathDespiteNewerTopLevelVersion(t *testing.T) {
	sm := newTestStateManager()
	sm.state.State["settings"] = &api.StateEntry{
		Data: map[string]any{
			"audio": map[string]any{
				"sync_test": map[string]any{
					"existing_key": "existing_value",
				},
			},
		},
		Version: api.Version{Counter: 10, NodeID: "local-node"},
		NestedVersions: map[string]api.Version{
			"settings.audio.sync_test.existing_key": {Counter: 10, NodeID: "local-node"},
		},
	}
	sm.version = api.Version{Counter: 10, NodeID: "local-node"}

	update := api.ConfigUpdate{
		Data: map[string]any{
			"settings": map[string]any{
				"audio": map[string]any{
					"sync_test": map[string]any{
						"existing_key":     "existing_value",
						"test_sync_string": "test_value",
					},
				},
			},
		},
		PathValues: map[string]any{
			"settings.audio.sync_test.test_sync_string": "test_value",
		},
		Version: api.Version{Counter: 6, NodeID: "remote-node"},
	}

	dirty, err := sm.ApplyUpdate(update)
	require.NoError(t, err)
	require.True(t, dirty)

	value, exists := sm.Get("settings.audio.sync_test.test_sync_string")
	require.True(t, exists)
	require.Equal(t, "test_value", value)
}

func TestApplyUpdate_RejectsStaleNestedPathVersion(t *testing.T) {
	sm := newTestStateManager()
	sm.state.State["settings"] = &api.StateEntry{
		Data: map[string]any{
			"audio": map[string]any{
				"sync_test": map[string]any{
					"test_sync_string": "local_value",
				},
			},
		},
		Version: api.Version{Counter: 10, NodeID: "local-node"},
		NestedVersions: map[string]api.Version{
			"settings.audio.sync_test.test_sync_string": {Counter: 7, NodeID: "local-node"},
		},
	}
	sm.version = api.Version{Counter: 10, NodeID: "local-node"}

	update := api.ConfigUpdate{
		Data: map[string]any{
			"settings": map[string]any{
				"audio": map[string]any{
					"sync_test": map[string]any{
						"test_sync_string": "remote_value",
					},
				},
			},
		},
		PathValues: map[string]any{
			"settings.audio.sync_test.test_sync_string": "remote_value",
		},
		Version: api.Version{Counter: 6, NodeID: "remote-node"},
	}

	dirty, err := sm.ApplyUpdate(update)
	require.NoError(t, err)
	require.False(t, dirty)

	value, exists := sm.Get("settings.audio.sync_test.test_sync_string")
	require.True(t, exists)
	require.Equal(t, "local_value", value)
}

func TestApplyUpdate_SeedsMissingTopLevelEntryFromNestedPatch(t *testing.T) {
	sm := newTestStateManager()

	update := api.ConfigUpdate{
		Data: map[string]any{
			"settings": map[string]any{
				"audio": map[string]any{
					"sync_test": map[string]any{
						"test_sync_string": "test_value",
					},
				},
			},
		},
		PathValues: map[string]any{
			"settings.audio.sync_test.test_sync_string": "test_value",
		},
		Version: api.Version{Counter: 3, NodeID: "remote-node"},
	}

	dirty, err := sm.ApplyUpdate(update)
	require.NoError(t, err)
	require.True(t, dirty)

	value, exists := sm.Get("settings.audio.sync_test.test_sync_string")
	require.True(t, exists)
	require.Equal(t, "test_value", value)

	entry := sm.state.State["settings"]
	require.NotNil(t, entry)
	require.Contains(t, entry.NestedVersions, "settings.audio.sync_test.test_sync_string")
}

func TestDeepCopyEntry_CopiesNestedVersions(t *testing.T) {
	src := &api.StateEntry{
		Data: map[string]any{
			"audio": map[string]any{
				"sync_test": map[string]any{
					"test_sync_string": "test_value",
				},
			},
		},
		Version: api.Version{Counter: 5, NodeID: "node-a"},
		NestedVersions: map[string]api.Version{
			"settings.audio.sync_test.test_sync_string": {Counter: 5, NodeID: "node-a"},
		},
	}

	dst := deepCopyEntry(src)
	require.NotNil(t, dst)
	require.NotSame(t, src, dst)

	dst.NestedVersions["settings.audio.sync_test.test_sync_string"] = api.Version{Counter: 9, NodeID: "node-b"}
	require.Equal(t, uint64(5), src.NestedVersions["settings.audio.sync_test.test_sync_string"].Counter)
	require.Equal(t, "node-a", src.NestedVersions["settings.audio.sync_test.test_sync_string"].NodeID)
}
