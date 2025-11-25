package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
	models "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// JobService is a service for managing sync jobs in the database
type JobService struct {
	db     *Database
	logger *zap.Logger
}

// NewJobService creates a new job database service
func NewJobService(db *Database, logger *zap.Logger) *JobService {
	if db == nil {
		panic("db cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	return &JobService{
		db:     db,
		logger: logger,
	}
}

// Create creates a new sync job record
func (s *JobService) Create(syncOperation, sourcePath, s3Bucket, s3Key string) (string, error) {
	jobID := uuid.New().String()

	// Create models.ProductSyncJob using SQLBoiler
	job := &models.ProductSyncJob{
		JobID:           jobID,
		SyncOperation:   syncOperation,
		Status:          "pending",
		S3Bucket:        s3Bucket,
		S3Key:           s3Key,
		TotalItems:      null.NewInt(0, false),
		SuccessfulItems: null.NewInt(0, false),
		FailedItems:     null.NewInt(0, false),
	}

	// Insert the job using SQLBoiler
	err := job.Insert(context.Background(), s.db.DB, boil.Infer())
	if err != nil {
		s.logger.Error("Failed to create sync job",
			zap.String("job_id", jobID),
			zap.String("operation", syncOperation),
			zap.Error(err),
		)
		return "", fmt.Errorf("failed to create sync job: %w", err)
	}

	s.logger.Info("Created sync job",
		zap.String("job_id", jobID),
		zap.String("operation", syncOperation),
		zap.String("source_path", sourcePath),
		zap.String("s3_bucket", s3Bucket),
		zap.String("s3_key", s3Key),
	)

	return jobID, nil
}

// UpdateStatus updates the job status and timestamps
func (s *JobService) UpdateStatus(jobID, status string, startedAt *time.Time, errorMsg *string) error {
	// Find the job first
	job, err := models.ProductSyncJobs(
		qm.Where("job_id = ?", jobID),
	).One(context.Background(), s.db.DB)

	if err != nil {
		s.logger.Error("Failed to find sync job for status update",
			zap.String("job_id", jobID),
			zap.Error(err),
		)
		return fmt.Errorf("failed to find sync job: %w", err)
	}

	// Update status
	job.Status = status

	// Update timestamps based on status
	now := time.Now().UTC()
	switch status {
	case "in_progress":
		if startedAt != nil {
			job.StartedAt = null.TimeFrom(*startedAt)
		} else {
			job.StartedAt = null.TimeFrom(now)
		}
	case "completed", "failed":
		job.CompletedAt = null.TimeFrom(now)
		if errorMsg != nil {
			job.ErrorMessage = null.StringFrom(*errorMsg)
		}
	}

	// Update the job
	_, err = job.Update(context.Background(), s.db.DB, boil.Infer())
	if err != nil {
		s.logger.Error("Failed to update sync job status",
			zap.String("job_id", jobID),
			zap.String("status", status),
			zap.Error(err),
		)
		return fmt.Errorf("failed to update sync job status: %w", err)
	}

	s.logger.Info("Updated sync job status",
		zap.String("job_id", jobID),
		zap.String("status", status),
		zap.Any("started_at", startedAt),
		zap.String("error_message", func() string {
			if errorMsg != nil {
				return *errorMsg
			}
			return ""
		}()),
	)

	return nil
}

// UpdateWithResults updates the job with final results
func (s *JobService) UpdateWithResults(jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error {
	// Find the job first
	job, err := models.ProductSyncJobs(
		qm.Where("job_id = ?", jobID),
	).One(context.Background(), s.db.DB)

	if err != nil {
		s.logger.Error("Failed to find sync job for results update",
			zap.String("job_id", jobID),
			zap.Error(err),
		)
		return fmt.Errorf("failed to find sync job: %w", err)
	}

	// Update all fields
	job.Status = status
	job.TotalItems = null.IntFrom(totalItems)
	job.SuccessfulItems = null.IntFrom(successful)
	job.FailedItems = null.IntFrom(failed)
	job.CompletedAt = null.TimeFrom(time.Now().UTC())

	// Store error message if provided
	if errorMsg != nil {
		job.ErrorMessage = null.StringFrom(*errorMsg)
	}

	// Update the job
	_, err = job.Update(context.Background(), s.db.DB, boil.Infer())
	if err != nil {
		s.logger.Error("Failed to update sync job with results",
			zap.String("job_id", jobID),
			zap.String("status", status),
			zap.Int("total", totalItems),
			zap.Int("successful", successful),
			zap.Int("failed", failed),
			zap.Error(err),
		)
		return fmt.Errorf("failed to update sync job with results: %w", err)
	}

	s.logger.Info("Updated sync job with results",
		zap.String("job_id", jobID),
		zap.String("status", status),
		zap.Int("total_items", totalItems),
		zap.Int("successful", successful),
		zap.Int("failed", failed),
		zap.Int("validation_warnings", len(validationWarnings)),
		zap.String("error_message", func() string {
			if errorMsg != nil {
				return *errorMsg
			}
			return ""
		}()),
	)

	return nil
}

// UpdateStatusAndResults atomically updates job status and results in a single transaction
// This ensures the job record is updated consistently without partial failures
func (s *JobService) UpdateStatusAndResults(
	ctx context.Context,
	jobID, status string,
	totalItems, successful, failed int,
	validationWarnings []string,
	errorMsg *string,
) error {
	return s.db.WithTransaction(ctx, func(tx *sql.Tx) error {
		// Find the job
		job, err := models.ProductSyncJobs(
			qm.Where("job_id = ?", jobID),
		).One(ctx, tx)

		if err != nil {
			s.logger.Error("Failed to find sync job for atomic update",
				zap.String("job_id", jobID),
				zap.Error(err),
			)
			return fmt.Errorf("failed to find sync job: %w", err)
		}

		// Update all fields atomically
		job.Status = status
		job.TotalItems = null.IntFrom(totalItems)
		job.SuccessfulItems = null.IntFrom(successful)
		job.FailedItems = null.IntFrom(failed)
		job.CompletedAt = null.TimeFrom(time.Now().UTC())

		// Store error message if provided
		if errorMsg != nil {
			job.ErrorMessage = null.StringFrom(*errorMsg)
		}

		// Update the job within the transaction
		_, err = job.Update(ctx, tx, boil.Infer())
		if err != nil {
			s.logger.Error("Failed to update sync job atomically",
				zap.String("job_id", jobID),
				zap.String("status", status),
				zap.Int("total", totalItems),
				zap.Int("successful", successful),
				zap.Int("failed", failed),
				zap.Error(err),
			)
			return fmt.Errorf("failed to update sync job: %w", err)
		}

		s.logger.Info("Atomically updated sync job",
			zap.String("job_id", jobID),
			zap.String("status", status),
			zap.Int("total_items", totalItems),
			zap.Int("successful", successful),
			zap.Int("failed", failed),
		)

		return nil
	})
}

// GetByID retrieves a sync job by its ID
func (s *JobService) GetByID(jobID string) (*types.SyncJobResult, error) {
	job, err := models.ProductSyncJobs(
		qm.Where("job_id = ?", jobID),
	).One(context.Background(), s.db.DB)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("sync job not found: %s", jobID)
		}
		s.logger.Error("Failed to get sync job by ID",
			zap.String("job_id", jobID),
			zap.Error(err),
		)
		return nil, fmt.Errorf("failed to get sync job: %w", err)
	}

	return s.mapToSyncJobResult(job), nil
}

func (s *JobService) mapToSyncJobResult(job *models.ProductSyncJob) *types.SyncJobResult {
	result := &types.SyncJobResult{
		ID:            job.ID,
		JobID:         job.JobID,
		SyncOperation: types.SyncOperation(job.SyncOperation),
		Status:        types.SyncStatus(job.Status),
		S3Bucket:      job.S3Bucket,
		S3Key:         job.S3Key,
		CreatedAt:     job.CreatedAt.Time,
	}

	// Handle optional fields with proper pointer conversion
	if job.FileSizeBytes.Valid {
		result.FileSizeBytes = &job.FileSizeBytes.Int64
	}

	if job.TotalItems.Valid {
		totalItems := int(job.TotalItems.Int)
		result.TotalItems = &totalItems
	}

	if job.SuccessfulItems.Valid {
		successfulItems := int(job.SuccessfulItems.Int)
		result.SuccessfulItems = &successfulItems
	}

	if job.FailedItems.Valid {
		failedItems := int(job.FailedItems.Int)
		result.FailedItems = &failedItems
	}

	if job.StartedAt.Valid {
		result.StartedAt = job.StartedAt.Ptr()
	}

	if job.CompletedAt.Valid {
		result.CompletedAt = job.CompletedAt.Ptr()
	}

	if job.ErrorMessage.Valid {
		result.ErrorMessage = &job.ErrorMessage.String
	}

	// Parse validation errors if they exist
	if job.ValidationErrors.Valid {
		var validationErrors map[string]interface{}
		if err := json.Unmarshal(job.ValidationErrors.JSON, &validationErrors); err != nil {
			s.logger.Warn("Failed to parse validation errors for job", zap.String("job_id", job.JobID), zap.Error(err))
		} else {
			result.ValidationErrors = validationErrors
		}
	}

	return result
}

// StoreValidationErrors stores validation errors from the error collector
func (s *JobService) StoreValidationErrors(jobID string, errorCollector *errors.ErrorCollector) error {
	if errorCollector == nil {
		return nil
	}

	summary := errorCollector.GetSummary()
	detailedErrors := errorCollector.GetAllErrors()

	// Create the validation errors JSON structure
	validationData := struct {
		Summary        errors.ErrorSummary `json:"summary"`
		DetailedErrors []*errors.SyncError `json:"detailed_errors"`
		Timestamp      time.Time           `json:"timestamp"`
	}{
		Summary:        summary,
		DetailedErrors: detailedErrors,
		Timestamp:      time.Now().UTC(),
	}

	// Convert to JSON
	jsonData, err := json.Marshal(validationData)
	if err != nil {
		return fmt.Errorf("failed to marshal validation errors: %w", err)
	}

	// Find and update the job
	job, err := models.ProductSyncJobs(
		qm.Where("job_id = ?", jobID),
	).One(context.Background(), s.db.DB)

	if err != nil {
		return fmt.Errorf("failed to find sync job for error storage: %w", err)
	}

	// Store the validation errors JSON
	job.ValidationErrors = null.JSONFrom(jsonData)

	// Update the job
	_, err = job.Update(context.Background(), s.db.DB, boil.Whitelist("validation_errors"))
	if err != nil {
		return fmt.Errorf("failed to store validation errors: %w", err)
	}

	s.logger.Info("Stored validation errors for sync job",
		zap.String("job_id", jobID),
		zap.Int("total_errors", summary.TotalErrors),
		zap.Int("critical_errors", summary.AlertCount),
	)

	return nil
}
