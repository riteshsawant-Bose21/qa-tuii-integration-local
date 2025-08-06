package service

import (
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/utils/jwtutil"
)

type UserService struct {
	repo       *repository.UserRepository
	jwtManager *jwtutil.JWTManager
}

func NewUserService(repo *repository.UserRepository, jwt *jwtutil.JWTManager) *UserService {
	return &UserService{
		repo:       repo,
		jwtManager: jwt,
	}
}

// GetUserProfile retrieves the user profile by user ID
func (s *UserService) GetUserProfile(userId int64) (*model.User, error) {
	user, err := s.repo.GetUserByID(userId)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (s *UserService) AddUserMetadata(userID int64, metadata *model.UserMetaData) (*model.User, error) {
	// Update user metadata in the repository
	if err := s.repo.UpdateUserMetadata(userID, metadata); err != nil {
		return nil, err
	}
	// Fetch and return updated user
	user, err := s.repo.GetUserByID(userID)
	if err != nil {
		return nil, err
	}
	return user, nil
}
