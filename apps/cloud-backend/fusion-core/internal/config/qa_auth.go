package config

import (
	"strconv"
	"strings"
)

// QAAuth holds the configuration settings for QA authentication
type QAAuth struct {
	Enabled         bool
	Auth0Domain     string
	ClientID        string
	ClientSecret    string
	DefaultPassword string
}

// QAAuth retrieves the QA authentication configuration from the store
func (c *Service) QAAuth() (*QAAuth, error) {
	// Check if QA auth is enabled (optional, defaults to false)
	enabledStr, err := c.store.ReqString(keyQAAuthEnabled)
	if err != nil {
		// If the key doesn't exist, assume disabled
		return &QAAuth{Enabled: false}, nil
	}

	enabled, err := strconv.ParseBool(strings.ToLower(enabledStr))
	if err != nil {
		// If invalid boolean value, assume disabled
		return &QAAuth{Enabled: false}, nil
	}

	// If QA auth is disabled, return a disabled config
	if !enabled {
		return &QAAuth{Enabled: false}, nil
	}

	domain, err := c.store.ReqString(keyQAAuth0Domain)
	if err != nil {
		return nil, err
	}

	clientID, err := c.store.ReqString(keyQAAuth0ClientID)
	if err != nil {
		return nil, err
	}

	clientSecret, err := c.store.ReqString(keyQAAuth0ClientSecret)
	if err != nil {
		return nil, err
	}

	defaultPassword, err := c.store.ReqString(keyQADefaultPassword)
	if err != nil {
		return nil, err
	}

	return &QAAuth{
		Enabled:         enabled,
		Auth0Domain:     domain,
		ClientID:        clientID,
		ClientSecret:    clientSecret,
		DefaultPassword: defaultPassword,
	}, nil
}

const (
	keyQAAuthEnabled       string = "QA_AUTH_ENABLED"
	keyQAAuth0Domain       string = "QA_AUTH0_DOMAIN"
	keyQAAuth0ClientID     string = "QA_AUTH0_CLIENT_ID"
	keyQAAuth0ClientSecret string = "QA_AUTH0_CLIENT_SECRET"
	keyQADefaultPassword   string = "QA_DEFAULT_PASSWORD"
)
