package config

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
)

// CloudConfig holds the configuration settings for connecting to a cloud service.
type CloudConfig struct {
	PriceS3Bucket        string
	ProductS3Bucket      string
	ProjectS3Bucket      string
	FirmwareBundleBucket string
	Region               string
	IoTEndpoint          string
	IoTCommandTopic      string
	IoTDevicePolicy      string
	AWSConfig            aws.Config
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

	firmwareBundleBucket, err := s.store.ReqString(environment.S3.FirmwareBundleBucket)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 firmware bucket: %w", err)
	}

	region, err := s.store.ReqString(environment.AWS.Region)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 region: %w", err)
	}

	iotEndpoint, err := s.store.ReqString(environment.IOT.Endpoint)
	if err != nil {
		return nil, fmt.Errorf("failed to get IoT endpoint: %w", err)
	}

	iotCommandTopic, err := s.store.ReqString(environment.IOT.CommandTopic)
	if err != nil {
		return nil, fmt.Errorf("failed to get IoT command topic: %w", err)
	}

	iotDevicePolicy, err := s.store.ReqString(environment.IOT.DevicePolicy)
	if err != nil {
		return nil, fmt.Errorf("failed to get IoT device policy: %w", err)
	}

	// Load AWS configuration
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(region))
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	return &CloudConfig{
		PriceS3Bucket:        priceBucket,
		ProductS3Bucket:      productBucket,
		ProjectS3Bucket:      projectBucket,
		FirmwareBundleBucket: firmwareBundleBucket,
		Region:               region,
		IoTEndpoint:          iotEndpoint,
		IoTCommandTopic:      iotCommandTopic,
		IoTDevicePolicy:      iotDevicePolicy,
		AWSConfig:            cfg,
	}, nil
}
