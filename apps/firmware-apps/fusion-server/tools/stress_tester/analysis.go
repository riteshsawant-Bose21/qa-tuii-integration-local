package main

import (
	"math"
	"sort"
	"time"
)

// buildListenerResult computes a ListenerResult from raw listener data.
func buildListenerResult(
	name, transport, address string,
	obs []observation,
	seen map[int]int,
	outOfOrder, duplicates, reconnects int,
	sendTimes map[int]time.Time,
	startGain, lastSentGain int,
) ListenerResult {
	lr := ListenerResult{
		Name:            name,
		Transport:       transport,
		Address:         address,
		ReceivedCount:   len(obs),
		DuplicateCount:  duplicates,
		OutOfOrderCount: outOfOrder,
		ReconnectCount:  reconnects,
	}

	if len(obs) > 0 {
		lr.FirstReceivedGain = obs[0].Gain
		lr.LastReceivedGain = obs[len(obs)-1].Gain
	}

	// Latest value check
	_, lr.LatestValueReceived = seen[lastSentGain]

	// Missing gains
	for g := startGain; g <= lastSentGain; g++ {
		if _, ok := seen[g]; !ok {
			lr.MissingGains = append(lr.MissingGains, g)
		}
	}
	lr.MissedCount = len(lr.MissingGains)

	// Latency stats — only for gains that have a known send time
	var latencies []float64
	for _, o := range obs {
		if st, ok := sendTimes[o.Gain]; ok {
			if seen[o.Gain] > 1 {
				// Skip duplicates for latency: only first observation matters.
				// But we record all; take min approach by iterating again below.
			}
			latMs := float64(o.ReceivedAt.Sub(st).Microseconds()) / 1000.0
			latencies = append(latencies, latMs)
		}
	}

	// Deduplicate latencies: keep the minimum for each gain.
	bestLatByGain := make(map[int]float64)
	for _, o := range obs {
		if st, ok := sendTimes[o.Gain]; ok {
			latMs := float64(o.ReceivedAt.Sub(st).Microseconds()) / 1000.0
			if cur, exists := bestLatByGain[o.Gain]; !exists || latMs < cur {
				bestLatByGain[o.Gain] = latMs
			}
		}
	}
	latencies = latencies[:0]
	for _, v := range bestLatByGain {
		latencies = append(latencies, v)
	}

	lr.LatencyStats = computeLatencyStats(latencies)
	return lr
}

// computeLatencyStats computes min/max/avg/p50/p95/p99 from a latency slice.
func computeLatencyStats(latencies []float64) LatencyStats {
	if len(latencies) == 0 {
		return LatencyStats{}
	}

	sort.Float64s(latencies)
	n := len(latencies)

	var sum float64
	for _, v := range latencies {
		sum += v
	}

	return LatencyStats{
		MinMs: latencies[0],
		MaxMs: latencies[n-1],
		AvgMs: sum / float64(n),
		P50Ms: percentile(latencies, 0.50),
		P95Ms: percentile(latencies, 0.95),
		P99Ms: percentile(latencies, 0.99),
	}
}

func percentile(sorted []float64, p float64) float64 {
	if len(sorted) == 0 {
		return 0
	}
	idx := p * float64(len(sorted)-1)
	lower := int(math.Floor(idx))
	upper := int(math.Ceil(idx))
	if lower == upper || upper >= len(sorted) {
		return sorted[lower]
	}
	frac := idx - float64(lower)
	return sorted[lower]*(1-frac) + sorted[upper]*frac
}

// buildAggregateResult summarises results across all listeners.
func buildAggregateResult(results []ListenerResult, sentCount int) AggregateResult {
	agg := AggregateResult{
		TotalListeners: len(results),
		TotalSent:      sentCount,
	}
	if len(results) == 0 {
		return agg
	}

	var allP99 []float64
	for _, r := range results {
		agg.TotalReceived += r.ReceivedCount
		agg.TotalDuplicates += r.DuplicateCount
		agg.TotalOutOfOrder += r.OutOfOrderCount
		agg.TotalMissed += r.MissedCount
		agg.TotalReconnects += r.ReconnectCount
		if r.LatestValueReceived {
			agg.LatestDeliveredCount++
		} else {
			agg.LatestMissedCount++
		}
		allP99 = append(allP99, r.LatencyStats.P99Ms)
	}

	// Worst/best/avg latency across listeners (comparing P99)
	sort.Float64s(allP99)
	agg.BestLatency = results[0].LatencyStats
	agg.WorstLatency = results[0].LatencyStats
	for _, r := range results {
		if r.LatencyStats.P99Ms > agg.WorstLatency.P99Ms {
			agg.WorstLatency = r.LatencyStats
		}
		if r.LatencyStats.P99Ms < agg.BestLatency.P99Ms || agg.BestLatency.P99Ms == 0 {
			agg.BestLatency = r.LatencyStats
		}
	}

	// Average latency across listeners
	var sumAvg, sumP50, sumP95, sumP99, sumMin, sumMax float64
	cnt := float64(len(results))
	for _, r := range results {
		sumMin += r.LatencyStats.MinMs
		sumMax += r.LatencyStats.MaxMs
		sumAvg += r.LatencyStats.AvgMs
		sumP50 += r.LatencyStats.P50Ms
		sumP95 += r.LatencyStats.P95Ms
		sumP99 += r.LatencyStats.P99Ms
	}
	agg.AvgLatency = LatencyStats{
		MinMs: sumMin / cnt,
		MaxMs: sumMax / cnt,
		AvgMs: sumAvg / cnt,
		P50Ms: sumP50 / cnt,
		P95Ms: sumP95 / cnt,
		P99Ms: sumP99 / cnt,
	}

	return agg
}
