package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/sqlite3"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3" // This is the SQLite driver import that was missing
)

func main() {
	var migrationsPath string
	var dbPath string
	var command string
	var forceVersion int

	flag.StringVar(&migrationsPath, "path", "db/migrations", "Path to migrations directory")
	flag.StringVar(&dbPath, "database", "db/app.db", "Path to SQLite database file")
	flag.StringVar(&command, "command", "up", "Migration command (up or down)")
	flag.IntVar(&forceVersion, "version", 1, "Force migration version (used only with 'force')")
	flag.Parse()

	// Ensure database directory exists
	dbDir := dbPath[:len(dbPath)-len("/app.db")]
	if err := os.MkdirAll(dbDir, 0755); err != nil {
		log.Fatalf("Failed to create database directory: %v", err)
	}

	// Open SQLite database connection
	db, err := sqlx.Open("sqlite3", dbPath)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer db.Close()

	// Create SQLite driver instance for migrate
	driver, err := sqlite3.WithInstance(db.DB, &sqlite3.Config{})
	if err != nil {
		log.Fatalf("Failed to create SQLite driver: %v", err)
	}

	// Create migrate instance
	sourceURL := fmt.Sprintf("file://%s", migrationsPath)
	m, err := migrate.NewWithDatabaseInstance(sourceURL, "sqlite3", driver)
	if err != nil {
		log.Fatalf("Failed to create migrate instance: %v", err)
	}

	// Run migrations
	switch command {
	case "up":
		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("Failed to apply migrations: %v", err)
		}
		log.Println("Migrations applied successfully")
	case "down":
		if err := m.Down(); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("Failed to revert migrations: %v", err)
		}
		log.Println("Migrations reverted successfully")
	case "force":
		if err := m.Force(forceVersion); err != nil {
			log.Fatalf("Failed to force migration version: %v", err)
		}
		log.Printf("Forced migration to version %d", forceVersion)
	default:
		log.Fatalf("Unknown command: %s (expected 'up' or 'down')", command)
	}
}
