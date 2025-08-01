package service

import (
	"fmt"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/utils"
	"fusion-cloud/internal/utils/jwtutil"
)

// Space represents a space entity.
type Space struct {
	repo       *repository.SpaceRepository
	jwtManager *jwtutil.JWTManager
}

// NewSpace creates a new Space.
func NewSpace(repo *repository.SpaceRepository, jwt *jwtutil.JWTManager) *Space {
	return &Space{
		repo:       repo,
		jwtManager: jwt,
	}
}

// GetSpaceByID retrieves a space by its ID.
func (s *Space) GetAllSpace() (*model.Space, error) {
	spaces, err := s.repo.GetAllSpaces()
	if err != nil {
		return nil, fmt.Errorf("error while getting spaces in service: %w", err)
	}
	if spaces == nil {
		return nil, utils.ErrDeviceNotFound
	}
	return spaces, nil
}

// CreateSpace creates a new space.
func (s *Space) CreateSpace(space *model.SpaceRequest) (*model.Space, error) {
	spc, err := s.repo.CreateSpace(space)
	if err != nil {
		return nil, fmt.Errorf("error while getting space in service: %w", err)
	}
	if spc == nil {
		return nil, utils.ErrSpaceNotFound
	}
	return spc, nil
}

// UpdateSpace updates an existing space.
func (s *Space) UpdateSpace(space *model.SpaceRequest) (bool, error) {
	isUpdated, err := s.repo.UpdateSpace(space)
	if err != nil {
		return false, fmt.Errorf("error while update space in service: %w", err)
	}
	if !isUpdated {
		return false, utils.ErrSpaceNotFound
	}
	return isUpdated, nil
}

// DeleteSpace deletes a space by ID.
func (s *Space) DeleteSpace(id string) error {
	err := s.repo.DeleteSpace(id)
	if err != nil {
		return fmt.Errorf("error while delete space in service: %w", err)
	}

	return nil
}
