package usersettings

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
)

func (s *Service) GetUserSettings(ctx context.Context, userID string) (*types.UserSettings, error) {
	return s.dbService.SelectByUserID(ctx, userID)
}

func (s *Service) CreateUserSettings(ctx context.Context, settingsDetails *types.UserSettings) error {
	return s.dbService.Insert(ctx, settingsDetails)
}

func (s *Service) UpdateUserSettings(ctx context.Context, settingsDetails *types.UserSettings) error {
	return s.dbService.Update(ctx, settingsDetails)
}

// CreateUserSettingsForRegistration creates settings during user registration process
// This is called internally, not from HTTP handlers
func (s *Service) CreateUserSettingsForRegistration(ctx context.Context, userID string) error {
	if userID == "" {
		return fmt.Errorf("userID is required")
	}
	if _, err := uuid.Parse(userID); err != nil {
		return fmt.Errorf("invalid user_id format: must be a valid UUID")
	}

	settings := &types.UserSettings{
		UserID:   userID,
		Language: "en-US",
		Theme:    "system",
	}

	return s.dbService.Insert(ctx, settings)
}
