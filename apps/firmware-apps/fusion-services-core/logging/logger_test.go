package logging

import (
	"bytes"
	"log"
	"os"
	"strings"
	"testing"
	"time"
)

func newTestLogger(t *testing.T, config LogConfig) (*Logger, *bytes.Buffer) {
	t.Helper()

	return newTestLoggerWithQueue(t, config, 1000, true)
}

func newTestLoggerWithQueue(t *testing.T, config LogConfig, queueSize int, startWorker bool) (*Logger, *bytes.Buffer) {
	t.Helper()

	var output bytes.Buffer
	l := &Logger{
		config:  config,
		msgChan: make(chan logEvent, queueSize),
	}
	l.initialize()
	l.logger = log.New(&output, "", log.LstdFlags)
	if startWorker {
		l.wg.Add(1)
		go l.processLogs()
	}
	return l, &output
}

func TestFlushWaitsForQueuedMessages(t *testing.T) {
	logger, output := newTestLogger(t, LogConfig{
		NodeName:    "flush",
		MaxFileSize: 100,
		MaxFiles:    3,
		LogLevel:    DEBUG,
	})
	defer logger.Close()

	logger.Info("message %d", 1)
	logger.Flush()

	if got := output.String(); !strings.Contains(got, "[flush] [INFO] message 1") {
		t.Fatalf("flushed output missing message: %q", got)
	}
}

func TestCloseDrainsQueuedMessages(t *testing.T) {
	logger, output := newTestLogger(t, LogConfig{
		NodeName:    "close",
		MaxFileSize: 100,
		MaxFiles:    3,
		LogLevel:    DEBUG,
	})

	logger.Warn("closing message")
	logger.Close()

	if got := output.String(); !strings.Contains(got, "[close] [WARN] closing message") {
		t.Fatalf("closed output missing message: %q", got)
	}
}

func TestLoggerDoesNotCreateLogFiles(t *testing.T) {
	dir := t.TempDir()
	logger, _ := newTestLogger(t, LogConfig{
		NodeName: "stdout-only",
		LogDir:   dir,
		LogLevel: DEBUG,
	})
	defer logger.Close()

	logger.Info("message")
	logger.Flush()

	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("read temp log dir: %v", err)
	}
	if len(entries) != 0 {
		t.Fatalf("expected no logger-managed files, got %d", len(entries))
	}
}

type panicStringer struct{}

func (panicStringer) String() string {
	panic("filtered log message should not be formatted")
}

func TestLogLevelFilteringHappensBeforeFormatting(t *testing.T) {
	logger, output := newTestLogger(t, LogConfig{
		NodeName: "level",
		LogLevel: WARN,
	})
	defer logger.Close()

	logger.Debug("debug value: %s", panicStringer{})
	logger.Info("info value: %s", panicStringer{})
	logger.Warn("kept")
	logger.Flush()

	got := output.String()
	if strings.Contains(got, "debug value") || strings.Contains(got, "info value") {
		t.Fatalf("filtered logs were written: %q", got)
	}
	if !strings.Contains(got, "[level] [WARN] kept") {
		t.Fatalf("warn log missing: %q", got)
	}
}

func TestQueueFullDropsInsteadOfBlockingCaller(t *testing.T) {
	logger, output := newTestLoggerWithQueue(t, LogConfig{
		NodeName: "overflow",
		LogLevel: DEBUG,
	}, 1, false)

	logger.Info("first")

	done := make(chan struct{})
	go func() {
		logger.Info("second")
		close(done)
	}()

	select {
	case <-done:
	case <-time.After(100 * time.Millisecond):
		t.Fatal("log call blocked when async queue was full")
	}

	if dropped := logger.droppedLogs.Load(); dropped != 1 {
		t.Fatalf("expected one dropped log, got %d", dropped)
	}

	logger.wg.Add(1)
	go logger.processLogs()
	logger.Flush()
	logger.Close()

	got := output.String()
	if !strings.Contains(got, "dropped 1 log messages") {
		t.Fatalf("expected dropped log warning, got %q", got)
	}
	if !strings.Contains(got, "[overflow] [INFO] first") {
		t.Fatalf("expected queued log to be written, got %q", got)
	}
	if strings.Contains(got, "[overflow] [INFO] second") {
		t.Fatalf("dropped log was unexpectedly written: %q", got)
	}
}

func TestLogAfterCloseIsIgnored(t *testing.T) {
	logger, output := newTestLogger(t, LogConfig{
		NodeName: "closed",
		LogLevel: DEBUG,
	})

	logger.Info("before close")
	logger.Close()
	logger.Info("after close")
	logger.Flush()

	got := output.String()
	if !strings.Contains(got, "before close") {
		t.Fatalf("queued pre-close log missing: %q", got)
	}
	if strings.Contains(got, "after close") {
		t.Fatalf("post-close log should be ignored: %q", got)
	}
}
