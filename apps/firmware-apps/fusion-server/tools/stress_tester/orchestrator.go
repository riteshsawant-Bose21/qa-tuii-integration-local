package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

// Run executes the full stress test lifecycle.
func Run(cfg Config) (*RunResult, error) {
	result := &RunResult{
		StartedAt: time.Now(),
		Config:    cfg,
	}

	// ─── 1. Create writer ───────────────────────────────────────────────
	logNormal(cfg.Verbosity, "Creating %s writer → %s", cfg.WriterMode, cfg.WriterHost)
	writer, err := NewWriter(cfg)
	if err != nil {
		return nil, fmt.Errorf("create writer: %w", err)
	}
	defer writer.Close()

	// ─── 2. Create WebSocket listeners ──────────────────────────────────
	wsListeners := make([]*WSListener, 0, cfg.WSListenerCount)
	for i := 0; i < cfg.WSListenerCount; i++ {
		host := cfg.WSListenerHosts[i%len(cfg.WSListenerHosts)]
		name := fmt.Sprintf("ws-%d", i+1)
		logVerbose(cfg.Verbosity, "  Creating WS listener %s → %s", name, host)
		l, err := NewWSListener(name, host)
		if err != nil {
			closeWSListeners(wsListeners)
			return nil, fmt.Errorf("create ws listener %s: %w", name, err)
		}
		wsListeners = append(wsListeners, l)
	}
	defer closeWSListeners(wsListeners)

	// ─── 3. Create UDP listeners ────────────────────────────────────────
	udpListeners := make([]*UDPListener, 0, cfg.UDPListenerCount)
	for i := 0; i < cfg.UDPListenerCount; i++ {
		bindIP := cfg.UDPListenerBindIPs[i%len(cfg.UDPListenerBindIPs)]
		name := fmt.Sprintf("udp-%d", i+1)
		logVerbose(cfg.Verbosity, "  Creating UDP listener %s bind=%s → %s", name, bindIP, cfg.UDPServerHost)
		l, err := NewUDPListener(name, bindIP, cfg.UDPServerHost)
		if err != nil {
			closeUDPListeners(udpListeners)
			return nil, fmt.Errorf("create udp listener %s: %w", name, err)
		}
		udpListeners = append(udpListeners, l)
	}
	defer closeUDPListeners(udpListeners)

	// ─── 4. Wait for all listeners to be ready ──────────────────────────
	logNormal(cfg.Verbosity, "Waiting for %d WS + %d UDP listeners to be ready...",
		cfg.WSListenerCount, cfg.UDPListenerCount)

	deadline := time.After(cfg.ListenerStartupTimeout)
	for _, l := range wsListeners {
		select {
		case <-l.Ready():
		case <-deadline:
			return nil, fmt.Errorf("timeout waiting for ws listener %s to be ready", l.Name())
		}
	}
	for _, l := range udpListeners {
		select {
		case <-l.Ready():
		case <-l.Stopped():
			return nil, fmt.Errorf("udp listener %s failed during startup: %v", l.Name(), l.Err())
		case <-deadline:
			return nil, fmt.Errorf("timeout waiting for udp listener %s to be ready (err=%v)", l.Name(), l.Err())
		}
	}
	logNormal(cfg.Verbosity, "All listeners ready.")

	// ─── 5. Send loop ───────────────────────────────────────────────────
	sendTimes := &sync.Map{} // int(gain) → time.Time
	var sharedSent atomic.Int64
	var sharedGain atomic.Int64
	sharedGain.Store(int64(cfg.StartGain - 1))
	sendStart := time.Now()

	// Progress ticker
	progressStop := make(chan struct{})
	progressDone := make(chan struct{})
	go func() {
		defer close(progressDone)
		t := time.NewTicker(5 * time.Second)
		defer t.Stop()
		for {
			select {
			case <-t.C:
				wsRx, udpRx := countReceived(wsListeners, udpListeners)
				printProgress(cfg.Verbosity, int(sharedSent.Load()), int(sharedGain.Load()), wsRx, udpRx, time.Since(sendStart))
			case <-progressStop:
				return
			}
		}
	}()

	logNormal(cfg.Verbosity, "Starting send loop: rate=%d/sec  burst=%v", cfg.UpdatesPerSecond, cfg.BurstMode)

	var nextGain, sentCount int
	if cfg.BurstMode {
		nextGain, sentCount = sendBurst(cfg, writer, sendTimes, cfg.StartGain, &sharedSent, &sharedGain)
	} else {
		nextGain, sentCount = sendEven(cfg, writer, sendTimes, cfg.StartGain, &sharedSent, &sharedGain)
	}

	lastSentGain := nextGain - 1
	result.SentCount = sentCount
	result.LastSentGain = lastSentGain
	result.WriterReconnects = writer.Reconnects()

	logNormal(cfg.Verbosity, "Send complete: %d updates sent, last gain=%d (%.1fs)",
		sentCount, lastSentGain, time.Since(sendStart).Seconds())

	// ─── 6. Grace period ────────────────────────────────────────────────
	logNormal(cfg.Verbosity, "Entering grace period (max %s, adaptive=%v)...", cfg.GracePeriod, cfg.AdaptiveGrace)
	waitGracePeriod(cfg, wsListeners, udpListeners, lastSentGain)

	// Stop progress goroutine
	close(progressStop)
	<-progressDone

	logNormal(cfg.Verbosity, "Grace period ended. Collecting results...")

	// ─── 7. Build results ───────────────────────────────────────────────
	// Convert sync.Map to regular map
	sendTimesMap := make(map[int]time.Time)
	sendTimes.Range(func(key, value any) bool {
		sendTimesMap[key.(int)] = value.(time.Time)
		return true
	})

	// WebSocket results
	for _, l := range wsListeners {
		obs, seen, ooo, dups, recon := l.Snapshot()
		lr := buildListenerResult(l.Name(), "websocket", l.Address(), obs, seen, ooo, dups, recon,
			sendTimesMap, cfg.StartGain, lastSentGain)
		result.WebSocketResults = append(result.WebSocketResults, lr)
	}

	// UDP results
	for _, l := range udpListeners {
		obs, seen, ooo, dups := l.Snapshot()
		lr := buildListenerResult(l.Name(), "udp", l.Address(), obs, seen, ooo, dups, 0,
			sendTimesMap, cfg.StartGain, lastSentGain)
		result.UDPResults = append(result.UDPResults, lr)
	}

	// Aggregate
	allResults := append(result.WebSocketResults, result.UDPResults...)
	result.Aggregate = buildAggregateResult(allResults, sentCount)
	result.EndedAt = time.Now()

	return result, nil
}

// sendEven sends updates at an even rate using a ticker.
func sendEven(cfg Config, w Writer, sendTimes *sync.Map, startGain int, sharedSent, sharedGain *atomic.Int64) (nextGain, sent int) {
	interval := time.Second / time.Duration(cfg.UpdatesPerSecond)
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	gain := startGain
	endGain := startGain + cfg.TotalUpdates // exclusive
	var soakDeadline time.Time
	if cfg.SoakMode {
		soakDeadline = time.Now().Add(cfg.SoakDuration)
	}

	var consecutiveErrors int
	const maxLoggedErrors = 5

	for {
		<-ticker.C

		if cfg.SoakMode {
			if time.Now().After(soakDeadline) {
				return gain, sent
			}
		} else {
			if gain >= endGain {
				return gain, sent
			}
		}

		now := time.Now()
		if err := w.Send(gain); err != nil {
			consecutiveErrors++
			if consecutiveErrors <= maxLoggedErrors {
				logVerbose(cfg.Verbosity, "send error gain=%d: %v", gain, err)
			} else if consecutiveErrors == maxLoggedErrors+1 {
				logVerbose(cfg.Verbosity, "  (further send errors suppressed)")
			}
			// Don't advance gain — retry same value next tick
			continue
		}
		if consecutiveErrors > maxLoggedErrors {
			logVerbose(cfg.Verbosity, "  send recovered after %d consecutive errors", consecutiveErrors)
		}
		consecutiveErrors = 0
		sendTimes.Store(gain, now)
		sent++
		sharedSent.Store(int64(sent))
		sharedGain.Store(int64(gain))
		gain++
	}
}

// sendBurst sends updates in bursts: send at BurstMultiplier × rate, then pause.
func sendBurst(cfg Config, w Writer, sendTimes *sync.Map, startGain int, sharedSent, sharedGain *atomic.Int64) (nextGain, sent int) {
	burstRate := int(float64(cfg.UpdatesPerSecond) * cfg.BurstMultiplier)
	burstInterval := time.Second / time.Duration(burstRate)

	// Burst window: send for 1/(BurstMultiplier) of a second, pause remainder.
	burstDuration := time.Second / time.Duration(cfg.BurstMultiplier)
	pauseDuration := time.Second - burstDuration

	gain := startGain
	endGain := startGain + cfg.TotalUpdates
	var soakDeadline time.Time
	if cfg.SoakMode {
		soakDeadline = time.Now().Add(cfg.SoakDuration)
	}

	done := func() bool {
		if cfg.SoakMode {
			return time.Now().After(soakDeadline)
		}
		return gain >= endGain
	}

	var consecutiveErrors int
	const maxLoggedErrors = 5

	for !done() {
		// Burst phase
		burstEnd := time.Now().Add(burstDuration)
		burstTicker := time.NewTicker(burstInterval)
		for time.Now().Before(burstEnd) && !done() {
			<-burstTicker.C
			now := time.Now()
			if err := w.Send(gain); err != nil {
				consecutiveErrors++
				if consecutiveErrors <= maxLoggedErrors {
					logVerbose(cfg.Verbosity, "send error gain=%d: %v", gain, err)
				} else if consecutiveErrors == maxLoggedErrors+1 {
					logVerbose(cfg.Verbosity, "  (further send errors suppressed)")
				}
				continue // retry same gain next tick
			}
			if consecutiveErrors > maxLoggedErrors {
				logVerbose(cfg.Verbosity, "  send recovered after %d consecutive errors", consecutiveErrors)
			}
			consecutiveErrors = 0
			sendTimes.Store(gain, now)
			sent++
			sharedSent.Store(int64(sent))
			sharedGain.Store(int64(gain))
			gain++
		}
		burstTicker.Stop()

		// Pause phase
		if !done() {
			time.Sleep(pauseDuration)
		}
	}

	return gain, sent
}

// waitGracePeriod waits up to GracePeriod for late arrivals.
// In adaptive mode, it exits early if all listeners have received lastSentGain.
func waitGracePeriod(cfg Config, wsListeners []*WSListener, udpListeners []*UDPListener, lastSentGain int) {
	deadline := time.After(cfg.GracePeriod)
	poll := time.NewTicker(2 * time.Second)
	defer poll.Stop()

	for {
		select {
		case <-deadline:
			return
		case <-poll.C:
			if !cfg.AdaptiveGrace {
				continue
			}
			if allReceivedLatest(wsListeners, udpListeners, lastSentGain) {
				logNormal(cfg.Verbosity, "All listeners received final gain %d — ending grace early.", lastSentGain)
				return
			}
		}
	}
}

func allReceivedLatest(wsListeners []*WSListener, udpListeners []*UDPListener, lastGain int) bool {
	for _, l := range wsListeners {
		_, seen, _, _, _ := l.Snapshot()
		if _, ok := seen[lastGain]; !ok {
			return false
		}
	}
	for _, l := range udpListeners {
		_, seen, _, _ := l.Snapshot()
		if _, ok := seen[lastGain]; !ok {
			return false
		}
	}
	return true
}

func countReceived(wsListeners []*WSListener, udpListeners []*UDPListener) (int, int) {
	wsCount := 0
	for _, l := range wsListeners {
		obs, _, _, _, _ := l.Snapshot()
		wsCount += len(obs)
	}
	udpCount := 0
	for _, l := range udpListeners {
		obs, _, _, _ := l.Snapshot()
		udpCount += len(obs)
	}
	return wsCount, udpCount
}

func closeWSListeners(listeners []*WSListener) {
	for _, l := range listeners {
		l.Close()
	}
}

func closeUDPListeners(listeners []*UDPListener) {
	for _, l := range listeners {
		l.Close()
	}
}
