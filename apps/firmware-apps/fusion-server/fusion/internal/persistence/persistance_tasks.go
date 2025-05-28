package persistence

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"

	"go.etcd.io/bbolt"
)

// LoadMetadata retrieves and unmarshals the api.SnapshotMetadata from the database.
func (p *Persistence) LoadTasks() (map[string]*api.Task, error) {

	p.mutex.RLock()
	defer p.mutex.RUnlock()

	tasks := make(map[string]*api.Task)

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(TasksBucketName))
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

		bucket := tx.Bucket([]byte(TasksBucketName))
		if bucket == nil {
			return fmt.Errorf("tasks bucket not found")
		}

		for key, task := range tasks {
			json, err := json.Marshal(task)
			if err != nil {
				return err
			}
			return bucket.Put([]byte(key), json)
		}
		return nil
	})

	if err != nil {
		return fmt.Errorf("failed to save tasks: %w", err)
	}

	if err := p.updateHash(); err != nil {
		return err
	}

	return nil
}

// DeleteTask removes the task
func (p *Persistence) DeleteTask(taskID string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	// Perform deletion in a single atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(TasksBucketName))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", TasksBucketName)
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
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	var exists bool
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(TasksBucketName))
		if b == nil {
			exists = false
			return fmt.Errorf("tasks bucket not found")
		}
		exists = b.Get([]byte(task.ID)) != nil
		return nil
	})
	return exists, err
}

// ImportTasks imports the snapshot data into the database
func (p *Persistence) ImportTasks(importData map[string]any) error {

	// Get the tasks from the data
	tasksData, ok := importData[TasksBucketName]
	if !ok {
		return fmt.Errorf("export does not contain tasks")
	}

	// Assert tasksData is a map[string]any.
	tasks, ok := tasksData.(map[string]any)
	if !ok {
		return fmt.Errorf("tasks data is not in the expected format")
	}

	if err := p.replaceBucketData(TasksBucketName, tasks); err != nil {
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
		b := tx.Bucket([]byte(TasksBucketName))
		if b == nil {
			return fmt.Errorf("bucket %q not found", TasksBucketName)
		}

		return b.ForEach(func(k, v []byte) error {
			var t api.Task
			if err := json.Unmarshal(v, &t); err != nil {
				return fmt.Errorf("invalid task data for key %q: %w", k, err)
			}
			if t.Type != api.TaskTypeSnapshot {
				return nil
			}
			if id, ok := t.Params["snapshot_id"]; ok && id == snapshotID {
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
