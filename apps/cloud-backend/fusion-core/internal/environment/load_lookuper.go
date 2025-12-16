package environment

import (
	"os"

	"github.com/joho/godotenv"
)

var DefaultLoadLookuper = defaultLoadLookuperService{}

// defaultLoadLookuperService is the default implementation of LoadLookuper
type defaultLoadLookuperService struct{}

// Load loads environment variables from the specified files.
func (d defaultLoadLookuperService) Load(filenames ...string) error {
	return godotenv.Load(filenames...)
}

// Lookup retrieves the value of the environment variable named by the key.
func (d defaultLoadLookuperService) Lookup(key string) (string, bool) {
	return os.LookupEnv(key)
}
