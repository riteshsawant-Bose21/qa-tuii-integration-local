package api

import (
	v1 "fusion-cloud/internal/api/v1"
	"fusion-cloud/internal/config"
	"fusion-cloud/internal/utils/jwtutil"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	httpSwagger "github.com/swaggo/http-swagger"
)

func NewRouter(cfg config.Config, jwtManager *jwtutil.JWTManager) *chi.Mux {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)    // Log each request
	r.Use(middleware.Recoverer) // Recover from panics

	r.Route("/api", func(r chi.Router) {
		r.Mount("/v1", v1.Router(cfg, jwtManager))
	})

	// Swagger UI
	r.Get("/docs/*", httpSwagger.WrapHandler)

	return r
}
