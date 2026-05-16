package api

import (
	"time"
)

// WebSocketStats represents connection and usage statistics.
type WebSocketStats struct {
	Connections    int              `json:"connections"`                // Active connections
	Messages       int64            `json:"messages"`                   // Total messages processed
	Errors         int64            `json:"errors"`                     // Total errors
	Uptime         time.Duration    `json:"uptime"`                     // Server uptime
	LastReset      time.Time        `json:"last_reset"`                 // Stats last reset
	MessagesByType map[string]int64 `json:"messages_by_type,omitempty"` // Messages by type
}
