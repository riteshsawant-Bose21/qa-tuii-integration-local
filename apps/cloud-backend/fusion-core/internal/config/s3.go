package config

// S3 holds the configuration settings for connecting to an S3 service.
type S3 struct {
	ProjectBucket string
}

// S3 retrieves the S3 configuration from the store.
func (s *Service) S3() (*S3, error) {
	projectBucket, err := s.store.ReqString(keyS3ProjectBucket)
	if err != nil {
		return nil, err
	}

	return &S3{
		ProjectBucket: projectBucket,
	}, nil
}

const (
	keyS3ProjectBucket string = "S3_PROJECT_BUCKET"
)
