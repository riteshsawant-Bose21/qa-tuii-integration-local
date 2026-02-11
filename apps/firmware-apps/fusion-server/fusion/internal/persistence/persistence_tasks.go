package persistence

import (
	"fmt"
	"fusion/internal/api"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

// LoadMetadata retrieves and unmarshals the api.SnapshotMetadata from the database.
func (p *Persistence) LoadTasks() (map[string]*api.Task, error) {

	tasks := make(map[string]*api.Task)

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketTasks))
		if b == nil {
			return fmt.Errorf("tasks bucket not found")
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
	err := p.db.Update(func(tx *bbolt.Tx) error {

		bucket := tx.Bucket([]byte(bucketTasks))
		if bucket == nil {
			return fmt.Errorf("tasks bucket not found")
		}

		// Clear existing bucket contents
		err := bucket.ForEach(func(k, _ []byte) error {
			return bucket.Delete(k)
		})
		if err != nil {
			return fmt.Errorf("failed to clear task bucket: %w", err)
		}

		// Write all current tasks
		for key, task := range tasks {
			data, err := json.Marshal(task)
			if err != nil {
				return err
			}
			if err := bucket.Put([]byte(key), data); err != nil {
				return err
			}
		}

		return nil
	})

	if err != nil {
		return fmt.Errorf("failed to save tasks: %w", err)
	}

	return p.updateHash()
}

// DeleteTask removes the task
func (p *Persistence) DeleteTask(taskID string) error {

	// Perform deletion in a single atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketTasks))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketTasks)
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
	if err := p.updateHash(); err != nil {
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
			return fmt.Errorf("tasks bucket not found")
		}
		exists = b.Get([]byte(task.ID)) != nil
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
			return fmt.Errorf("tasks bucket not found")
		}
		data := b.Get([]byte(id))
		if data == nil {
			return fmt.Errorf("task '%s' not found", id)
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

	if err := p.replaceBucketData(bucketTasks, tasks); err != nil {
		return err
	}

	// Update the overall database hash.
	if err := p.updateHash(); err != nil {
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
			return fmt.Errorf("bucket %q not found", bucketTasks)
		}

		return b.ForEach(func(k, v []byte) error {
			var t api.Task
			if err := json.Unmarshal(v, &t); err != nil {
				return fmt.Errorf("invalid task data for key %q: %w", k, err)
			}
			if t.Type != api.TaskTypeSnapshot {
				return nil
			}
			if id, ok := t.Params[api.SnapshotIDKey]; ok && id == snapshotID {
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
