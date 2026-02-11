// Package log provides logging configuration and setup for the application.
package log

import (
	"os"
	"path/filepath"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
)

// LoggerConfig holds configuration for setting up application loggers.
type LoggerConfig struct {
	Mode        string // "debug" or "release"
	LogDir      string // Base directory for logs
	AuditConfig RotationConfig
	AppConfig   RotationConfig
}

// RotationConfig holds configuration for log file rotation.
type RotationConfig struct {
	MaxSize    int  // MB
	MaxAge     int  // Days
	MaxBackups int  // Number of backups
	Compress   bool // Compress rotated files
}

// Loggers holds the configured application loggers.
type Loggers struct {
	AuditLogger *zap.Logger
	AppLogger   *zap.Logger
}

// DefaultLoggerConfig returns a default configuration
func DefaultLoggerConfig() *LoggerConfig {
	return &LoggerConfig{
		Mode:   "debug",
		LogDir: "/var/log/fusion-core",
		AuditConfig: RotationConfig{
			MaxSize:    50, // 50MB
			MaxAge:     30, // 30 days
			MaxBackups: 10, // Keep 10 backups
			Compress:   true,
		},
		AppConfig: RotationConfig{
			MaxSize:    100, // 100MB
			MaxAge:     7,   // 7 days
			MaxBackups: 5,   // Keep 5 backups
			Compress:   true,
		},
	}
}

// NewLoggers creates both audit and application loggers with lumberjack rotation
func NewLoggers(cfg *LoggerConfig) (*Loggers, error) {
	// Ensure log directories exist
	auditDir := filepath.Join(cfg.LogDir, "audit")
	appDir := filepath.Join(cfg.LogDir, "application")

	if err := os.MkdirAll(auditDir, 0750); err != nil {
		return nil, err
	}
	if err := os.MkdirAll(appDir, 0750); err != nil {
		return nil, err
	}

	// Create lumberjack writers
	auditWriter := &lumberjack.Logger{
		Filename:   filepath.Join(auditDir, "audit.log"),
		MaxSize:    cfg.AuditConfig.MaxSize,
		MaxAge:     cfg.AuditConfig.MaxAge,
		MaxBackups: cfg.AuditConfig.MaxBackups,
		Compress:   cfg.AuditConfig.Compress,
	}

	appWriter := &lumberjack.Logger{
		Filename:   filepath.Join(appDir, "app.log"),
		MaxSize:    cfg.AppConfig.MaxSize,
		MaxAge:     cfg.AppConfig.MaxAge,
		MaxBackups: cfg.AppConfig.MaxBackups,
		Compress:   cfg.AppConfig.Compress,
	}

	// Configure encoder
	var encoderConfig zapcore.EncoderConfig
	if cfg.Mode == "release" {
		encoderConfig = zap.NewProductionEncoderConfig()
	} else {
		encoderConfig = zap.NewDevelopmentEncoderConfig()
	}
	encoderConfig.TimeKey = "timestamp"
	encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder

	encoder := zapcore.NewJSONEncoder(encoderConfig)

	// Create cores for different log levels
	var auditLevel, appLevel zapcore.Level
	if cfg.Mode == "release" {
		auditLevel = zapcore.InfoLevel
		appLevel = zapcore.InfoLevel
	} else {
		auditLevel = zapcore.DebugLevel
		appLevel = zapcore.DebugLevel
	}

	// Create audit logger core (for request/response logs, auth events)
	auditCore := zapcore.NewCore(
		encoder,
		zapcore.AddSync(auditWriter),
		auditLevel,
	)

	// Create application logger core (for general app logs)
	appCore := zapcore.NewCore(
		encoder,
		zapcore.AddSync(appWriter),
		appLevel,
	)

	// Add console output for development mode
	if cfg.Mode != "release" {
		consoleEncoder := zapcore.NewConsoleEncoder(encoderConfig)
		consoleCore := zapcore.NewCore(
			consoleEncoder,
			zapcore.AddSync(os.Stdout),
			zapcore.DebugLevel,
		)

		// Combine with console output for development
		auditCore = zapcore.NewTee(auditCore, consoleCore)
		appCore = zapcore.NewTee(appCore, consoleCore)
	}

	// Create loggers
	auditLogger := zap.New(auditCore, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))
	appLogger := zap.New(appCore, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))

	return &Loggers{
		AuditLogger: auditLogger,
		AppLogger:   appLogger,
	}, nil
}

// Close cleanly closes both loggers
func (l *Loggers) Close() {
	if l.AuditLogger != nil {
		_ = l.AuditLogger.Sync() // Logger sync errors are not critical during shutdown
	}
	if l.AppLogger != nil {
		_ = l.AppLogger.Sync() // Logger sync errors are not critical during shutdown
	}
}
