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
func (s *Service) Insert(ctx context.Context, userSettings *types.UserSettings) (string, error) {

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
		return "", fmt.Errorf("failed to insert User Settings: %v", err)
	}

	return row.ID, nil
}

func (s *Service) Update(ctx context.Context, userSettings *types.UserSettings) error {
	row := &model.UserSetting{
		ID:       userSettings.ID,
		UserID:   userSettings.UserID,
		Language: null.StringFrom(userSettings.Language),
		Theme:    null.StringFrom(userSettings.Theme),
	}
	_, err := row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to update user settings: %v", err)
	}

	return nil
}
