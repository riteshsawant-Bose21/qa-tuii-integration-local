package cluster

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"math"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"
)

const (
	httpTimeout             = 2 * time.Second
	latencyEndpoint         = "/metrics/latency"
	latencyAveragesEndpoint = "/metrics/latency/averages"
)

var httpClient = &http.Client{
	Timeout: httpTimeout,
}

type aggregatedKey struct {
	Sender, Operation string
}

// SyncLatency holds synchronization latency information
type SyncLatency struct {
	Sender    string    `json:"sender"`
	Receiver  string    `json:"receiver"`
	Operation string    `json:"operation"`
	Latency   float64   `json:"latency_ms"`
	Timestamp time.Time `json:"timestamp"`
}

type rollingStats struct {
	TotalLatency float64
	Count        int
	LastUpdated  time.Time
}

type LatencyStore struct {
	mu         sync.RWMutex
	records    []SyncLatency
	maxRecords int
	maxAge     time.Duration
	aggregated map[aggregatedKey]*rollingStats
}

func NewLatencyStore(maxRecords int, maxAge time.Duration) *LatencyStore {
	s := &LatencyStore{
		records:    make([]SyncLatency, 0),
		maxRecords: maxRecords,
		maxAge:     maxAge,
		aggregated: make(map[aggregatedKey]*rollingStats),
	}
	go s.cleanupLoop()
	return s
}

// Add inserts a new record and updates rolling stats.
func (s *LatencyStore) Add(record SyncLatency) {
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

func (s *LatencyStore) pruneLocked() {
	// Prune by age
	cutoff := time.Now().Add(-s.maxAge)

	// in-place filter
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

	// drop stale aggregates
	for key, stats := range s.aggregated {
		if stats.LastUpdated.Before(cutoff) {
			delete(s.aggregated, key)
		}
	}
}

func (s *LatencyStore) GetAll() []SyncLatency {
	s.mu.RLock()
	defer s.mu.RUnlock()
	// Append to nil to force a copy of the underlying slice
	return append([]SyncLatency(nil), s.records...)
}

type AggregatedLatency struct {
	Sender    string    `json:"sender"`
	Operation string    `json:"operation"`
	AverageMs float64   `json:"average_ms"`
	Count     int       `json:"count"`
	UpdatedAt time.Time `json:"updated_at"`
}

// GetAverages returns all current averages in a stable order.
func (s *LatencyStore) GetAverages() []AggregatedLatency {
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

func (c *Cluster) HandleGetLatencies(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllLatencies())
}

func (c *Cluster) HandleGetLatencyAverages(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllLatencyAverages())
}

func (c *Cluster) HandleGetNTPSkew(w http.ResponseWriter, r *http.Request) {
	c.delegate.mu.RLock()
	defer c.delegate.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c.delegate.timeSkews)
}

func (c *Cluster) getNodeAddresses() []string {
	var addrs []string
	for _, ip := range c.getClusterIPs() {
		addr := fmt.Sprintf("%s:%s", ip, api.HTTPPort)
		addrs = append(addrs, addr)
	}
	return addrs
}

func fetchFromPeers[T any](
	addrs []string,
	selfIP, endpoint string,
	localFn func() []T,
	decodeFn func(io.Reader) ([]T, error),
) []T {
	var (
		wg  sync.WaitGroup
		mu  sync.Mutex
		all []T
	)

	for _, addr := range addrs {
		wg.Add(1)
		addr := addr
		go func() {
			defer wg.Done()

			var items []T
			if strings.HasPrefix(addr, selfIP) {
				items = localFn()
			} else {
				resp, err := httpClient.Get("http://" + addr + endpoint)
				if err != nil {
					logging.GetLogger().Error("failed to GET peer metrics: %v", err)
					return
				}
				// close immediately after decode
				defer resp.Body.Close()

				items, err = decodeFn(resp.Body)
				if err != nil {
					logging.GetLogger().Error("failed to decode peer metrics: %v", err)
					return
				}
			}

			mu.Lock()
			all = append(all, items...)
			mu.Unlock()
		}()
	}

	wg.Wait()
	return all
}

func (c *Cluster) fetchAllLatencies() []SyncLatency {
	addrs := c.getNodeAddresses()
	selfIP := c.Memberlist.LocalNode().Addr.String()

	return fetchFromPeers(
		addrs, selfIP, latencyEndpoint,

		func() []SyncLatency {
			return c.delegate.latencies.GetAll()
		},

		func(r io.Reader) ([]SyncLatency, error) {
			var xs []SyncLatency
			return xs, json.NewDecoder(r).Decode(&xs)
		},
	)
}

func (c *Cluster) fetchAllLatencyAverages() []AggregatedLatency {
	addrs := c.getNodeAddresses()
	selfIP := c.Memberlist.LocalNode().Addr.String()

	return fetchFromPeers(
		addrs, selfIP, latencyAveragesEndpoint,
		func() []AggregatedLatency {
			return c.delegate.latencies.GetAverages()
		},
		func(r io.Reader) ([]AggregatedLatency, error) {
			var xs []AggregatedLatency
			return xs, json.NewDecoder(r).Decode(&xs)
		},
	)
}

// cleanupLoop periodically prunes to avoid unbounded growth.
func (s *LatencyStore) cleanupLoop() {
	ticker := time.NewTicker(s.maxAge / 2)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		s.pruneLocked()
		s.mu.Unlock()
	}
}
