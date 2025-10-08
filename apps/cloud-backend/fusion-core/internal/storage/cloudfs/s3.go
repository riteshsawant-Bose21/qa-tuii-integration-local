package cloudfs

import (
	"context"
	"fmt"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3 struct {
	client *s3.Client
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
		client: client,
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
func (s *S3) Bucket(name string) BucketHandle {
	return &S3BucketHandle{
		name:   name,
		client: s.client,
		config: s.config,
	}
}

func (b *S3BucketHandle) Upload(ctx context.Context, name string, content io.Reader, contentType *string) error {
	// Implement the upload logic using AWS SDK for Go v2
	return nil
}

func (b *S3BucketHandle) Object(name string) ObjectHandle {
	return &S3ObjectHandle{
		handle: b,
		name:   name,
	}
}

// func (b *S3BucketHandle) GetSignedURL(ctx context.Context, name string) (string, error) {
// 	// Implement the logic to generate a signed URL using AWS SDK for Go v2
// 	return "", nil
// }

// S3ObjectHandle provides methods to operate on an object in an S3 bucket.
type S3ObjectHandle struct {
	handle *S3BucketHandle
	name   string
	client *s3.Client
	bucket string
}

// func (o *S3ObjectHandle) Name() string {
// 	return o.name
// }

func (o *S3ObjectHandle) NewReader(ctx context.Context) (io.ReadCloser, error) {
	resp, err := o.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(o.bucket),
		Key:    aws.String(o.name),
	})
	if err != nil {
		return nil, err
	}
	return resp.Body, nil
}
