package errorutil

import (
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// ErrorCategory represents the type of error
type ErrorCategory string

const (
	// ValidationError represents data validation related errors.
	ValidationError ErrorCategory = "VALIDATION"
)

// Sentinel errors for common operations
var (
	// ErrProductNotFound is returned when a product with the given ID does not exist
	ErrProductNotFound = fmt.Errorf("product not found")

	// ErrNoPricesFound is returned when no prices are found for a product
	ErrNoPricesFound = fmt.Errorf("no prices found")
)

// ErrorSeverity represents how critical the error is
type ErrorSeverity string

// Error severity constants.
const (
	// SeverityCritical represents errors that stop the entire sync operation.
	SeverityCritical ErrorSeverity = "CRITICAL" // Stops entire sync
	SeverityHigh     ErrorSeverity = "HIGH"     // Affects many items
	SeverityMedium   ErrorSeverity = "MEDIUM"   // Affects single item
	SeverityLow      ErrorSeverity = "LOW"      // Warning only
)

// SyncError represents a detailed error with context
type SyncError struct {
	ID          string        `json:"id"`        // Unique error ID for tracking
	Category    ErrorCategory `json:"category"`  // Error type
	Severity    ErrorSeverity `json:"severity"`  // How critical
	Message     string        `json:"message"`   // Human readable message
	Details     string        `json:"details"`   // Technical details
	Context     ErrorContext  `json:"context"`   // Where/when it happened
	OriginalErr error         `json:"-"`         // Original error (not serialized)
	Timestamp   time.Time     `json:"timestamp"` // When it occurred
	Retryable   bool          `json:"retryable"` // Can this be retried?
}

// ErrorContext provides detailed information about where the error occurred
type ErrorContext struct {
	JobID       string                 `json:"job_id,omitempty"`
	SyncType    string                 `json:"sync_type,omitempty"`    // "product" or "price"
	ProductID   *int                   `json:"product_id,omitempty"`   // Which product
	ProductType string                 `json:"product_type,omitempty"` // speaker, amplifier, etc.
	SKU         *int                   `json:"sku,omitempty"`          // For price sync
	Currency    string                 `json:"currency,omitempty"`     // For price sync
	Variant     string                 `json:"variant,omitempty"`      // Color variant
	FieldName   string                 `json:"field_name,omitempty"`   // Which field caused error
	FileName    string                 `json:"file_name,omitempty"`    // Source file
	LineNumber  *int                   `json:"line_number,omitempty"`  // Line in file
	Goroutine   int                    `json:"goroutine_id,omitempty"` // Which worker
	Metadata    map[string]interface{} `json:"metadata,omitempty"`     // Additional context
}

// Error implements the error interface
func (se *SyncError) Error() string {
	return fmt.Sprintf("[%s][%s] %s: %s", se.Category, se.Severity, se.Message, se.Details)
}

// ToZapFields converts SyncError to structured zap fields for logging
func (se *SyncError) ToZapFields() []zap.Field {
	fields := []zap.Field{
		zap.String("error_id", se.ID),
		zap.String("error_category", string(se.Category)),
		zap.String("error_severity", string(se.Severity)),
		zap.String("error_message", se.Message),
		zap.String("error_details", se.Details),
		zap.Time("error_timestamp", se.Timestamp),
		zap.Bool("retryable", se.Retryable),
	}

	// Add context fields
	if se.Context.JobID != "" {
		fields = append(fields, zap.String("job_id", se.Context.JobID))
	}
	if se.Context.SyncType != "" {
		fields = append(fields, zap.String("sync_type", se.Context.SyncType))
	}
	if se.Context.ProductID != nil {
		fields = append(fields, zap.Int("product_id", *se.Context.ProductID))
	}
	if se.Context.ProductType != "" {
		fields = append(fields, zap.String("product_type", se.Context.ProductType))
	}
	if se.Context.SKU != nil {
		fields = append(fields, zap.Int("sku", *se.Context.SKU))
	}
	if se.Context.Currency != "" {
		fields = append(fields, zap.String("currency", se.Context.Currency))
	}
	if se.Context.Variant != "" {
		fields = append(fields, zap.String("variant", se.Context.Variant))
	}
	if se.Context.FieldName != "" {
		fields = append(fields, zap.String("field_name", se.Context.FieldName))
	}
	if se.Context.FileName != "" {
		fields = append(fields, zap.String("file_name", se.Context.FileName))
	}
	if se.Context.Goroutine != 0 {
		fields = append(fields, zap.Int("goroutine_id", se.Context.Goroutine))
	}

	// Add original error if present
	if se.OriginalErr != nil {
		fields = append(fields, zap.Error(se.OriginalErr))
	}

	return fields
}

// ShouldAlert determines if this error should trigger an alert
func (se *SyncError) ShouldAlert() bool {
	return se.Severity == SeverityCritical || se.Severity == SeverityHigh
}

// NewSyncError creates a new SyncError with the given parameters
func NewSyncError(category ErrorCategory, severity ErrorSeverity, message, details string, productID *int, fieldName string) *SyncError {
	syncErr := &SyncError{
		ID:        generateErrorID(),
		Category:  category,
		Severity:  severity,
		Message:   message,
		Details:   details,
		Timestamp: time.Now().UTC(),
		Context:   ErrorContext{},
	}

	if productID != nil {
		syncErr.Context.ProductID = productID
	}

	if fieldName != "" {
		syncErr.Context.FieldName = fieldName
	}

	return syncErr
}

// generateErrorID creates a unique error ID for tracking
func generateErrorID() string {
	return fmt.Sprintf("ERR_%d", time.Now().UTC().UnixNano())
}

// ==========================
// ==== Error Collectors ====
// ==========================

// ErrorCollector collects and manages errors during sync operations
type ErrorCollector struct {
	mu            sync.RWMutex
	errors        []*SyncError
	errorsByType  map[ErrorCategory]int
	errorsBySev   map[ErrorSeverity]int
	retryableErrs int
	alerts        []*SyncError
	logger        *zap.Logger
	jobID         string
	syncType      string
}

// NewErrorCollector creates a new error collector
func NewErrorCollector(logger *zap.Logger, jobID, syncType string) *ErrorCollector {
	return &ErrorCollector{
		errors:       make([]*SyncError, 0),
		errorsByType: make(map[ErrorCategory]int),
		errorsBySev:  make(map[ErrorSeverity]int),
		alerts:       make([]*SyncError, 0),
		logger:       logger,
		jobID:        jobID,
		syncType:     syncType,
	}
}

// Add adds an error to the collector
func (ec *ErrorCollector) Add(err *SyncError) {
	if err == nil {
		return
	}

	ec.mu.Lock()
	defer ec.mu.Unlock()

	// Set context if not already set
	if err.Context.JobID == "" {
		err.Context.JobID = ec.jobID
	}
	if err.Context.SyncType == "" {
		err.Context.SyncType = ec.syncType
	}

	// Add to collections
	ec.errors = append(ec.errors, err)
	ec.errorsByType[err.Category]++
	ec.errorsBySev[err.Severity]++

	if err.Retryable {
		ec.retryableErrs++
	}

	if err.ShouldAlert() {
		ec.alerts = append(ec.alerts, err)
	}

	// Log the error with full context
	ec.logError(err)
}

// AddFieldValidationError adds a field-specific validation error
func (ec *ErrorCollector) AddFieldValidationError(category ErrorCategory, severity ErrorSeverity, productID int, fieldName, fieldPath, message string, suggestion string) {
	details := fmt.Sprintf("Field path: %s. Suggestion: %s", fieldPath, suggestion)
	syncErr := NewSyncError(category, severity, message, details, &productID, fieldName)

	syncErr.Context.JobID = ec.jobID
	syncErr.Context.SyncType = ec.syncType

	ec.Add(syncErr)
}

// logError logs the error with appropriate level and structured fields
func (ec *ErrorCollector) logError(err *SyncError) {
	fields := err.ToZapFields()

	switch err.Severity {
	case SeverityCritical:
		ec.logger.Error("CRITICAL ERROR - Sync operation may fail", fields...)
	case SeverityHigh:
		ec.logger.Error("HIGH SEVERITY ERROR", fields...)
	case SeverityMedium:
		ec.logger.Warn("MEDIUM SEVERITY ERROR", fields...)
	case SeverityLow:
		ec.logger.Info("LOW SEVERITY WARNING", fields...)
	default:
		ec.logger.Error("UNKNOWN SEVERITY ERROR", fields...)
	}
}

// GetSummary returns a summary of collected errors
func (ec *ErrorCollector) GetSummary() ErrorSummary {
	ec.mu.RLock()
	defer ec.mu.RUnlock()

	return ErrorSummary{
		TotalErrors:    len(ec.errors),
		RetryableCount: ec.retryableErrs,
		AlertCount:     len(ec.alerts),
		ErrorsByType:   copyMap(ec.errorsByType),
		ErrorsBySev:    copyMap(ec.errorsBySev),
		CriticalErrors: ec.getCriticalErrors(),
	}
}

// GetAllErrors returns all collected errors
func (ec *ErrorCollector) GetAllErrors() []*SyncError {
	ec.mu.RLock()
	defer ec.mu.RUnlock()

	errors := make([]*SyncError, len(ec.errors))
	copy(errors, ec.errors)
	return errors
}

// getCriticalErrors returns critical error messages for summary
func (ec *ErrorCollector) getCriticalErrors() []string {
	var critical []string
	for _, err := range ec.errors {
		if err.Severity == SeverityCritical || err.Severity == SeverityHigh {
			critical = append(critical, fmt.Sprintf("[%s] %s", err.Category, err.Message))
		}
	}
	return critical
}

// ErrorSummary provides a summary of error statistics
type ErrorSummary struct {
	TotalErrors    int                   `json:"total_errors"`
	RetryableCount int                   `json:"retryable_count"`
	AlertCount     int                   `json:"alert_count"`
	ErrorsByType   map[ErrorCategory]int `json:"errors_by_type"`
	ErrorsBySev    map[ErrorSeverity]int `json:"errors_by_severity"`
	CriticalErrors []string              `json:"critical_errors"`
}

// copyMap creates a copy of a map to prevent external modification
func copyMap[K comparable, V any](original map[K]V) map[K]V {
	result := make(map[K]V, len(original))
	for k, v := range original {
		result[k] = v
	}
	return result
}
