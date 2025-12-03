package usersettings

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Service provides methods to interact with the user settings database
type Service struct {
	dbService DatabaseService
}

// DatabaseService defines the interface for database operations related to user settings.
type DatabaseService interface {
	SelectByUserID(ctx context.Context, userID string) (*types.UserSettings, error)
	Update(ctx context.Context, settings *types.UserSettings) error
	Insert(ctx context.Context, settings *types.UserSettings) error
}

// NewService creates a new user settings service.
func NewService(dbService DatabaseService) *Service {
	if dbService == nil {
		panic("user-settings dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
	}
}
