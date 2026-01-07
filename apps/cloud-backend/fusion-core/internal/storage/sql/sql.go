package sql

import (
	"database/sql"
	"fmt"
)

// New creates a new SQL database connection.
func New(
	opener Opener,
	host, port, user, password, instance, sslMode string,
) (*sql.DB, error) {
	dataSourceName := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		host, port, user, password, instance, sslMode,
	)
	// IMPORTANT: No SSL mode is specified, so it defaults to "disable".
	db, err := opener.Open(dataSourceName)
	if err != nil {
		return nil, fmt.Errorf("failed to open postgres database connection: %w", err)
	}
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping postgres database: %w", err)
	}
	return db, nil
}

type Opener interface {
	Open(dataSourceName string) (*sql.DB, error)
}
