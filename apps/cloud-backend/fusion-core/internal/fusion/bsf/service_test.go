package bsf

import (
	"context"
	"errors"
	"io"
	"strings"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/storage/cloudfs"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// ---------------------------------------------------------------------------
// stubBucket — simple test double for cloudfs.BucketHandle
// ---------------------------------------------------------------------------

type stubBucket struct {
	uploadErr           error
	capturedKey         string
	capturedContentType string
}

func (s *stubBucket) Upload(ctx context.Context, name string, content io.Reader, contentType *string) error {
	s.capturedKey = name
	if contentType != nil {
		s.capturedContentType = *contentType
	}
	return s.uploadErr
}

func (s *stubBucket) Object(_ string) cloudfs.ObjectHandle { return nil }
func (s *stubBucket) PresignGet(_ context.Context, _ string, _ time.Duration, _ *zap.Logger) (string, error) {
	return "", nil
}
func (s *stubBucket) PresignPut(_ context.Context, _ string, _ time.Duration, _ *zap.Logger) (string, error) {
	return "", nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func testServiceRequest() *types.BSFGenerateRequest {
	return &types.BSFGenerateRequest{
		ProductName: "DM3SE",
		Family:      "DesignMax",
		Description: "Compact surface-mount speaker",
		SKU:         "841919-0110",
		IsSubwoofer: false,
		Category:    types.ComponentCategorySpeaker,
		SPMData:     []byte("spm measurement data"),
	}
}

// ---------------------------------------------------------------------------
// NewService — constructor validation
// ---------------------------------------------------------------------------

func TestNewService_PanicsOnNilBucket(t *testing.T) {
	assert.Panics(t, func() {
		NewService(nil, "https://example.com")
	})
}

func TestNewService_PanicsOnEmptyBaseURL(t *testing.T) {
	assert.Panics(t, func() {
		NewService(&stubBucket{}, "")
	})
}

func TestNewService_TrimsTrailingSlashFromBaseURL(t *testing.T) {
	svc := NewService(&stubBucket{}, "https://example.com/")
	assert.Equal(t, "https://example.com", svc.assetBaseURL)
}

func TestNewService_MultipleTrailingSlashes_AllTrimmed(t *testing.T) {
	svc := NewService(&stubBucket{}, "https://example.com///")
	assert.Equal(t, "https://example.com", svc.assetBaseURL)
}

func TestNewService_NoTrailingSlash_BaseURLUnchanged(t *testing.T) {
	svc := NewService(&stubBucket{}, "https://example.com")
	assert.Equal(t, "https://example.com", svc.assetBaseURL)
}

// ---------------------------------------------------------------------------
// Generate — error cases
// ---------------------------------------------------------------------------

func TestService_Generate_UnsupportedCategory_ReturnsError(t *testing.T) {
	svc := NewService(&stubBucket{}, "https://example.com")
	req := testServiceRequest()
	req.Category = "slider"

	_, err := svc.Generate(context.Background(), req, zaptest.NewLogger(t))
	require.Error(t, err)
	assert.Contains(t, err.Error(), "unsupported component category")
}

func TestService_Generate_S3UploadError_ReturnsWrappedError(t *testing.T) {
	bucket := &stubBucket{uploadErr: errors.New("S3 unavailable")}
	svc := NewService(bucket, "https://example.com")

	_, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to upload BSF")
}

// ---------------------------------------------------------------------------
// Generate — success
// ---------------------------------------------------------------------------

func TestService_Generate_Success_ReturnsNonNilResponse(t *testing.T) {
	svc := NewService(&stubBucket{}, "https://example.com")

	resp, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)
	require.NotNil(t, resp)
}

func TestService_Generate_Success_ResponseURLNotEmpty(t *testing.T) {
	svc := NewService(&stubBucket{}, "https://example.com")

	resp, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)
	assert.NotEmpty(t, resp.BSFURL)
}

// ---------------------------------------------------------------------------
// Generate — S3 key format
// ---------------------------------------------------------------------------

func TestService_Generate_S3KeyStartsWithProductBSFPath(t *testing.T) {
	bucket := &stubBucket{}
	svc := NewService(bucket, "https://example.com")
	req := testServiceRequest()

	_, err := svc.Generate(context.Background(), req, zaptest.NewLogger(t))
	require.NoError(t, err)

	expectedPrefix := "product/BSF/" + req.Family + "/" + req.ProductName + "_"
	assert.True(t,
		strings.HasPrefix(bucket.capturedKey, expectedPrefix),
		"S3 key %q should start with %q", bucket.capturedKey, expectedPrefix,
	)
}

func TestService_Generate_S3KeyEndsWithBSFExtension(t *testing.T) {
	bucket := &stubBucket{}
	svc := NewService(bucket, "https://example.com")

	_, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)

	assert.True(t, strings.HasSuffix(bucket.capturedKey, ".bsf"),
		"S3 key %q should end with .bsf", bucket.capturedKey)
}

func TestService_Generate_S3KeyContainsFamilyAndProductName(t *testing.T) {
	bucket := &stubBucket{}
	req := testServiceRequest()
	svc := NewService(bucket, "https://example.com")

	_, err := svc.Generate(context.Background(), req, zaptest.NewLogger(t))
	require.NoError(t, err)

	assert.Contains(t, bucket.capturedKey, req.Family)
	assert.Contains(t, bucket.capturedKey, req.ProductName)
}

// ---------------------------------------------------------------------------
// Generate — S3 upload content type
// ---------------------------------------------------------------------------

func TestService_Generate_UploadContentTypeIsApplicationZip(t *testing.T) {
	bucket := &stubBucket{}
	svc := NewService(bucket, "https://example.com")

	_, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)
	assert.Equal(t, "application/zip", bucket.capturedContentType)
}

// ---------------------------------------------------------------------------
// Generate — response URL construction
// ---------------------------------------------------------------------------

func TestService_Generate_ResponseURL_StartsWithBaseURL(t *testing.T) {
	svc := NewService(&stubBucket{}, "https://assets.example.com")

	resp, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)
	assert.True(t,
		strings.HasPrefix(resp.BSFURL, "https://assets.example.com/"),
		"response URL %q should start with the configured base URL", resp.BSFURL,
	)
}

func TestService_Generate_ResponseURL_EndsWithS3Key(t *testing.T) {
	bucket := &stubBucket{}
	svc := NewService(bucket, "https://example.com")

	resp, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)
	assert.True(t,
		strings.HasSuffix(resp.BSFURL, bucket.capturedKey),
		"response URL %q should end with the uploaded S3 key %q", resp.BSFURL, bucket.capturedKey,
	)
}

func TestService_Generate_BaseURLWithTrailingSlash_NoDoubleSlashInURL(t *testing.T) {
	// NewService strips the trailing slash, so the final URL should never have //
	svc := NewService(&stubBucket{}, "https://example.com/")

	resp, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)
	assert.NotContains(t, resp.BSFURL, "//product",
		"URL should not have a double slash before the S3 path segment")
}

func TestService_Generate_ResponseURL_IsBaseURLPlusSlashPlusKey(t *testing.T) {
	bucket := &stubBucket{}
	baseURL := "https://cdn.example.com"
	svc := NewService(bucket, baseURL)

	resp, err := svc.Generate(context.Background(), testServiceRequest(), zaptest.NewLogger(t))
	require.NoError(t, err)
	expected := baseURL + "/" + bucket.capturedKey
	assert.Equal(t, expected, resp.BSFURL)
}
