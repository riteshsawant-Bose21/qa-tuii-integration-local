package config

import "fmt"

// S3 holds the configuration settings for connecting to an S3 service.
type S3 struct {
	ProjectBucket string
	Region        string
}

// S3 retrieves the S3 configuration from the store.
func (s *Service) S3() (*S3, error) {
	projectBucket, err := s.store.ReqString(keyS3ProjectBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 project bucket: %w", err)
	}

	region, err := s.store.ReqString(keyS3Region)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 region: %w", err)
	}

	return &S3{
		ProjectBucket: projectBucket,
		Region:        region,
	}, nil
}

const (
	keyS3ProjectBucket string = "S3_PROJECT_BUCKET"
	keyS3Region        string = "S3_REGION"
)
