package fusion

import (
	"context"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
)

// Sync defines the interface for sync operations
type Sync interface {
	// Product sync operations
	SyncProducts(ctx context.Context, data []byte, jobID string) (*SyncResult, error)

	// Price sync operations
	SyncPrices(ctx context.Context, data []byte) (*SyncResult, error)
}

// SyncResult represents the result of a sync operation
type SyncResult struct {
	SyncType           string               `json:"sync_type"`
	TotalItems         int                  `json:"total_items"`
	Successful         int                  `json:"successful"`
	Failed             int                  `json:"failed"`
	Skipped            int                  `json:"skipped"`
	Errors             []string             `json:"errors"`
	ValidationWarnings []string             `json:"validation_warnings"`
	Duration           time.Duration        `json:"duration"`
	JobID              string               `json:"job_id,omitempty"`
	ErrorSummary       *errors.ErrorSummary `json:"error_summary,omitempty"`
	DetailedErrors     []*errors.SyncError  `json:"detailed_errors,omitempty"`
}

// SyncJobResult represents a sync job result for external consumers
type SyncJobResult struct {
	ID               int                    `json:"id"`
	JobID            string                 `json:"job_id"`
	SyncOperation    SyncOperation          `json:"sync_operation"`
	Status           SyncStatus             `json:"status"`
	S3Bucket         string                 `json:"s3_bucket"`
	S3Key            string                 `json:"s3_key"`
	FileSizeBytes    *int64                 `json:"file_size_bytes,omitempty"`
	ErrorMessage     *string                `json:"error_message,omitempty"`
	ValidationErrors map[string]interface{} `json:"validation_errors,omitempty"`
	TotalItems       *int                   `json:"total_items,omitempty"`
	SuccessfulItems  *int                   `json:"successful_items,omitempty"`
	FailedItems      *int                   `json:"failed_items,omitempty"`
	StartedAt        *time.Time             `json:"started_at,omitempty"`
	CompletedAt      *time.Time             `json:"completed_at,omitempty"`
	CreatedAt        time.Time              `json:"created_at"`
}

// Business logic enums for sync operations
type SyncOperation string
type SyncStatus string

const (
	SyncOperationFullSync      SyncOperation = "full_sync"
	SyncOperationManualSync    SyncOperation = "manual_sync"
	SyncOperationScheduledSync SyncOperation = "scheduled_sync"
)

const (
	SyncStatusPending    SyncStatus = "pending"
	SyncStatusInProgress SyncStatus = "in_progress"
	SyncStatusCompleted  SyncStatus = "completed"
	SyncStatusFailed     SyncStatus = "failed"
)
