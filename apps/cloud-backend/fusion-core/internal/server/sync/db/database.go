package db

import (
	"context"
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

// WithTransaction executes a function within a database transaction.
// If the function returns an error or panics, the transaction is rolled back.
// Otherwise, the transaction is committed.
func (d *Database) WithTransaction(ctx context.Context, fn func(*sql.Tx) error) error {
	tx, err := d.DB.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	// Handle panics and ensure rollback
	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback()
			panic(p) // Re-throw panic after rollback
		}
	}()

	// Execute the function
	if err := fn(tx); err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return fmt.Errorf("tx error: %v, rollback error: %v", err, rbErr)
		}
		return err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}
