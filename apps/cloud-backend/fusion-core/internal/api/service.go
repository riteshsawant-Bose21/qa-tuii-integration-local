package api

import (
	"errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	"github.com/gin-gonic/gin"
)

// API is a service for the main API.
type API struct {
	engine  *gin.Engine
	product product.Product
	project project.Project
}

// New returns a new API from the given services.
func New(engine *gin.Engine,
	productSvc product.Product,
	projectSvc project.Project,
) (*API, error) {
	if engine == nil {
		return nil, errors.New("missing gin engine")
	}
	if productSvc == nil {
		return nil, errors.New("missing product service")
	}

	if projectSvc == nil {
		return nil, errors.New("missing project service")
	}

	api := &API{
		engine:  engine,
		product: productSvc,
		project: projectSvc,
	}

	api.registerRoutes()
	return api, nil
}

// Engine returns the underlying Gin engine.
func (a *API) Engine() *gin.Engine {
	return a.engine
}
