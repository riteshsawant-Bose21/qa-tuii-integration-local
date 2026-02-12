package main

import (
	"fusion-services-core/logging"
	"testing"
)

func TestLogLevelStringsConsistency(t *testing.T) {
	tests := []struct {
		level    logging.LogLevel
		expected string
	}{
		{logging.DEBUG, "DEBUG"},
		{logging.INFO, "INFO"},
		{logging.WARN, "WARN"},
		{logging.ERROR, "ERROR"},
		{logging.FATAL, "FATAL"},
	}

	for _, tt := range tests {
		if got := logging.LogLevelStrings[tt.level]; got != tt.expected {
			t.Errorf("logLevelStrings[%d] = %q; want %q", tt.level, got, tt.expected)
		}
	}
}
