//go:build darwin

package network

import (
	"context"
	"errors"
	"time"

	"github.com/go-ble/ble"
)

type goBLETransport struct {
	device        ble.Device
	serviceUUID   ble.UUID
	characterUUID ble.UUID
	bridge        *bluetoothBridge
}

type goBLENotificationSession struct {
	ctx   context.Context
	close func() error
	write func([]byte) error
}

func (s goBLENotificationSession) Context() context.Context { return s.ctx }
func (s goBLENotificationSession) Close() error             { return s.close() }
func (s goBLENotificationSession) Write(data []byte) error  { return s.write(data) }

func newGoBLETransport(name string, serviceUUID string, characterUUID string, bridge *bluetoothBridge) (*goBLETransport, error) {
	d, err := newBLEDevice(name)
	if err != nil {
		return nil, err
	}
	ble.SetDefaultDevice(d)

	return &goBLETransport{
		device:        d,
		serviceUUID:   ble.MustParse(serviceUUID),
		characterUUID: ble.MustParse(characterUUID),
		bridge:        bridge,
	}, nil
}

func (t *goBLETransport) serve(ctx context.Context) error {
	svc := ble.NewService(t.serviceUUID)
	char := ble.NewCharacteristic(t.characterUUID)
	char.Property = ble.CharRead | ble.CharWrite | ble.CharNotify

	char.HandleWrite(ble.WriteHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		incoming := append([]byte(nil), req.Data()...)
		rsp.SetStatus(ble.ErrSuccess)
		t.bridge.handleWrite(incoming)
	}))

	char.HandleNotify(ble.NotifyHandlerFunc(func(req ble.Request, n ble.Notifier) {
		t.bridge.runNotificationSession(goBLENotificationSession{
			ctx:   n.Context(),
			close: req.Conn().Close,
			write: func(data []byte) error {
				_, err := n.Write(data)
				return err
			},
		})
	}))

	svc.AddCharacteristic(char)
	ble.AddService(svc)

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			err := ble.AdvertiseNameAndServices(ctx, bluetoothDeviceName, svc.UUID)
			if err == nil {
				continue
			}
			if errors.Is(err, context.Canceled) {
				return err
			}
			t.bridge.logger.Error("BLE advertising failed: %v. Retrying in %d seconds", err, bleRetryTime)
			time.Sleep(bleRetryTime)
		}
	}
}

func (t *goBLETransport) stop() {
	t.device.Stop()
}
