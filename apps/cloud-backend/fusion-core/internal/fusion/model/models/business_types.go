// Code manually added for business logic types
// This file contains types used by business logic that complement the SQLBoiler generated models

package models

import (
	"time"
)

// Business logic enums that match SQLBoiler enum constants
type SyncOperation string
type SyncStatus string
type ProductType string

const (
	// SyncOperation constants matching SQLBoiler
	SyncOperationFullSync      SyncOperation = "full_sync"
	SyncOperationManualSync    SyncOperation = "manual_sync"
	SyncOperationScheduledSync SyncOperation = "scheduled_sync"
)

const (
	// SyncStatus constants matching SQLBoiler
	SyncStatusPending    SyncStatus = "pending"
	SyncStatusInProgress SyncStatus = "in_progress"
	SyncStatusCompleted  SyncStatus = "completed"
	SyncStatusFailed     SyncStatus = "failed"
)

const (
	// ProductType constants matching SQLBoiler
	ProductTypeSpeaker    ProductType = "speaker"
	ProductTypeAmplifier  ProductType = "amplifier"
	ProductTypeDSP        ProductType = "dsp"
	ProductTypeController ProductType = "controller"
	ProductTypeIOEndpoint ProductType = "io_endpoint"
	ProductTypeAccessory  ProductType = "accessory"
)

// Business logic struct for sync job results (different from database model)
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
