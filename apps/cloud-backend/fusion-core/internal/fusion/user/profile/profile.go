package userprofile

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
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

// CreateUserProfileForRegistration creates a profile during user registration process
// This is called internally, not from HTTP handlers
func (s *Service) CreateUserProfileForRegistration(ctx context.Context, profileData *types.UserProfile) error {
	// Validate required fields for registration
	if profileData.UserID == "" {
		return fmt.Errorf("userID is required")
	}

	if _, err := uuid.Parse(profileData.UserID); err != nil {
		return fmt.Errorf("invalid user_id format: must be a valid UUID")
	}

	if profileData.Email == "" {
		return fmt.Errorf("email is required")
	}

	return s.dbService.Insert(ctx, profileData)
}
