package userprofile

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

func (s *Service) GetUserProfile(ctx context.Context, userID string) (*types.UserProfile, error) {
	return s.dbService.SelectByUserID(ctx, userID)
}

func (s *Service) CreateUserProfile(ctx context.Context, profileDetails *types.UserProfile) error {
	return s.dbService.Insert(ctx, profileDetails)
}

func (s *Service) UpdateUserProfile(ctx context.Context, profileDetails *types.UserProfile) error {
	return s.dbService.Update(ctx, profileDetails)
}
