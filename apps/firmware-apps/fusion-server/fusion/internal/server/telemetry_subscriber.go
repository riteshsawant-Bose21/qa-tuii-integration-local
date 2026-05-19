package server

import (
	"bytes"
	"context"
	"fmt"
	"sync"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/pubsub"

	"github.com/go-zeromq/zmq4"
	json "github.com/goccy/go-json"
)

const (
	zmqReconnectBaseDelay = 1 * time.Second
	zmqReconnectMaxDelay  = 30 * time.Second

	zmqShutdownMsg = "TelemetrySubscriber: shutting down subscription to %s"
)

// TelemetrySubscriber manages per-device ZMQ SUB connections on the VIP node.
// When the VIP is gained, call Start() with all current cluster device IPs.
// When the VIP is lost, call Stop(). Use Reconcile() when cluster membership changes.
//
// Each device gets its own goroutine + ZMQ SUB socket. Incoming meter_data messages
// are fanned into the hub so BroadcastMessage → routeMeterData can distribute them
// to the correct WebSocket clients based on their registered filters.
type TelemetrySubscriber struct {
	hub     *pubsub.Hub
	zmqPort string

	mu      sync.Mutex
	devices map[string]context.CancelFunc // deviceIP → cancel for its goroutine
}

// NewTelemetrySubscriber creates a TelemetrySubscriber that will connect to ZMQ PUB
// sockets on the given port on each device added to it.
func NewTelemetrySubscriber(hub *pubsub.Hub, zmqPort string) *TelemetrySubscriber {
	return &TelemetrySubscriber{
		hub:     hub,
		zmqPort: zmqPort,
		devices: make(map[string]context.CancelFunc),
	}
}

// Start subscribes to ZMQ PUB on each IP in deviceIPs. It is idempotent: IPs
// already subscribed are skipped; any previously subscribed IP not in deviceIPs
// is cancelled (Reconcile behaviour).
func (t *TelemetrySubscriber) Start(deviceIPs []string) {
	t.mu.Lock()
	defer t.mu.Unlock()

	wanted := make(map[string]bool, len(deviceIPs))
	for _, ip := range deviceIPs {
		wanted[ip] = true
	}

	for ip, cancel := range t.devices {
		if !wanted[ip] {
			cancel()
			delete(t.devices, ip)
		}
	}

	for _, ip := range deviceIPs {
		if _, exists := t.devices[ip]; !exists {
			t.subscribeDevice(ip)
		}
	}
}

// Reconcile updates subscriptions to match deviceIPs.
func (t *TelemetrySubscriber) Reconcile(deviceIPs []string) {
	t.Start(deviceIPs)
}

// Stop cancels all active device subscriptions.
func (t *TelemetrySubscriber) Stop() {
	t.mu.Lock()
	defer t.mu.Unlock()

	for ip, cancel := range t.devices {
		cancel()
		delete(t.devices, ip)
	}
	logging.GetLogger().Debug("TelemetrySubscriber: stopped all ZMQ subscriptions")
}

// subscribeDevice spins up a goroutine that maintains a ZMQ SUB connection to
// the device and feeds received meter_data messages into the hub.
// Must be called with t.mu held.
func (t *TelemetrySubscriber) subscribeDevice(deviceIP string) {
	ctx, cancel := context.WithCancel(context.Background())
	t.devices[deviceIP] = cancel

	go t.listenLoop(ctx, deviceIP)
	logging.GetLogger().Debug("TelemetrySubscriber: subscribing to %s:%s", deviceIP, t.zmqPort)
}

// listenLoop connects to a single ZMQ PUB socket and reads meter_data messages.
// On transient errors it reconnects with exponential backoff until the context
// is cancelled (clean shutdown via Stop or Reconcile).
func (t *TelemetrySubscriber) listenLoop(ctx context.Context, deviceIP string) {
	logger := logging.GetLogger()
	addr := fmt.Sprintf("tcp://%s:%s", deviceIP, t.zmqPort)
	delay := zmqReconnectBaseDelay

	for {
		if ctx.Err() != nil {
			logger.Debug(zmqShutdownMsg, addr)
			return
		}

		connStart := time.Now()
		err := t.connectAndRecv(ctx, deviceIP, addr)
		if ctx.Err() != nil {
			logger.Debug(zmqShutdownMsg, addr)
			return
		}

		if time.Since(connStart) > zmqReconnectMaxDelay {
			delay = zmqReconnectBaseDelay
		}

		// Transient error — back off and retry
		logger.Debug("TelemetrySubscriber: connection to %s lost (%v), reconnecting in %s", addr, err, delay)

		select {
		case <-time.After(delay):
			delay = min(delay*2, zmqReconnectMaxDelay)
		case <-ctx.Done():
			logger.Debug(zmqShutdownMsg, addr)
			return
		}
	}
}

// connectAndRecv establishes a ZMQ SUB connection and reads messages until an
// error occurs or the context is cancelled. Returns the error that caused exit.
func (t *TelemetrySubscriber) connectAndRecv(ctx context.Context, deviceIP, addr string) error {
	logger := logging.GetLogger()

	sub := zmq4.NewSub(ctx)
	defer sub.Close()

	if err := sub.Dial(addr); err != nil {
		return fmt.Errorf("failed to dial: %w", err)
	}

	if err := sub.SetOption(zmq4.OptionSubscribe, ""); err != nil {
		return fmt.Errorf("failed to set subscribe option: %w", err)
	}

	logger.Debug("TelemetrySubscriber: connected to %s", addr)

	for {
		msg, err := sub.Recv()
		if err != nil {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			return fmt.Errorf("recv error: %w", err)
		}

		if len(msg.Frames) == 0 {
			continue
		}

		t.handleMessage(deviceIP, msg.Frames[0])
	}
}

// meterDataMarker is used for a fast pre-check to avoid JSON parsing
// messages that are clearly not meter_data.
var meterDataMarker = []byte(`"meter_data"`)

// handleMessage parses a raw ZMQ frame and routes it to WebSocket clients via the hub.
func (t *TelemetrySubscriber) handleMessage(deviceIP string, raw []byte) {
	logger := logging.GetLogger()

	if !bytes.Contains(raw, meterDataMarker) {
		return
	}

	var msg model.MeterDataMessage
	if err := json.Unmarshal(raw, &msg); err != nil {
		logger.Error("TelemetrySubscriber: failed to unmarshal meter_data from %s: %v", deviceIP, err)
		return
	}

	if msg.MessageName != "meter_data" {
		return
	}

	t.hub.BroadcastToObservers(api.NewNotifyMessage(api.NotifyOpMeterData, deviceIP, func(m *api.NotifyMessage) {
		m.MeterData = &msg
	}))
}
