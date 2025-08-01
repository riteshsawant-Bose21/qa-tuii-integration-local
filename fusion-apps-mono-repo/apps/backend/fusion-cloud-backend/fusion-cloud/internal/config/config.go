package config

import "os"

type Config struct {
	Port                  string
	DBPath                string
	JwtSecret             string
	JwtRefreshSecret      string
	XyteApiKey            string
	XyteBaseURL           string
	AllowedBackendOrigins string
}

func Load() Config {
	return Config{
		Port:                  getEnv("PORT", "8020"),
		DBPath:                getEnv("DB_PATH", "app.db"),
		JwtSecret:             getEnv("JWT_SECRET", "defaultsecret"),
		JwtRefreshSecret:      getEnv("JWT_REFRESH_SECRET", "defaultrefreshsecret"),
		XyteApiKey:            getEnv("XYTE_API_KEY", "defaultapikey"),
		XyteBaseURL:           getEnv("XYTE_BASE_URL", "defaultbaseurl"),
		AllowedBackendOrigins: getEnv("ALLOWED_ORIGINS", "localhost:3000,localhost:3002"),
	}
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
