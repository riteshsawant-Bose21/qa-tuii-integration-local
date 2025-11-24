package db

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
)

// Database represents the database connection wrapper
// SQLBoiler works with standard database/sql connections
type Database struct {
	DB *sql.DB
}

// Close closes the database connection
func (d *Database) Close() error {
	return d.DB.Close()
}

// Ping checks if the database connection is alive
func (d *Database) Ping() error {
	return d.DB.Ping()
}

// Connect establishes database connection and returns a Database wrapper
// This connection can be used directly with SQLBoiler models
func Connect(dsn string) (*Database, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Optimize for Lambda (lower connection pool)
	db.SetMaxOpenConns(2)
	db.SetMaxIdleConns(1)
	db.SetConnMaxLifetime(5 * time.Minute)
	db.SetConnMaxIdleTime(2 * time.Minute)

	return &Database{DB: db}, nil
}
