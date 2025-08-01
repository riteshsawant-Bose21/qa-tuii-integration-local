package service

import (
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/utils"
	"fusion-cloud/internal/utils/jwtutil"

	"encoding/json"

	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	repo       *repository.UserRepository
	jwtManager *jwtutil.JWTManager
}

func NewAuthService(repo *repository.UserRepository, jwt *jwtutil.JWTManager) *AuthService {
	return &AuthService{
		repo:       repo,
		jwtManager: jwt,
	}
}

func (s *AuthService) RegisterUser(user *model.UserRegistration) (int64, error) {
	// Validate struct using validator.v10
	if err := utils.Validate.Struct(user); err != nil {
		return 0, utils.NewValidationError(utils.ErrValidation.Error(), err)
	}

	// Check if user already exists
	existingUser, err := s.repo.FindByEmail(user.Email)
	if err != nil {
		return 0, err
	}

	if existingUser != nil {
		return 0, utils.ErrUserAlreadyExists
	}

	// Hash the password
	hashed, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		return 0, err
	}
	user.Password = string(hashed)

	// Save to database
	return s.repo.Create(user)
}

func (s *AuthService) LoginUser(login *model.UserLogin) (*model.AuthResponse, error) {
	// Validate struct using validator
	if err := utils.Validate.Struct(login); err != nil {
		return nil, utils.NewValidationError(utils.ErrValidation.Error(), err)
	}

	// Fetch user by email
	user, err := s.repo.FindByEmail(login.Email)
	if err != nil {
		return nil, err
	}

	if user == nil {
		return nil, utils.ErrInvalidCredentials
	}

	// Compare hashed password with provided password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(login.Password)); err != nil {
		return nil, utils.ErrInvalidCredentials
	}

	// Parse metadata
	var meta model.UserMetaData
	if err := json.Unmarshal([]byte(user.MetaData), &meta); err != nil {
		return nil, utils.ErrInternalServerError
	}

	// Generate tokens
	accessToken, err := s.jwtManager.GenerateAccessToken(user.ID, user.Email)
	if err != nil {
		return nil, utils.ErrInternalServerError
	}
	refreshToken, err := s.jwtManager.GenerateRefreshToken(user.ID, user.Email)
	if err != nil {
		return nil, utils.ErrInternalServerError
	}

	return &model.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User: &model.UserResponse{
			ID:        user.ID,
			Email:     user.Email,
			MetaData:  user.MetaData,
			CreatedAt: user.CreatedAt,
			UpdatedAt: user.UpdatedAt,
		},
	}, nil
}

func (s *AuthService) RefreshToken(refreshToken string) (*model.AuthResponse, error) {
	// Validate and parse refresh token
	claims, err := s.jwtManager.VerifyRefreshToken(refreshToken)
	if err != nil {
		return nil, utils.ErrInvalidCredentials
	}

	// Fetch user from DB
	user, err := s.repo.FindByEmail(claims.Email)
	if err != nil || user == nil {
		return nil, utils.ErrInvalidCredentials
	}

	// Parse metadata
	var meta model.UserMetaData
	if err := json.Unmarshal([]byte(user.MetaData), &meta); err != nil {
		return nil, utils.ErrInternalServerError
	}

	// Generate new tokens
	accessToken, err := s.jwtManager.GenerateAccessToken(user.ID, user.Email)
	if err != nil {
		return nil, utils.ErrInternalServerError
	}
	newRefreshToken, err := s.jwtManager.GenerateRefreshToken(user.ID, user.Email)
	if err != nil {
		return nil, utils.ErrInternalServerError
	}

	return &model.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		User: &model.UserResponse{
			ID:        user.ID,
			Email:     user.Email,
			MetaData:  user.MetaData,
			CreatedAt: user.CreatedAt,
			UpdatedAt: user.UpdatedAt,
		},
	}, nil
}
