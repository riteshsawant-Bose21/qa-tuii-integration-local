package v1

import (
	"fusion-cloud/db"
	"fusion-cloud/internal/api/v1/handler"
	"fusion-cloud/internal/config"
	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/middleware"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils/jwtutil"
	"fusion-cloud/internal/xyte"
	"net/http"

	"github.com/go-chi/chi/v5"
)

func Router(cfg config.Config, jwtManager *jwtutil.JWTManager) *chi.Mux {
	r := chi.NewRouter()
	xyteService := xyte.NewClient(&http.Client{}, cfg.XyteBaseURL, cfg.XyteApiKey)

	// Initialize repositories
	userRepo := repository.NewUserRepository(db.DB)
	projectRepo := repository.NewProjectRepository(db.DB)
	productRepo := repository.NewProductRepository(constants.ProductFilePath)
	fileRoute := repository.NewFileRepository(constants.FileUploadBaseDir)
	organizationRepo := repository.NewOrganization(db.DB, xyteService)
	deviceRepo := repository.NewDevice(db.DB, xyteService)
	spaceRepo := repository.NewSpace(db.DB, xyteService)
	filePreviewRepo := repository.NewFilePreviewRepository(constants.FileUploadBaseDir)

	// Initialize services
	authService := service.NewAuthService(userRepo, jwtManager)
	userService := service.NewUserService(userRepo, jwtManager)
	projectService := service.NewProjectService(projectRepo, jwtManager)
	productService := service.NewProductService(productRepo)
	fileService := service.NewFileService(fileRoute)
	organizationService := service.NewOrganization(organizationRepo, jwtManager)
	deviceService := service.NewDevice(deviceRepo, jwtManager)
	spaceService := service.NewSpace(spaceRepo, jwtManager)
	filePreviewService := service.NewFilePreviewService(filePreviewRepo)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authService)
	userHandler := handler.NewUserHandler(userService)
	projectHandler := handler.NewProjectHandler(projectService)
	productHandler := handler.NewProductHandler(productService)
	fileHandler := handler.NewFileHandler(fileService)
	organizationHandler := handler.NewOrganizationHandler(organizationService)
	deviceHandler := handler.NewDevice(deviceService)
	spaceHandler := handler.NewSpace(spaceService)
	filePreviewHandler := handler.NewFilePreviewHandler(filePreviewService)

	// Helper for protected route groups
	withAuth := func(routeFn func(r chi.Router)) func(r chi.Router) {
		return func(r chi.Router) {
			r.Use(middleware.JWTAuthMiddleware(jwtManager))
			routeFn(r)
		}
	}

	// Public routes
	r.Route("/auth", authHandler.RegisterRoutes)
	r.Route("/file-preview", filePreviewHandler.RegisterRoutes)

	// Protected routes
	r.Route("/users", withAuth(userHandler.RegisterRoutes))
	r.Route("/projects", withAuth(projectHandler.RegisterRoutes))
	r.Route("/products", withAuth(productHandler.RegisterRoutes))
	r.Route("/files", withAuth(fileHandler.RegisterRoutes))
	r.Route("/organization", withAuth(organizationHandler.RegisterRoutes))
	r.Route("/devices", withAuth(deviceHandler.RegisterRoutes))
	r.Route("/spaces", withAuth(spaceHandler.RegisterRoutes))

	return r
}
