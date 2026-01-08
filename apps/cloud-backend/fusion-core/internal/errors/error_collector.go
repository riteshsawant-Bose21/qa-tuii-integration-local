package errors

import (
	"fmt"
	"sync"

	"go.uber.org/zap"
)

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
	syncErr := NewError(category, severity, message).
		WithProductID(productID).
		WithField(fieldName).
		WithDetails(fmt.Sprintf("Field path: %s. Suggestion: %s", fieldPath, suggestion)).
		WithContext(ErrorContext{
			JobID:     ec.jobID,
			SyncType:  ec.syncType,
			FieldName: fieldName,
		}).
		Build()

	ec.Add(syncErr)
}

// AddMissingRequiredFieldError adds an error for missing required fields
func (ec *ErrorCollector) AddMissingRequiredFieldError(productID int, fieldName, fieldPath, description string) {
	message := fmt.Sprintf("Product ID %d: Missing required field '%s' (%s)", productID, fieldName, description)
	suggestion := fmt.Sprintf("Add field '%s' to product %d data", fieldPath, productID)

	ec.AddFieldValidationError(MissingRequiredFieldError, SeverityHigh, productID, fieldName, fieldPath, message, suggestion)
}

// AddMissingOptionalFieldError adds a warning for missing optional fields
func (ec *ErrorCollector) AddMissingOptionalFieldError(productID int, fieldName, fieldPath, description string) {
	message := fmt.Sprintf("Product ID %d: Missing recommended field '%s' (%s)", productID, fieldName, description)
	suggestion := fmt.Sprintf("Consider adding field '%s' to product %d to improve data completeness", fieldPath, productID)

	ec.AddFieldValidationError(MissingOptionalFieldError, SeverityLow, productID, fieldName, fieldPath, message, suggestion)
}

// AddInvalidFieldTypeError adds an error for wrong field types
func (ec *ErrorCollector) AddInvalidFieldTypeError(productID int, fieldName, fieldPath, expectedType, actualType string, actualValue interface{}) {
	message := fmt.Sprintf("Product ID %d: Field '%s' has wrong type: expected %s, got %s", productID, fieldName, expectedType, actualType)
	suggestion := fmt.Sprintf("Convert field '%s' in product %d to type %s (current value: %v)", fieldPath, productID, expectedType, actualValue)

	ec.AddFieldValidationError(InvalidFieldTypeError, SeverityMedium, productID, fieldName, fieldPath, message, suggestion)
}

// AddFieldConstraintError adds an error for constraint violations
func (ec *ErrorCollector) AddFieldConstraintError(productID int, fieldName, fieldPath, constraintDescription string, actualValue interface{}) {
	message := fmt.Sprintf("Product ID %d: Field '%s' violates constraint: %s", productID, fieldName, constraintDescription)
	suggestion := fmt.Sprintf("Fix field '%s' in product %d to meet constraint requirements (current value: %v)", fieldPath, productID, actualValue)

	ec.AddFieldValidationError(FieldConstraintError, SeverityMedium, productID, fieldName, fieldPath, message, suggestion)
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

	// Return a copy to prevent external modification
	errors := make([]*SyncError, len(ec.errors))
	copy(errors, ec.errors)
	return errors
}

// GetErrorsForRetry returns errors that should be retried
func (ec *ErrorCollector) GetErrorsForRetry() []*SyncError {
	ec.mu.RLock()
	defer ec.mu.RUnlock()

	var retryable []*SyncError
	for _, err := range ec.errors {
		if err.IsRetryable() {
			retryable = append(retryable, err)
		}
	}
	return retryable
}

// GetAlertsRequired returns errors that need alerting
func (ec *ErrorCollector) GetAlertsRequired() []*SyncError {
	ec.mu.RLock()
	defer ec.mu.RUnlock()

	alerts := make([]*SyncError, len(ec.alerts))
	copy(alerts, ec.alerts)
	return alerts
}

// LogSummary logs a comprehensive error summary
func (ec *ErrorCollector) LogSummary() {
	summary := ec.GetSummary()

	if summary.TotalErrors == 0 {
		ec.logger.Info("Sync completed successfully with no errors",
			zap.String("job_id", ec.jobID),
			zap.String("sync_type", ec.syncType),
		)
		return
	}

	fields := []zap.Field{
		zap.String("job_id", ec.jobID),
		zap.String("sync_type", ec.syncType),
		zap.Int("total_errors", summary.TotalErrors),
		zap.Int("retryable_errors", summary.RetryableCount),
		zap.Int("alert_errors", summary.AlertCount),
		zap.Any("errors_by_type", summary.ErrorsByType),
		zap.Any("errors_by_severity", summary.ErrorsBySev),
	}

	if summary.AlertCount > 0 {
		ec.logger.Error("Sync completed with CRITICAL/HIGH severity errors requiring attention", fields...)
	} else if summary.TotalErrors > 0 {
		ec.logger.Warn("Sync completed with errors", fields...)
	}

	// Log top error patterns
	if len(summary.CriticalErrors) > 0 {
		ec.logger.Error("Critical errors detected",
			zap.String("job_id", ec.jobID),
			zap.Any("critical_errors", summary.CriticalErrors),
		)
	}
}

// GetJobID returns the job ID for this error collector
func (ec *ErrorCollector) GetJobID() string {
	ec.mu.RLock()
	defer ec.mu.RUnlock()
	return ec.jobID
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
	copy := make(map[K]V, len(original))
	for k, v := range original {
		copy[k] = v
	}
	return copy
}
