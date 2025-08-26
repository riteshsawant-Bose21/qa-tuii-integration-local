package sql

import (
	"database/sql"

	_ "github.com/lib/pq" // PostgreSQL driver
)

// PostgresOpener is the opener for the Postgres database.
var PostgresOpener = postgresOpenerService{}

// postgresOpenerService implements sql.Opener used to open a connection with a SQL database.
type postgresOpenerService struct{}

// Open opens a connection with a PostgreSQL database specified by the given data source name, usually
// consisting of at least the database name and connection information.
func (p postgresOpenerService) Open(dataSourceName string) (*sql.DB, error) {
	return sql.Open("postgres", dataSourceName)
}
