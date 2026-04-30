package stresstester

import "time"

// RunResult is the top-level result written as JSON.
type RunResult struct {
	StartedAt time.Time `json:"started_at"`
	EndedAt   time.Time `json:"ended_at"`
	Config    Config    `json:"config"`

	SentCount        int             `json:"sent_count"`
	LastSentGain     int             `json:"last_sent_gain"`
	WriterReconnects int             `json:"writer_reconnects"`
	ProfileResults   []ProfileResult `json:"profile_results,omitempty"`

	WebSocketResults []ListenerResult `json:"websocket_results"`
	UDPResults       []ListenerResult `json:"udp_results"`

	Aggregate AggregateResult `json:"aggregate"`
}

// ListenerResult holds per-listener observation metrics.
type ListenerResult struct {
	Name                string       `json:"name"`
	Transport           string       `json:"transport"`
	Address             string       `json:"address"`
	ReceivedCount       int          `json:"received_count"`
	DuplicateCount      int          `json:"duplicate_count"`
	OutOfOrderCount     int          `json:"out_of_order_count"`
	MissedCount         int          `json:"missed_count"`
	ReconnectCount      int          `json:"reconnect_count"`
	LatestValueReceived bool         `json:"latest_value_received"`
	FirstReceivedGain   int          `json:"first_received_gain"`
	LastReceivedGain    int          `json:"last_received_gain"`
	LatencyStats        LatencyStats `json:"latency_stats"`
	MissingGains        []int        `json:"missing_gains"`
}

// LatencyStats holds percentile latency information.
type LatencyStats struct {
	MinMs float64 `json:"min_ms"`
	MaxMs float64 `json:"max_ms"`
	AvgMs float64 `json:"avg_ms"`
	P50Ms float64 `json:"p50_ms"`
	P95Ms float64 `json:"p95_ms"`
	P99Ms float64 `json:"p99_ms"`
}

// AggregateResult summarises results across all listeners.
type AggregateResult struct {
	TotalListeners       int          `json:"total_listeners"`
	TotalSent            int          `json:"total_sent"`
	TotalReceived        int          `json:"total_received"`
	TotalDuplicates      int          `json:"total_duplicates"`
	TotalOutOfOrder      int          `json:"total_out_of_order"`
	TotalMissed          int          `json:"total_missed"`
	TotalReconnects      int          `json:"total_reconnects"`
	LatestDeliveredCount int          `json:"latest_delivered_count"`
	LatestMissedCount    int          `json:"latest_missed_count"`
	WorstLatency         LatencyStats `json:"worst_latency"`
	BestLatency          LatencyStats `json:"best_latency"`
	AvgLatency           LatencyStats `json:"avg_latency"`
}

type ProfileResult struct {
	Host       string `json:"host"`
	Started    bool   `json:"started"`
	Stopped    bool   `json:"stopped"`
	Active     bool   `json:"active"`
	Path       string `json:"path,omitempty"`
	StartError string `json:"start_error,omitempty"`
	StopError  string `json:"stop_error,omitempty"`
}

// observation is an internal record captured by listeners.
type observation struct {
	Gain       int
	ReceivedAt time.Time
}
