package types

import (
	"time"

	errorutil "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
)

var (
	ProductCategorySpeaker                string = "speaker"
	ProductCategoryAmplifier              string = "amplifier"
	ProductCategoryDigitalSignalProcessor string = "dsp"
	ProductCategoryController             string = "controller"
	ProductCategoryEndpoint               string = "io_endpoint"
	ProductCategoryAccessory              string = "accessory"
)

// Generic product item response used for all product types
type ProductItemResponse struct {
	ProductID          int         `json:"product_id"`
	Assets             interface{} `json:"assets"`
	ModelName          string      `json:"model_name"`
	ModelFamily        string      `json:"model_family,omitempty"`
	Description        string      `json:"description,omitempty"`
	Specifications     interface{} `json:"specifications"`
	IsFusionCompatible bool        `json:"is_fusion_compatible"`
}

// New API response structure matching the required schema
type ProductResponse struct {
	Version    string                `json:"version"`
	Speaker    []ProductItemResponse `json:"speaker,omitempty"`
	Amplifier  []ProductItemResponse `json:"amplifier,omitempty"`
	Controller []ProductItemResponse `json:"controller,omitempty"`
	DSP        []ProductItemResponse `json:"dsp,omitempty"`
	Accessory  []ProductItemResponse `json:"accessory,omitempty"`
	IOEndpoint []ProductItemResponse `json:"io_endpoint,omitempty"`
}

// Individual product response when fetching by ID
type SingleProductResponse struct {
	Version    string               `json:"version"`
	Speaker    *ProductItemResponse `json:"speaker,omitempty"`
	Amplifier  *ProductItemResponse `json:"amplifier,omitempty"`
	DSP        *ProductItemResponse `json:"dsp,omitempty"`
	Controller *ProductItemResponse `json:"controller,omitempty"`
	Accessory  *ProductItemResponse `json:"accessory,omitempty"`
	IOEndpoint *ProductItemResponse `json:"io_endpoint,omitempty"`
}

// Price API response types
type PriceResponse struct {
	Version   string        `json:"version"`
	ProductID int           `json:"product_id"`
	Prices    []PriceDetail `json:"prices"`
}

type PriceDetail struct {
	Variant  string  `json:"variant,omitempty"`
	Currency string  `json:"currency"`
	Price    float64 `json:"price"`
}

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
	SyncType           string                  `json:"sync_type"`
	TotalItems         int                     `json:"total_items"`
	Successful         int                     `json:"successful"`
	Failed             int                     `json:"failed"`
	Skipped            int                     `json:"skipped"`
	Errors             []string                `json:"errors"`
	ValidationWarnings []string                `json:"validation_warnings"`
	Duration           time.Duration           `json:"duration"`
	JobID              string                  `json:"job_id,omitempty"`
	ErrorSummary       *errorutil.ErrorSummary `json:"error_summary,omitempty"`
	DetailedErrors     []*errorutil.SyncError  `json:"detailed_errors,omitempty"`
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

// DBProduct represents a product in database format
type DBProduct struct {
	ProductID          int     `json:"product_id"`
	ProductType        string  `json:"product_type"`
	ModelName          string  `json:"model_name"`
	ModelFamily        string  `json:"model_family"`
	ShortDescription   string  `json:"short_description"`
	Description        string  `json:"description"`
	Images             string  `json:"images"`         // JSON string
	Specifications     string  `json:"specifications"` // JSON string
	IsFusionCompatible bool    `json:"is_fusion_compatible"`
	CreatedAt          *string `json:"created_at"` // Epoch timestamp as string
	UpdatedAt          *string `json:"updated_at"` // Epoch timestamp as string
}

// DBPrice represents a price in database format
type DBPrice struct {
	ProductID int     `json:"product_id"`
	Currency  string  `json:"currency"`
	Amount    float64 `json:"amount"`
	Variant   *string `json:"variant,omitempty"`    // Optional variant field
	UpdatedAt *string `json:"updated_at"`           // RFC3339 timestamp
	CreatedAt *string `json:"created_at,omitempty"` // Optional creation timestamp
}

type PriceKey struct {
	ProductID int    `json:"product_id"`
	Currency  string `json:"currency"`
	Variant   string `json:"variant"` // Empty string for null variants
}

// DBSyncJob represents a sync job creation request
type DBSyncJob struct {
	JobType     string                 `json:"job_type"`
	Status      string                 `json:"status"`
	Source      string                 `json:"source"`
	SourceJobID *int                   `json:"source_job_id,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// SyncRequest represents a sync execution request
type SyncRequest struct {
	SyncType         string
	SyncOperation    string // "manual_sync" or "scheduled_sync"
	SourceType       string
	FilePath         string
	S3Bucket         string
	S3Key            string
	Region           string
	EnableValidation bool
}

// Product represents a product from JSON data (internal struct for sync processing)
type Product struct {
	ProductID          int                    `json:"id"`
	ModelName          string                 `json:"model_name"`
	ModelFamily        string                 `json:"model_family,omitempty"`
	Description        string                 `json:"description,omitempty"`
	ShortDescription   string                 `json:"short_description,omitempty"`
	IsFusionCompatible bool                   `json:"is_fusion_compatible,omitempty"`
	UpdatedAt          string                 `json:"updated_at,omitempty"`
	Images             []map[string][]string  `json:"images,omitempty"`
	RawData            map[string]interface{} `json:"-"`
}

// ProductData represents the structure of the JSON data from the source
type ProductData struct {
	Version                 string    `json:"version,omitempty"`
	Title                   string    `json:"title,omitempty"`
	Description             string    `json:"description,omitempty"`
	Speakers                []Product `json:"speakers,omitempty"`
	Amplifiers              []Product `json:"amplifiers,omitempty"`
	DigitalSignalProcessors []Product `json:"digital_signal_processors,omitempty"`
	Controllers             []Product `json:"controllers,omitempty"`
	IOEndpoints             []Product `json:"i_o_endpoints,omitempty"`
	AdditionalAccessories   []Product `json:"additional_accessories,omitempty"`
}

// ProductCategoryGroup represents a group of products by category for concurrent processing
type ProductCategoryGroup struct {
	CategoryName string
	CategoryType string
	Products     []Product
}

// CategoryResult represents the result of processing a category
type CategoryResult struct {
	CategoryName       string
	Successful         int
	Failed             int
	Errors             []string
	ValidationWarnings []string
	Duration           time.Duration
}

// RRPData represents the root structure for price data JSON
type RRPData struct {
	Version string        `json:"version"`
	RRPData []RRPSKUEntry `json:"rrp_data"`
}

// RRPSKUEntry represents a SKU with its price variants
type RRPSKUEntry struct {
	SKU      int          `json:"sku"`
	Variants []RRPVariant `json:"variants"`
}

// RRPVariant represents a specific price variant for a SKU
type RRPVariant struct {
	Variant  *string `json:"variant"`
	Currency string  `json:"currency"`
	Price    float64 `json:"price"`
}
