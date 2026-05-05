package logging

import (
	"fmt"
	"log"
	"os"
	"sync"
	"sync/atomic"
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

type logEvent struct {
	message string
	flush   chan struct{}
}

type Logger struct {
	config      LogConfig
	logger      *log.Logger
	mu          sync.RWMutex
	msgChan     chan logEvent
	wg          sync.WaitGroup
	droppedLogs atomic.Uint64
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
			msgChan: make(chan logEvent, 1000),
		}
		instance.initialize()
		instance.wg.Add(1)
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

func (l *Logger) Debug(format string, args ...any) {
	l.log(DEBUG, format, args...)
}

func (l *Logger) Info(format string, args ...any) {
	l.log(INFO, format, args...)
}

func (l *Logger) Warn(format string, args ...any) {
	l.log(WARN, format, args...)
}

func (l *Logger) Error(format string, args ...any) {
	l.log(ERROR, format, args...)
}

func (l *Logger) Fatal(format string, args ...any) {
	l.log(FATAL, format, args...)
	l.Flush()
	os.Exit(1)
}

// Flush waits until all log messages queued before this call have been written.
func (l *Logger) Flush() {
	flush := make(chan struct{})

	l.mu.RLock()
	if l.closed || l.msgChan == nil {
		l.mu.RUnlock()
		return
	}

	l.msgChan <- logEvent{flush: flush}
	l.mu.RUnlock()

	<-flush
}

// Close marks the logger as closed and drains queued messages.
func (l *Logger) Close() {
	l.mu.Lock()
	if !l.closed {
		l.closed = true
		close(l.msgChan)
	}
	l.mu.Unlock()

	l.wg.Wait()
}

func (l *Logger) initialize() {
	if l.initialized {
		return
	}
	l.mu.Lock()
	defer l.mu.Unlock()

	// Set up console logger.
	l.logger = log.New(os.Stdout, "", log.LstdFlags)

	l.initialized = true
}

func (l *Logger) processLogs() {
	defer l.wg.Done()

	for event := range l.msgChan {
		if event.flush != nil {
			close(event.flush)
			continue
		}

		l.writeLog(event.message)
	}
}

func (l *Logger) writeLog(msg string) {
	if dropped := l.droppedLogs.Swap(0); dropped > 0 {
		l.writeLogLine(fmt.Sprintf("[%s] [WARN] dropped %d log messages because the async log queue was full", l.config.NodeName, dropped))
	}
	l.writeLogLine(msg)
}

func (l *Logger) writeLogLine(msg string) {
	l.logger.Println(msg)
}

// log formats and queues a log message. If the async queue is full, the
// message is dropped instead of being written synchronously from the caller.
func (l *Logger) log(level LogLevel, format string, args ...any) {

	if level < l.config.LogLevel {
		return
	}

	levelStr := LogLevelStrings[level]
	message := fmt.Sprintf(format, args...)
	logMessage := fmt.Sprintf("[%s] [%s] %s", l.config.NodeName, levelStr, message)

	l.mu.RLock()
	if l.closed || l.msgChan == nil {
		l.mu.RUnlock()
		return
	}

	if level == FATAL {
		l.msgChan <- logEvent{message: logMessage}
		l.mu.RUnlock()
		return
	}

	select {
	case l.msgChan <- logEvent{message: logMessage}:
	default:
		l.droppedLogs.Add(1)
	}
	l.mu.RUnlock()
}
