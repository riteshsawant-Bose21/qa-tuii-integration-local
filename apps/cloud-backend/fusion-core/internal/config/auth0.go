package config

// Auth0 holds the configuration settings for Auth0 integration.
type Auth0 struct {
	Domain string
}

// Auth0 retrieves the Auth0 configuration from the store.
func (c *Service) Auth0() (*Auth0, error) {
	domain, err := c.store.ReqString(keyAuth0Domain)
	if err != nil {
		return nil, err
	}

	return &Auth0{
		Domain: domain,
	}, nil
}

const (
	keyAuth0Domain string = "AUTH0_DOMAIN"
)
