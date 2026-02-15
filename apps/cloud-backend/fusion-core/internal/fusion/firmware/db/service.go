package db

import (
	"context"
	"database/sql"
	"errors"
	"time"

	types "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"

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

func (s *Service) GetReleaseByVersion(ctx context.Context, platform string, version string) (*model.FirmwareRelease, error) {
	if platform == "" || version == "" {
		return nil, errors.New("platform and version cannot be empty")
	}

	row, err := model.FirmwareReleases(
		qm.Where("version_parts = string_to_array(?, '.')::int[]", version),
		qm.OrderBy("version_parts ASC"),
		qm.Limit(1),
	).One(ctx, s.db)

	if err != nil {
		return nil, err
	}

	return row, nil
}

func (s *Service) CheckIfNewerVersionExists(ctx context.Context, platform string, version string) (bool, error) {
	if platform == "" || version == "" {
		return false, errors.New("platform and version cannot be empty")
	}

	exists, err := model.FirmwareReleases(
		qm.Where("platform = ?", platform),
		qm.Where("version_parts >= string_to_array(?, '.')::int[]", version),
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

func (s *Service) ListReleases(ctx context.Context, limit, offset int, platform string) ([]*model.FirmwareRelease, int64, error) {
	var mods []qm.QueryMod

	if platform != "" {
		mods = append(mods, qm.Where("platform = ?", platform))
	}

	total, err := model.FirmwareReleases(mods...).Count(ctx, s.db)
	if err != nil {
		return nil, 0, err
	}

	mods = append(mods, qm.Limit(limit), qm.Offset(offset), qm.OrderBy("created_at DESC"))

	releases, err := model.FirmwareReleases(mods...).All(ctx, s.db)
	if err != nil {
		return nil, 0, err
	}

	return releases, total, nil
}
