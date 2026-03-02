package user

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
)

// GetUserSettings fetches user settings by user ID
func (s *Service) GetUserSettings(ctx context.Context, userID string) (*types.UserSettings, error) {
	return s.dbService.SelectUserSettingsByUserID(ctx, userID)
}

// CreateUserSettings creates new user settings
func (s *Service) CreateUserSettings(ctx context.Context, settingsDetails *types.UserSettings) (string, error) {
	return s.dbService.InsertUserSettings(ctx, settingsDetails)
}

// UpdateUserSettings updates existing user settings
func (s *Service) UpdateUserSettings(ctx context.Context, settingsDetails *types.UpdateUserSettingsRequest, settingsID string, userID string) error {
	if settingsDetails == nil {
		return fmt.Errorf("settingsDetails cannot be nil")
	}

	existingSettings, err := s.dbService.SelectUserSettingsBySettingsIDAndUserID(ctx, settingsID, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user settings not found")
		}
		return fmt.Errorf("failed to fetch user settings: %v", err)
	}

	// Update the settings only if the fields are present in the request payload and is not null
	if settingsDetails.Language != nil {
		existingSettings.Language = *settingsDetails.Language
	}
	if settingsDetails.Theme != nil {
		existingSettings.Theme = *settingsDetails.Theme
	}

	return s.dbService.UpdateUserSettings(ctx, existingSettings)
}

// CreateUserSettingsForRegistration creates settings during user registration process
func (s *Service) CreateUserSettingsForRegistration(ctx context.Context, userID string) (string, error) {
	if userID == "" {
		return "", fmt.Errorf("userID is required")
	}
	if _, err := uuid.Parse(userID); err != nil {
		return "", fmt.Errorf("invalid user_id format: must be a valid UUID")
	}

	// Default values for language and theme
	defaultLanguage := "en-US"
	defaultTheme := "system"

	settings := &types.UserSettings{
		UserID:   userID,
		Language: defaultLanguage,
		Theme:    defaultTheme,
	}

	return s.dbService.InsertUserSettings(ctx, settings)
}
