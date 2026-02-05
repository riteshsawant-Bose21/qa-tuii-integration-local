package log

import (
	"fmt"

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
