package cloudfs

import (
	"context"
	"fmt"
	"io"
	"os"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3 struct {
	Client *s3.Client
	config *s3Config
}

type s3Config struct {
	accessKey string
	secretKey string
	region    string
}

func NewS3Client(ctx context.Context, accessKey string, secretKey string, region string) (*S3, error) {

	awsconfig := &s3Config{
		accessKey: accessKey,
		secretKey: secretKey,
		region:    region,
	}
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(awsconfig.accessKey, awsconfig.secretKey, "")),
		config.WithRegion(awsconfig.region),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(cfg)

	return &S3{
		Client: client,
		config: awsconfig,
	}, nil
}

// S3BucketHandle provides methods to operate on a bucket in AWS S3.
type S3BucketHandle struct {
	name   string
	client *s3.Client
	config *s3Config
}

// Bucket returns an S3BucketHandle, which provides operations on a bucket with the given name.
// func (s *S3) Bucket(name string) BucketHandle {
// 	return &S3BucketHandle{
// 		name:   name,
// 		client: s.client,
// 		config: s.config,
// 	}
// }

// func (b *S3BucketHandle) Upload(ctx context.Context, name string, content io.Reader, contentType *string) error {
// 	// Implement the upload logic using AWS SDK for Go v2
// 	return nil
// }

// func (b *S3BucketHandle) Object(name string) ObjectHandle {
// 	return &S3ObjectHandle{
// 		handle: b,
// 		name:   name,
// 	}
// }

// func (b *S3BucketHandle) GetSignedURL(ctx context.Context, name string) (string, error) {
// 	// Implement the logic to generate a signed URL using AWS SDK for Go v2
// 	return "", nil
// }

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
	bucket string
	key    string
	region string
}

func NewS3Source(bucket, key, region string) (*S3Source, error) {
	if bucket == "" || key == "" {
		return nil, fmt.Errorf("bucket and key are required for S3 source")
	}

	return &S3Source{
		bucket: bucket,
		key:    key,
		region: region,
	}, nil
}

func (s *S3Source) ReadAll() ([]byte, error) {
	// Create S3 client using the NewS3Client function
	ctx := context.Background()

	// Use environment variables for AWS credentials
	accessKey := os.Getenv("AWS_ACCESS_KEY_ID")
	secretKey := os.Getenv("AWS_SECRET_ACCESS_KEY")

	// Default region if not provided
	region := s.region
	if region == "" {
		region = os.Getenv("AWS_REGION")
		if region == "" {
			region = "us-east-1" // Default region
		}
	}

	s3Client, err := NewS3Client(ctx, accessKey, secretKey, region)
	if err != nil {
		return nil, fmt.Errorf("failed to create S3 client: %w", err)
	}

	// Use the S3 client directly to get the object
	input := &s3.GetObjectInput{
		Bucket: &s.bucket,
		Key:    &s.key,
	}

	resp, err := s3Client.Client.GetObject(ctx, input)
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
