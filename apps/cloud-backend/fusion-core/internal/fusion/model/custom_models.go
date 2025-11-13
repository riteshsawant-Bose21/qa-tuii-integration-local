package model

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

// GetProjectModel combines a Project model with additional metadata
type GetProjectModel struct {
	Project   models.Project
	IsStarred bool
	LockedByUserEmail string
}