package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type UserProfile interface {
	GetUserProfile(ctx context.Context, userID string) (*types.UserProfile, error)
	CreateUserProfile(ctx context.Context, userProfileDetails *types.UserProfile) error
	UpdateUserProfile(ctx context.Context, userProfileDetails *types.UserProfile) error
	CreateUserProfileForRegistration(ctx context.Context, userID string) error
}
