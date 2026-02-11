package db

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"go.uber.org/zap"
)

// Service is a service for managing projects in the database.
type Service struct {
	db model.DBWithTransactions
}

// NewService creates a new database service.
func NewService(db model.DBWithTransactions) *Service {
	if db == nil {
		panic("db cannot be nil")
	}

	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

func (s *Service) Insert(ctx context.Context, req *types.DeviceCreateRequest, accountID string, logger *zap.Logger) error {

	device := models.Device{
		DeviceSerialNumber: req.DeviceID,
		DeviceModel:        null.NewString(req.DeviceName, req.DeviceName != ""),
		ClaimedBy:          null.NewString(accountID, accountID != ""),
		ClaimStatus:        "CLAIMED",
		ThingName:          null.NewString(req.DeviceID, req.DeviceID != ""),
	}

	err := device.Insert(ctx, s.db, boil.Infer())

	if err != nil {
		logger.Error("Failed to insert device into database", zap.Error(err))
		return err
	}

	return nil
}
