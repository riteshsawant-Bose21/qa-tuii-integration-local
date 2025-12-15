package user

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Service struct {
	dbService DatabaseService
}

type DatabaseService interface {
	GetUserByEmail(ctx context.Context, email string) (*types.User, error)
	GetUserAuthorization(ctx context.Context, email string) (*types.UserAuthorizationResponse, error)
	CheckUserPermission(ctx context.Context, userEmail, featureName string, requiredLevel string) (bool, error)
	CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error)
	UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error)

	// Profile DB Methods
	SelectUserProfileByUserID(ctx context.Context, userID string) (*types.UserProfile, error)
	InsertUserProfile(ctx context.Context, userProfile *types.UserProfile) (string, error)
	UpdateUserProfile(ctx context.Context, profile *types.UserProfile) error

	// Settings DB Methods
	SelectUserSettingsByUserID(ctx context.Context, userID string) (*types.UserSettings, error)
	InsertUserSettings(ctx context.Context, userSettings *types.UserSettings) (string, error)
	UpdateUserSettings(ctx context.Context, settings *types.UserSettings) error
}

func NewService(dbService DatabaseService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
	}
}
