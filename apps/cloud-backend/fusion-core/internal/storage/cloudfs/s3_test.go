package cloudfs

import (
	"bytes"
	"context"
	"errors"
	"io"
	"testing"
	"time"

	v4 "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/stretchr/testify/assert"
)

const (
	testBucketName = "test-bucket"
	testObjectKey  = "test-key"
)

type mockS3Client struct {
	getObjectFunc func(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.Options)) (*s3.GetObjectOutput, error)
	putObjectFunc func(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.Options)) (*s3.PutObjectOutput, error)
}

func (m *mockS3Client) GetObject(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.Options)) (*s3.GetObjectOutput, error) {
	return m.getObjectFunc(ctx, params, optFns...)
}
func (m *mockS3Client) PutObject(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.Options)) (*s3.PutObjectOutput, error) {
	return m.putObjectFunc(ctx, params, optFns...)
}

type mockPresignClient struct {
	presignGetFunc func(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error)
	presignPutFunc func(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error)
}

func (m *mockPresignClient) PresignGetObject(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error) {
	return m.presignGetFunc(ctx, params, optFns...)
}
func (m *mockPresignClient) PresignPutObject(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error) {
	return m.presignPutFunc(ctx, params, optFns...)
}

func TestPresignGet(t *testing.T) {
	mockPresign := &mockPresignClient{
		presignGetFunc: func(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error) {
			return &v4.PresignedHTTPRequest{URL: "https://example.com/get"}, nil
		},
	}
	bucket := &S3BucketHandle{
		bucketName:    testBucketName,
		presignClient: mockPresign,
	}
	url, err := bucket.PresignGet(context.Background(), testObjectKey, time.Minute)
	assert.NoError(t, err)
	assert.Equal(t, "https://example.com/get", url)
}

func TestPresignPut(t *testing.T) {
	mockPresign := &mockPresignClient{
		presignPutFunc: func(ctx context.Context, params *s3.PutObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error) {
			return &v4.PresignedHTTPRequest{URL: "https://example.com/put"}, nil
		},
	}
	bucket := &S3BucketHandle{
		bucketName:    testBucketName,
		presignClient: mockPresign,
	}
	url, err := bucket.PresignPut(context.Background(), testObjectKey, time.Minute)
	assert.NoError(t, err)
	assert.Equal(t, "https://example.com/put", url)
}

func TestNewReaderSuccess(t *testing.T) {
	mockBody := io.NopCloser(bytes.NewBufferString("hello world"))
	mockClient := &mockS3Client{
		getObjectFunc: func(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.Options)) (*s3.GetObjectOutput, error) {
			return &s3.GetObjectOutput{Body: mockBody}, nil
		},
	}
	obj := &S3ObjectHandle{
		client: mockClient,
		bucket: testBucketName,
		name:   testObjectKey,
	}
	r, err := obj.NewReader(context.Background())
	assert.NoError(t, err)
	b, err := io.ReadAll(r)
	assert.NoError(t, err)
	assert.Equal(t, []byte("hello world"), b)
}

func TestNewReaderError(t *testing.T) {
	mockClient := &mockS3Client{
		getObjectFunc: func(ctx context.Context, params *s3.GetObjectInput, optFns ...func(*s3.Options)) (*s3.GetObjectOutput, error) {
			return nil, errors.New("get error")
		},
	}
	obj := &S3ObjectHandle{
		client: mockClient,
		bucket: testBucketName,
		name:   testObjectKey,
	}
	r, err := obj.NewReader(context.Background())
	assert.Nil(t, r)
	assert.EqualError(t, err, "get error")
}

func TestObject(t *testing.T) {
	bucket := &S3BucketHandle{
		bucketName: "bucket",
		client:     &mockS3Client{},
	}
	obj := bucket.Object("key")
	assert.NotNil(t, obj)
	assert.Equal(t, "key", obj.(*S3ObjectHandle).name)
}

func TestBucket(t *testing.T) {
	s3Client := &S3{
		client:        &mockS3Client{},
		presignClient: &mockPresignClient{},
		config:        &s3Config{},
	}
	bucket := s3Client.Bucket("bucket")
	assert.NotNil(t, bucket)
	assert.Equal(t, "bucket", bucket.(*S3BucketHandle).bucketName)
}
