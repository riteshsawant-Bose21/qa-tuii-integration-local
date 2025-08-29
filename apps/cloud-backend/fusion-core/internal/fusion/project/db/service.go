package db

import (
	"context"
	"database/sql"
	"errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion"
)

type Service struct {
	db *sql.DB
}

func NewService(db *sql.DB) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

func (s *Service) Insert(ctx context.Context, project *fusion.Project) error {
	if project == nil {
		return errors.New("project cannot be nil")
	}
	// Insert the project into the database.
	return nil
}

func (s *Service) GetByID(ctx context.Context, id string) (*fusion.Project, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}
	// Retrieve the project from the database.
	return nil, nil
}

func (s *Service) GetAll(ctx context.Context) ([]*fusion.Project, error) {
	var projects []*fusion.Project
	// Retrieve all projects from the database.
	return projects, nil
}

func (s *Service) Update(ctx context.Context, id string, project *fusion.Project) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	if project == nil {
		return errors.New("project cannot be nil")
	}
	// Update the project in the database.
	return nil
}

func (s *Service) Delete(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	// Delete the project from the database.
	return nil
}
