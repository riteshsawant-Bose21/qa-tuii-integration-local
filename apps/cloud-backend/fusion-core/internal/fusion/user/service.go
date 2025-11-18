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
	CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error)
	UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error)
}

func NewService(dbService DatabaseService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
	}
}
