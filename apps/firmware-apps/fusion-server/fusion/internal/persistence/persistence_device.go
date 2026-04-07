package persistence

import (
	"fmt"
	"fusion/internal/api"

	json "github.com/goccy/go-json"
	"strconv"

	"go.etcd.io/bbolt"
)

// GetDeviceInfo retrieves and unmarshals the device info from the database.
func (p *Persistence) GetStoredDeviceInfo() (*api.DevicePatch, error) {
	var info api.DevicePatch
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketDevice))
		if bucket == nil {
			return fmt.Errorf("device bucket not found")
		}
		data := bucket.Get([]byte(keyDeviceInfo))
		if data == nil {
			return fmt.Errorf("device info not found")
		}
		return json.Unmarshal(data, &info)
	})
	if err != nil {
		return nil, err
	}

	return &info, nil
}

// SetDeviceInfo sets the device info in the database.
func (p *Persistence) SetDeviceInfo(info *api.DevicePatch) error {
	data, err := json.Marshal(info)
	if err != nil {
		return fmt.Errorf("failed to marshal device info: %w", err)
	}
	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketDevice))
		if bucket == nil {
			return fmt.Errorf("device bucket not found")
		}
		return bucket.Put([]byte(keyDeviceInfo), data)
	})
}

// GetDeviceName retrieves the "name" attribute.
func (p *Persistence) GetDeviceName(deviceID string) (string, error) {
	return p.getDeviceJSONField(deviceID, "name")
}

// SetDeviceName sets the device name in the database.
func (p *Persistence) SetDeviceName(deviceID, name string) error {
	return p.setDeviceStringField(deviceID, "name", name)
}

// GetDeviceLocation retrieves the "location" attribute.
func (p *Persistence) GetDeviceLocation(deviceID string) (string, error) {
	return p.getDeviceJSONField(deviceID, "location")
}

// SetDeviceLocation sets the device location in the database.
func (p *Persistence) SetDeviceLocation(deviceID, loc string) error {
	return p.setDeviceStringField(deviceID, "location", loc)
}

// getDeviceJSONField opens a read‐only transaction, fetches the raw JSON
// for deviceID, and then extracts exactly the named field (as a string).
func (p *Persistence) getDeviceJSONField(deviceID, field string) (string, error) {
	var value string

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketDevice))
		if b == nil {
			return fmt.Errorf("bucket %q not found", bucketDevice)
		}

		raw := b.Get([]byte(deviceID))
		if raw == nil {
			return fmt.Errorf("device %q not found", deviceID)
		}

		// Decode into a map[string]json.RawMessage so we only unmarshal the one piece we care about
		var m map[string]json.RawMessage
		if err := json.Unmarshal(raw, &m); err != nil {
			return fmt.Errorf("invalid JSON for device %q: %w", deviceID, err)
		}

		fld, ok := m[field]
		if !ok {
			return fmt.Errorf("field %q not found for device %q", field, deviceID)
		}

		if err := json.Unmarshal(fld, &value); err != nil {
			return fmt.Errorf("invalid %q value for device %q: %w", field, deviceID, err)
		}

		return nil
	})

	return value, err
}

// setDeviceStringField updates exactly one JSON string‐valued field for the device.
func (p *Persistence) setDeviceStringField(deviceID, field, newVal string) error {
	return p.db.Update(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketDevice))
		if b == nil {
			return fmt.Errorf("bucket %q not found", bucketDevice)
		}

		key := []byte(deviceID)
		raw := b.Get(key)
		if raw == nil {
			return fmt.Errorf("device %q not found", deviceID)
		}

		var m map[string]json.RawMessage
		if err := json.Unmarshal(raw, &m); err != nil {
			return fmt.Errorf("invalid JSON for device %q: %w", deviceID, err)
		}

		m[field] = json.RawMessage(strconv.Quote(newVal))

		updated, err := json.Marshal(m)
		if err != nil {
			return fmt.Errorf("failed to marshal updated data for device %q: %w", deviceID, err)
		}

		if err := b.Put(key, updated); err != nil {
			return fmt.Errorf("failed to save updated device %q: %w", deviceID, err)
		}
		return nil
	})
}
