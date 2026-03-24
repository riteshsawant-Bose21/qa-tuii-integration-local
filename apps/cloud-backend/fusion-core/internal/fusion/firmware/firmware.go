package firmware

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/validation"
	"go.uber.org/zap"
)

func (s *Service) NotifyBundleUpload(ctx context.Context, payload *types.NotifyBundleUploadPayload, logger *zap.Logger) (*types.BundleResponse, error) {
	// Check if the specific bundle version already exists
	existingBundle, err := s.dbService.GetBundleByVersion(ctx, payload.Version)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing bundle version: %w", err)
	}

	if existingBundle != nil {
		return nil, errorutil.ErrVersionExists
	}

	// Insert into bundle table
	ID, err := s.dbService.InsertBundle(ctx, *payload, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to insert firmware bundle: %v", err)
	}

	return &types.BundleResponse{
		ID: ID,
	}, nil
}

func (s *Service) ListBundles(ctx context.Context, approvalStatus *string, page, limit int) (*types.BundleListResponse, error) {
	offset := (page - 1) * limit

	bundles, total, err := s.dbService.ListBundles(ctx, approvalStatus, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list bundles: %w", err)
	}

	bundleDetailsList := make([]types.BundleDetails, 0, len(bundles))
	for _, b := range bundles {
		bundleDetailsList = append(bundleDetailsList, types.BundleDetails{
			ID:                   b.ID,
			Version:              b.Version,
			ReleaseNotes:         b.ReleaseNotes.String,
			MinPrevVersion:       b.MinPrevVersion,
			MinDesktopAppVersion: b.MinDesktopAppVersion,
			ApprovalStatus:       b.ApprovalStatus,
			CreatedAt:            b.CreatedAt,
			UpdatedAt:            b.UpdatedAt,
		})
	}

	return &types.BundleListResponse{
		Bundles: bundleDetailsList,
		Total:   total,
		Page:    page,
		Limit:   limit,
	}, nil
}

func (s *Service) ApproveBundle(ctx context.Context, bundleID string, approvedBy string, approvalStatus string, logger *zap.Logger) error {
	// Check if bundle exists
	bundle, err := s.dbService.GetBundleByID(ctx, bundleID)
	if err != nil {
		return fmt.Errorf("failed to get bundle: %v", err)
	}
	if bundle == nil {
		return errorutil.ErrBundleNotFound
	}

	// not allowing to revoke approval if bundle is not approved yet
	if bundle.ApprovalStatus != types.BundleStatusApproved && approvalStatus == types.BundleStatusRevoked {
		return errorutil.ErrBundleNotApproved
	}

	err = s.dbService.ApproveBundle(ctx, bundleID, approvedBy, approvalStatus)
	if err != nil {
		return fmt.Errorf("failed to approve bundle: %v", err)
	}

	return nil
}

func (s *Service) CheckForUpdate(ctx context.Context, req *types.FirmwareUpdateRequest, logger *zap.Logger) (*types.FirmwareUpdateResponse, error) {
	// 1. Find the latest approved bundle compatible with the current desktop app version
	compatibleBundle, err := s.dbService.GetLatestCompatibleBundle(ctx, req.CurrentFirmwareVersion, req.CurrentDesktopAppVersion, req.Channel)
	if err != nil {
		return nil, fmt.Errorf("failed to get latest compatible bundle: %w", err)
	}

	if compatibleBundle != nil {
		// Compatible bundle found - database query already verified all compatibility constraints
		return mapBundleToUpdateResponse(compatibleBundle), nil
	}

	// 2. If no directly compatible bundle is found, or if firmware is too old,
	// check for the latest bundle that is compatible with the current firmware to see if an app update is required.
	latestCompatibleBundle, err := s.dbService.GetLatestBundleCompatibleWithFirmware(ctx, req.CurrentFirmwareVersion, req.Channel)
	if err != nil {
		return nil, fmt.Errorf("failed to get latest bundle compatible with firmware: %w", err)
	}

	if latestCompatibleBundle != nil {
		// A newer bundle exists that is compatible with the current firmware, but it requires a newer app version.
		currentAppSemver, err := validation.ParseSemanticVersion(req.CurrentDesktopAppVersion)
		if err != nil {
			return nil, fmt.Errorf("invalid current desktop app version: %w", err)
		}
		minAppSemver, err := validation.ParseSemanticVersion(latestCompatibleBundle.MinDesktopAppVersion)
		if err != nil {
			return nil, fmt.Errorf("invalid min_desktop_app_version in bundle %s: %w", latestCompatibleBundle.Version, err)
		}

		if !validation.IsVersionGreaterOrEqual(currentAppSemver, minAppSemver) {
			return &types.FirmwareUpdateResponse{
				UpdateAvailable:      true,
				AppUpdateRequired:    true,
				MinDesktopAppVersion: latestCompatibleBundle.MinDesktopAppVersion,
			}, nil
		}

		// If we reach here, the latest bundle compatible with firmware is ALSO compatible with the app.
		// This might happen if there's a minor mismatch between DB and Go version comparison logic.
		return mapBundleToUpdateResponse(latestCompatibleBundle), nil
	}

	// 3. If we reach here, no update is available.
	return &types.FirmwareUpdateResponse{
		UpdateAvailable:   false,
		AppUpdateRequired: false,
	}, nil
}

func mapBundleToUpdateResponse(b *models.Bundle) *types.FirmwareUpdateResponse {
	response := &types.FirmwareUpdateResponse{
		UpdateAvailable:      true,
		AppUpdateRequired:    false,
		BundleID:             b.ID,
		Version:              b.Version,
		MinPrevVersion:       b.MinPrevVersion,
		MinDesktopAppVersion: b.MinDesktopAppVersion,
		CreatedAt:            &b.CreatedAt,
	}

	// Handle nullable fields
	if b.ReleaseNotes.Valid {
		response.ReleaseNotes = b.ReleaseNotes.String
	}
	if b.ManifestData.Valid {
		var manifestData map[string]interface{}
		if err := json.Unmarshal(b.ManifestData.JSON, &manifestData); err == nil {
			response.ManifestData = manifestData
		}
	}

	return response
}

func (s *Service) GetBundleDownloadURL(ctx context.Context, bundleID string, logger *zap.Logger) (*types.DownloadArtifactResponse, error) {
	// Get bundle by ID
	bundle, err := s.dbService.GetBundleByID(ctx, bundleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get bundle: %w", err)
	}
	if bundle == nil {
		return nil, errorutil.ErrBundleNotFound
	}

	if bundle.ApprovalStatus != "APPROVED" {
		return nil, errorutil.ErrBundleNotApprovedForDownload
	}

	if bundle.S3Path == "" {
		return nil, fmt.Errorf("no s3 path found for bundle")
	}

	// Use the artifact path stored in the database
	// Generate presigned GET URL with a n-hour TTL
	downloadURL, err := s.presigner.PresignGet(ctx, bundle.S3Path, constants.S3PresignedUrlTTL, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to generate download URL: %v", err)
	}

	if downloadURL == "" {
		return nil, errorutil.ErrBundleArtifactNotFound
	}

	return &types.DownloadArtifactResponse{
		DownloadURL: downloadURL,
		Checksum:    bundle.Checksum,
	}, nil
}

func (s *Service) InsertBundleUpdateStatus(ctx context.Context, payload *types.LogBundleUpdateStatusPayload, logger *zap.Logger) error {
	return s.dbService.InsertBundleUpdateStatus(ctx, payload)
}
