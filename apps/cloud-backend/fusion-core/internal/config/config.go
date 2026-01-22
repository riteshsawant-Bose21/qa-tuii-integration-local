package config

import (
	"errors"
)

// Service provides methods to fetch configuration settings.
type Service struct {
	store Store
}

// Store defines the interface for configuration storage.
type Store interface {
	ReqString(key string) (string, error)
	ReqBool(key string) (bool, error)
}

// NewService creates a new configuration service with the provided store.
func NewService(store Store) (*Service, error) {
	if store == nil {
		return nil, errors.New("store cannot be nil")
	}
	return &Service{store: store}, nil
}
