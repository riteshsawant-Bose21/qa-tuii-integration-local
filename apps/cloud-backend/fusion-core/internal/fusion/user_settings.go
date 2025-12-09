package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type UserSettings interface {
	GetUserSettings(ctx context.Context, userID string) (*types.UserSettings, error)
	CreateUserSettings(ctx context.Context, settings *types.UserSettings) error
	UpdateUserSettings(ctx context.Context, settings *types.UserSettings) error
	CreateUserSettingsForRegistration(ctx context.Context, userID string) error
}
