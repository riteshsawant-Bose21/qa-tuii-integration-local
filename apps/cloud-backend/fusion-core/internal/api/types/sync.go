package types

import (
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
)

type SyncOperation string
type SyncStatus string
type ProductType string

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

const (
	ProductTypeSpeaker    ProductType = "speaker"
	ProductTypeAmplifier  ProductType = "amplifier"
	ProductTypeDSP        ProductType = "dsp"
	ProductTypeController ProductType = "controller"
	ProductTypeIOEndpoint ProductType = "io_endpoint"
	ProductTypeAccessory  ProductType = "accessory"
)

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

// LambdaEvent represents the Lambda event structure
type LambdaEvent struct {
	SyncType   string `json:"syncType"`   // "product" or "price"
	SourceType string `json:"sourceType"` // "local" or "s3"
	SourcePath string `json:"sourcePath,omitempty"`
	S3Bucket   string `json:"s3Bucket,omitempty"`
	S3Key      string `json:"s3Key,omitempty"`
	Region     string `json:"region,omitempty"`
}

// LambdaResponse represents the Lambda response
type LambdaResponse struct {
	Success    bool     `json:"success"`
	JobID      string   `json:"jobId,omitempty"`
	TotalItems int      `json:"totalItems"`
	Successful int      `json:"successful"`
	Failed     int      `json:"failed"`
	Errors     []string `json:"errors,omitempty"`
	Duration   string   `json:"duration"`
	Message    string   `json:"message"`
}
