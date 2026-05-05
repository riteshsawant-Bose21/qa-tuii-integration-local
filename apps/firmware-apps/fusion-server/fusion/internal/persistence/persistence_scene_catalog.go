package persistence

import (
	"fmt"
	model "fusion/internal/gen/proto/fusion"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

// UpsertSnapshotDefinitions creates or overwrites snapshot definitions by ID.
func (p *Persistence) UpsertSnapshotDefinitions(items []*model.SnapshotDefinition) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshotDefs)
		}

		for _, item := range items {
			if item.GetId() == "" {
				return fmt.Errorf("snapshot definition id is required")
			}
			data, err := json.Marshal(item)
			if err != nil {
				return fmt.Errorf("failed to marshal snapshot definition '%s': %w", item.GetId(), err)
			}
			if err := bucket.Put([]byte(item.GetId()), data); err != nil {
				return fmt.Errorf("failed to put snapshot definition '%s': %w", item.GetId(), err)
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

	return p.updateHashWithVersionBump(true)
}

// GetSnapshotDefinition returns a snapshot definition by ID.
func (p *Persistence) GetSnapshotDefinition(id string) (*model.SnapshotDefinition, error) {
	var out model.SnapshotDefinition
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
func (p *Persistence) ListSnapshotDefinitions() ([]*model.SnapshotDefinition, error) {
	items := make([]*model.SnapshotDefinition, 0)
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			return ErrNotFound
		}

		return bucket.ForEach(func(_, value []byte) error {
			var item model.SnapshotDefinition
			if err := json.Unmarshal(value, &item); err != nil {
				return err
			}
			items = append(items, &item)
			return nil
		})
	})

	return items, err
}

// DeleteAllSnapshotDefinitions removes all stored snapshot definitions.
func (p *Persistence) DeleteAllSnapshotDefinitions() error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshotDefs)
		}

		cursor := bucket.Cursor()
		for key, _ := cursor.First(); key != nil; key, _ = cursor.Next() {
			if err := cursor.Delete(); err != nil {
				return fmt.Errorf("failed to delete snapshot definition: %w", err)
			}
		}

		return nil
	})
	if err != nil {
		return err
	}

	return p.updateHashWithVersionBump(true)
}

// DeleteSnapshotDefinition removes one stored snapshot definition by ID.
func (p *Persistence) DeleteSnapshotDefinition(id string) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshotDefs))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshotDefs)
		}

		if bucket.Get([]byte(id)) == nil {
			return ErrNotFound
		}

		if err := bucket.Delete([]byte(id)); err != nil {
			return fmt.Errorf("failed to delete snapshot definition '%s': %w", id, err)
		}

		return nil
	})
	if err != nil {
		return err
	}

	return p.updateHashWithVersionBump(true)
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
func (p *Persistence) UpsertSceneSets(items []*model.SceneSet) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSceneSets)
		}

		for _, item := range items {
			if item.GetSetId() == "" {
				return fmt.Errorf("scene set id is required")
			}
			data, err := json.Marshal(item)
			if err != nil {
				return fmt.Errorf("failed to marshal scene set '%s': %w", item.GetSetId(), err)
			}
			if err := bucket.Put([]byte(item.GetSetId()), data); err != nil {
				return fmt.Errorf("failed to put scene set '%s': %w", item.GetSetId(), err)
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

	return p.updateHashWithVersionBump(true)
}

// GetSceneSet returns a scene set by set_id.
func (p *Persistence) GetSceneSet(setID string) (*model.SceneSet, error) {
	var out model.SceneSet
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
func (p *Persistence) ListSceneSets() ([]*model.SceneSet, error) {
	items := make([]*model.SceneSet, 0)
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return ErrNotFound
		}

		return bucket.ForEach(func(_, value []byte) error {
			var item model.SceneSet
			if err := json.Unmarshal(value, &item); err != nil {
				return err
			}
			items = append(items, &item)
			return nil
		})
	})

	return items, err
}

// DeleteAllSceneSets removes all stored scene sets.
// Deleting scene sets also removes their associated scenes because scenes are embedded in each set.
func (p *Persistence) DeleteAllSceneSets() error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSceneSets)
		}

		cursor := bucket.Cursor()
		for key, _ := cursor.First(); key != nil; {
			nextKey, _ := cursor.Next()
			if err := bucket.Delete(key); err != nil {
				return err
			}
			key = nextKey
		}

		return nil
	})
	if err != nil {
		return err
	}

	return p.updateHashWithVersionBump(true)
}

// DeleteSceneSet removes one stored scene set by set_id.
func (p *Persistence) DeleteSceneSet(setID string) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSceneSets)
		}

		if bucket.Get([]byte(setID)) == nil {
			return ErrNotFound
		}

		if err := bucket.Delete([]byte(setID)); err != nil {
			return fmt.Errorf("failed to delete scene set '%s': %w", setID, err)
		}

		return nil
	})
	if err != nil {
		return err
	}

	return p.updateHashWithVersionBump(true)
}

// DeleteScene removes one scene by ID from any scene set that contains it.
func (p *Persistence) DeleteScene(sceneID string) error {
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSceneSets))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSceneSets)
		}

		// Collect updates to apply after iteration — mutating the bucket
		// inside ForEach is not safe in bbolt.
		type pendingUpdate struct {
			key  []byte
			data []byte
		}
		var updates []pendingUpdate
		found := false

		c := bucket.Cursor()
		for k, v := c.First(); k != nil; k, v = c.Next() {
			var set model.SceneSet
			if err := json.Unmarshal(v, &set); err != nil {
				return fmt.Errorf("failed to unmarshal scene set '%s': %w", string(k), err)
			}

			filtered := make([]*model.Scene, 0, len(set.GetScenes()))
			removedFromSet := false
			for _, scene := range set.GetScenes() {
				if scene.GetId() == sceneID {
					removedFromSet = true
					continue
				}
				filtered = append(filtered, scene)
			}

			if !removedFromSet {
				continue
			}

			found = true
			set.Scenes = filtered
			if set.GetDefaultScene() == sceneID {
				set.DefaultScene = ""
			}
			if set.GetCurrentSceneId() == sceneID {
				set.CurrentSceneId = ""
			}

			updated, err := json.Marshal(set)
			if err != nil {
				return fmt.Errorf("failed to marshal updated scene set '%s': %w", set.GetSetId(), err)
			}

			// Copy the key — cursor keys are only valid for the lifetime of the transaction step.
			keyCopy := make([]byte, len(k))
			copy(keyCopy, k)
			updates = append(updates, pendingUpdate{key: keyCopy, data: updated})
		}

		if !found {
			return ErrNotFound
		}

		for _, u := range updates {
			if err := bucket.Put(u.key, u.data); err != nil {
				return fmt.Errorf("failed to update scene set '%s': %w", string(u.key), err)
			}
		}

		return nil
	})
	if err != nil {
		return err
	}

	return p.updateHashWithVersionBump(true)
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

		var set model.SceneSet
		if err := json.Unmarshal(data, &set); err != nil {
			return fmt.Errorf("failed to unmarshal scene set '%s': %w", setID, err)
		}

		set.CurrentSceneId = sceneID

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

	return p.updateHashWithVersionBump(true)
}

// GetSceneInSet returns the scene by ID if it belongs to the specified scene set.
func (p *Persistence) GetSceneInSet(setID, sceneID string) (*model.Scene, error) {
	set, err := p.GetSceneSet(setID)
	if err != nil {
		return nil, err
	}

	for _, scene := range set.GetScenes() {
		if scene.GetId() == sceneID {
			found := scene
			return found, nil
		}
	}

	return nil, ErrNotMember
}
