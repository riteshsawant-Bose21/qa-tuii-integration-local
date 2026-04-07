package log

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Logger provides the methods for leveled structured logging.
type Logger struct {
	zap *zap.Logger
}

// NewProduction returns a new Logger meant for production use.
// This logger will log anything info level and above.
func NewProduction() (*Logger, error) {
	z, err := zap.NewProduction(zap.AddCallerSkip(1))
	if err != nil {
		return nil, fmt.Errorf("can't initialize zap: %v", err)
	}

	return &Logger{
		zap: z,
	}, nil
}

// Error logs a message at ErrorLevel.
func (l *Logger) Error(msg string, fields ...zapcore.Field) {
	l.zap.Error(msg, fields...)
}

// Fatal logs a message at FatalLevel and then immediately exits the program.
func (l *Logger) Fatal(msg string, fields ...zapcore.Field) {
	l.zap.Fatal(msg, fields...)
}

// Info logs a message at InfoLevel.
func (l *Logger) Info(msg string, fields ...zapcore.Field) {
	l.zap.Info(msg, fields...)
}

// Warn logs a message at WarnLevel.
func (l *Logger) Warn(msg string, fields ...zapcore.Field) {
	l.zap.Warn(msg, fields...)
}

// JobSyncLog returns the underlying zap logger for job synchronization logging.
func (l *Logger) JobSyncLog() *zap.Logger {
	return l.zap
}

// GetLogger extracts the logger from the gin context.
// If the logger is not found, it returns the global zap logger as a fallback.
func GetLogger(c *gin.Context) *zap.Logger {
	loggerVal, exists := c.Get("logger")
	if !exists {
		return zap.L()
	}
	logger, ok := loggerVal.(*zap.Logger)
	if !ok {
		return zap.L()
	}
	return logger
}
