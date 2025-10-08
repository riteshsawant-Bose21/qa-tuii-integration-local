package cloudfs

import (
	"context"
	"io"
)

// define interface for cloud storages

// Store is a client to access a cloud file storage.
type Store interface {
	Bucket(name string) BucketHandle
}

// BucketHandle provides methods to operate on a bucket in the cloud file storage.
type BucketHandle interface {
	Upload(ctx context.Context, name string, content io.Reader, contentType *string) error
	Object(name string) ObjectHandle
	// GetSignedURL(ctx context.Context, name string) (string, error)
}

// ObjectHandle provides methods to operate on an object in a bucket in the cloud file storage.
type ObjectHandle interface {
	// Name() string
	NewReader(ctx context.Context) (io.ReadCloser, error)
}
