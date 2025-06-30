package main

import (
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

const websocketURL = "ws://192.168.64.100:8080/ws"

func TestWebsocketConnect(t *testing.T) {
	// Dial the websocket endpoint.
	c, _, err := websocket.DefaultDialer.Dial(websocketURL, nil)
	if err != nil {
		t.Fatalf("Websocket dial failed: %v", err)
	}
	defer c.Close()
	//t.Logf("Connected to websocket server, HTTP status: %s", resp.Status)

	// Set a deadline and read the initial state sent by the server.
	c.SetReadDeadline(time.Now().Add(5 * time.Second))
	_, _, err = c.ReadMessage()
	if err != nil {
		t.Fatalf("Failed to read initial state: %v", err)
	}
	//t.Logf("Initial message received: %s", initialMsg)

	// Now send a test message.
	testMsg := "ping"
	if err := c.WriteMessage(websocket.TextMessage, []byte(testMsg)); err != nil {
		t.Fatalf("Failed to send message: %v", err)
	}
	//t.Logf("Sent message: %s", testMsg)

	// Set a short deadline for any potential subsequent message.
	c.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, _, err = c.ReadMessage()
	if err != nil {
		// A timeout or close error here is acceptable if no reply is expected.
		//t.Logf("No reply received after sending message (this may be expected): %v", err)
	}
}
