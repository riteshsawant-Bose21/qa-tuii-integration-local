package project

import (
	"context"
	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion"
)

func (s *Service) Insert(ctx context.Context, project *fusion.Project) error {
	return s.dbService.Insert(ctx, project)
}

func (s *Service) GetByID(ctx context.Context, id string) (*fusion.Project, error) {
	return s.dbService.GetByID(ctx, id)
}

func (s *Service) GetAll(ctx context.Context) ([]*fusion.Project, error) {
	return s.dbService.GetAll(ctx)
}

func (s *Service) Update(ctx context.Context, id string, project *fusion.Project) error {
	return s.dbService.Update(ctx, id, project)
}

func (s *Service) Delete(ctx context.Context, id string) error {
	return s.dbService.Delete(ctx, id)
}
