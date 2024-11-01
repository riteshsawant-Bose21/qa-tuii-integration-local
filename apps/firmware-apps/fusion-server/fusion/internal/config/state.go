package config

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"fusion/internal/api"
)

// StateManager handles the distributed state of the system
type StateManager struct {
	sync.RWMutex
	state       map[string]*api.StateEntry
	version     int64
	nodeID      string
	subscribers []chan struct{}
}

// NewStateManager creates a new state manager instance
func NewStateManager(nodeID string) *StateManager {
	return &StateManager{
		state:       make(map[string]*api.StateEntry),
		nodeID:      nodeID,
		subscribers: make([]chan struct{}, 0),
	}
}

// GetVersion returns the current version of the state
func (sm *StateManager) GetVersion() int64 {
	sm.RLock()
	defer sm.RUnlock()
	return sm.version
}

// Get retrieves a value from the state
func (sm *StateManager) Get(key string) (interface{}, bool) {
	sm.RLock()
	defer sm.RUnlock()

	if entry, exists := sm.state[key]; exists {
		return entry, true
	}
	return nil, false
}

// Set updates or creates a value in the state
func (sm *StateManager) Set(key string, value interface{}) error {
	sm.Lock()
	defer sm.Unlock()

	sm.version++
	sm.state[key] = &api.StateEntry{
		Value:     value,
		Version:   sm.version,
		NodeID:    sm.nodeID,
		Timestamp: time.Now().UTC(),
	}

	sm.notifySubscribers()
	return nil
}

// ApplyUpdate applies a config update to the state
func (sm *StateManager) ApplyUpdate(update api.ConfigUpdate) error {
	sm.Lock()
	defer sm.Unlock()

	existing, exists := sm.state[update.Key]
	if !exists || existing.Version < update.Version {
		sm.state[update.Key] = &api.StateEntry{
			Value:     update.Value,
			Version:   update.Version,
			NodeID:    update.NodeID,
			Timestamp: update.Time,
		}
		if update.Version > sm.version {
			sm.version = update.Version
		}
		sm.notifySubscribers()
	}

	return nil
}

// GetFullState returns a copy of the current state
func (sm *StateManager) GetFullState() map[string]*api.StateEntry {
	sm.RLock()
	defer sm.RUnlock()

	stateCopy := make(map[string]*api.StateEntry, len(sm.state))
	for k, v := range sm.state {
		stateCopy[k] = v
	}
	return stateCopy
}

// Subscribe returns a channel that will be notified of state changes
func (sm *StateManager) Subscribe() chan struct{} {
	sm.Lock()
	defer sm.Unlock()

	ch := make(chan struct{}, 1)
	sm.subscribers = append(sm.subscribers, ch)
	return ch
}

// notifySubscribers notifies all subscribers of a state change
func (sm *StateManager) notifySubscribers() {
	for _, ch := range sm.subscribers {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}

// VerifyState generates a hash of the current state for verification
func (sm *StateManager) VerifyState() string {
	sm.RLock()
	defer sm.RUnlock()

	data, err := json.Marshal(sm.state)
	if err != nil {
		return ""
	}

	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash)
}

// StartStateDumping starts periodic state dumping for debugging
func (sm *StateManager) StartStateDumping(interval time.Duration) {
	go func() {
		for {
			time.Sleep(interval)
			sm.RLock()
			fmt.Printf("[STATE] Current state version: %d, entries: %d\n",
				sm.version, len(sm.state))
			sm.RUnlock()
		}
	}()
}

// MergeRemoteState merges a remote state into the local state
func (sm *StateManager) MergeRemoteState(remoteState map[string]*api.StateEntry, sourceNodeID string) {
	sm.Lock()
	defer sm.Unlock()

	for key, remoteEntry := range remoteState {
		localEntry, exists := sm.state[key]
		if !exists || remoteEntry.Version > localEntry.Version {
			sm.state[key] = remoteEntry
			if remoteEntry.Version > sm.version {
				sm.version = remoteEntry.Version
			}
		}
	}
	sm.notifySubscribers()
}
