package config

import "fmt"

// AWS holds the configuration settings for AWS services.
type AWS struct {
	Region  string
	Profile string
}

const (
	keyAWSRegion  string = "AWS_REGION"
	keyAWSProfile string = "AWS_PROFILE"
)

// AWS retrieves the AWS configuration from the store.
func (p *Service) AWS() (*AWS, error) {
	region, err := p.store.ReqString(keyAWSRegion)
	if err != nil {
		return nil, fmt.Errorf("AWS_REGION environment variable is required")
	}

	profile, err := p.store.ReqString(keyAWSProfile)
	if err != nil {
		return nil, fmt.Errorf("AWS_PROFILE environment variable is required")
	}

	return &AWS{
		Region:  region,
		Profile: profile,
	}, nil
}
