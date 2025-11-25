package model

import (
	"context"
	"database/sql"
)

// DBExecutor provides basic SQL query operations (compatible with both *sql.DB and *sql.Tx)
type DBExecutor interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
}

// DBContextExecutor adds context-aware operations
type DBContextExecutor interface {
	DBExecutor
	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
}

// DBWithTransactions includes transaction creation (only for *sql.DB)
type DBWithTransactions interface {
	DBContextExecutor
	BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error)
}

// DBTxExecutor adds transaction control (only for *sql.Tx)
type DBTxExecutor interface {
	DBContextExecutor
	Commit() error
	Rollback() error
}
