package errors

import (
	"fmt"
	"time"

	"go.uber.org/zap"
)

// ErrorCategory represents the type of error
type ErrorCategory string

const (
	// Data-related errors
	ValidationError ErrorCategory = "VALIDATION"
	ParseError      ErrorCategory = "PARSE"
	TransformError  ErrorCategory = "TRANSFORM"

	// Field validation specific errors
	MissingRequiredFieldError ErrorCategory = "MISSING_REQUIRED_FIELD"
	MissingOptionalFieldError ErrorCategory = "MISSING_OPTIONAL_FIELD"
	InvalidFieldTypeError     ErrorCategory = "INVALID_FIELD_TYPE"
	InvalidFieldValueError    ErrorCategory = "INVALID_FIELD_VALUE"
	FieldConstraintError      ErrorCategory = "FIELD_CONSTRAINT_VIOLATION"

	// Database-related errors
	DatabaseError    ErrorCategory = "DATABASE"
	ConnectionError  ErrorCategory = "CONNECTION"
	TransactionError ErrorCategory = "TRANSACTION"

	// External service errors
	NetworkError ErrorCategory = "NETWORK"
	TimeoutError ErrorCategory = "TIMEOUT"
	AuthError    ErrorCategory = "AUTH"

	// Business logic errors
	BusinessRuleError ErrorCategory = "BUSINESS_RULE"
	DuplicateError    ErrorCategory = "DUPLICATE"
	NotFoundError     ErrorCategory = "NOT_FOUND"

	// System errors
	ConfigError ErrorCategory = "CONFIG"
	SystemError ErrorCategory = "SYSTEM"
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

const (
	SeverityCritical ErrorSeverity = "CRITICAL" // Stops entire sync
	SeverityHigh     ErrorSeverity = "HIGH"     // Affects many items
	SeverityMedium   ErrorSeverity = "MEDIUM"   // Affects single item
	SeverityLow      ErrorSeverity = "LOW"      // Warning only
)

// SyncError represents a detailed error with context
type SyncError struct {
	ID          string        `json:"id"`          // Unique error ID for tracking
	Category    ErrorCategory `json:"category"`    // Error type
	Severity    ErrorSeverity `json:"severity"`    // How critical
	Message     string        `json:"message"`     // Human readable message
	Details     string        `json:"details"`     // Technical details
	Context     ErrorContext  `json:"context"`     // Where/when it happened
	OriginalErr error         `json:"-"`           // Original error (not serialized)
	Timestamp   time.Time     `json:"timestamp"`   // When it occurred
	Retryable   bool          `json:"retryable"`   // Can this be retried?
	RetryCount  int           `json:"retry_count"` // How many times retried
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
		zap.Int("retry_count", se.RetryCount),
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

// IsRetryable determines if this error should trigger a retry
func (se *SyncError) IsRetryable() bool {
	if !se.Retryable {
		return false
	}

	// Don't retry validation errors
	if se.Category == ValidationError || se.Category == ParseError {
		return false
	}

	// Don't retry business rule violations
	if se.Category == BusinessRuleError || se.Category == DuplicateError {
		return false
	}

	// Don't retry auth errors
	if se.Category == AuthError {
		return false
	}

	return se.RetryCount < 3 // Max 3 retries
}

// ShouldAlert determines if this error should trigger an alert
func (se *SyncError) ShouldAlert() bool {
	return se.Severity == SeverityCritical || se.Severity == SeverityHigh
}

// ErrorBuilder helps create SyncError instances
type ErrorBuilder struct {
	err *SyncError
}

// NewError creates a new error builder
func NewError(category ErrorCategory, severity ErrorSeverity, message string) *ErrorBuilder {
	return &ErrorBuilder{
		err: &SyncError{
			ID:        generateErrorID(),
			Category:  category,
			Severity:  severity,
			Message:   message,
			Timestamp: time.Now().UTC(),
			Context:   ErrorContext{},
		},
	}
}

// WithDetails adds technical details
func (eb *ErrorBuilder) WithDetails(details string) *ErrorBuilder {
	eb.err.Details = details
	return eb
}

// WithOriginalError adds the underlying error
func (eb *ErrorBuilder) WithOriginalError(err error) *ErrorBuilder {
	eb.err.OriginalErr = err
	if eb.err.Details == "" {
		eb.err.Details = err.Error()
	}
	return eb
}

// WithContext sets the error context
func (eb *ErrorBuilder) WithContext(ctx ErrorContext) *ErrorBuilder {
	eb.err.Context = ctx
	return eb
}

// WithProductID adds product context
func (eb *ErrorBuilder) WithProductID(productID int) *ErrorBuilder {
	eb.err.Context.ProductID = &productID
	return eb
}

// WithSKU adds SKU context
func (eb *ErrorBuilder) WithSKU(sku int) *ErrorBuilder {
	eb.err.Context.SKU = &sku
	return eb
}

// WithField adds field context
func (eb *ErrorBuilder) WithField(fieldName string) *ErrorBuilder {
	eb.err.Context.FieldName = fieldName
	return eb
}

// AsRetryable marks the error as retryable
func (eb *ErrorBuilder) AsRetryable() *ErrorBuilder {
	eb.err.Retryable = true
	return eb
}

// Build creates the final SyncError
func (eb *ErrorBuilder) Build() *SyncError {
	return eb.err
}

// generateErrorID creates a unique error ID for tracking
func generateErrorID() string {
	return fmt.Sprintf("ERR_%d", time.Now().UTC().UnixNano())
}
