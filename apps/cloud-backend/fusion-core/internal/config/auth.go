package config

// Auth0 holds the configuration settings for Auth0 integration.
type AuthZero struct {
	Domain                       string
	AccessTokenEndpoint          string
	ClientID                     string
	ClientSecret                 string
	ResourceOwnerPasswordFlowEnabled string
	DefaultResourceOwnerPassword string
}

// Auth0 retrieves the Auth0 configuration from the store.
func (c *Service) AuthZero() (*AuthZero, error) {
	domain, err := c.store.ReqString(keyAuthZeroDomain)
	if err != nil {
		return nil, err
	}

	accessTokenEndpoint, err := c.store.ReqString(keyAuthZeroAccessTokenEndpoint)
	if err != nil {
		return nil, err
	}

	clientID, err := c.store.ReqString(keyAuthZeroClientID)
	if err != nil {
		return nil, err
	}

	clientSecret, err := c.store.ReqString(keyAuthZeroClientSecret)
	if err != nil {
		return nil, err
	}

	resourceOwnerPasswordFlowEnabled, err := c.store.ReqString(keyAuthZeroResourceOwnerPasswordFlowEnabled)
	if err != nil {
		return nil, err
	}

	testUserDefaultPassword, err := c.store.ReqString(keyAuthZeroTestUserDefaultPassword)
	if err != nil {
		return nil, err
	}

	return &AuthZero{
		Domain:                       domain,
		AccessTokenEndpoint:          accessTokenEndpoint,
		ClientID:                     clientID,
		ClientSecret:                 clientSecret,
		ResourceOwnerPasswordFlowEnabled: resourceOwnerPasswordFlowEnabled,
		DefaultResourceOwnerPassword: testUserDefaultPassword,
	}, nil
}

const (
	// Auth0 configuration keys
	keyAuthZeroDomain string = "AUTH0_DOMAIN"
	keyAuthZeroAccessTokenEndpoint string = "AUTH0_ACCESS_TOKEN_ENDPOINT"
	keyAuthZeroClientID     string = "AUTH0_CLIENT_ID"
	keyAuthZeroClientSecret string = "AUTH0_CLIENT_SECRET"
	keyAuthZeroResourceOwnerPasswordFlowEnabled string = "AUTH0_RESOURCE_OWNER_PASSWORD_FLOW_ENABLED"
	keyAuthZeroTestUserDefaultPassword   string = "AUTH0_TEST_USER_DEFAULT_PASSWORD"
)
