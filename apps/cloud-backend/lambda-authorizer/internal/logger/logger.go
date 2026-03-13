package logger

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/BoseProfessional/lambda-authorizer/internal/constants"
)

// LogLevel represents the severity of a log message
type LogLevel string

const (
	LogLevelInfo  LogLevel = "INFO"
	LogLevelWarn  LogLevel = "WARN"
	LogLevelError LogLevel = "ERROR"
	LogLevelDebug LogLevel = "DEBUG"
)

// LogEntry represents a structured log entry for CloudWatch
type LogEntry struct {
	Timestamp   string                 `json:"timestamp"`
	Level       LogLevel               `json:"level"`
	Message     string                 `json:"message"`
	RequestID   string                 `json:"request_id,omitempty"`
	SourceIP    string                 `json:"source_ip,omitempty"`
	Email       string                 `json:"email,omitempty"`
	Method      string                 `json:"method,omitempty"`
	Path        string                 `json:"path,omitempty"`
	Decision    string                 `json:"decision,omitempty"` // "allow" or "deny"
	Reason      string                 `json:"reason,omitempty"`
	DurationMs  int64                  `json:"duration_ms,omitempty"`
	Error       string                 `json:"error,omitempty"`
	UserContext map[string]interface{} `json:"user_context,omitempty"`
	Extra       map[string]interface{} `json:"extra,omitempty"`
}

// Logger provides structured logging for Lambda
type Logger struct {
	requestID string
	sourceIP  string
}

// NewLogger creates a new logger instance
func NewLogger(requestID, sourceIP string) *Logger {
	return &Logger{
		requestID: requestID,
		sourceIP:  sourceIP,
	}
}

// log outputs a structured JSON log entry to stdout (CloudWatch)
func (l *Logger) log(entry LogEntry) {
	entry.Timestamp = time.Now().UTC().Format(time.RFC3339Nano)
	entry.RequestID = l.requestID
	if l.sourceIP != "" {
		entry.SourceIP = l.sourceIP
	}

	jsonBytes, err := json.Marshal(entry)
	if err != nil {
		// Fallback to simple logging if JSON marshaling fails
		fmt.Printf(`{"level":"ERROR","message":"Failed to marshal log entry","error":"%s"}%s`, err.Error(), "\n")
		return
	}
	fmt.Println(string(jsonBytes))
}

// Info logs an informational message
func (l *Logger) Info(message string) {
	l.log(LogEntry{
		Level:   LogLevelInfo,
		Message: message,
	})
}

// Warn logs a warning message
func (l *Logger) Warn(message string) {
	l.log(LogEntry{
		Level:   LogLevelWarn,
		Message: message,
	})
}

// Error logs an error message
func (l *Logger) Error(message string, err error) {
	entry := LogEntry{
		Level:   LogLevelError,
		Message: message,
	}
	if err != nil {
		entry.Error = err.Error()
	}
	l.log(entry)
}

// Debug logs a debug message
func (l *Logger) Debug(message string) {
	l.log(LogEntry{
		Level:   LogLevelDebug,
		Message: message,
	})
}

// LogAuthAttempt logs an authentication attempt
func (l *Logger) LogAuthAttempt(email, method, path string, success bool, reason string) {
	decision := constants.Deny
	if success {
		decision = constants.Allow
	}

	l.log(LogEntry{
		Level:    LogLevelInfo,
		Message:  "Authentication attempt",
		Email:    email,
		Method:   method,
		Path:     path,
		Decision: decision,
		Reason:   reason,
	})
}

// LogAuthZDecision logs an authorization decision
func (l *Logger) LogAuthZDecision(email, method, path string, allowed bool, reason string, durationMs int64) {
	decision := constants.Deny
	level := LogLevelWarn
	if allowed {
		decision = constants.Allow
		level = LogLevelInfo
	}

	l.log(LogEntry{
		Level:      level,
		Message:    "Authorization decision",
		Email:      email,
		Method:     method,
		Path:       path,
		Decision:   decision,
		Reason:     reason,
		DurationMs: durationMs,
	})
}

// LogUserContext logs successful authorization with user context
func (l *Logger) LogUserContext(email, method, path string, userContext map[string]interface{}, durationMs int64) {
	l.log(LogEntry{
		Level:       LogLevelInfo,
		Message:     "Authorization successful",
		Email:       email,
		Method:      method,
		Path:        path,
		Decision:    constants.Allow,
		DurationMs:  durationMs,
		UserContext: userContext,
	})
}

// LogInitialization logs Lambda initialization events
func (l *Logger) LogInitialization(component string, success bool, err error) {
	level := LogLevelInfo
	message := fmt.Sprintf("Initialized %s", component)

	entry := LogEntry{
		Level:   level,
		Message: message,
	}

	if !success {
		level = LogLevelError
		message = fmt.Sprintf("Failed to initialize %s", component)
		entry.Level = level
		entry.Message = message
		if err != nil {
			entry.Error = err.Error()
		}
	}

	l.log(entry)
}

// WithFields adds extra fields to the log entry
func (l *Logger) WithFields(message string, level LogLevel, fields map[string]interface{}) {
	l.log(LogEntry{
		Level:   level,
		Message: message,
		Extra:   fields,
	})
}
