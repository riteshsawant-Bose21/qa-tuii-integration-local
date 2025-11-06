package sql

import (
	"database/sql"
	"fmt"

	"github.com/aarondl/sqlboiler/v4/boil"
)

// New creates a new SQL database connection.
func New(
	opener Opener,
	host, port, user, password, instance string,
) (*sql.DB, error) {
	dataSourceName := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, instance,
	)
	// IMPORTANT: No SSL mode is specified, so it defaults to "disable".
	db, err := opener.Open(dataSourceName)
	if err != nil {
		return nil, fmt.Errorf("failed to open postgres database connection: %w", err)
	}
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping postgres database: %w", err)
	}
	boil.SetDB(db)

	boil.DebugMode = true
	return db, nil
}

type Opener interface {
	Open(dataSourceName string) (*sql.DB, error)
}
