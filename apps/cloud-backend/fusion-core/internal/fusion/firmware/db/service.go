package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/aarondl/null/v8"
	"github.com/google/uuid"

	apiTypes "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/validation"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	"github.com/aarondl/sqlboiler/v4/types"
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

func (s *Service) GetBundleByVersion(ctx context.Context, version string) (*models.Bundle, error) {
	bundle, err := models.Bundles(
		models.BundleWhere.Version.EQ(version),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // No bundle found
		}
		return nil, fmt.Errorf("failed to get bundle by version: %w", err)
	}

	return bundle, nil
}

func (s *Service) InsertBundle(ctx context.Context, payload apiTypes.NotifyBundleUploadPayload, logger *zap.Logger) (string, error) {

	// Convert manifest data to proper JSON for sqlboiler type
	manifestBytes, err := json.Marshal(payload.ManifestData)
	if err != nil {
		logger.Error("Failed to marshal manifest data", zap.Error(err))
		return "", fmt.Errorf("failed to marshal manifest: %w", err)
	}

	// Parse version to extract prerelease information
	parsedVersion, err := validation.ParseSemanticVersion(payload.Version)
	if err != nil {
		logger.Error("Failed to parse bundle version", zap.Error(err), zap.String("version", payload.Version))
		return "", fmt.Errorf("failed to parse version: %w", err)
	}

	bundleRecord := &models.Bundle{
		Version:              payload.Version,
		Checksum:             payload.Checksum,
		S3Path:               payload.S3Path,
		MinPrevVersion:       payload.MinPrevVersion,
		MinDesktopAppVersion: payload.MinDesktopAppVersion,
		ManifestData:         null.JSONFrom(manifestBytes),
		ApprovalStatus:       models.BundleApprovalStatusEnumPENDING,
	}

	// Set prerelease fields if present
	if parsedVersion.Prerelease != "" {
		if parsedVersion.PrereleaseTag != "" {
			bundleRecord.PrereleaseTag = null.StringFrom(parsedVersion.PrereleaseTag)
		}
		if parsedVersion.PrereleaseNum >= 0 {
			bundleRecord.PrereleaseNum = null.IntFrom(parsedVersion.PrereleaseNum)
		}
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

func (s *Service) ApproveBundle(ctx context.Context, bundleID string, approvedBy string, approvalStatus string) error {
	if bundleID == "" {
		return errors.New("bundleID cannot be empty")
	}
	if approvedBy == "" {
		return errors.New("approvedBy cannot be empty")
	}

	bundle := &models.Bundle{
		ID:                      bundleID,
		ApprovalStatus:          approvalStatus,
		ApprovalStatusChangedBy: null.StringFrom(approvedBy),
		ApprovalStatusChangedAt: null.TimeFrom(time.Now()),
	}

	_, err := bundle.Update(ctx, s.db, boil.Whitelist(models.BundleColumns.ApprovalStatus, models.BundleColumns.ApprovalStatusChangedBy, models.BundleColumns.ApprovalStatusChangedAt))
	return err
}

func (s *Service) GetBundleByID(ctx context.Context, bundleID string) (*models.Bundle, error) {
	if bundleID == "" {
		return nil, errors.New("bundleID cannot be empty")
	}

	bundle, err := models.Bundles(
		models.BundleWhere.ID.EQ(bundleID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get bundle: %w", err)
	}

	return bundle, nil
}

func (s *Service) GetLatestBundleCompatibleWithFirmware(ctx context.Context, currentFirmwareVersion string, channel string) (*models.Bundle, error) {
	parsedFirmware, err := s.toVersionArray(currentFirmwareVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to parse current firmware version: %w", err)
	}

	queryMods := []qm.QueryMod{
		models.BundleWhere.ApprovalStatus.EQ(models.BundleApprovalStatusEnumAPPROVED),
		models.BundleWhere.VersionArray.GT(parsedFirmware),
		qm.Expr(
			models.BundleWhere.MinPrevVersion.EQ("0.0.0"),
			qm.Or2(models.BundleWhere.MinPrevVersionArray.LTE(parsedFirmware)),
		),
		qm.OrderBy("version_array DESC, prerelease_num DESC NULLS LAST"),
	}

	// Filter by channel: empty string means stable (prerelease_tag IS NULL)
	if channel == "" {
		queryMods = append(queryMods, qm.Where("prerelease_tag IS NULL"))
	} else {
		queryMods = append(queryMods, qm.Where("prerelease_tag = ?", channel))
	}

	bundle, err := models.Bundles(queryMods...).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // No compatible bundle found
		}
		return nil, fmt.Errorf("failed to get latest bundle compatible with firmware: %w", err)
	}

	return bundle, nil
}

func (s *Service) GetLatestCompatibleBundle(ctx context.Context, currentFirmwareVersion string, currentDesktopAppVersion string, channel string) (*models.Bundle, error) {
	parsedCurrentFirmwareVersion, err := s.toVersionArray(currentFirmwareVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to parse current firmware version: %w", err)
	}

	parsedCurrentDesktopAppVersion, err := s.toVersionArray(currentDesktopAppVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to parse current desktop app version: %w", err)
	}

	queryMods := []qm.QueryMod{
		models.BundleWhere.ApprovalStatus.EQ(models.BundleApprovalStatusEnumAPPROVED),
		models.BundleWhere.VersionArray.GT(parsedCurrentFirmwareVersion),
		qm.Expr(
			models.BundleWhere.MinPrevVersion.EQ("0.0.0"),
			qm.Or2(models.BundleWhere.MinPrevVersionArray.LTE(parsedCurrentFirmwareVersion)),
		),
		qm.Expr(
			models.BundleWhere.MinDesktopAppVersion.EQ("0.0.0"),
			qm.Or2(models.BundleWhere.MinDesktopAppVersionArray.LTE(parsedCurrentDesktopAppVersion)),
		),
		qm.OrderBy("version_array DESC, prerelease_num DESC NULLS LAST"),
	}

	// Filter by channel: empty string means stable (prerelease_tag IS NULL)
	if channel == "" {
		queryMods = append(queryMods, qm.Where("prerelease_tag IS NULL"))
	} else {
		queryMods = append(queryMods, qm.Where("prerelease_tag = ?", channel))
	}

	bundle, err := models.Bundles(queryMods...).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // No compatible bundle found
		}
		return nil, fmt.Errorf("failed to get latest compatible bundle: %w", err)
	}

	return bundle, nil
}

func (s *Service) InsertBundleUpdateStatus(ctx context.Context, payload *apiTypes.LogBundleUpdateStatusPayload) error {
	status := &models.BundleUpdateStatus{
		ID:                    uuid.New().String(),
		UpdateID:              payload.UpdateID,
		ProjectID:             payload.ProjectID,
		BundleVersion:         payload.BundleVersion,
		PreviousBundleVersion: null.NewString(payload.PreviousBundleVersion, payload.PreviousBundleVersion != ""),
		Status:                payload.Status,
		DesktopAppVersion:     null.NewString(payload.DesktopAppVersion, payload.DesktopAppVersion != ""),
		InstalledAt:           payload.InstalledAt,
	}

	return status.Insert(ctx, s.db, boil.Infer())
}

func (s *Service) ListBundles(ctx context.Context, approvalStatus *string, limit, offset int) ([]*models.Bundle, int, error) {
	var queryMods []qm.QueryMod

	if approvalStatus != nil {
		queryMods = append(queryMods, models.BundleWhere.ApprovalStatus.EQ(*approvalStatus))
	}

	// Get total count
	totalCount, err := models.Bundles(queryMods...).Count(ctx, s.db)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count bundles: %w", err)
	}

	// Add pagination and ordering
	queryMods = append(queryMods,
		qm.OrderBy("created_at DESC"),
		qm.Limit(limit),
		qm.Offset(offset),
	)

	bundles, err := models.Bundles(queryMods...).All(ctx, s.db)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list bundles: %w", err)
	}

	return bundles, int(totalCount), nil
}

func (s *Service) toVersionArray(version string) (types.Int64Array, error) {
	parsed, err := validation.ParseSemanticVersion(version)
	if err != nil {
		return nil, err
	}
	return types.Int64Array{int64(parsed.Major), int64(parsed.Minor), int64(parsed.Patch)}, nil
}
