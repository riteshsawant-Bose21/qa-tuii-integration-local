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
	copy := make(map[K]V, len(original))
	for k, v := range original {
		copy[k] = v
	}
	return copy
}
