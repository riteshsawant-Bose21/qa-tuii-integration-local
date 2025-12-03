package usersettings

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
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
