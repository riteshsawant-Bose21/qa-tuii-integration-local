package repository

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"fusion-cloud/internal/model"
	// "fusion-cloud/internal/utils"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(user *model.UserRegistration) (int64, error) {
	query := `INSERT INTO users (email, password) VALUES (?, ?)`
	result, err := r.db.Exec(query, user.Email, user.Password)

	if err != nil {
		return 0, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}

	return id, nil
}

func (r *UserRepository) FindByEmail(email string) (*model.User, error) {
	query := `SELECT id, email, password, metadata, created_at, updated_at FROM users WHERE email = ?`

	var user model.User
	err := r.db.QueryRow(query, email).Scan(
		&user.ID,
		&user.Email,
		&user.Password,
		&user.MetaData,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// No user found with the given email
			return nil, nil
		}
		// Some other error occurred
		return nil, fmt.Errorf("failed to fetch user by email: %w", err)
	}

	return &user, nil
}

// GetUserByID retrieves a user by their ID
func (r *UserRepository) GetUserByID(id int64) (*model.User, error) {
	query := `SELECT id, email, metadata, created_at, updated_at FROM users WHERE id = ?`

	var user model.User
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Email,
		&user.MetaData,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // No user found with the given ID
		}
		return nil, fmt.Errorf("failed to fetch user by ID: %w", err)
	}

	return &user, nil
}

func (r *UserRepository) UpdateUserMetadata(userID int64, metadata *model.UserMetaData) error {
	// Fetch existing metadata
	// existingUser, err := r.GetUserByID(userID)
	// if err != nil {
	// 	return fmt.Errorf("failed to fetch user for metadata update: %w", err)
	// }

	// var existingMeta model.UserMetaData
	// if existingUser.MetaData != "" {
	// 	_ = json.Unmarshal([]byte(existingUser.MetaData), &existingMeta)
	// }

	// // Merge new metadata into existing
	// utils.MergeUserMetaData(&existingMeta, metadata)

	// metaJSON, err := json.Marshal(existingMeta)
	// if err != nil {
	// 	return fmt.Errorf("failed to marshal metadata: %w", err)
	// }
	// query := `UPDATE users SET metadata = ? WHERE id = ?`
	// _, err = r.db.Exec(query, metaJSON, userID)
	// if err != nil {
	// 	return fmt.Errorf("failed to update user metadata: %w", err)
	// }

	// return nil

	query := `UPDATE users SET metadata = ? WHERE id = ?`
	metaJSON, err := json.Marshal(metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	_, err = r.db.Exec(query, metaJSON, userID)
	if err != nil {
		return fmt.Errorf("failed to update user metadata: %w", err)
	}

	return nil
}
