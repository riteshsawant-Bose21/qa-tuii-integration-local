package service

import (
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/utils"
	"fusion-cloud/internal/utils/jwtutil"
)

type ProjectService struct {
	repo       *repository.ProjectRepository
	jwtManager *jwtutil.JWTManager
}

func NewProjectService(repo *repository.ProjectRepository, jwt *jwtutil.JWTManager) *ProjectService {
	return &ProjectService{
		repo:       repo,
		jwtManager: jwt,
	}
}

func (s *ProjectService) CreateProject(project *model.ProjectRequest, ownerId int64) (int64, error) {
	// Validate struct using validator
	if err := utils.Validate.Struct(project); err != nil {
		return 0, utils.NewValidationError(utils.ErrValidation.Error(), err)
	}
	// Check if project with the same name already exists with the same owner
	existingProject, err := s.repo.FindByNameAndOwner(project.Name, ownerId)

	if err != nil {
		return 0, err
	}
	if existingProject != nil {
		return 0, utils.ErrProjectAlreadyExists
	}

	// Save to database
	return s.repo.Create(project, ownerId)
}

func (s *ProjectService) ListProjectsByOwner(ownerId int64) ([]model.Project, error) {
	projects, err := s.repo.FindByOwner(ownerId)
	if err != nil {
		return nil, err
	}
	return projects, nil
}

func (s *ProjectService) GetProjectByID(ownerId int64, projectId string) (*model.Project, error) {
	project, err := s.repo.FindByID(ownerId, projectId)
	if err != nil {
		return nil, err
	}
	if project == nil {
		return nil, utils.ErrProjectNotFound
	}
	return project, nil
}

func (s *ProjectService) UpdateProject(ownerId int64, projectId string, project *model.ProjectRequest) error {
	// Validate struct using validator
	if err := utils.Validate.Struct(project); err != nil {
		return utils.NewValidationError(utils.ErrValidation.Error(), err)
	}

	// Check if project exists
	existingProject, err := s.repo.FindByID(ownerId, projectId)
	if err != nil {
		return err
	}
	if existingProject == nil {
		return utils.ErrProjectNotFound
	}

	// Update project in database
	return s.repo.Update(ownerId, projectId, project)
}

func (s *ProjectService) DeleteProject(ownerId int64, projectId string) error {
	// Check if project exists
	existingProject, err := s.repo.FindByID(ownerId, projectId)
	if err != nil {
		return err
	}
	if existingProject == nil {
		return utils.ErrProjectNotFound
	}

	// Delete project from database
	return s.repo.Delete(ownerId, projectId)
}
