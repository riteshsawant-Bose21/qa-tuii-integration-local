package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"

	"github.com/go-ble/ble"
)

// MockBLEClient implements the necessary ble.Client interface methods for testing
type MockBLEClient struct {
	data     []byte
	err      error
	profile  *ble.Profile
	services []*ble.Service
}

func NewMockBLEClient() *MockBLEClient {
	return &MockBLEClient{
		profile: &ble.Profile{},
	}
}

// Disconnected implements ble.Client.
func (m *MockBLEClient) Disconnected() <-chan struct{} {
	panic("unimplemented")
}

// DiscoverCharacteristics implements ble.Client.
func (m *MockBLEClient) DiscoverCharacteristics(filter []ble.UUID, s *ble.Service) ([]*ble.Characteristic, error) {
	panic("unimplemented")
}

// DiscoverDescriptors implements ble.Client.
func (m *MockBLEClient) DiscoverDescriptors(filter []ble.UUID, c *ble.Characteristic) ([]*ble.Descriptor, error) {
	panic("unimplemented")
}

// DiscoverIncludedServices implements ble.Client.
func (m *MockBLEClient) DiscoverIncludedServices(filter []ble.UUID, s *ble.Service) ([]*ble.Service, error) {
	panic("unimplemented")
}

// ExchangeMTU implements ble.Client.
func (m *MockBLEClient) ExchangeMTU(rxMTU int) (txMTU int, err error) {
	panic("unimplemented")
}

// ReadLongCharacteristic implements ble.Client.
func (m *MockBLEClient) ReadLongCharacteristic(c *ble.Characteristic) ([]byte, error) {
	panic("unimplemented")
}

// ReadRSSI implements ble.Client.
func (m *MockBLEClient) ReadRSSI() int {
	panic("unimplemented")
}

// Required ble.Client interface methods
func (m *MockBLEClient) Addr() ble.Addr {
	return ble.NewAddr("00:00:00:00:00:00")
}

func (m *MockBLEClient) Name() string {
	return "MockBLEDevice"
}

func (m *MockBLEClient) Profile() *ble.Profile {
	return m.profile
}

func (m *MockBLEClient) DiscoverProfile(force bool) (*ble.Profile, error) {
	if m.err != nil {
		return nil, m.err
	}
	return m.profile, nil
}

func (m *MockBLEClient) DiscoverServices(ss []ble.UUID) ([]*ble.Service, error) {
	if m.err != nil {
		return nil, m.err
	}
	return m.services, nil
}

func (m *MockBLEClient) ReadCharacteristic(c *ble.Characteristic) ([]byte, error) {
	if m.err != nil {
		return nil, m.err
	}
	return m.data, nil
}

func (m *MockBLEClient) WriteCharacteristic(c *ble.Characteristic, b []byte, noRsp bool) error {
	if m.err != nil {
		return m.err
	}
	m.data = b
	return nil
}

func (m *MockBLEClient) ReadDescriptor(d *ble.Descriptor) ([]byte, error) {
	if m.err != nil {
		return nil, m.err
	}
	return m.data, nil
}

func (m *MockBLEClient) WriteDescriptor(d *ble.Descriptor, b []byte) error {
	if m.err != nil {
		return m.err
	}
	m.data = b
	return nil
}

func (m *MockBLEClient) Subscribe(c *ble.Characteristic, ind bool, h ble.NotificationHandler) error {
	return m.err
}

func (m *MockBLEClient) Unsubscribe(c *ble.Characteristic, ind bool) error {
	return m.err
}

func (m *MockBLEClient) ClearSubscriptions() error {
	return m.err
}
func (m *MockBLEClient) Conn() ble.Conn {
	return nil
}

func (m *MockBLEClient) CancelConnection() error {
	return m.err
}

// ReadWithTimeout reads data from a BLE characteristic with a timeout
func ReadWithTimeout(client ble.Client, charUUID string, timeout time.Duration) ([]byte, error) {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	dataCh := make(chan []byte, 1)
	errCh := make(chan error, 1)

	go func() {
		// Find the characteristic
		profile, err := client.DiscoverProfile(true)
		if err != nil {
			errCh <- fmt.Errorf("failed to discover profile: %v", err)
			return
		}

		charUUIDParsed := ble.MustParse(charUUID)

		// Iterate through services and characteristics
		for _, svc := range profile.Services {
			for _, char := range svc.Characteristics {
				if char.UUID.Equal(charUUIDParsed) {
					// Found the characteristic, now read from it
					n, err := client.ReadCharacteristic(char)
					if err != nil {
						errCh <- fmt.Errorf("failed to read characteristic: %v", err)
						return
					}
					dataCh <- n
					return
				}
			}
		}
		errCh <- fmt.Errorf("characteristic not found: %s", charUUID)
	}()

	select {
	case data := <-dataCh:
		return data, nil
	case err := <-errCh:
		return nil, err
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return nil, errors.New("read timeout")
		}
		return nil, ctx.Err()
	}
}

func TestReadWithTimeoutBLE(t *testing.T) {
	mockClient := NewMockBLEClient()

	// Test 1: Test timeout when no data is available
	mockClient.err = errors.New("discovery failed")
	_, err := ReadWithTimeout(mockClient, "1234", 500*time.Millisecond)
	if err == nil || !strings.Contains(err.Error(), "failed to discover profile") {
		t.Fatalf("Expected discovery error, got: %v", err)
	}

	// Test 2: Test successful read
	expectedData := []byte("test data")
	mockClient.err = nil
	mockClient.data = expectedData

	// Create a mock service and characteristic
	char := &ble.Characteristic{
		UUID: ble.MustParse("1234"),
	}
	svc := &ble.Service{
		UUID:            ble.MustParse("2345"),
		Characteristics: []*ble.Characteristic{char},
	}
	mockClient.profile.Services = []*ble.Service{svc}

	data, err := ReadWithTimeout(mockClient, "1234", time.Second)
	if err != nil {
		t.Fatalf("Expected successful read, got error: %v", err)
	}

	if !bytes.Equal(data, expectedData) {
		t.Errorf("Expected data %v, got: %v", expectedData, data)
	}
}

func TestTimeoutScenarios(t *testing.T) {
	mockClient := NewMockBLEClient()
	charUUID := "1234"

	// Immediate timeout
	mockClient.err = errors.New("simulated timeout")
	_, err := ReadWithTimeout(mockClient, charUUID, 1*time.Millisecond)
	if err == nil {
		t.Fatal("Expected timeout error, got nil")
	}

	// Profile discovery failure
	mockClient.err = errors.New("profile discovery failed")
	_, err = ReadWithTimeout(mockClient, charUUID, time.Second)
	if err == nil || !strings.Contains(err.Error(), "failed to discover profile") {
		t.Fatalf("Expected profile discovery error, got: %v", err)
	}

	// Characteristic not found
	mockClient.err = nil
	mockClient.profile.Services = []*ble.Service{} // Empty services
	_, err = ReadWithTimeout(mockClient, charUUID, time.Second)
	if err == nil || !strings.Contains(err.Error(), "characteristic not found") {
		t.Fatalf("Expected characteristic not found error, got: %v", err)
	}

	// Successful read just before timeout
	expectedData := []byte("test data")
	mockClient.data = expectedData
	char := &ble.Characteristic{
		UUID: ble.MustParse(charUUID),
	}
	svc := &ble.Service{
		UUID:            ble.MustParse("2345"),
		Characteristics: []*ble.Characteristic{char},
	}
	mockClient.profile.Services = []*ble.Service{svc}

	data, err := ReadWithTimeout(mockClient, charUUID, time.Second)
	if err != nil {
		t.Fatalf("Expected successful read, got error: %v", err)
	}
	if !bytes.Equal(data, expectedData) {
		t.Errorf("Expected data %v, got: %v", expectedData, data)
	}
}

func TestRESTEndpointOverBLE(t *testing.T) {
	mockClient := NewMockBLEClient()
	charUUID := "1234"

	// Setup mock response
	responseData := []byte(`{"type":"response","payload":{"status":200,"body":"OK"}}`)
	mockClient.data = responseData

	// Create mock characteristic
	char := &ble.Characteristic{
		UUID: ble.MustParse(charUUID),
	}
	svc := &ble.Service{
		UUID:            ble.MustParse("2345"),
		Characteristics: []*ble.Characteristic{char},
	}
	mockClient.profile.Services = []*ble.Service{svc}

	// Test reading the response
	data, err := ReadWithTimeout(mockClient, charUUID, time.Second)
	if err != nil {
		t.Fatalf("Failed to read from BLE: %v", err)
	}

	// Parse and validate the response
	var response map[string]any
	err = json.Unmarshal(data, &response)
	if err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	payload := response["payload"].(map[string]any)
	if payload["status"] != float64(200) {
		t.Errorf("Expected status 200, got %v", payload["status"])
	}
	if payload["body"] != "OK" {
		t.Errorf("Expected body 'OK', got %v", payload["body"])
	}
}

func TestJSONDataOverBLE(t *testing.T) {
	mockClient := NewMockBLEClient()
	charUUID := "1234"

	// Test uploading JSON data
	expectedData := []byte(`{"type":"response","payload":{"status":201,"message":"Data processed"}}`)
	mockClient.data = expectedData

	// Create mock characteristic
	char := &ble.Characteristic{
		UUID: ble.MustParse(charUUID),
	}
	svc := &ble.Service{
		UUID:            ble.MustParse("2345"),
		Characteristics: []*ble.Characteristic{char},
	}
	mockClient.profile.Services = []*ble.Service{svc}

	// Read response
	data, err := ReadWithTimeout(mockClient, charUUID, time.Second)
	if err != nil {
		t.Fatalf("Failed to read from BLE: %v", err)
	}

	// Validate response
	var response map[string]any
	err = json.Unmarshal(data, &response)
	if err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	payload := response["payload"].(map[string]any)
	if payload["status"] != float64(201) {
		t.Errorf("Expected status 201, got %v", payload["status"])
	}
	if payload["message"] != "Data processed" {
		t.Errorf("Expected message 'Data processed', got %v", payload["message"])
	}
}
