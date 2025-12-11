package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type UserSettings interface {
	GetUserSettings(ctx context.Context, userID string) (*types.UserSettings, error)
	CreateUserSettings(ctx context.Context, settings *types.UserSettings) (string, error)
	UpdateUserSettings(ctx context.Context, settings *types.UpdateUserSettingsRequest, settingsID string, userID string) error
	CreateUserSettingsForRegistration(ctx context.Context, userID string) (string, error)
}
