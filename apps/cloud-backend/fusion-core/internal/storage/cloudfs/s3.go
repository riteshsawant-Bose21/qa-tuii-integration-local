package cloudfs

import (
	"context"
	"fmt"
	"io"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	v4 "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type s3Client interface {
	GetObject(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.Options)) (*s3.GetObjectOutput, error)
	PutObject(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.Options)) (*s3.PutObjectOutput, error)
}

type presignClient interface {
	PresignGetObject(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error)
	PresignPutObject(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error)
}

type S3 struct {
	client        s3Client
	presignClient presignClient
	config        *s3Config
}

type s3Config struct {
	accessKey string
	secretKey string
	region    string
}

func NewS3Client(ctx context.Context) (*S3, error) {

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(cfg)

	return &S3{
		client:        client,
		presignClient: s3.NewPresignClient(client),
	}, nil
}

// S3BucketHandle provides methods to operate on a bucket in AWS S3.
type S3BucketHandle struct {
	bucketName    string
	client        s3Client
	config        *s3Config
	presignClient presignClient
}

// Bucket returns an S3BucketHandle, which provides operations on a bucket with the given name.
func (s *S3) Bucket(name string) BucketHandle {
	return &S3BucketHandle{
		bucketName:    name,
		client:        s.client,
		config:        s.config,
		presignClient: s.presignClient,
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

func (b *S3BucketHandle) PresignGet(ctx context.Context, objectKey string, ttl time.Duration) (string, error) {

	req, err := b.presignClient.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(b.bucketName),
		Key:    aws.String(objectKey),
	}, func(po *s3.PresignOptions) { po.Expires = ttl })
	if err != nil {
		return "", err
	}
	return req.URL, nil
}

func (b *S3BucketHandle) PresignPut(ctx context.Context, objectKey string, ttl time.Duration) (string, error) {

	req, err := b.presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(b.bucketName),
		Key:    aws.String(objectKey),
	}, func(po *s3.PresignOptions) { po.Expires = ttl })
	if err != nil {
		return "", err
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
		return nil, err
	}
	return resp.Body, nil
}
