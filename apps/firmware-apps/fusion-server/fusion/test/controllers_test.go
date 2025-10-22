package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion/internal/routes"
)

const controllersServerAddr = "http://192.168.64.100:8080"

// ControllerInfo mirrors the server's API model.
type ControllerInfo struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Address string `json:"address"`
	Version string `json:"version"`
}

func TestControllerLifecycle(t *testing.T) {
	controller := ControllerInfo{
		ID:      "ctrl-test-001",
		Name:    "Test Controller",
		Address: "192.168.64.250:8000",
		Version: "1.0.0",
	}

	base := fmt.Sprintf("%s%s", controllersServerAddr, routes.ControllersEndpoint)

	t.Run("Register Controller", func(t *testing.T) {
		body, err := json.Marshal(controller)
		if err != nil {
			t.Fatalf("marshal controller: %v", err)
		}

		resp, err := http.Post(base, api.JsonMIMEType, bytes.NewBuffer(body))
		if err != nil {
			t.Fatalf("POST failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
		}

		var got ControllerInfo
		if err := json.NewDecoder(resp.Body).Decode(&got); err != nil {
			t.Fatalf("decode register response: %v", err)
		}
		if got.ID != controller.ID {
			t.Errorf("wrong controller ID: got %q want %q", got.ID, controller.ID)
		}
	})

	t.Run("List Controllers", func(t *testing.T) {
		resp, err := http.Get(base)
		if err != nil {
			t.Fatalf("GET failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
		}

		var list []ControllerInfo
		if err := json.NewDecoder(resp.Body).Decode(&list); err != nil {
			t.Fatalf("decode list response: %v", err)
		}

		found := false
		for _, c := range list {
			if c.ID == controller.ID {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("controller %q not found in list", controller.ID)
		}
	})

	t.Run("Get Controller By ID", func(t *testing.T) {
		url := fmt.Sprintf("%s/%s", base, controller.ID)
		resp, err := http.Get(url)
		if err != nil {
			t.Fatalf("GET by ID failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
		}

		var got ControllerInfo
		if err := json.NewDecoder(resp.Body).Decode(&got); err != nil {
			t.Fatalf("decode controller: %v", err)
		}
		if got.ID != controller.ID {
			t.Errorf("expected ID %q got %q", controller.ID, got.ID)
		}
	})

	t.Run("Delete Controller", func(t *testing.T) {
		client := &http.Client{}
		req, err := http.NewRequest("DELETE", fmt.Sprintf("%s/%s", base, controller.ID), nil)
		if err != nil {
			t.Fatalf("create DELETE request: %v", err)
		}
		resp, err := client.Do(req)
		if err != nil {
			t.Fatalf("DELETE request failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
		}
	})

	t.Run("Verify Deleted Controller", func(t *testing.T) {
		time.Sleep(200 * time.Millisecond)

		resp, err := http.Get(fmt.Sprintf("%s/%s", base, controller.ID))
		if err != nil {
			t.Fatalf("GET deleted controller failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusNotFound {
			t.Errorf("expected 404 Not Found, got %d", resp.StatusCode)
		}
	})
}
