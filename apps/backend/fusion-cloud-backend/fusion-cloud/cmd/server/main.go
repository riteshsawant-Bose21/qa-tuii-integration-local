// @title           Fusion Cloud API
// @version         1.0
// @description     Fusion Cloud API provides a RESTful interface for managing projects, users, and authentication.

// @host      localhost:8020
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer {your token}" to authenticate.

package main

import (
	"log"
	"net/http"
	"time"

	"fusion-cloud/db"
	"fusion-cloud/internal/api"
	"fusion-cloud/internal/config"
	"fusion-cloud/internal/utils"
	"fusion-cloud/internal/utils/jwtutil"

	_ "fusion-cloud/docs" // Import the generated Swagger docs

	"github.com/joho/godotenv"
	"github.com/rs/cors"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found. Falling back to defaults.")
	}

	cfg := config.Load()

	// Init SQLite
	db.Init(cfg.DBPath)

	// Auto-run DB migrations
	if err := db.AutoMigrate(db.DB, "db/migrations"); err != nil {
		log.Fatalf("Auto migration failed: %v", err)
	}

	// Initialize JWT Manager
	jwtManager := jwtutil.NewJWTManager(cfg.JwtSecret, cfg.JwtRefreshSecret, time.Minute*60, time.Hour*24*7)

	r := api.NewRouter(cfg, jwtManager)

	allowedOrigins := utils.FormatOrigins(cfg.AllowedBackendOrigins)
	log.Println("Allowed Origins:", allowedOrigins)

	corsHandler := cors.New(cors.Options{
		AllowedOrigins:   allowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})

	//Wrap handler with CORS middleware
	handler := corsHandler.Handler(r)

	log.Printf("Starting server on %s...", cfg.Port)
	if err := http.ListenAndServe(`:`+cfg.Port, handler); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
