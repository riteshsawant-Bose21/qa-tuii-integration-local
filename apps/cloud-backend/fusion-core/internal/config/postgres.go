package config

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
)

// Postgres holds the configuration settings for connecting to a PostgreSQL database.
type Postgres struct {
	Host     string
	Port     string
	User     string
	Password string
	Database string
	SSLMode  string
}

// Postgres retrieves the PostgreSQL configuration from the store.
func (p *Service) Postgres() (*Postgres, error) {
	host, err := p.store.ReqString(environment.DB.Host)
	if err != nil {
		return nil, err
	}

	port, err := p.store.ReqString(environment.DB.Port)
	if err != nil {
		return nil, err
	}

	user, err := p.store.ReqString(environment.DB.User)
	if err != nil {
		return nil, err
	}

	password, err := p.store.ReqString(environment.DB.Password)
	if err != nil {
		return nil, err
	}

	database, err := p.store.ReqString(environment.DB.Instance)
	if err != nil {
		return nil, err
	}

	sslMode, err := p.store.ReqString(environment.DB.SSLMode)
	if err != nil {
		return nil, err
	}

	return &Postgres{
		Host:     host,
		Port:     port,
		User:     user,
		Password: password,
		Database: database,
		SSLMode:  sslMode,
	}, nil
}

// DO WE NEED DEFAULTS?
// const (
// 	defaultPostgresHost string = "127.0.0.1"
// 	defaultPostgresPort string = "5432"
// )
