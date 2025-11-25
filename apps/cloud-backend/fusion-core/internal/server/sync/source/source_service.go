package source

import (
	"context"
	"fmt"
	"io"
	"os"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"github.com/joho/godotenv"
)

// Service provides data source creation functionality
type Service struct{}

// NewService creates a new source service
func NewService() *Service {
	return &Service{}
}

// DataSource represents a data source interface
type DataSource interface {
	ReadAll() ([]byte, error)
	GetPath() string
	GetSize() (*int64, error)
	Close() error
}

// New creates a data source based on type
func (s *Service) New(sourceType, filePath, bucket, key, region string) (DataSource, error) {
	switch sourceType {
	case "local":
		return NewLocalFileSource(filePath)
	case "s3":
		return NewS3Source(bucket, key, region)
	default:
		return nil, fmt.Errorf("invalid source type: %s", sourceType)
	}
}

// LocalFileSource implements DataSource for local filesystem
type LocalFileSource struct {
	filePath string
}

func NewLocalFileSource(filePath string) (*LocalFileSource, error) {
	// Verify file exists and is readable
	if _, err := os.Stat(filePath); err != nil {
		return nil, fmt.Errorf("failed to access file: %w", err)
	}

	return &LocalFileSource{
		filePath: filePath,
	}, nil
}

func (l *LocalFileSource) ReadAll() ([]byte, error) {
	data, err := os.ReadFile(l.filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}
	return data, nil
}

func (l *LocalFileSource) GetPath() string {
	return l.filePath
}

func (l *LocalFileSource) GetSize() (*int64, error) {
	info, err := os.Stat(l.filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to stat file: %w", err)
	}
	size := info.Size()
	return &size, nil
}

func (l *LocalFileSource) Close() error {
	// No resources to close for local file source
	return nil
}

// S3Source implements DataSource for AWS S3
type S3Source struct {
	bucket     string
	key        string
	cloudStore cloudfs.Store
}

func NewS3Source(bucket, key, awsRegion string) (*S3Source, error) {
	if bucket == "" || key == "" {
		return nil, fmt.Errorf("bucket and key are required for S3 source")
	}

	// Load environment variables from .env file
	_ = godotenv.Load()

	// Get AWS profile from environment variable, fallback to default
	awsProfile := os.Getenv("AWS_PROFILE")
	if awsProfile == "" {
		awsProfile = "default"
	}

	// Use region from parameter or environment variable
	if awsRegion == "" {
		awsRegion = os.Getenv("AWS_REGION")
	}

	// Create S3 client using cloudfs abstraction
	ctx := context.TODO()
	s3Client, err := cloudfs.NewS3ClientWithProfile(ctx, awsProfile, awsRegion)
	if err != nil {
		return nil, fmt.Errorf("failed to create S3 client: %w", err)
	}

	return &S3Source{
		bucket:     bucket,
		key:        key,
		cloudStore: s3Client,
	}, nil
}

func (s *S3Source) ReadAll() ([]byte, error) {
	stream, err := s.ReadStream()
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 object stream: %w", err)
	}
	defer stream.Close()

	data, err := io.ReadAll(stream)
	if err != nil {
		return nil, fmt.Errorf("failed to read S3 object: %w", err)
	}
	return data, nil
}

func (s *S3Source) GetSize() (*int64, error) {
	data, err := s.ReadAll()
	if err != nil {
		return nil, err
	}
	size := int64(len(data))
	return &size, nil
}

func (s *S3Source) GetPath() string {
	return fmt.Sprintf("s3://%s/%s", s.bucket, s.key)
}

func (s *S3Source) Close() error {
	// cloudfs doesn't require explicit closing
	return nil
}

func (s *S3Source) ReadStream() (io.ReadCloser, error) {
	ctx := context.TODO()
	bucketHandle := s.cloudStore.Bucket(s.bucket)
	objectHandle := bucketHandle.Object(s.key)

	reader, err := objectHandle.NewReader(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 object: %w", err)
	}
	return reader, nil
}
