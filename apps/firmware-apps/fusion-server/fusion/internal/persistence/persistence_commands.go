package persistence

import (
	"fmt"
	"time"

	json "github.com/goccy/go-json"
	"go.etcd.io/bbolt"
)

const errPendingCommandsBucketNotFound = "pending_commands bucket not found"

// SaveCommand stores a command in the database.
func (p *Persistence) SaveCommand(cmd *Command) error {
	if cmd == nil {
		return fmt.Errorf("command cannot be nil")
	}

	data, err := json.Marshal(cmd)
	if err != nil {
		return fmt.Errorf("failed to marshal command: %w", err)
	}

	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		return bucket.Put([]byte(cmd.ID), data)
	})
}

// GetCommand retrieves a command by ID.
func (p *Persistence) GetCommand(id string) (*Command, error) {
	var cmd Command
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketCommands))
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
func (p *Persistence) GetAllPendingCommands() ([]Command, error) {
	var commands []Command
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		return bucket.ForEach(func(k, v []byte) error {
			var cmd Command
			if err := json.Unmarshal(v, &cmd); err != nil {
				return fmt.Errorf("failed to unmarshal command %s: %w", string(k), err)
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

// GetCommandsByStatus retrieves all commands with a specific status.
func (p *Persistence) GetCommandsByStatus(status CommandStatus) ([]Command, error) {
	all, err := p.GetAllPendingCommands()
	if err != nil {
		return nil, err
	}

	var filtered []Command
	for _, cmd := range all {
		if cmd.Status == status {
			filtered = append(filtered, cmd)
		}
	}
	return filtered, nil
}

// UpdateCommandStatus updates the status of a command.
func (p *Persistence) UpdateCommandStatus(id string, status CommandStatus, errorMsg string) error {
	cmd, err := p.GetCommand(id)
	if err != nil {
		return err
	}

	cmd.Status = status
	if status == CommandStatusCompleted || status == CommandStatusFailed {
		now := time.Now().UTC()
		cmd.CompletedAt = &now
	}
	if errorMsg != "" {
		cmd.ErrorMsg = errorMsg
	}

	return p.SaveCommand(cmd)
}

// DeleteCommand removes a command from the database.
func (p *Persistence) DeleteCommand(id string) error {
	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		return bucket.Delete([]byte(id))
	})
}

// MarkPendingRebootCommandsCompleted marks all pending commands as completed.
// Called at startup on each node to indicate it has successfully (re)booted.
func (p *Persistence) MarkPendingRebootCommandsCompleted() error {
	cmds, err := p.GetCommandsByStatus(CommandStatusPending)
	if err != nil {
		return err
	}
	for _, cmd := range cmds {
		if err := p.UpdateCommandStatus(cmd.ID, CommandStatusCompleted, ""); err != nil {
			return err
		}
	}
	return nil
}

// ClearCompletedCommands removes all completed/failed commands from the database.
func (p *Persistence) ClearCompletedCommands() error {
	commands, err := p.GetAllPendingCommands()
	if err != nil {
		return err
	}

	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketCommands))
		if bucket == nil {
			return fmt.Errorf(errPendingCommandsBucketNotFound)
		}
		for _, cmd := range commands {
			if cmd.Status == CommandStatusCompleted || cmd.Status == CommandStatusFailed {
				if err := bucket.Delete([]byte(cmd.ID)); err != nil {
					return err
				}
			}
		}
		return nil
	})
}
