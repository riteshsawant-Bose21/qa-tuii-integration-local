package cloudfs

import (
	"context"
	"io"
	"time"
)

// define interface for cloud storages

// Store is a client to access a cloud file storage.
type Store interface {
	Bucket(name string) BucketHandle
}

type PresignHandle interface {
	PresignGet(ctx context.Context, objectKey string, ttl time.Duration) (string, error)
	PresignPut(ctx context.Context, objectKey string, ttl time.Duration) (string, error)
}

// BucketHandle provides methods to operate on a bucket in the cloud file storage.
type BucketHandle interface {
	Upload(ctx context.Context, name string, content io.Reader, contentType *string) error
	Object(name string) ObjectHandle
	PresignHandle
}

// ObjectReader provides streaming read-only access to an object.
type ObjectReader interface {
	NewReader(ctx context.Context) (io.ReadCloser, error)
}

// ObjectHandle composes reading and presigning. Consumers can depend on the
// smaller interfaces (ObjectReader or ObjectPresigner) if they don't need both.
type ObjectHandle interface {
	NewReader(ctx context.Context) (io.ReadCloser, error)
}
