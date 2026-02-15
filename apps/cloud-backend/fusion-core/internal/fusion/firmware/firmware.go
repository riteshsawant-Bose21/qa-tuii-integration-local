package firmware

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/validation"
	"go.uber.org/zap"
)

const (
	firmwareArtifactPathFormat = "%s/%s/%s.zip"
)

// generateProjectFileURL generates a presigned URL for firmware update file operations
func (s *Service) generateFirmwareArtifactURL(ctx context.Context, platform string, version string, fileName string, ttl time.Duration, operation string, logger *zap.Logger) (string, error) {
	// If no presigner is configured (e.g., in tests), return empty string
	if s.presigner == nil {
		return "", nil
	}

	key := fmt.Sprintf(firmwareArtifactPathFormat, platform, version, fileName)

	switch operation {
	case "get":
		return s.presigner.PresignGet(ctx, key, ttl, logger)
	case "put":
		return s.presigner.PresignPut(ctx, key, ttl, logger)
	default:
		return "", fmt.Errorf("unsupported operation: %s", operation)
	}
}

func (s *Service) InitiateRelease(ctx context.Context, releaseDetails *types.InitiateFirmwareReleasePayload, logger *zap.Logger) (releaseID string, presignURL string, err error) {
	if s.presigner == nil {
		return "", "", nil
	}

	// Validate version format MAJOR.MINOR.PATCH
	err = validation.ValidateFirmwareVersionFormat(releaseDetails.MetaData.FirmwareVersion)
	if err != nil {
		return "", "", fmt.Errorf("failed to validate firmware version format: %v", err)
	}

	// check if the version already exists for the platform or if a newer version exists
	exists, err := s.dbService.CheckIfNewerVersionExists(ctx, releaseDetails.MetaData.Platform, releaseDetails.MetaData.FirmwareVersion)
	if err != nil {
		return "", "", fmt.Errorf("failed to check firmware versions: %v", err)
	}
	if exists {
		return "", "", errors.New("a newer or equal version already exists for this platform")
	}

	presignURL, err = s.generateFirmwareArtifactURL(ctx, releaseDetails.MetaData.Platform, releaseDetails.MetaData.FirmwareVersion, "firmware", time.Minute*15, "put", logger)
	if err != nil {
		return "", "", fmt.Errorf("failed to generate presign URL: %v", err)
	}

	// Insert to release table
	ID, err := s.dbService.InsertRelease(ctx, releaseDetails.MetaData, "", fmt.Sprintf(firmwareArtifactPathFormat, releaseDetails.MetaData.Platform, releaseDetails.MetaData.FirmwareVersion, "firmware"), s.dbService.GetDB(ctx), logger)
	if err != nil {
		return "", "", fmt.Errorf("failed to insert firmware release: %v", err)
	}

	return ID, presignURL, nil
}

func (s *Service) MakeReleaseAvailable(ctx context.Context, releaseID string, logger *zap.Logger) error {
	// Check if release exists
	release, err := s.dbService.GetReleaseByID(ctx, releaseID)
	if err != nil {
		return fmt.Errorf("failed to get release: %v", err)
	}
	if release == nil {
		return errors.New("release not found")
	}

	// Start transaction
	db := s.dbService.GetDB(ctx)
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %v", err)
	}

	// Update status to AVAILABLE
	err = s.dbService.UpdateReleaseStatus(ctx, releaseID, "AVAILABLE", tx)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update release status: %v", err)
	}

	// Insert into deployments
	_, err = s.dbService.InsertDeployment(ctx, releaseID, tx, "dev", logger)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to insert deployment: %v", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %v", err)
	}

	return nil
}
