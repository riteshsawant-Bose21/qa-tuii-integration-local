package logging

import (
	"fmt"
	"io"
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
	closed      bool
}

var (
	instance *Logger
	once     sync.Once
)

// InitLogger initializes the global logger instance (only once).
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

// GetLogger returns the global logger instance.
func GetLogger() *Logger {
	if instance == nil {
		panic("Logger not initialized. Call InitLogger first")
	}
	return instance
}

// SetGlobalLogger allows tests (or other code) to override the global logger.
func SetGlobalLogger(l *Logger) {
	instance = l
}

func (l *Logger) initialize() {
	if l.initialized {
		return
	}
	l.mu.Lock()
	defer l.mu.Unlock()

	// Set up console logger.
	l.logger = log.New(os.Stdout, "", log.LstdFlags)

	// Create log directory if it doesn't exist.
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
				// File already closed or deleted, continue to create a new file.
				l.logFile = nil
			} else {
				return err
			}
		} else if info.Size() < l.config.MaxFileSize*1024*1024 {
			// File size is under the limit; no need to rotate.
			return nil
		}

		// Close the file before rotating.
		if err := l.logFile.Close(); err != nil {
			l.logger.Printf("Failed to close log file during rotation: %v", err)
		}
		l.logFile = nil
	}

	// Perform rotation.
	for i := l.config.MaxFiles - 1; i > 0; i-- {
		oldPath := filepath.Join(l.config.LogDir, fmt.Sprintf("fusion-%s.%d.log", l.config.NodeName, i))
		newPath := filepath.Join(l.config.LogDir, fmt.Sprintf("fusion-%s.%d.log", l.config.NodeName, i+1))
		os.Rename(oldPath, newPath)
	}

	// Open new log file.
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
	// This goroutine will range over msgChan until it is closed.
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

// log sends the formatted log message to the channel if the logger is not closed.
// If the logger is closed (or if sending to the channel panics), it logs directly.
func (l *Logger) log(level LogLevel, format string, args ...interface{}) {
	if level < l.config.LogLevel {
		return
	}

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	levelStr := LogLevelStrings[level]
	message := fmt.Sprintf(format, args...)
	logMessage := fmt.Sprintf("%s [%s] [%s] %s", timestamp, l.config.NodeName, levelStr, message)

	l.mu.RLock()
	closed := l.closed
	l.mu.RUnlock()
	if closed {
		// Logger is closed; log directly.
		l.mu.RLock()
		l.logger.Println(logMessage)
		if l.fileLogger != nil {
			l.fileLogger.Println(logMessage)
		}
		l.mu.RUnlock()
		return
	}

	// Attempt to send the log message to the channel.
	// Use a deferred recover in case the channel was closed concurrently.
	func() {
		defer func() {
			if r := recover(); r != nil {
				l.mu.RLock()
				l.logger.Println(logMessage)
				if l.fileLogger != nil {
					l.fileLogger.Println(logMessage)
				}
				l.mu.RUnlock()
			}
		}()
		select {
		case l.msgChan <- logMessage:
		default:
			// Channel is full; log directly.
			l.mu.RLock()
			l.logger.Println(logMessage)
			if l.fileLogger != nil {
				l.fileLogger.Println(logMessage)
			}
			l.mu.RUnlock()
		}
	}()
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

// Flush drains the log channel by closing and re-creating it.
// Note: In this implementation, Flush is used only to clear the buffer,
// and does not mark the logger as closed.
func (l *Logger) Flush() {
	l.mu.Lock()
	defer l.mu.Unlock()
	// Close the channel safely if not already closed.
	if !l.closed {
		close(l.msgChan)
		l.msgChan = make(chan string, 1000)
	}
}

// Close marks the logger as closed and closes its channel and file.
func (l *Logger) Close() {
	l.mu.Lock()
	if !l.closed {
		l.closed = true
		close(l.msgChan)
	}
	l.mu.Unlock()

	if l.logFile != nil {
		l.logFile.Close()
	}
}

// NewDummyLogger returns a logger used for testing to avoid panics
func NewDummyLogger() *Logger {
	return &Logger{
		// A dummy configuration; these values won’t really be used.
		config: LogConfig{
			NodeName:    "dummy",
			LogDir:      "",
			MaxFileSize: 1,
			MaxFiles:    1,
			LogLevel:    DEBUG,
		},
		// Use io.Discard so nothing is actually written.
		logger:     log.New(io.Discard, "", 0),
		fileLogger: log.New(io.Discard, "", 0),
		// Create a channel, but mark the logger as closed so it never sends.
		msgChan:     make(chan string, 1000),
		initialized: true,
		closed:      true,
	}
}
