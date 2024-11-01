package logging

import (
	"fmt"
	"log"
	"os"
	"sync"
)

// DebugLogger provides debug logging functionality
type DebugLogger struct {
	sync.Mutex
	logger  *log.Logger
	enabled bool
}

// NewDebugLogger creates a new debug logger
func NewDebugLogger(prefix string) *DebugLogger {
	return &DebugLogger{
		logger:  log.New(os.Stdout, fmt.Sprintf("[DEBUG-%s] ", prefix), log.LstdFlags),
		enabled: true,
	}
}

// SetEnabled enables or disables debug logging
func (d *DebugLogger) SetEnabled(enabled bool) {
	d.Lock()
	defer d.Unlock()
	d.enabled = enabled
}

// Printf logs a formatted debug message if debug logging is enabled
func (d *DebugLogger) Printf(format string, v ...interface{}) {
	d.Lock()
	defer d.Unlock()
	if d.enabled {
		d.logger.Printf(format, v...)
	}
}

// LogFilter implements io.Writer for filtering log messages
type LogFilter struct {
	MinLevel int
	Writer   *log.Logger
}

// Write implements io.Writer
func (f *LogFilter) Write(p []byte) (n int, err error) {
	if len(p) > 0 && int(p[0]) >= f.MinLevel {
		return f.Writer.Writer().Write(p)
	}
	return len(p), nil
}

// NewLogFilter creates a new log filter with the specified minimum level
func NewLogFilter(minLevel int, prefix string) *LogFilter {
	return &LogFilter{
		MinLevel: minLevel,
		Writer:   log.New(os.Stdout, prefix, log.LstdFlags),
	}
}

// Debug logs a debug message
func (d *DebugLogger) Debug(msg string) {
	d.Printf("DEBUG: %s", msg)
}

// Info logs an info message
func (d *DebugLogger) Info(msg string) {
	d.Printf("INFO: %s", msg)
}

// Warning logs a warning message
func (d *DebugLogger) Warning(msg string) {
	d.Printf("WARNING: %s", msg)
}

// Error logs an error message
func (d *DebugLogger) Error(msg string) {
	d.Printf("ERROR: %s", msg)
}

// LogState logs the current state of a component
func (d *DebugLogger) LogState(component string, state interface{}) {
	d.Printf("STATE[%s]: %+v", component, state)
}

// WithContext returns a new debug logger with added context
func (d *DebugLogger) WithContext(context string) *DebugLogger {
	return &DebugLogger{
		logger:  log.New(os.Stdout, fmt.Sprintf("%s[%s] ", d.logger.Prefix(), context), log.LstdFlags),
		enabled: d.enabled,
	}
}
