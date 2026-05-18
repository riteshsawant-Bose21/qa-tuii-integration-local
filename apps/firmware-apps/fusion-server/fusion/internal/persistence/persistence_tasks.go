package persistence

import (
	"bytes"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"strings"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

func validateSnapshotTaskRefs(tasks map[string]any, snapshotExists func(string) (bool, error)) error {
	for key, value := range tasks {
		data, err := json.Marshal(value)
		if err != nil {
			return fmt.Errorf("failed to marshal imported task %q: %w", key, err)
		}

		var task api.Task
		if err := json.Unmarshal(data, &task); err != nil {
			return fmt.Errorf("failed to unmarshal imported task %q: %w", key, err)
		}

		if task.Type != api.TaskTypeSnapshot {
			continue
		}

		snapshotIDValue, ok := task.GetParam(api.SnapshotIDKey)
		if !ok {
			return fmt.Errorf("imported snapshot task %q missing %q", key, api.SnapshotIDKey)
		}

		snapshotID, ok := snapshotIDValue.(string)
		if !ok {
			return fmt.Errorf("imported snapshot task %q missing %q", key, api.SnapshotIDKey)
		}

		snapshotID = strings.TrimSpace(snapshotID)
		if snapshotID == "" {
			return fmt.Errorf("imported snapshot task %q missing %q", key, api.SnapshotIDKey)
		}

		exists, err := snapshotExists(snapshotID)
		if err != nil {
			return fmt.Errorf("failed to validate snapshot for imported task %q: %w", key, err)
		}
		if !exists {
			return fmt.Errorf("imported snapshot task %q references missing snapshot %q", key, snapshotID)
		}
	}

	return nil
}

func (p *Persistence) validateImportedTasks(tasks map[string]any) error {
	return validateSnapshotTaskRefs(tasks, p.SnapshotExists)
}

// LoadMetadata retrieves and unmarshals the api.SnapshotMetadata from the database.
func (p *Persistence) LoadTasks() (map[string]*api.Task, error) {

	tasks := make(map[string]*api.Task)

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketTasks))
		if b == nil {
			return nil
		}
		return b.ForEach(func(key, value []byte) error {
			var task api.Task
			if err := json.Unmarshal(value, &task); err != nil {
				return fmt.Errorf("failed to unmarshal task data: %w", err)
			}
			tasks[string(key)] = &task
			return nil
		})
	})

	if err != nil {
		return nil, err
	}

	return tasks, nil
}

// SaveTasks saves tasks data into the database
func (p *Persistence) SaveTasks(tasks map[string]*api.Task) error {
	existing := make(map[string][]byte)
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketTasks))
		if bucket == nil {
			return fmt.Errorf("%w: tasks bucket not found", ErrNotFound)
		}
		return bucket.ForEach(func(k, v []byte) error {
			existing[string(k)] = append([]byte(nil), v...)
			return nil
		})
	})
	if err != nil {
		return fmt.Errorf("failed to save tasks: %w", err)
	}

	changed := len(existing) != len(tasks)
	desired := make(map[string][]byte, len(tasks))
	for key, task := range tasks {
		data, err := json.Marshal(task)
		if err != nil {
			return fmt.Errorf("failed to save tasks: %w", err)
		}
		desired[key] = data
		if !bytes.Equal(existing[key], data) {
			changed = true
		}
		delete(existing, key)
	}
	if !changed && len(existing) == 0 {
		logging.GetLogger().Debug("Task persistence skipped: no task changes")
		return nil
	}

	existing = make(map[string][]byte)
	err = p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketTasks))
		if bucket == nil {
			return fmt.Errorf("%w: tasks bucket not found", ErrNotFound)
		}
		return bucket.ForEach(func(k, v []byte) error {
			existing[string(k)] = append([]byte(nil), v...)
			return nil
		})
	})
	if err != nil {
		return fmt.Errorf("failed to save tasks: %w", err)
	}

	err = p.db.Update(func(tx *bbolt.Tx) error {

		bucket := tx.Bucket([]byte(bucketTasks))
		if bucket == nil {
			return fmt.Errorf("%w: tasks bucket not found", ErrNotFound)
		}

		for key, data := range desired {
			if bytes.Equal(existing[key], data) {
				delete(existing, key)
				continue
			}
			if err := bucket.Put([]byte(key), data); err != nil {
				return err
			}
			changed = true
			delete(existing, key)
		}

		for key := range existing {
			if err := bucket.Delete([]byte(key)); err != nil {
				return fmt.Errorf("failed to delete task %q: %w", key, err)
			}
			changed = true
		}

		return nil
	})

	if err != nil {
		return fmt.Errorf("failed to save tasks: %w", err)
	}
	return p.updateHash(true)
}

// DeleteTask removes the task
func (p *Persistence) DeleteTask(taskID string) error {

	// Perform deletion in a single atomic transaction.
	exists, err := p.keyExists(bucketTasks, taskID)
	if err != nil {
		return fmt.Errorf("failed to delete task '%s': %w", taskID, err)
	}
	if !exists {
		return fmt.Errorf("%w: task %q not found", ErrNotFound, taskID)
	}

	err = p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketTasks))
		if bucket == nil {
			return fmt.Errorf("%w: bucket %q not found", ErrNotFound, bucketTasks)
		}
		if bucket.Get([]byte(taskID)) == nil {
			return fmt.Errorf("%w: task %q not found", ErrNotFound, taskID)
		}
		if err := bucket.Delete([]byte(taskID)); err != nil {
			return fmt.Errorf("failed to delete task '%s': %w", taskID, err)
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("failed to delete task '%s': %w", taskID, err)
	}

	// Update the database hash
	if err := p.updateHash(true); err != nil {
		return fmt.Errorf("to update hash after deleting task '%s': %v", taskID, err)
	}
	return nil
}

// TaskExists checks if a task exists already.
func (p *Persistence) TaskExists(task *api.Task) (bool, error) {

	var exists bool
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketTasks))
		if b == nil {
			exists = false
			return nil
		}
		exists = b.Get([]byte(task.Id)) != nil
		return nil
	})
	return exists, err
}

// GetTask loads a task by ID
func (p *Persistence) GetTask(id string) (*api.Task, error) {
	var task api.Task
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketTasks))
		if b == nil {
			return fmt.Errorf("%w: tasks bucket not found", ErrNotFound)
		}
		data := b.Get([]byte(id))
		if data == nil {
			return fmt.Errorf("%w: task %q not found", ErrNotFound, id)
		}
		return json.Unmarshal(data, &task)
	})

	if err != nil {
		return nil, err
	}

	return &task, nil
}

// ImportTasks imports the snapshot data into the database
func (p *Persistence) ImportTasks(importData map[string]any) error {

	// Get the tasks from the data
	tasksData, ok := importData[bucketTasks]
	if !ok {
		return fmt.Errorf("export does not contain tasks")
	}

	// Assert tasksData is a map[string]any.
	tasks, ok := tasksData.(map[string]any)
	if !ok {
		return fmt.Errorf("tasks data is not in the expected format")
	}

	if err := p.validateImportedTasks(tasks); err != nil {
		return err
	}

	if err := p.replaceBucketData(bucketTasks, tasks); err != nil {
		return err
	}

	// Update the overall database hash.
	if err := p.updateHash(false); err != nil {
		return fmt.Errorf("failed to update DB hash after import: %w", err)
	}
	return nil
}

// GetTaskIDsBySnapshot returns the IDs of all tasks associated with snapshotID
func (p *Persistence) GetTaskIDsBySnapshot(snapshotID string) ([]string, error) {
	var taskIDs []string

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketTasks))
		if b == nil {
			return nil
		}

		return b.ForEach(func(k, v []byte) error {
			var t api.Task
			if err := json.Unmarshal(v, &t); err != nil {
				return fmt.Errorf("invalid task data for key %q: %w", k, err)
			}
			if t.Type != api.TaskTypeSnapshot {
				return nil
			}
			if id, ok := t.GetParam(api.SnapshotIDKey); ok && id == snapshotID {
				taskIDs = append(taskIDs, string(k))
			}
			return nil
		})
	})

	if err != nil {
		return nil, err
	}
	return taskIDs, nil
}
