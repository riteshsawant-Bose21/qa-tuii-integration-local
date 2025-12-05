package db

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
)

type Service struct {
	db *sql.DB
}

// NewService initializes the DB service
func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// SelectByUserID fetches user settings for a specific userID
func (s *Service) SelectByUserID(ctx context.Context, userID string) (*types.UserSettings, error) {
	row, err := model.UserSettings(model.UserSettingWhere.UserID.EQ(userID)).One(ctx, s.db)
	if err != nil {
		return nil, err
	}

	return newUserSettings(row)
}

// Insert a new user settings in the database
func (s *Service) Insert(ctx context.Context, userSettings *types.UserSettings) error {

	// Validations
	if userSettings == nil {
		return fmt.Errorf("userSettings cannot be nil")
	}

	// Create the user settings
	row := &model.UserSetting{
		UserID:    userSettings.UserID,
		Language:  null.NewString(userSettings.Language, userSettings.Language != ""),
		Theme:     null.NewString(userSettings.Theme, userSettings.Theme != ""),
		UpdatedAt: null.Time{},
	}

	// Insert the user settings into the database
	err := row.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to insert User Settings: %v", err)
	}

	// Populate the ID from the inserted row
	userSettings.ID = row.ID
	return nil
}

func (s *Service) Update(ctx context.Context, userSettings *types.UserSettings) error {
	if userSettings == nil {
		return fmt.Errorf("userSettings cannot be nil")
	}

	existingSettings, err := model.UserSettings(model.UserSettingWhere.ID.EQ(userSettings.ID)).One(ctx, s.db)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user settings not found")
		}
		return fmt.Errorf("failed to fetch user settings: %v", err)
	}

	if existingSettings.UserID != userSettings.UserID {
		return fmt.Errorf("user settings do not belong to the specified user")
	}

	row := &model.UserSetting{
		ID:        existingSettings.ID,
		UserID:    userSettings.UserID,
		Language:  null.NewString(userSettings.Language, userSettings.Language != ""),
		Theme:     null.NewString(userSettings.Theme, userSettings.Theme != ""),
		CreatedAt: existingSettings.CreatedAt,
	}

	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to update user settings: %v", err)
	}

	return nil
}
