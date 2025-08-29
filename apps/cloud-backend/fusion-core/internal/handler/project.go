package handler

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion/project"
	"github.com/gin-gonic/gin"
)

type ProjectHandler struct {
	project project.Project
}

func NewProjectHandler(project project.Project) *ProjectHandler {
	return &ProjectHandler{
		project: project,
	}
}

func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	var p fusion.Project
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(400, gin.H{"error": err.Error()})
		return
	}
	h.project.Insert(ctx, &p)
	ctx.JSON(201, p)
}

// GetProject retrieves a project by ID
func (h *ProjectHandler) GetProject(ctx *gin.Context) {
	id := ctx.Param("id")
	project, err := h.project.GetByID(ctx, id)
	if err != nil {
		ctx.JSON(404, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(200, project)
}

// GetProjects retrieves all projects
func (h *ProjectHandler) GetProjects(ctx *gin.Context) {
	projects, err := h.project.GetAll(ctx)
	if err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(200, projects)
}

// UpdateProject updates an existing project
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	id := ctx.Param("id")
	var p fusion.Project
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(400, gin.H{"error": err.Error()})
		return
	}
	h.project.Update(ctx, id, &p)
	ctx.JSON(200, p)
}

// DeleteProject deletes a project by ID
func (h *ProjectHandler) DeleteProject(ctx *gin.Context) {
	id := ctx.Param("id")
	if err := h.project.Delete(ctx, id); err != nil {
		ctx.JSON(404, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(204, nil)
}
