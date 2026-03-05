package persistence

import (
	"fmt"
	"time"

	json "github.com/goccy/go-json"
	"go.etcd.io/bbolt"
)

const errPendingCommandsBucketNotFound = "pending_commands bucket not found"

// SavePendingCommand stores a pending command in the database.
func (p *Persistence) SavePendingCommand(cmd *PendingCommand) error {
	if cmd == nil {
		return fmt.Errorf("pending command cannot be nil")
	}

	data, err := json.Marshal(cmd)
	if err != nil {
		return fmt.Errorf("failed to marshal pending command: %w", err)
	}

	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketPendingCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		return bucket.Put([]byte(cmd.ID), data)
	})
}

// GetPendingCommand retrieves a pending command by ID.
func (p *Persistence) GetPendingCommand(id string) (*PendingCommand, error) {
	var cmd PendingCommand
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketPendingCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		data := bucket.Get([]byte(id))
		if data == nil {
			return ErrNotFound
		}
		return json.Unmarshal(data, &cmd)
	})
	if err != nil {
		return nil, err
	}
	return &cmd, nil
}

// GetAllPendingCommands retrieves all pending commands.
func (p *Persistence) GetAllPendingCommands() ([]PendingCommand, error) {
	var commands []PendingCommand
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketPendingCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		return bucket.ForEach(func(k, v []byte) error {
			var cmd PendingCommand
			if err := json.Unmarshal(v, &cmd); err != nil {
				return fmt.Errorf("failed to unmarshal pending command %s: %w", string(k), err)
			}
			commands = append(commands, cmd)
			return nil
		})
	})
	if err != nil {
		return nil, err
	}
	return commands, nil
}

// GetPendingCommandsByStatus retrieves all commands with a specific status.
func (p *Persistence) GetPendingCommandsByStatus(status PendingCommandStatus) ([]PendingCommand, error) {
	all, err := p.GetAllPendingCommands()
	if err != nil {
		return nil, err
	}

	var filtered []PendingCommand
	for _, cmd := range all {
		if cmd.Status == status {
			filtered = append(filtered, cmd)
		}
	}
	return filtered, nil
}

// UpdatePendingCommandStatus updates the status of a pending command.
func (p *Persistence) UpdatePendingCommandStatus(id string, status PendingCommandStatus, errorMsg string) error {
	cmd, err := p.GetPendingCommand(id)
	if err != nil {
		return err
	}

	cmd.Status = status
	if status == PendingCommandStatusCompleted || status == PendingCommandStatusFailed {
		now := time.Now().UTC()
		cmd.CompletedAt = &now
	}
	if errorMsg != "" {
		cmd.ErrorMsg = errorMsg
	}

	return p.SavePendingCommand(cmd)
}

// DeletePendingCommand removes a pending command from the database.
func (p *Persistence) DeletePendingCommand(id string) error {
	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketPendingCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		return bucket.Delete([]byte(id))
	})
}

// ClearCompletedCommands removes all completed/failed commands from the database.
func (p *Persistence) ClearCompletedCommands() error {
	commands, err := p.GetAllPendingCommands()
	if err != nil {
		return err
	}

	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketPendingCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		for _, cmd := range commands {
			if cmd.Status == PendingCommandStatusCompleted || cmd.Status == PendingCommandStatusFailed {
				if err := bucket.Delete([]byte(cmd.ID)); err != nil {
					return err
				}
			}
		}
		return nil
	})
}
