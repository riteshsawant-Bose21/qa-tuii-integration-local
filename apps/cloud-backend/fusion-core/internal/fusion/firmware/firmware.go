package firmware

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/validation"
	"go.uber.org/zap"
)

const (
	firmwareArtifactPathFormat = "%s/%s/%s.zip"

	// Deployment channels
	// TODO : create channel table to handle different channels
	ChannelDev     = "dev"
	ChannelTesting = "testing"
	ChannelStable  = "stable"
)

// DefaultChannel returns the default deployment channel
func DefaultChannel() string {
	return ChannelDev
}

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

	// Validate version format MAJOR.MINOR.PATCH+prerelease_tag.prerelease_version
	err = validation.ValidateFirmwareVersionFormat(releaseDetails.MetaData.FirmwareVersion)
	if err != nil {
		return "", "", fmt.Errorf("failed to validate firmware version format: %v", err)
	}

	// Check if a newer version already exists - prevent creating older versions
	newerExists, err := s.dbService.CheckIfNewerVersionExists(ctx, releaseDetails.MetaData.Platform, releaseDetails.MetaData.FirmwareVersion)
	if err != nil {
		return "", "", fmt.Errorf("failed to check for newer versions: %w", err)
	}
	if newerExists {
		return "", "", errorutil.ErrVersionExists
	}

	// Check if the version already exists
	existingRelease, err := s.dbService.GetReleaseByPlatformVersion(ctx, releaseDetails.MetaData.Platform, releaseDetails.MetaData.FirmwareVersion)
	if err != nil {
		return "", "", fmt.Errorf("failed to check existing version: %w", err)
	}

	// If version exists and is not PENDING_UPLOAD, return error
	if existingRelease != nil && existingRelease.Status != "PENDING_UPLOAD" {
		return "", "", errorutil.ErrVersionExists
	}

	// Generate presigned URL (for both re-upload and new release)
	presignURL, err = s.generateFirmwareArtifactURL(ctx, releaseDetails.MetaData.Platform, releaseDetails.MetaData.FirmwareVersion, "firmware", time.Minute*15, "put", logger)
	if err != nil {
		return "", "", fmt.Errorf("failed to generate presign URL: %w", err)
	}

	// If version exists with PENDING_UPLOAD, return existing releaseID with new presigned URL
	if existingRelease != nil && existingRelease.Status == "PENDING_UPLOAD" {
		return existingRelease.ID, presignURL, nil
	}

	// Version doesn't exist, create new release
	// Insert to release table
	ID, err := s.dbService.InsertRelease(ctx, releaseDetails.MetaData, "", fmt.Sprintf(firmwareArtifactPathFormat, releaseDetails.MetaData.Platform, releaseDetails.MetaData.FirmwareVersion, "firmware"), s.dbService.GetDB(ctx), logger)
	if err != nil {
		return "", "", fmt.Errorf("failed to insert firmware release: %v", err)
	}

	return ID, presignURL, nil
}

func (s *Service) NotifyBundleUpload(ctx context.Context, payload *types.NotifyBundleUploadPayload, logger *zap.Logger) (*types.BundleResponse, error) {
	// Validate version format MAJOR.MINOR.PATCH+prerelease_tag.prerelease_version
	err := validation.ValidateFirmwareVersionFormat(payload.Version)
	if err != nil {
		return nil, fmt.Errorf("failed to validate bundle version format: %v", err)
	}

	// Check if the specific bundle version already exists
	existingBundle, err := s.dbService.GetBundleByVersion(ctx, payload.Version)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing bundle version: %w", err)
	}

	if existingBundle != nil {
		return nil, errorutil.ErrVersionExists
	}

	// Insert into bundle table
	ID, err := s.dbService.InsertBundle(ctx, *payload, s.dbService.GetDB(ctx), logger)
	if err != nil {
		return nil, fmt.Errorf("failed to insert firmware bundle: %v", err)
	}

	return &types.BundleResponse{
		ID: ID,
	}, nil
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
	// Currently I am Deploying the release to the "dev" channel directly in the release step itself
	// TODO : remove this once the deployment flow is finalized
	_, err = s.dbService.InsertDeployment(ctx, releaseID, tx, DefaultChannel(), logger)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to insert deployment: %v", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %v", err)
	}

	return nil
}

func (s *Service) CheckForUpdates(ctx context.Context, request *types.CheckUpdateRequest) (*types.CheckUpdateResponse, error) {
	results := make(map[string]types.DeviceUpdateResult)

	for _, device := range request.Devices {
		// Skip if platform or current version is missing
		if device.Platform == "" || device.CurrentFirmwareVersion == "" {
			results[device.DeviceID] = types.DeviceUpdateResult{
				UpdateAvailable: false,
			}
			continue
		}

		// Query DB for latest release newer than current version
		newerRelease, err := s.dbService.GetLatestReleaseNewerThan(ctx, device.Platform, request.Channel, device.CurrentFirmwareVersion)
		if err != nil {
			// Log error but continue for other devices in batch operation
			continue
		}

		// If no newer release found, no update available
		if newerRelease == nil {
			results[device.DeviceID] = types.DeviceUpdateResult{
				UpdateAvailable: false,
			}
			continue
		}

		// Newer release found
		results[device.DeviceID] = types.DeviceUpdateResult{
			UpdateAvailable: true,
			LatestVersion:   newerRelease.Version,
			ReleaseNotes:    newerRelease.ReleaseNotes,
		}
	}

	return &types.CheckUpdateResponse{Results: results}, nil
}

func (s *Service) GetArtifactDownloadURL(ctx context.Context, platform, version string, logger *zap.Logger) (*types.DownloadArtifactResponse, error) {
	// Get release by platform and version
	release, err := s.dbService.GetReleaseByPlatformAndVersion(ctx, platform, version)
	if err != nil {
		return nil, fmt.Errorf("failed to get release: %w", err)
	}
	if release == nil {
		return nil, errorutil.ErrReleaseNotFound
	}

	// Generate presigned GET URL
	downloadURL, err := s.generateFirmwareArtifactURL(ctx, platform, version, "firmware", time.Minute*15, "get", logger)
	if err != nil {
		return nil, fmt.Errorf("failed to generate download URL: %v", err)
	}

	return &types.DownloadArtifactResponse{
		DownloadURL: downloadURL,
		Checksum:    release.FileChecksum,
	}, nil
}

func (s *Service) ListReleases(ctx context.Context, platform string, page, limit int, minVersion string) (*types.FirmwareReleaseListResponse, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	offset := (page - 1) * limit

	releases, total, err := s.dbService.ListReleases(ctx, limit, offset, platform, minVersion)
	if err != nil {
		return nil, err
	}

	var releaseDetails []types.FirmwareReleaseDetails
	for _, r := range releases {
		releaseDetails = append(releaseDetails, types.FirmwareReleaseDetails{
			ID:                   r.ID,
			Platform:             r.Platform,
			FirmwareVersion:      r.Version,
			Status:               r.Status,
			ReleaseNotes:         r.ReleaseNotes,
			MinDesktopAppVersion: r.MinDesktopAppVersion,
			HwCompatibility:      r.HWCompatibility,
			ApiVersion:           r.APILevel,
			Created:              r.CreatedAt,
			Updated:              r.UpdatedAt,
		})
	}

	return &types.FirmwareReleaseListResponse{
		Releases: releaseDetails,
		Total:    total,
		Page:     page,
		Limit:    limit,
	}, nil
}

func (s *Service) LogFirmwareUpdate(ctx context.Context, req *types.LogFirmwareUpdateRequest) error {
	return s.dbService.LogFirmwareUpdate(ctx, req.DeviceID, req.ReleaseVersion, req.Status, req.EventTime)
}

func (s *Service) DeployRelease(ctx context.Context, releaseID string, channel string, logger *zap.Logger) error {
	// Validate channel
	// TODO : create channel table to handle different channels
	if channel != ChannelDev && channel != ChannelTesting && channel != ChannelStable {
		return errorutil.ErrInvalidChannel
	}

	// Check if release exists
	release, err := s.dbService.GetReleaseByID(ctx, releaseID)
	if err != nil {
		return fmt.Errorf("failed to get release: %v", err)
	}
	if release == nil {
		return errorutil.ErrReleaseNotFound
	}

	// Only AVAILABLE releases can be deployed
	if release.Status != "AVAILABLE" {
		return errorutil.ErrInvalidReleaseStatus
	}

	// Insert into deployments
	_, err = s.dbService.InsertDeployment(ctx, releaseID, s.dbService.GetDB(ctx), channel, logger)
	if err != nil {
		return fmt.Errorf("failed to insert deployment: %v", err)
	}

	return nil
}
