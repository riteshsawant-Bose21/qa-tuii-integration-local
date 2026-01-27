package cloudfs

import (
	"context"
	"errors"
	"fmt"
	"io"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	v4 "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
	"go.uber.org/zap"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/aws/smithy-go"
)

type s3Client interface {
	GetObject(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.Options)) (*s3.GetObjectOutput, error)
	PutObject(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.Options)) (*s3.PutObjectOutput, error)
	HeadObject(ctx context.Context, params *s3.HeadObjectInput, optFns ...func(*s3.Options)) (*s3.HeadObjectOutput, error)
}

type presignClient interface {
	PresignGetObject(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error)
	PresignPutObject(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error)
}

type S3 struct {
	Client        s3Client
	PresignClient presignClient
	config        *s3Config
}

type s3Config struct {
	accessKey string
	secretKey string
	region    string
}

func NewS3Client(ctx context.Context, region string) (*S3, error) {

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(cfg)
	presignClient := s3.NewPresignClient(client)

	// Create config from loaded AWS config
	s3Cfg := &s3Config{
		region: cfg.Region,
	}

	return &S3{
		Client:        client,
		PresignClient: presignClient,
		config:        s3Cfg,
	}, nil
}

// S3BucketHandle provides methods to operate on a bucket in AWS S3.
type S3BucketHandle struct {
	bucketName    string
	client        s3Client
	presignClient presignClient
}

// Bucket returns an S3BucketHandle, which provides operations on a bucket with the given name.
func (s *S3) Bucket(name string) BucketHandle {
	return &S3BucketHandle{
		bucketName:    name,
		client:        s.Client,
		presignClient: s.PresignClient,
	}
}

func (b *S3BucketHandle) Object(name string) ObjectHandle {
	return &S3ObjectHandle{
		handle: b,
		name:   name,
		client: b.client,
		bucket: b.bucketName,
	}
}

func (b *S3BucketHandle) Upload(ctx context.Context, name string, content io.Reader, contentType *string) error {
	return nil
}

func (b *S3BucketHandle) ObjectExists(ctx context.Context, name string, logger *zap.Logger) (bool, error) {
	_, err := b.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(b.bucketName),
		Key:    aws.String(name),
	})
	if err != nil {
		var apiError smithy.APIError
		if errors.As(err, &apiError) {
			switch apiError.(type) {
			case *types.NotFound:
				return false, nil
			default:
				logger.Error("Failed to check if object exists", zap.Error(err))
				return false, fmt.Errorf("failed to check if object exists: %w", err)
			}
		}
		logger.Error("Failed to check if object exists", zap.Error(err))
		return false, fmt.Errorf("failed to check if object exists: %w", err)
	}
	return true, nil
}

func (b *S3BucketHandle) PresignGet(ctx context.Context, objectKey string, ttl time.Duration, logger *zap.Logger) (string, error) {

	exists, err := b.ObjectExists(ctx, objectKey, logger)
	if err != nil {
		return "", err
	}
	if !exists {
		return "", nil
	}

	req, err := b.presignClient.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(b.bucketName),
		Key:    aws.String(objectKey),
	}, func(po *s3.PresignOptions) { po.Expires = ttl })
	if err != nil {
		logger.Error("Failed to presign get object request", zap.Error(err))
		return "", fmt.Errorf("failed to presign get object request: %w", err)
	}
	return req.URL, nil
}

func (b *S3BucketHandle) PresignPut(ctx context.Context, objectKey string, ttl time.Duration, logger *zap.Logger) (string, error) {

	req, err := b.presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(b.bucketName),
		Key:    aws.String(objectKey),
	}, func(po *s3.PresignOptions) { po.Expires = ttl })
	if err != nil {
		logger.Error("Failed to presign put object request", zap.Error(err))
		return "", fmt.Errorf("failed to presign put object request: %w", err)
	}
	return req.URL, nil
}

// S3ObjectHandle provides methods to operate on an object in an S3 bucket.
type S3ObjectHandle struct {
	handle *S3BucketHandle
	name   string
	client s3Client
	bucket string
}

func (o *S3ObjectHandle) NewReader(ctx context.Context) (io.ReadCloser, error) {
	resp, err := o.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(o.bucket),
		Key:    aws.String(o.name),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get object: %w", err)
	}
	return resp.Body, nil
}

// // S3ObjectHandle provides methods to operate on an object in an S3 bucket.
// type S3ObjectHandle struct {
// 	handle *S3BucketHandle
// 	name   string
// 	client *s3.Client
// 	bucket string
// }

// // func (o *S3ObjectHandle) Name() string {
// // 	return o.name
// // }

// func (o *S3ObjectHandle) NewReader(ctx context.Context) (io.ReadCloser, error) {
// 	resp, err := o.handle.client.GetObject(ctx, &s3.GetObjectInput{
// 		Bucket: aws.String(o.handle.name),
// 		Key:    aws.String(o.name),
// 	})
// 	if err != nil {
// 		return nil, err
// 	}
// 	return resp.Body, nil
// }

///// Modifyed files below /////

// S3Source implements DataSource for AWS S3
type S3Source struct {
	bucket   string
	key      string
	region   string
	s3Client *S3
}

func NewS3Source(s3Client *S3, bucket, key, region string) (*S3Source, error) {
	if bucket == "" || key == "" {
		return nil, fmt.Errorf("bucket and key are required for S3 source")
	}
	if s3Client == nil {
		return nil, fmt.Errorf("s3Client is required for S3 source")
	}

	return &S3Source{
		bucket:   bucket,
		key:      key,
		region:   region,
		s3Client: s3Client,
	}, nil
}

func (s *S3Source) ReadAll() ([]byte, error) {
	ctx := context.Background()

	// Use the existing S3 client
	input := &s3.GetObjectInput{
		Bucket: &s.bucket,
		Key:    &s.key,
	}

	resp, err := s.s3Client.Client.GetObject(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 object %s/%s: %w", s.bucket, s.key, err)
	}
	defer resp.Body.Close()

	// Read all data
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read data from S3 object: %w", err)
	}

	return data, nil
}

func (s *S3Source) GetPath() string {
	return fmt.Sprintf("s3://%s/%s", s.bucket, s.key)
}

func (s *S3Source) GetSize() (*int64, error) {
	// TODO: Implement S3 size retrieval
	return nil, fmt.Errorf("S3 source size retrieval not implemented")
}

func (s *S3Source) Close() error {
	// No resources to close for S3 source
	return nil
}

// DataSource interface for compatibility with sync service
type DataSource interface {
	ReadAll() ([]byte, error)
	GetPath() string
	GetSize() (*int64, error)
	Close() error
}
