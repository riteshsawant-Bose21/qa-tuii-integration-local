package logging

import core "fusion-services-core/logging"

type LogLevel = core.LogLevel

const (
	DEBUG = core.DEBUG
	INFO  = core.INFO
	WARN  = core.WARN
	ERROR = core.ERROR
	FATAL = core.FATAL
)

var LogLevelStrings = core.LogLevelStrings

type LogConfig = core.LogConfig
type Logger = core.Logger

// InitLogger initializes the global logger instance (only once).
func InitLogger(config LogConfig) {
	core.InitLogger(config)
}

// GetLogger returns the global logger instance.
func GetLogger() *Logger {
	return core.GetLogger()
}

// SetGlobalLogger allows tests (or other code) to override the global logger.
func SetGlobalLogger(l *Logger) {
	core.SetGlobalLogger(l)
}
