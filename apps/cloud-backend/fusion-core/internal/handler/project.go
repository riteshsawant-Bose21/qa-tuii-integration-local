package handler

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
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
	if err := h.project.Insert(ctx, &p); err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}
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
	if err := h.project.Update(ctx, id, &p); err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}
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

// SyncProject triggers synchronization for a project by ID
func (h *ProjectHandler) SyncProject(ctx *gin.Context) {
	id := ctx.Param("id")
	var req struct {
		MetaData   map[string]interface{} `json:"meta_data"`
		ZipFileURL string                 `json:"zip_file_url"`
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.SyncProject(ctx, id, req.MetaData, req.ZipFileURL); err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(200, gin.H{"message": "Project sync initiated"})
}
