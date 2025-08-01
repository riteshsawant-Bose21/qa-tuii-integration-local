package xyte

import (
	"encoding/json"
	"fmt"
	"fusion-cloud/internal/model"
	"io"
	"net/http"
	"strings"
)

func (c *Client) ClaimDevice(dvcObj *model.ClaimDeviceRequest) (*model.Device, error) {
	payloadBytes, err := json.Marshal(dvcObj)
	if err != nil {
		return nil, fmt.Errorf("error marshaling payload: %w", err)
	}
	payload := strings.NewReader(string(payloadBytes))

	resp, err := c.MakeRequest("devices/claim", http.MethodPost, payload, nil)
	if err != nil {
		return nil, fmt.Errorf("error making POST request: %w", err)
	}
	defer resp.Close()
	var s model.Device
	bodyBytes, err := io.ReadAll(resp)
	if err != nil {
		return nil, fmt.Errorf("error reading response body: %w", err)
	}
	if len(bodyBytes) == 0 {
		return nil, fmt.Errorf("empty response body")
	}
	if err := json.Unmarshal(bodyBytes, &s); err != nil {
		return nil, fmt.Errorf("error decode json: %w", err)
	}

	return &s, nil
}

func (c *Client) GetAllDevices() (*model.Device, error) {
	body := io.Reader(nil) // No body needed for GET request
	resp, err := c.MakeRequest("devices", http.MethodGet, body, nil)
	if err != nil {
		return nil, fmt.Errorf("error making GET request: %w", err)
	}
	defer resp.Close()

	var dvc model.Device
	if err := json.NewDecoder(resp).Decode(&dvc); err != nil {
		return nil, fmt.Errorf("error decode json: %w", err)
	}
	return &dvc, nil
}

func (c *Client) GetDeviceHistories(device *model.DeviceRequest) (*model.DeviceHistory, error) {
	queryParams := map[string]string{
		"device_id": device.ID,
	}
	if device.Status != "" {
		queryParams["status"] = device.Status
	}
	if device.FromTime != "" {
		queryParams["from_time"] = device.FromTime
	}
	if device.ToTime != "" {
		queryParams["to_time"] = device.ToTime
	}
	if device.SpaceID != "" {
		queryParams["space_id"] = device.SpaceID
	}
	resp, err := c.MakeRequest("devices/histories", http.MethodGet, nil, queryParams)
	if err != nil {
		return nil, fmt.Errorf("error making GET request: %w", err)
	}
	defer resp.Close()

	var histories *model.DeviceHistory
	if err := json.NewDecoder(resp).Decode(&histories); err != nil {
		return nil, fmt.Errorf("error decode json: %w", err)
	}

	return histories, nil
}
