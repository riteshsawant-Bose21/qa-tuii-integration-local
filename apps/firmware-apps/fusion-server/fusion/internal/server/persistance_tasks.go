package server

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
		b := tx.Bucket([]byte(tasksBucketName))
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

		bucket := tx.Bucket([]byte(tasksBucketName))
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

// TaskExists checks if a task exists alread.
func (p *Persistence) TaskExists(task api.Task) (bool, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	var exists bool
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(tasksBucketName))
		if b == nil {
			exists = false
			return nil
		}
		exists = b.Get([]byte(task.ID)) != nil
		return nil
	})
	return exists, err
}

// ImportTasks imports the snapshot data into the database
func (p *Persistence) ImportTasks(importData map[string]any) error {

	// Get the tasks from the data
	tasksData, ok := importData[tasksBucketName]
	if !ok {
		return fmt.Errorf("export does not contain tasks")
	}

	// Assert tasksData is a map[string]any.
	tasks, ok := tasksData.(map[string]any)
	if !ok {
		return fmt.Errorf("tasks data is not in the expected format")
	}

	if err := p.replaceBucketData(tasksBucketName, tasks); err != nil {
		return err
	}

	// Update the overall database hash.
	if err := p.updateHash(); err != nil {
		return fmt.Errorf("failed to update DB hash after import: %w", err)
	}
	return nil
}
