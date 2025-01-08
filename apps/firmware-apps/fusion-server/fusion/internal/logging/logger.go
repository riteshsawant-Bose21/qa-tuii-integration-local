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
	FATAL
)

var LogLevelStrings = map[LogLevel]string{
	DEBUG: "DEBUG",
	INFO:  "INFO",
	WARN:  "WARN",
	ERROR: "ERROR",
	FATAL: "FATAL",
}

type LogConfig struct {
	NodeName    string
	LogDir      string
	MaxFileSize int64
	MaxFiles    int
	LogLevel    LogLevel
}

type Logger struct {
	config      LogConfig
	logFile     *os.File
	logger      *log.Logger
	fileLogger  *log.Logger
	mu          sync.RWMutex
	msgChan     chan string
	initialized bool
}

var (
	instance *Logger
	once     sync.Once
)

func InitLogger(config LogConfig) {
	once.Do(func() {
		instance = &Logger{
			config:  config,
			msgChan: make(chan string, 1000),
		}
		instance.initialize()
		go instance.processLogs()
	})
}

func GetLogger() *Logger {
	if instance == nil {
		panic("Logger not initialized. Call InitLogger first")
	}
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

	// Create log directory if it doesn't exist
	if err := os.MkdirAll(l.config.LogDir, 0755); err != nil {
		l.logger.Printf("Failed to create log directory: %v", err)
		return
	}

	if err := l.rotateLogFileIfNeeded(); err != nil {
		l.logger.Printf("Failed to setup log file: %v", err)
		return
	}

	l.initialized = true
}

func (l *Logger) rotateLogFileIfNeeded() error {
	if l.logFile != nil {
		info, err := l.logFile.Stat()
		if err != nil {
			if os.IsNotExist(err) {
				// File already closed or deleted, continue to create a new file
				l.logFile = nil
			} else {
				return err
			}
		} else if info.Size() < l.config.MaxFileSize*1024*1024 {
			// File size is under the limit, no need to rotate
			return nil
		}

		// Close the file before rotating
		if err := l.logFile.Close(); err != nil {
			l.logger.Printf("Failed to close log file during rotation: %v", err)
		}
		l.logFile = nil
	}

	// Perform rotation
	for i := l.config.MaxFiles - 1; i > 0; i-- {
		oldPath := filepath.Join(l.config.LogDir, fmt.Sprintf("fusion-%s.%d.log", l.config.NodeName, i))
		newPath := filepath.Join(l.config.LogDir, fmt.Sprintf("fusion-%s.%d.log", l.config.NodeName, i+1))
		os.Rename(oldPath, newPath)
	}

	// Open new log file
	logPath := filepath.Join(l.config.LogDir, fmt.Sprintf("fusion-%s.1.log", l.config.NodeName))
	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return err
	}

	l.logFile = file
	l.fileLogger = log.New(file, "", log.LstdFlags)
	return nil
}

func (l *Logger) processLogs() {
	for msg := range l.msgChan {
		l.mu.RLock()
		if l.fileLogger != nil {
			if err := l.rotateLogFileIfNeeded(); err != nil {
				l.logger.Printf("Failed to rotate log file: %v", err)
			}
			l.fileLogger.Println(msg)
		}
		l.logger.Println(msg)
		l.mu.RUnlock()
	}
}

func (l *Logger) log(level LogLevel, format string, args ...interface{}) {
	if level < l.config.LogLevel {
		return
	}

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	levelStr := LogLevelStrings[level]
	message := fmt.Sprintf(format, args...)
	logMessage := fmt.Sprintf("%s [%s] [%s] %s", timestamp, l.config.NodeName, levelStr, message)

	select {
	case l.msgChan <- logMessage:
	default:
		// Channel is full, log directly
		l.mu.RLock()
		l.logger.Println(logMessage)
		if l.fileLogger != nil {
			l.fileLogger.Println(logMessage)
		}
		l.mu.RUnlock()
	}
}

func (l *Logger) Flush() {
	l.mu.Lock()
	defer l.mu.Unlock()

	close(l.msgChan)
	l.msgChan = make(chan string, 1000)
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

func (l *Logger) Fatal(format string, args ...interface{}) {
	l.log(FATAL, format, args...)
	time.Sleep(50 * time.Millisecond)
	os.Exit(1)
}

func (l *Logger) Close() {
	close(l.msgChan)
	if l.logFile != nil {
		l.logFile.Close()
	}
}
