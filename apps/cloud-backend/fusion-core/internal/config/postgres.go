package config

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
	host, err := p.store.ReqString(keyPostgresHost)
	if err != nil {
		return nil, err
	}

	port, err := p.store.ReqString(keyPostgresPort)
	if err != nil {
		return nil, err
	}

	user, err := p.store.ReqString(keyPostgresUser)
	if err != nil {
		return nil, err
	}

	password, err := p.store.ReqString(keyPostgresPass)
	if err != nil {
		return nil, err
	}

	database, err := p.store.ReqString(keyPostgresInstance)
	if err != nil {
		return nil, err
	}

	sslMode, err := p.store.ReqString(keyPostgresSSLMode)
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

const (
	keyPostgresHost     string = "POSTGRES_HOST"
	keyPostgresPort     string = "POSTGRES_PORT"
	keyPostgresUser     string = "POSTGRES_USER"
	keyPostgresPass     string = "POSTGRES_PASS"
	keyPostgresInstance string = "POSTGRES_INSTANCE"
	keyPostgresSSLMode  string = "POSTGRES_SSL_MODE"
)
