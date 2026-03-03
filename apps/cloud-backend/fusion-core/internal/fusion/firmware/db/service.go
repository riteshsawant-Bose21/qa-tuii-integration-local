package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	types "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"

	"github.com/aarondl/null/v8"

	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	"go.uber.org/zap"
)

type Service struct {
	db customModel.DBWithTransactions
}

// NewService creates a new database service.
func NewService(db customModel.DBWithTransactions) *Service {
	if db == nil {
		panic("db cannot be nil")
	}

	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

// GetDB returns the database instance for transaction management.
func (s *Service) GetDB(_ context.Context) customModel.DBWithTransactions {
	return s.db
}

func (s *Service) GetReleaseByPlatformAndVersion(ctx context.Context, platform string, version string) (*model.FirmwareRelease, error) {
	if platform == "" || version == "" {
		return nil, errors.New("platform and version cannot be empty")
	}

	release, err := model.FirmwareReleases(
		qm.Where("platform = ?", platform),
		qm.Where("version = ?", version),
		qm.Limit(1),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return release, nil
}

func (s *Service) CheckIfNewerVersionExists(ctx context.Context, platform string, version string) (bool, error) {
	if platform == "" || version == "" {
		return false, errors.New("platform and version cannot be empty")
	}

	exists, err := model.FirmwareReleases(
		qm.Where("platform = ?", platform),
		qm.Where("version_parts > string_to_array(?, '.')::int[]", version),
	).Exists(ctx, s.db)

	if err != nil {
		return false, err
	}

	return exists, nil
}

func (s *Service) InsertRelease(ctx context.Context, releaseDetails types.FirmwareReleaseMetaData, checksum string, filePath string, dbTx customModel.DBContextExecutor, logger *zap.Logger) (string, error) {
	firmwareReleaseRecord := &model.FirmwareRelease{
		Platform:             releaseDetails.Platform,
		Version:              releaseDetails.FirmwareVersion,
		ReleaseNotes:         releaseDetails.ReleaseNotes,
		MinDesktopAppVersion: releaseDetails.MinDesktopAppVersion,
		HWCompatibility:      releaseDetails.HwCompatibility,
		APILevel:             releaseDetails.ApiVersion,
		S3Key:                filePath,
		FileChecksum:         checksum,
	}

	if err := firmwareReleaseRecord.Insert(ctx, dbTx, boil.Infer()); err != nil {
		logger.Error("Error inserting firmware release",
			zap.Error(err),
			zap.String("platform", releaseDetails.Platform),
			zap.String("version", releaseDetails.FirmwareVersion))
		return "", err
	}

	return firmwareReleaseRecord.ID, nil
}

func (s *Service) InsertDeployment(ctx context.Context, releaseID string, dbTx customModel.DBContextExecutor, channel string, logger *zap.Logger) (string, error) {
	deployRecord := &model.FirmwareDeployment{
		ReleaseID: releaseID,
		Channel:   channel,
	}

	if err := deployRecord.Insert(ctx, dbTx, boil.Infer()); err != nil {
		logger.Error("Error inserting deployment data",
			zap.Error(err),
			zap.String("release_id", releaseID),
			zap.String("channel", channel))
		return "", err
	}

	return deployRecord.ID, nil
}

func (s *Service) GetReleaseByID(ctx context.Context, releaseID string) (*model.FirmwareRelease, error) {
	if releaseID == "" {
		return nil, errors.New("releaseID cannot be empty")
	}

	release, err := model.FindFirmwareRelease(ctx, s.db, releaseID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // Return nil if not found, let caller handle
		}
		return nil, err
	}

	return release, nil
}

func (s *Service) UpdateReleaseStatus(ctx context.Context, releaseID string, status string, tx customModel.DBContextExecutor) error {
	if releaseID == "" || status == "" {
		return errors.New("releaseID and status cannot be empty")
	}

	release := &model.FirmwareRelease{
		ID:        releaseID,
		Status:    status,
		UpdatedAt: time.Now(),
	}

	_, err := release.Update(ctx, tx, boil.Whitelist(model.FirmwareReleaseColumns.Status, model.FirmwareReleaseColumns.UpdatedAt))
	return err
}

func (s *Service) ListReleases(ctx context.Context, limit, offset int, platform string, minVersion string) ([]*model.FirmwareRelease, int64, error) {
	var mods []qm.QueryMod

	if platform != "" {
		mods = append(mods, qm.Where("platform = ?", platform))
	}

	if minVersion != "" {
		mods = append(mods, qm.Where("version_parts > string_to_array(?, '.')::int[]", minVersion))
	}

	total, err := model.FirmwareReleases(mods...).Count(ctx, s.db)
	if err != nil {
		return nil, 0, err
	}

	mods = append(mods, qm.Limit(limit), qm.Offset(offset), qm.OrderBy("version_parts DESC"))

	releases, err := model.FirmwareReleases(mods...).All(ctx, s.db)
	if err != nil {
		return nil, 0, err
	}

	return releases, total, nil
}

// LogFirmwareUpdate inserts a firmware update log entry
func (s *Service) LogFirmwareUpdate(ctx context.Context, deviceID, releaseVersion, status string, eventTime time.Time) error {
	log := &model.FirmwareUpdateLog{
		DeviceID:       deviceID,
		ReleaseVersion: releaseVersion,
		Status:         status,
		EventTime:      eventTime,
	}

	err := log.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to insert firmware update log: %w", err)
	}

	return nil
}

func (s *Service) GetLatestReleaseNewerThan(ctx context.Context, platformName, channelName, currentVersion string) (*model.FirmwareRelease, error) {
	if platformName == "" || channelName == "" || currentVersion == "" {
		return nil, errors.New("platform, channel, and currentVersion cannot be empty")
	}

	release, err := model.FirmwareReleases(
		qm.InnerJoin("firmware_deployments on firmware_deployments.release_id = firmware_releases.id"),
		qm.Where("firmware_releases.platform = ?", platformName),
		qm.Where("firmware_deployments.channel = ?", channelName),
		qm.Where("firmware_releases.version_parts > string_to_array(?, '.')::int[]", currentVersion),
		qm.OrderBy("firmware_releases.version_parts DESC"),
		qm.Limit(1),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // Return nil if no newer release found
		}
		return nil, err
	}

	return release, nil
}

func (s *Service) GetReleaseByPlatformVersion(ctx context.Context, platform string, version string) (*model.FirmwareRelease, error) {
	release, err := model.FirmwareReleases(
		model.FirmwareReleaseWhere.Platform.EQ(platform),
		model.FirmwareReleaseWhere.Version.EQ(version),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get release: %w", err)
	}

	return release, nil
}

func (s *Service) GetBundleByVersion(ctx context.Context, version string) (*model.Bundle, error) {
	if version == "" {
		return nil, errors.New("version cannot be empty")
	}

	bundle, err := model.Bundles(
		model.BundleWhere.Version.EQ(version),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get bundle: %w", err)
	}

	return bundle, nil
}

func (s *Service) ListBundles(ctx context.Context, isApproved *bool, limit, offset int) ([]*model.Bundle, int64, error) {
	var mods []qm.QueryMod

	if isApproved != nil {
		mods = append(mods, model.BundleWhere.IsApproved.EQ(*isApproved))
	}

	total, err := model.Bundles(mods...).Count(ctx, s.db)
	if err != nil {
		return nil, 0, err
	}

	mods = append(mods,
		qm.Limit(limit),
		qm.Offset(offset),
		qm.OrderBy(model.BundleColumns.CreatedAt+" DESC"),
	)

	bundles, err := model.Bundles(mods...).All(ctx, s.db)
	if err != nil {
		return nil, 0, err
	}

	return bundles, total, nil
}

func (s *Service) GetLatestCompatibleBundle(ctx context.Context, currentFirmwareVersion string, currentDesktopAppVersion string) (*model.Bundle, error) {
	bundle, err := model.Bundles(
		model.BundleWhere.IsApproved.EQ(true),
		qm.Where("version_parts > string_to_array(?, '.')::int[]", currentFirmwareVersion),
		qm.Where("min_desktop_app_version_parts <= string_to_array(?, '.')::int[]", currentDesktopAppVersion),
		qm.OrderBy("version_parts DESC"),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // No compatible bundle found
		}
		return nil, fmt.Errorf("failed to get latest compatible bundle: %w", err)
	}

	return bundle, nil
}

func (s *Service) GetLatestBundleCompatibleWithFirmware(ctx context.Context, currentFirmwareVersion string) (*model.Bundle, error) {
	bundle, err := model.Bundles(
		model.BundleWhere.IsApproved.EQ(true),
		qm.Where("version_parts > string_to_array(?, '.')::int[]", currentFirmwareVersion),
		qm.Where("min_prev_version_parts <= string_to_array(?, '.')::int[]", currentFirmwareVersion),
		qm.OrderBy("version_parts DESC"),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // No compatible bundle found
		}
		return nil, fmt.Errorf("failed to get latest bundle compatible with firmware: %w", err)
	}

	return bundle, nil
}

func (s *Service) GetLatestApprovedBundleNewerThan(ctx context.Context, currentFirmwareVersion string) (*model.Bundle, error) {
	bundle, err := model.Bundles(
		model.BundleWhere.IsApproved.EQ(true),
		qm.Where("version_parts > string_to_array(?, '.')::int[]", currentFirmwareVersion),
		qm.OrderBy("version_parts DESC"),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // No bundle found
		}
		return nil, fmt.Errorf("failed to get latest bundle: %w", err)
	}

	return bundle, nil
}

func (s *Service) InsertBundle(ctx context.Context, payload types.NotifyBundleUploadPayload, logger *zap.Logger) (string, error) {

	// Convert manifest data to proper JSON for sqlboiler type
	manifestBytes, err := json.Marshal(payload.ManifestData)
	if err != nil {
		logger.Error("Failed to marshal manifest data", zap.Error(err))
		return "", fmt.Errorf("failed to marshal manifest: %w", err)
	}

	bundleRecord := &model.Bundle{
		Version:              payload.Version,
		Checksum:             payload.Checksum,
		MinPrevVersion:       payload.MinPrevVersion,
		MinDesktopAppVersion: payload.MinDesktopAppVersion,
		ManifestData:         manifestBytes,
		IsApproved:           false,
	}

	if payload.ReleaseNotes != "" {
		bundleRecord.ReleaseNotes = null.StringFrom(payload.ReleaseNotes)
	}

	if err := bundleRecord.Insert(ctx, s.db, boil.Infer()); err != nil {
		logger.Error("Error inserting firmware bundle",
			zap.Error(err),
			zap.String("version", payload.Version))
		return "", err
	}

	return bundleRecord.ID, nil
}

func (s *Service) ApproveBundle(ctx context.Context, bundleID string, approvedBy string) error {
	if bundleID == "" {
		return errors.New("bundleID cannot be empty")
	}
	if approvedBy == "" {
		return errors.New("approvedBy cannot be empty")
	}

	bundle := &model.Bundle{
		ID:         bundleID,
		IsApproved: true,
		ApprovedBy: null.StringFrom(approvedBy),
		ApprovedAt: null.TimeFrom(time.Now()),
	}

	_, err := bundle.Update(ctx, s.db, boil.Whitelist(model.BundleColumns.IsApproved, model.BundleColumns.ApprovedBy, model.BundleColumns.ApprovedAt))
	return err
}

func (s *Service) GetBundleByID(ctx context.Context, bundleID string) (*model.Bundle, error) {
	if bundleID == "" {
		return nil, errors.New("bundleID cannot be empty")
	}

	bundle, err := model.Bundles(
		model.BundleWhere.ID.EQ(bundleID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get bundle: %w", err)
	}

	return bundle, nil
}
