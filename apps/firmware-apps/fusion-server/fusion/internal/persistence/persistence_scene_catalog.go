package persistence

import (
	"fmt"
	"fusion/internal/api"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

// UpsertSnapshotDefinitions creates or overwrites snapshot definitions by ID.
func (p *Persistence) UpsertSnapshotDefinitions(items []api.SnapshotDefinition) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshotDefs)
		}

		for _, item := range items {
			if item.ID == "" {
				return fmt.Errorf("snapshot definition id is required")
			}
			data, err := json.Marshal(item)
			if err != nil {
				return fmt.Errorf("failed to marshal snapshot definition '%s': %w", item.ID, err)
			}
			if err := bucket.Put([]byte(item.ID), data); err != nil {
				return fmt.Errorf("failed to put snapshot definition '%s': %w", item.ID, err)
			}
		}

		return nil
	})
	if err != nil {
		return err
	}

	if len(items) == 0 {
		return nil
	}

	return p.updateHash()
}

// GetSnapshotDefinition returns a snapshot definition by ID.
func (p *Persistence) GetSnapshotDefinition(id string) (*api.SnapshotDefinition, error) {
	var out api.SnapshotDefinition
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			return ErrNotFound
		}

		data := bucket.Get([]byte(id))
		if data == nil {
			return ErrNotFound
		}

		if err := json.Unmarshal(data, &out); err != nil {
			return fmt.Errorf("failed to unmarshal snapshot definition '%s': %w", id, err)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return &out, nil
}

// ListSnapshotDefinitions returns all stored snapshot definitions.
func (p *Persistence) ListSnapshotDefinitions() ([]api.SnapshotDefinition, error) {
	items := make([]api.SnapshotDefinition, 0)
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			return ErrNotFound
		}

		return bucket.ForEach(func(_, value []byte) error {
			var item api.SnapshotDefinition
			if err := json.Unmarshal(value, &item); err != nil {
				return err
			}
			items = append(items, item)
			return nil
		})
	})

	return items, err
}

// SnapshotDefinitionExists checks if a snapshot definition exists.
func (p *Persistence) SnapshotDefinitionExists(id string) (bool, error) {
	var exists bool
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			exists = false
			return nil
		}
		exists = bucket.Get([]byte(id)) != nil
		return nil
	})

	return exists, err
}

// UpsertSceneSets creates or overwrites scene sets by set_id.
func (p *Persistence) UpsertSceneSets(items []api.SceneSet) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSceneSets)
		}

		for _, item := range items {
			if item.SetID == "" {
				return fmt.Errorf("scene set id is required")
			}
			data, err := json.Marshal(item)
			if err != nil {
				return fmt.Errorf("failed to marshal scene set '%s': %w", item.SetID, err)
			}
			if err := bucket.Put([]byte(item.SetID), data); err != nil {
				return fmt.Errorf("failed to put scene set '%s': %w", item.SetID, err)
			}
		}

		return nil
	})
	if err != nil {
		return err
	}

	if len(items) == 0 {
		return nil
	}

	return p.updateHash()
}

// GetSceneSet returns a scene set by set_id.
func (p *Persistence) GetSceneSet(setID string) (*api.SceneSet, error) {
	var out api.SceneSet
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return ErrNotFound
		}

		data := bucket.Get([]byte(setID))
		if data == nil {
			return ErrNotFound
		}

		if err := json.Unmarshal(data, &out); err != nil {
			return fmt.Errorf("failed to unmarshal scene set '%s': %w", setID, err)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return &out, nil
}

// ListSceneSets returns all stored scene sets.
func (p *Persistence) ListSceneSets() ([]api.SceneSet, error) {
	items := make([]api.SceneSet, 0)
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return ErrNotFound
		}

		return bucket.ForEach(func(_, value []byte) error {
			var item api.SceneSet
			if err := json.Unmarshal(value, &item); err != nil {
				return err
			}
			items = append(items, item)
			return nil
		})
	})

	return items, err
}

// SceneSetExists checks if a scene set exists.
func (p *Persistence) SceneSetExists(setID string) (bool, error) {
	var exists bool
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			exists = false
			return nil
		}
		exists = bucket.Get([]byte(setID)) != nil
		return nil
	})

	return exists, err
}

// SetCurrentScene updates current_scene_id for the given scene set.
func (p *Persistence) SetCurrentScene(setID, sceneID string) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return ErrNotFound
		}

		data := bucket.Get([]byte(setID))
		if data == nil {
			return ErrNotFound
		}

		var set api.SceneSet
		if err := json.Unmarshal(data, &set); err != nil {
			return fmt.Errorf("failed to unmarshal scene set '%s': %w", setID, err)
		}

		set.CurrentSceneID = sceneID

		updated, err := json.Marshal(set)
		if err != nil {
			return fmt.Errorf("failed to marshal scene set '%s': %w", setID, err)
		}

		if err := bucket.Put([]byte(setID), updated); err != nil {
			return fmt.Errorf("failed to update scene set '%s': %w", setID, err)
		}

		return nil
	})
	if err != nil {
		return err
	}

	return p.updateHash()
}
