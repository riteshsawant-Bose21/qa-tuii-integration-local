package project

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

var (
	errDatabaseMsg = errors.New("database error")
)

type mockDBService struct {
	mock.Mock
}

func (m *mockDBService) Insert(ctx context.Context, project *fusion.ProjectCreateRequest) error {
	args := m.Called(ctx, project)
	return args.Error(0)
}

func (m *mockDBService) SelectAll(ctx context.Context, params *fusion.GetAllProjectsParams) ([]*fusion.Project, error) {
	args := m.Called(ctx, params)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*fusion.Project), args.Error(1)
}

func (m *mockDBService) Update(ctx context.Context, id string, project *fusion.ProjectUpdateRequest) error {
	args := m.Called(ctx, id, project)
	return args.Error(0)
}

func (m *mockDBService) Delete(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

type mockPresigner struct {
	mock.Mock
}

func (m *mockPresigner) PresignGet(ctx context.Context, key string, ttl time.Duration) (string, error) {
	args := m.Called(ctx, key, ttl)
	return args.String(0), args.Error(1)
}

func (m *mockPresigner) PresignPut(ctx context.Context, key string, ttl time.Duration) (string, error) {
	return "", errors.New("not implemented")
}

func TestCreateProject(t *testing.T) {
	tests := []struct {
		name        string
		project     *fusion.ProjectCreateRequest
		mockErr     error
		expectedErr error
	}{
		{
			name: "successful creation",
			project: &fusion.ProjectCreateRequest{
				Name: "Test Project",
			},
			mockErr:     nil,
			expectedErr: nil,
		},
		{
			name: "database error",
			project: &fusion.ProjectCreateRequest{
				Name: "Test Project",
			},
			mockErr:     errDatabaseMsg,
			expectedErr: fmt.Errorf("failed to insert project: %w", errDatabaseMsg),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockDB.On("Insert", mock.Anything, tt.project).Return(tt.mockErr)

			service := &Service{
				dbService: mockDB,
			}

			err := service.CreateProject(context.Background(), tt.project)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
			} else {
				assert.NoError(t, err)
			}
			mockDB.AssertExpectations(t)
		})
	}
}

func TestGetAllProjects(t *testing.T) {
	mockProjects := []*fusion.Project{
		{
			ID:        "1",
			AccountID: "acc1",
			Name:      "Project 1",
		},
		{
			ID:        "2",
			AccountID: "acc2",
			Name:      "Project 2",
		},
	}

	tests := []struct {
		name           string
		params         *fusion.GetAllProjectsParams
		mockProjects   []*fusion.Project
		mockDBErr      error
		mockPresignURL string
		mockPresignErr error
		expectedErr    error
	}{
		{
			name:           "successful retrieval",
			params:         &fusion.GetAllProjectsParams{},
			mockProjects:   mockProjects,
			mockDBErr:      nil,
			mockPresignURL: "https://presigned-url",
			mockPresignErr: nil,
			expectedErr:    nil,
		},
		{
			name:           "database error",
			params:         &fusion.GetAllProjectsParams{},
			mockProjects:   nil,
			mockDBErr:      errDatabaseMsg,
			mockPresignURL: "",
			mockPresignErr: nil,
			expectedErr:    errDatabaseMsg,
		},
		{
			name:           "presign error",
			params:         &fusion.GetAllProjectsParams{},
			mockProjects:   mockProjects,
			mockDBErr:      nil,
			mockPresignURL: "",
			mockPresignErr: fmt.Errorf("presign error"),
			expectedErr:    fmt.Errorf("failed to generate presign URL for project 1: presign error"),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			mockDB.On("SelectAll", mock.Anything, tt.params).Return(tt.mockProjects, tt.mockDBErr)
			for _, p := range tt.mockProjects {
				mockPresigner.On("PresignGet",
					mock.Anything,
					fmt.Sprintf("projects/%s/%s/", p.AccountID, p.ID),
					time.Minute*5,
				).Return(tt.mockPresignURL, tt.mockPresignErr).Maybe()
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			projects, err := service.GetAllProjects(context.Background(), tt.params)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
				assert.Nil(t, projects)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, len(tt.mockProjects), len(projects))
				for i, p := range projects {
					assert.Equal(t, tt.mockPresignURL, p.ProjectFileURL)
					assert.Equal(t, tt.mockProjects[i].ID, p.ID)
				}
			}

			mockDB.AssertExpectations(t)
			mockPresigner.AssertExpectations(t)
		})
	}
}

func TestUpdateProject(t *testing.T) {
	tests := []struct {
		name        string
		id          string
		project     *fusion.ProjectUpdateRequest
		mockErr     error
		expectedErr error
	}{
		{
			name: "successful update",
			id:   "1",
			project: &fusion.ProjectUpdateRequest{
				Name: "Updated Project",
			},
			mockErr:     nil,
			expectedErr: nil,
		},
		{
			name: "database error",
			id:   "1",
			project: &fusion.ProjectUpdateRequest{
				Name: "Updated Project",
			},
			mockErr:     errDatabaseMsg,
			expectedErr: errDatabaseMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockDB.On("Update", mock.Anything, tt.id, tt.project).Return(tt.mockErr)

			service := &Service{
				dbService: mockDB,
			}

			err := service.UpdateProject(context.Background(), tt.id, tt.project)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
			} else {
				assert.NoError(t, err)
			}
			mockDB.AssertExpectations(t)
		})
	}
}

func TestDeleteProject(t *testing.T) {
	tests := []struct {
		name        string
		id          string
		mockErr     error
		expectedErr error
	}{
		{
			name:        "successful deletion",
			id:          "1",
			mockErr:     nil,
			expectedErr: nil,
		},
		{
			name:        "database error",
			id:          "1",
			mockErr:     errDatabaseMsg,
			expectedErr: errDatabaseMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockDB.On("Delete", mock.Anything, tt.id).Return(tt.mockErr)

			service := &Service{
				dbService: mockDB,
			}

			err := service.DeleteProject(context.Background(), tt.id)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
			} else {
				assert.NoError(t, err)
			}
			mockDB.AssertExpectations(t)
		})
	}
}
