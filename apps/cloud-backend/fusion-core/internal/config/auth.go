package config

// Auth0 holds the configuration settings for Auth0 integration.
type Auth0 struct {
	Domain                       string
	ClientID                     string
	ClientSecret                 string
	ResourceOwnerPasswordFlowEnabled bool
	DefaultResourceOwnerPassword string
}

// Auth0 retrieves the Auth0 configuration from the store.
func (c *Service) Auth0() (*Auth0, error) {
	domain, err := c.store.ReqString(auth0Domain)
	if err != nil {
		return nil, err
	}

	clientID, err := c.store.ReqString(keyAuth0ClientID)
	if err != nil {
		return nil, err
	}

	clientSecret, err := c.store.ReqString(keyAuth0ClientSecret)
	if err != nil {
		return nil, err
	}

	resourceOwnerPasswordFlowEnabled, err := c.store.ReqBool(keyAuth0ResourceOwnerPasswordFlowEnabled)
	if err != nil {
		return nil, err
	}

	testUserDefaultPassword, err := c.store.ReqString(keyAuth0TestUserDefaultPassword)
	if err != nil {
		return nil, err
	}

	return &Auth0{
		Domain:                       domain,
		ClientID:                     clientID,
		ClientSecret:                 clientSecret,
		ResourceOwnerPasswordFlowEnabled: resourceOwnerPasswordFlowEnabled,
		DefaultResourceOwnerPassword: testUserDefaultPassword,
	}, nil
}

const (
	// Auth0 configuration keys
	auth0Domain string = "AUTH0_DOMAIN"
	keyAuth0ClientID     string = "AUTH0_CLIENT_ID"
	keyAuth0ClientSecret string = "AUTH0_CLIENT_SECRET"
	keyAuth0ResourceOwnerPasswordFlowEnabled string = "AUTH0_RESOURCE_OWNER_PASSWORD_FLOW_ENABLED"
	keyAuth0TestUserDefaultPassword   string = "AUTH0_TEST_USER_DEFAULT_PASSWORD"
)
