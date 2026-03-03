package config

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
)

// CloudConfig holds the configuration settings for connecting to a cloud service.
type CloudConfig struct {
	PriceS3Bucket   string
	ProductS3Bucket string
	ProjectS3Bucket string
	Region          string
}

// Cloud retrieves the cloud configuration from the store.
func (s *Service) Cloud() (*CloudConfig, error) {
	projectBucket, err := s.store.ReqString(environment.S3.ProjectBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 project bucket: %w", err)
	}

	productBucket, err := s.store.ReqString(environment.S3.ProductBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 product bucket: %w", err)
	}

	priceBucket, err := s.store.ReqString(environment.S3.PriceBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 price bucket: %w", err)
	}

	region, err := s.store.ReqString(environment.AWS.Region)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 region: %w", err)
	}

	return &CloudConfig{
		PriceS3Bucket:   priceBucket,
		ProductS3Bucket: productBucket,
		ProjectS3Bucket: projectBucket,
		Region:          region,
	}, nil
}
