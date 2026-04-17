package main

import (
	"fmt"
	"os"
	"time"

	json "github.com/goccy/go-json"
)

// writeJSONReport marshals RunResult to a file.
func writeJSONReport(path string, result *RunResult) error {
	data, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal report: %w", err)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		return fmt.Errorf("write report: %w", err)
	}
	return nil
}

// printProgress prints a one-line progress update.
func printProgress(v Verbosity, sent, lastGain int, wsCount, udpCount int, elapsed time.Duration) {
	if v == VerbosityQuiet {
		return
	}
	fmt.Printf("[%s] sent=%d  gain=%d  ws_rx=%d  udp_rx=%d\n",
		elapsed.Truncate(time.Second), sent, lastGain, wsCount, udpCount)
}

// printSummary prints the final console summary.
func printSummary(result *RunResult) {
	dur := result.EndedAt.Sub(result.StartedAt).Truncate(time.Millisecond)
	fmt.Println()
	fmt.Println("=================================================================")
	fmt.Println("  STRESS TEST SUMMARY")
	fmt.Println("=================================================================")
	fmt.Printf("  Duration:       %s\n", dur)
	fmt.Printf("  Writer mode:    %s\n", result.Config.WriterMode)
	fmt.Printf("  Target rate:    %d updates/sec\n", result.Config.UpdatesPerSecond)
	fmt.Printf("  Sent:           %d  (last gain = %d)\n", result.SentCount, result.LastSentGain)
	fmt.Println()

	printListenerTable("WebSocket Listeners", result.WebSocketResults)
	printListenerTable("UDP Listeners", result.UDPResults)

	agg := result.Aggregate
	fmt.Println("-----------------------------------------------------------------")
	fmt.Println("  AGGREGATE")
	fmt.Println("-----------------------------------------------------------------")
	fmt.Printf("  Listeners:      %d total\n", agg.TotalListeners)
	fmt.Printf("  Received:       %d total\n", agg.TotalReceived)
	fmt.Printf("  Missed:         %d total\n", agg.TotalMissed)
	fmt.Printf("  Duplicates:     %d total\n", agg.TotalDuplicates)
	fmt.Printf("  Out-of-order:   %d total\n", agg.TotalOutOfOrder)
	fmt.Printf("  Latest value:   %d delivered / %d missed\n", agg.LatestDeliveredCount, agg.LatestMissedCount)
	fmt.Printf("  Avg latency:    p50=%.2fms  p95=%.2fms  p99=%.2fms\n",
		agg.AvgLatency.P50Ms, agg.AvgLatency.P95Ms, agg.AvgLatency.P99Ms)
	fmt.Printf("  Worst latency:  p99=%.2fms  max=%.2fms\n",
		agg.WorstLatency.P99Ms, agg.WorstLatency.MaxMs)
	fmt.Println("=================================================================")

	if agg.LatestMissedCount > 0 {
		fmt.Println()
		fmt.Println("  WARNING: Not all listeners received the latest value!")
	}
}

func printListenerTable(header string, results []ListenerResult) {
	if len(results) == 0 {
		return
	}
	fmt.Printf("  %s\n", header)
	fmt.Println("  ---------------------------------------------------------------")
	fmt.Printf("  %-14s %6s %6s %5s %5s %8s %8s %8s %s\n",
		"Name", "Recv", "Miss", "Dup", "OoO", "P50ms", "P95ms", "P99ms", "Latest?")
	for _, r := range results {
		latest := "YES"
		if !r.LatestValueReceived {
			latest = "NO (ERR)"
		}
		fmt.Printf("  %-14s %6d %6d %5d %5d %8.2f %8.2f %8.2f %s\n",
			r.Name, r.ReceivedCount, r.MissedCount, r.DuplicateCount,
			r.OutOfOrderCount, r.LatencyStats.P50Ms, r.LatencyStats.P95Ms,
			r.LatencyStats.P99Ms, latest)
	}
	fmt.Println()
}

// logVerbose prints a message only in verbose mode.
func logVerbose(v Verbosity, format string, args ...any) {
	if v == VerbosityVerbose {
		fmt.Printf(format+"\n", args...)
	}
}

// logNormal prints a message in normal or verbose mode.
func logNormal(v Verbosity, format string, args ...any) {
	if v != VerbosityQuiet {
		fmt.Printf(format+"\n", args...)
	}
}
