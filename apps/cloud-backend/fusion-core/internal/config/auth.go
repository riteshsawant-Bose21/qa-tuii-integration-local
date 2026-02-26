package config

import "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"

// AuthZero holds the configuration settings for Auth0 integration.
type AuthZero struct {
	Domain                           string
	AccessTokenEndpoint              string
	ClientID                         string
	ClientSecret                     string
	ResourceOwnerPasswordFlowEnabled string
	DefaultResourceOwnerPassword     string
}

// AuthZero retrieves the Auth0 configuration from the store.
func (c *Service) AuthZero() (*AuthZero, error) {
	domain, err := c.store.ReqString(environment.Auth0.Domain)
	if err != nil {
		return nil, err
	}

	accessTokenEndpoint, err := c.store.ReqString(environment.Auth0.AccessTokenEndpoint)
	if err != nil {
		return nil, err
	}

	clientID, err := c.store.ReqString(environment.Auth0.ClientID)
	if err != nil {
		return nil, err
	}

	clientSecret, err := c.store.ReqString(environment.Auth0.ClientSecret)
	if err != nil {
		return nil, err
	}

	resourceOwnerPasswordFlowEnabled, err := c.store.ReqString(environment.Auth0.ResourceOwnerPasswordFlowEnabled)
	if err != nil {
		return nil, err
	}

	testUserDefaultPassword, err := c.store.ReqString(environment.Auth0.TestUserDefaultPassword)
	if err != nil {
		return nil, err
	}

	return &AuthZero{
		Domain:                           domain,
		AccessTokenEndpoint:              accessTokenEndpoint,
		ClientID:                         clientID,
		ClientSecret:                     clientSecret,
		ResourceOwnerPasswordFlowEnabled: resourceOwnerPasswordFlowEnabled,
		DefaultResourceOwnerPassword:     testUserDefaultPassword,
	}, nil
}
