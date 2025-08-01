package db

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

var DB *sql.DB

func Init(dbPath string) {
	var err error
	DB, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		log.Fatalf("Failed to open SQLite database: %v", err)
	}

	if err = DB.Ping(); err != nil {
		log.Fatalf("Failed to connect to SQLite database: %v", err)
	}

	log.Printf("Successfully connected to SQLite database at %s", dbPath)
}
