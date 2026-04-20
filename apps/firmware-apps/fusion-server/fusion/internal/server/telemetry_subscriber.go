package server

import (
	"context"
	"fmt"
	"sync"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/pubsub"

	"github.com/go-zeromq/zmq4"
	json "github.com/goccy/go-json"
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

	// Remove stale (IPs no longer in cluster)
	for ip, cancel := range t.devices {
		if !wanted[ip] {
			cancel()
			delete(t.devices, ip)
		}
	}

	// Add new
	for _, ip := range deviceIPs {
		if _, exists := t.devices[ip]; !exists {
			t.subscribeDevice(ip)
		}
	}
}

// Reconcile updates subscriptions to match deviceIPs — equivalent to Start.
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
	logging.GetLogger().Info("TelemetrySubscriber: stopped all ZMQ subscriptions")
}

// subscribeDevice spins up a goroutine that maintains a ZMQ SUB connection to
// the device and feeds received meter_data messages into the hub.
// Must be called with t.mu held.
func (t *TelemetrySubscriber) subscribeDevice(deviceIP string) {
	ctx, cancel := context.WithCancel(context.Background())
	t.devices[deviceIP] = cancel

	addr := fmt.Sprintf("ws://%s:%s", deviceIP, t.zmqPort)
	go t.listenLoop(ctx, deviceIP, addr)
	logging.GetLogger().Info("TelemetrySubscriber: subscribing to %s", addr)
}

// listenLoop connects to a single ZMQ PUB socket and reads meter_data messages
// until the context is cancelled or a fatal socket error occurs.
func (t *TelemetrySubscriber) listenLoop(ctx context.Context, deviceIP, addr string) {
	logger := logging.GetLogger()

	sub := zmq4.NewSub(ctx)
	defer sub.Close()

	if err := sub.Dial(addr); err != nil {
		logger.Error("TelemetrySubscriber: failed to dial %s: %v", addr, err)
		return
	}

	// Subscribe to all topics (empty string = receive everything)
	if err := sub.SetOption(zmq4.OptionSubscribe, ""); err != nil {
		logger.Error("TelemetrySubscriber: failed to set subscribe option for %s: %v", addr, err)
		return
	}

	logger.Info("TelemetrySubscriber: connected to %s", addr)

	for {
		msg, err := sub.Recv()
		if err != nil {
			// Context cancelled → clean shutdown
			if ctx.Err() != nil {
				logger.Info("TelemetrySubscriber: shutting down subscription to %s", addr)
				return
			}
			logger.Error("TelemetrySubscriber: recv error from %s: %v", addr, err)
			return
		}

		if len(msg.Frames) == 0 {
			continue
		}

		t.handleMessage(deviceIP, msg.Frames[0])
	}
}

// handleMessage parses a raw ZMQ frame and routes it to WebSocket clients via the hub.
func (t *TelemetrySubscriber) handleMessage(deviceIP string, raw []byte) {
	logger := logging.GetLogger()

	// Quick pre-check: only handle meter_data messages
	var envelope struct {
		MessageName string `json:"message_name"`
	}
	if err := json.Unmarshal(raw, &envelope); err != nil {
		logger.Error("TelemetrySubscriber: failed to parse message from %s: %v", deviceIP, err)
		return
	}
	if envelope.MessageName != "meter_data" {
		return
	}

	var msg api.MeterDataMessage
	if err := json.Unmarshal(raw, &msg); err != nil {
		logger.Error("TelemetrySubscriber: failed to unmarshal meter_data from %s: %v", deviceIP, err)
		return
	}

	t.hub.BroadcastToObservers(api.NewNotifyMessage(api.NotifyOpMeterData, deviceIP, func(m *api.NotifyMessage) {
		m.MeterData = &msg
	}))
}
