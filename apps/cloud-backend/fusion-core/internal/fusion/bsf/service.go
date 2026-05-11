package bsf

import (
	"bytes"
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/storage/cloudfs"
	"go.uber.org/zap"
)

// Service implements the fusion.BSF interface.
type Service struct {
	bucket       cloudfs.BucketHandle
	assetBaseURL string
}

// NewService creates a new BSF service.
func NewService(bucket cloudfs.BucketHandle, assetBaseURL string) *Service {
	if bucket == nil {
		panic("bucket cannot be nil")
	}
	if assetBaseURL == "" {
		panic("assetBaseURL cannot be empty")
	}
	return &Service{
		bucket:       bucket,
		assetBaseURL: strings.TrimRight(assetBaseURL, "/"),
	}
}

// Generate builds a BSF archive and uploads it to S3.
func (s *Service) Generate(ctx context.Context, req *types.BSFGenerateRequest, logger *zap.Logger) (*types.BSFGenerateResponse, error) {
	logger = logger.With(zap.String("service", "bsf"), zap.String("product", req.ProductName))

	builder, err := NewBuilder(req.Category)
	if err != nil {
		logger.Error("Failed to create builder", zap.Error(err))
		return nil, fmt.Errorf("unsupported component category: %s", req.Category)
	}

	bsfBytes, err := builder.Build(req)
	if err != nil {
		logger.Error("Failed to build BSF archive", zap.Error(err))
		return nil, fmt.Errorf("failed to build BSF: %w", err)
	}

	timestamp := time.Now().Format("20060102T150405")
	s3Key := fmt.Sprintf("product/BSF/%s/%s_%s.bsf", req.Family, req.ProductName, timestamp)

	contentType := "application/zip"
	if err := s.bucket.Upload(ctx, s3Key, bytes.NewReader(bsfBytes), &contentType); err != nil {
		logger.Error("Failed to upload BSF to S3", zap.String("s3Key", s3Key), zap.Error(err))
		return nil, fmt.Errorf("failed to upload BSF: %w", err)
	}

	logger.Info("BSF uploaded successfully", zap.String("s3Key", s3Key))

	bsfURL := s.assetBaseURL + "/" + s3Key

	return &types.BSFGenerateResponse{
		BSFURL: bsfURL,
	}, nil
}
