package config

import (
	"fmt"
)

// S3 holds the configuration settings for connecting to an S3 service.
type S3Config struct {
	PriceBucket   string
	ProductBucket string
	ProjectBucket string
	Region        string
}

// S3 retrieves the S3 configuration from the store.
func (s *Service) S3() (*S3Config, error) {
	projectBucket, err := s.store.ReqString(keyS3ProjectBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 project bucket: %w", err)
	}

	productBucket, err := s.store.ReqString(keyProductBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 product bucket: %w", err)
	}

	priceBucket, err := s.store.ReqString(keyPriceBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 price bucket: %w", err)
	}

	region, err := s.store.ReqString(keyS3Region)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 region: %w", err)
	}

	return &S3Config{
		PriceBucket:   priceBucket,
		ProductBucket: productBucket,
		ProjectBucket: projectBucket,
		Region:        region,
	}, nil
}

const (
	keyPriceBucket     string = "S3_PRICE_BUCKET"
	keyProductBucket   string = "S3_PRODUCT_BUCKET"
	keyS3ProjectBucket string = "S3_PROJECT_BUCKET"
	keyS3Region        string = "AWS_REGION"
)
