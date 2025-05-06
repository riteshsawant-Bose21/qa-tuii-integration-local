package cluster

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/routes"
	"io"
	"math"
	"net"
	"net/http"
	"sort"
	"sync"
	"time"
)

const (
	dialTimeout          = 1 * time.Second
	httpTimeout          = 2 * time.Second
	rttThreshold         = 50.0
	syncLatencyThreshold = 100.0
	tickerTime           = 10 * time.Second
)

var httpClient = &http.Client{
	Timeout: httpTimeout,
}

// aggregatedKey is used to group sync latency records by sender and operation.
type aggregatedKey struct {
	Sender, Operation string
}

// failureStats holds count and last‐seen timestamp of dial failures.
type failureStats struct {
	Count       int       // total failures
	LastFailure time.Time // most recent failure time
}

type NodeLatencyStatus struct {
	Node            string  `json:"node"`
	HighRTT         bool    `json:"high_rtt"`
	RTT             float64 `json:"rtt_ms,omitempty"`
	FailureCount    int     `json:"failure_count,omitempty"`
	HighSyncLatency bool    `json:"high_sync_latency"`
	AvgSyncLatency  float64 `json:"avg_sync_latency_ms,omitempty"`
}

// NetworkLatency holds network round-trip time between two cluster nodes.
type NetworkLatency struct {
	Source    string    `json:"source"`    // Node initiating the measurement
	Target    string    `json:"target"`    // Node being measured
	RTT       float64   `json:"rtt_ms"`    // Round-trip time in milliseconds
	Timestamp time.Time `json:"timestamp"` // Time of measurement
}

// NetworkLatencyStore stores historical network latency measurements.
type NetworkLatencyStore struct {
	mu         sync.RWMutex
	records    []NetworkLatency
	failures   map[string]*failureStats
	maxRecords int
	maxAge     time.Duration
}

// NewNetworkLatencyStore creates a NetworkLatencyStore that keeps at most
// maxRecords entries no older than maxAge, and spawns a background cleanup.
func NewNetworkLatencyStore(maxRecords int, maxAge time.Duration) *NetworkLatencyStore {
	s := &NetworkLatencyStore{
		records:    make([]NetworkLatency, 0, maxRecords),
		failures:   make(map[string]*failureStats),
		maxRecords: maxRecords,
		maxAge:     maxAge,
	}
	go s.cleanupLoop()
	return s
}

// Add inserts a new NetworkLatency and prunes stale or excess records.
func (s *NetworkLatencyStore) Add(record NetworkLatency) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.records = append(s.records, record)
	s.pruneLocked()
}

// GetAll returns a snapshot of current records.
func (s *NetworkLatencyStore) GetAll() []NetworkLatency {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return append([]NetworkLatency(nil), s.records...)
}

// pruneLocked must be called with the write‐lock held. It drops
// entries older than maxAge and, if still over capacity, the oldest ones.
func (s *NetworkLatencyStore) pruneLocked() {
	cutoff := time.Now().Add(-s.maxAge)

	i := 0
	for _, rec := range s.records {
		if rec.Timestamp.After(cutoff) {
			s.records[i] = rec
			i++
		}
	}
	s.records = s.records[:i]

	if len(s.records) > s.maxRecords {
		s.records = s.records[len(s.records)-s.maxRecords:]
	}

	// Prune stale failures
	for tgt, fs := range s.failures {
		if fs.LastFailure.Before(cutoff) {
			delete(s.failures, tgt)
		}
	}
}

// RecordFailure increments the failure count for a given target.
func (s *NetworkLatencyStore) RecordFailure(target string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	fs := s.failures[target]
	if fs == nil {
		fs = &failureStats{}
		s.failures[target] = fs
	}
	fs.Count++
	fs.LastFailure = time.Now()
}

// GetFailures returns a snapshot of current failure stats.
func (s *NetworkLatencyStore) GetFailures() map[string]failureStats {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make(map[string]failureStats, len(s.failures))
	for tgt, fs := range s.failures {
		out[tgt] = *fs
	}
	return out
}

// cleanupLoop runs periodically to pruneLocked without waiting for Add().
func (s *NetworkLatencyStore) cleanupLoop() {
	ticker := time.NewTicker(s.maxAge / 2)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		s.pruneLocked()
		s.mu.Unlock()
	}
}

// SyncLatency represents a single synchronization latency measurement.
type SyncLatency struct {
	Sender    string    `json:"sender"`     // Node that sent the message
	Receiver  string    `json:"receiver"`   // Node that received the message
	Operation string    `json:"operation"`  // Operation name (e.g., config_update)
	Latency   float64   `json:"latency_ms"` // Latency in milliseconds
	Timestamp time.Time `json:"timestamp"`  // Time of measurement
}

// rollingStats maintains aggregate latency stats for a specific sender/operation.
type rollingStats struct {
	TotalLatency float64   // Sum of latencies for averaging
	Count        int       // Number of samples
	LastUpdated  time.Time // Last update timestamp
}

// SyncLatencyStore stores sync latency metrics and rolling aggregates.
type SyncLatencyStore struct {
	mu         sync.RWMutex
	records    []SyncLatency
	maxRecords int
	maxAge     time.Duration
	aggregated map[aggregatedKey]*rollingStats
}

// NewSyncLatencyStore initializes a new SyncLatencyStore with given limits.
func NewSyncLatencyStore(maxRecords int, maxAge time.Duration) *SyncLatencyStore {
	s := &SyncLatencyStore{
		records:    make([]SyncLatency, 0),
		maxRecords: maxRecords,
		maxAge:     maxAge,
		aggregated: make(map[aggregatedKey]*rollingStats),
	}
	go s.cleanupLoop()
	return s
}

// Add inserts a new sync latency record and updates rolling stats.
func (s *SyncLatencyStore) Add(record SyncLatency) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.records = append(s.records, record)
	s.pruneLocked()

	key := aggregatedKey{record.Sender, record.Operation}
	stats := s.aggregated[key]
	if stats == nil {
		stats = &rollingStats{}
		s.aggregated[key] = stats
	}
	stats.TotalLatency += record.Latency
	stats.Count++
	stats.LastUpdated = time.Now()
}

// pruneLocked removes old sync latency records and stale aggregates.
func (s *SyncLatencyStore) pruneLocked() {
	cutoff := time.Now().Add(-s.maxAge)

	i := 0
	for _, rec := range s.records {
		if rec.Timestamp.After(cutoff) {
			s.records[i] = rec
			i++
		}
	}
	s.records = s.records[:i]
	if len(s.records) > s.maxRecords {
		s.records = s.records[len(s.records)-s.maxRecords:]
	}

	for key, stats := range s.aggregated {
		if stats.LastUpdated.Before(cutoff) {
			delete(s.aggregated, key)
		}
	}
}

// GetAll returns a copy of all stored sync latency records.
func (s *SyncLatencyStore) GetAll() []SyncLatency {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return append([]SyncLatency(nil), s.records...)
}

// AggregatedLatency holds average latency stats for a sender/operation.
type AggregatedLatency struct {
	Sender    string    `json:"sender"`     // Sender node name
	Operation string    `json:"operation"`  // Operation type
	AverageMs float64   `json:"average_ms"` // Average latency in ms
	Count     int       `json:"count"`      // Number of samples
	UpdatedAt time.Time `json:"updated_at"` // Last update time
}

// GetAverages returns aggregated sync latency stats sorted by sender and operation.
func (s *SyncLatencyStore) GetAverages() []AggregatedLatency {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var out []AggregatedLatency
	for k, stats := range s.aggregated {
		if stats.Count == 0 {
			continue
		}
		avg := math.Round((stats.TotalLatency/float64(stats.Count))*100) / 100
		out = append(out, AggregatedLatency{
			Sender:    k.Sender,
			Operation: k.Operation,
			AverageMs: avg,
			Count:     stats.Count,
			UpdatedAt: stats.LastUpdated,
		})
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Sender == out[j].Sender {
			return out[i].Operation < out[j].Operation
		}
		return out[i].Sender < out[j].Sender
	})
	return out
}

// HandleGetNetworkLatency returns all network latencies across the cluster.
func (c *Cluster) HandleGetNetworkLatency(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllNetworkLatencies())
}

// HandleGetNetworkLatency returns network latencies for the calling instance.
func (c *Cluster) HandleGetNetworkLatencyLocal(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.delegate.networkLatencies.GetAll())
}

// HandleGetSyncLatency returns all sync latencies across the cluster.
func (c *Cluster) HandleGetSyncLatency(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllSyncLatencies())
}

// HandleGetSyncLatencyLocal returns all sync latencies for the calling instance.
func (c *Cluster) HandleGetSyncLatencyLocal(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.delegate.syncLatencies.GetAll())
}

// HandleGetSyncLatencyAverages returns aggregated sync latency statistics.
func (c *Cluster) HandleGetSyncLatencyAverages(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllSyncLatencyAverages())
}

// HandleGetSyncLatencyAverages returns aggregated sync latency statistics for the calling instance.
func (c *Cluster) HandleGetSyncLatencyAveragesLocal(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.delegate.syncLatencies.GetAverages())
}

// HandleGetNTPSkew returns recorded NTP time skews from the skew store.
func (c *Cluster) HandleGetNTPSkew(w http.ResponseWriter, r *http.Request) {
	c.delegate.skewStore.mu.RLock()
	defer c.delegate.skewStore.mu.RUnlock()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c.delegate.skewStore.timeSkews)
}

// HandleGetNetworkFailures returns overall failure counts across the cluster
func (c *Cluster) HandleGetNetworkFailures(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllNetworkFailures())
}

// HandleGetNetworkFailuresLocal gets local failures only
func (c *Cluster) HandleGetNetworkFailuresLocal(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.delegate.networkLatencies.GetFailures())
}

// HandleGetLatencyStatus gets latency status
func (c *Cluster) HandleGetLatencyStatus(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllLatencyStatus())
}

// HandleGetLatencyStatus gets local latency status
func (c *Cluster) HandleGetLatencyStatusLocal(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.getLocalLatencyStatus())
}

func (c *Cluster) fetchAllNetworkFailures() []map[string]failureStats {
	return fetchAll(
		c,
		func() []map[string]failureStats {
			return []map[string]failureStats{c.delegate.networkLatencies.GetFailures()}
		},
		routes.ClusterLatencyNetworkFailuresLocalEndpoint,
	)
}

func (c *Cluster) fetchAllLatencyStatus() []NodeLatencyStatus {
	return fetchAll(
		c,
		c.getLocalLatencyStatus,
		routes.ClusterLatencyStatusLocalEndpoint,
	)
}

func (c *Cluster) getNodeAdminAddresses() []string {
	var addrs []string
	for _, member := range c.Memberlist.Members() {
		host := member.Addr.String()
		addrs = append(addrs, net.JoinHostPort(host, api.AdminPort))
	}
	return addrs
}

func (c *Cluster) getLocalEndpointResponse(addr, endpoint string) (response *http.Response, err error) {

	url := fmt.Sprintf("http://%s%s", addr, endpoint)
	resp, err := httpClient.Get(url)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("unexpected status %d", resp.StatusCode)
	}

	return resp, nil
}

func (c *Cluster) getLocalLatencyStatus() []NodeLatencyStatus {

	self := c.Memberlist.LocalNode().Addr.String()
	status := NodeLatencyStatus{Node: self}

	// Use last RTT to each peer
	latencies := c.delegate.networkLatencies.GetAll()
	for _, rec := range latencies {
		if rec.Source == self {
			if rec.RTT > status.RTT {
				status.RTT = rec.RTT
			}
		}
	}
	status.HighRTT = status.RTT > rttThreshold

	// Failures
	failures := c.delegate.networkLatencies.GetFailures()
	if f, ok := failures[self]; ok {
		status.FailureCount = f.Count
	}

	// Sync latency
	avgs := c.delegate.syncLatencies.GetAverages()
	for _, avg := range avgs {
		if avg.Sender == self && avg.AverageMs > status.AvgSyncLatency {
			status.AvgSyncLatency = avg.AverageMs
		}
	}
	status.HighSyncLatency = status.AvgSyncLatency > syncLatencyThreshold

	return []NodeLatencyStatus{status}
}

// decodeSlice will close the body and unmarshal into the pointer v (which
// must be a pointer to a slice, e.g. *[]NetworkLatency).
func decodeSlice(body io.ReadCloser, v any) error {
	defer body.Close()
	return json.NewDecoder(body).Decode(v)
}

func (c *Cluster) hostIsLocal(addr string) bool {
	host, _, _ := net.SplitHostPort(addr)
	return host == c.Memberlist.LocalNode().Addr.String()
}

// fetchAll is a package-level generic function.
func fetchAll[T any](
	c *Cluster,
	localFn func() []T,
	endpoint string,
) []T {
	var all []T
	logger := logging.GetLogger()

	for _, addr := range c.getNodeAdminAddresses() {
		if c.hostIsLocal(addr) {
			all = append(all, localFn()...)
			continue
		}
		var remote []T
		if err := fetchAndDecode(c, addr, endpoint, &remote); err != nil {
			url := fmt.Sprintf("http://%s%s", addr, endpoint)
			logger.Error("GET %s failed: %v", url, err)
			continue
		}
		all = append(all, remote...)
	}
	return all
}

// fetchAndDecode is also a generic package-level function.
// It reuses your getLocalEndpointResponse + decodeSlice logic.
func fetchAndDecode[T any](
	c *Cluster,
	addr, endpoint string,
	dest *[]T,
) error {
	resp, err := c.getLocalEndpointResponse(addr, endpoint)
	if err != nil {
		return err
	}
	return decodeSlice(resp.Body, dest)
}

func (c *Cluster) fetchAllNetworkLatencies() []NetworkLatency {
	return fetchAll(
		c,
		c.delegate.networkLatencies.GetAll,
		routes.ClusterLatencyNetworkLocalEndpoint,
	)
}

func (c *Cluster) fetchAllSyncLatencies() []SyncLatency {
	return fetchAll(
		c,
		c.delegate.syncLatencies.GetAll,
		routes.ClusterLatencySyncLocalEndpoint,
	)
}

func (c *Cluster) fetchAllSyncLatencyAverages() []AggregatedLatency {
	return fetchAll(
		c,
		c.delegate.syncLatencies.GetAverages,
		routes.ClusterLatencySyncAveragesLocalEndpoint,
	)
}

// cleanupLoop periodically prunes old records and aggregates.
func (s *SyncLatencyStore) cleanupLoop() {
	ticker := time.NewTicker(s.maxAge / 2)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		s.pruneLocked()
		s.mu.Unlock()
	}
}

// measureRTT performs a TCP dial to the target and returns the round-trip time in ms.
func measureRTT(target string) (float64, error) {
	start := time.Now()
	conn, err := net.DialTimeout("tcp", target, tcpTimeout)
	if err != nil {
		return 0, err
	}
	_ = conn.Close()
	return float64(time.Since(start).Milliseconds()), nil
}

func (c *Cluster) startNetworkLatencyProbes() {

	go func() {
		ticker := time.NewTicker(tickerTime)
		defer ticker.Stop()

		logger := logging.GetLogger()

		addr := c.Memberlist.LocalNode().Addr.String()
		selfHost, _, err := net.SplitHostPort(addr)
		if err != nil {
			// Assume it's just an IP with no port
			selfHost = addr
		}

		for range ticker.C {
			for _, ip := range c.getClusterIPs() {
				// Skip self
				if ip == selfHost {
					continue
				}

				target := net.JoinHostPort(ip, api.HTTPPort)
				rtt, err := measureRTT(target)
				if err != nil {
					logger.Error("RTT error to %s: %v", target, err)
					c.delegate.networkLatencies.RecordFailure(ip)
					continue
				}

				c.delegate.networkLatencies.Add(NetworkLatency{
					Source:    selfHost,
					Target:    ip,
					RTT:       rtt,
					Timestamp: time.Now(),
				})
			}
		}
	}()
}
