package environment

import (
	"fmt"
)

// LoadLookuper defines the interface for loading and looking up environment variables.
type LoadLookuper interface {
	Load(filepath ...string) error
	Lookup(key string) (string, bool)
}

// Environment provides methods to load and retrieve environment variables.
type Environment struct {
	loadLookuper LoadLookuper
}

// New creates a new Environment with the provided LoadLookuper.
func New(loadLookuper LoadLookuper) *Environment {
	return &Environment{loadLookuper}
}

// Load loads environment variables from the specified file path.
func (e *Environment) Load(fpath string) error {
	if err := e.loadLookuper.Load(fpath); err != nil {
		return fmt.Errorf("can't load config from env file %s: %v", fpath, err)
	}
	return nil
}

// ReqString retrieves the string value for the given key from the environment.
func (e *Environment) ReqString(key string) (string, error) {
	val, ok := e.loadLookuper.Lookup(key)
	if !ok {
		return "", fmt.Errorf("key %s not found in environment", key)
	}
	return val, nil
}
