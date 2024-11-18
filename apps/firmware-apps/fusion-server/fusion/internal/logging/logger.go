package logging

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type LogLevel int

const (
	DEBUG LogLevel = iota
	INFO
	WARN
	ERROR
)

type Logger struct {
	nodeName    string
	logFile     *os.File
	logger      *log.Logger
	fileLogger  *log.Logger
	logLevel    LogLevel
	mu          sync.Mutex
	initialized bool
}

var (
	instance *Logger
	once     sync.Once
)

func GetLogger(nodeName string) *Logger {
	once.Do(func() {
		instance = &Logger{
			nodeName: nodeName,
			logLevel: INFO,
		}
		instance.initialize()
	})
	return instance
}

func (l *Logger) initialize() {
	if l.initialized {
		return
	}

	l.mu.Lock()
	defer l.mu.Unlock()

	// Set up console logger
	l.logger = log.New(os.Stdout, "", log.LstdFlags)

	// Set up file logger
	logDir := "/var/log/fusion"
	if err := os.MkdirAll(logDir, 0755); err != nil {
		l.logger.Printf("Failed to create log directory: %v", err)
		return
	}

	logPath := filepath.Join(logDir, fmt.Sprintf("fusion-%s.log", l.nodeName))
	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		l.logger.Printf("Failed to open log file: %v", err)
		return
	}

	l.logFile = file
	l.fileLogger = log.New(file, "", log.LstdFlags)
	l.initialized = true
}

func (l *Logger) log(level LogLevel, format string, args ...interface{}) {
	if level < l.logLevel {
		return
	}

	l.mu.Lock()
	defer l.mu.Unlock()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	levelStr := [...]string{"DEBUG", "INFO", "WARN", "ERROR"}[level]
	message := fmt.Sprintf(format, args...)
	logMessage := fmt.Sprintf("%s [%s] [%s] %s", timestamp, l.nodeName, levelStr, message)

	l.logger.Println(logMessage)
	if l.fileLogger != nil {
		l.fileLogger.Println(logMessage)
	}
}

func (l *Logger) Debug(format string, args ...interface{}) {
	l.log(DEBUG, format, args...)
}

func (l *Logger) Info(format string, args ...interface{}) {
	l.log(INFO, format, args...)
}

func (l *Logger) Warn(format string, args ...interface{}) {
	l.log(WARN, format, args...)
}

func (l *Logger) Error(format string, args ...interface{}) {
	l.log(ERROR, format, args...)
}

func (l *Logger) SetLogLevel(level LogLevel) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.logLevel = level
}

func (l *Logger) Close() {
	if l.logFile != nil {
		l.logFile.Close()
	}
}
