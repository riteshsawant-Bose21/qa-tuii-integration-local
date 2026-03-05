package firmware

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/validation"
	"go.uber.org/zap"
)

const (
	firmwareArtifactPathFormat = "%s/%s/%s.zip"

	ChannelStable = "stable"
)

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
	ID, err := s.dbService.InsertBundle(ctx, *payload, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to insert firmware bundle: %v", err)
	}

	return &types.BundleResponse{
		ID: ID,
	}, nil
}

func (s *Service) ListBundles(ctx context.Context, isApproved *bool, page, limit int) (*types.BundleListResponse, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	} else if limit > 100 {
		limit = 100
	}

	offset := (page - 1) * limit

	bundles, total, err := s.dbService.ListBundles(ctx, isApproved, limit, offset)
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
			IsApproved:           b.IsApproved,
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

func (s *Service) ApproveBundle(ctx context.Context, bundleID string, approvedBy string, logger *zap.Logger) error {
	// Check if bundle exists
	bundle, err := s.dbService.GetBundleByID(ctx, bundleID)
	if err != nil {
		return fmt.Errorf("failed to get bundle: %v", err)
	}
	if bundle == nil {
		return errorutil.ErrBundleNotFound
	}

	err = s.dbService.ApproveBundle(ctx, bundleID, approvedBy)
	if err != nil {
		return fmt.Errorf("failed to approve bundle: %v", err)
	}

	return nil
}

func (s *Service) CheckForUpdate(ctx context.Context, req *types.CheckForUpdateRequest, logger *zap.Logger) (*types.CheckForUpdateResponse, error) {
	// 1. Find the latest approved bundle compatible with the current desktop app version
	compatibleBundle, err := s.dbService.GetLatestCompatibleBundle(ctx, req.CurrentFirmwareVersion, req.CurrentDesktopAppVersion, req.Channel)
	if err != nil {
		return nil, fmt.Errorf("failed to get latest compatible bundle: %w", err)
	}

	if compatibleBundle != nil {
		// Compatible bundle found - database query already verified all compatibility constraints
		response := &types.CheckForUpdateResponse{
			UpdateAvailable:      true,
			AppUpdateRequired:    false,
			BundleID:             compatibleBundle.ID,
			Version:              compatibleBundle.Version,
			MinPrevVersion:       compatibleBundle.MinPrevVersion,
			MinDesktopAppVersion: compatibleBundle.MinDesktopAppVersion,
			CreatedAt:            &compatibleBundle.CreatedAt,
		}

		// Handle nullable fields
		if compatibleBundle.ReleaseNotes.Valid {
			response.ReleaseNotes = compatibleBundle.ReleaseNotes.String
		}
		if compatibleBundle.ManifestData.Valid {
			var manifestData map[string]interface{}
			if err := json.Unmarshal(compatibleBundle.ManifestData.JSON, &manifestData); err == nil {
				response.ManifestData = manifestData
			}
		}

		return response, nil
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
			return &types.CheckForUpdateResponse{
				UpdateAvailable:      true,
				AppUpdateRequired:    true,
				MinDesktopAppVersion: latestCompatibleBundle.MinDesktopAppVersion,
			}, nil
		}
	}

	// 3. If we reach here, no update is available.
	return &types.CheckForUpdateResponse{
		UpdateAvailable:   false,
		AppUpdateRequired: false,
	}, nil
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

	// Only approved bundles can be downloaded
	if !bundle.IsApproved {
		return nil, errorutil.ErrBundleNotApproved
	}

	// Generate S3 object key
	objectKey, err := s.generateBundleArtifactKey(bundle.Version)
	if err != nil {
		return nil, fmt.Errorf("failed to generate bundle artifact key: %w", err)
	}

	// Generate presigned GET URL with a 5-hour TTL
	downloadURL, err := s.presigner.PresignGet(ctx, objectKey, 5*time.Hour, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to generate download URL: %v", err)
	}

	return &types.DownloadArtifactResponse{
		DownloadURL: downloadURL,
		Checksum:    bundle.Checksum,
	}, nil
}

func (s *Service) LogBundleUpdateStatus(ctx context.Context, payload *types.LogBundleUpdateStatusPayload, logger *zap.Logger) error {
	return s.dbService.LogBundleUpdateStatus(ctx, payload)
}

// generateBundleArtifactKey constructs the S3 object key for a given bundle version.
// It uses the pre-release tag (e.g., "alpha", "beta") as the channel in the S3 path.
// If no pre-release tag is present, it defaults to the "stable" channel.
func (s *Service) generateBundleArtifactKey(version string) (string, error) {
	parsedVersion, err := validation.ParseSemanticVersion(version)
	if err != nil {
		return "", fmt.Errorf("invalid bundle version for generating key: %w", err)
	}

	channel := ChannelStable
	if parsedVersion.PrereleaseFlag != "" {
		channel = parsedVersion.PrereleaseFlag
	}

	fileName := fmt.Sprintf("fusion-bundle-%s.zip", version)
	return fmt.Sprintf("bundles/%s/%s", channel, fileName), nil
}
