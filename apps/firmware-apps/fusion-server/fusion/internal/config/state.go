package config

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"sync"
	"time"
)

type StateManager struct {
	sync.RWMutex
	state       map[string]*api.StateEntry
	version     int64
	nodeID      string
	subscribers []chan struct{}
}

func NewStateManager(nodeID string) *StateManager {
	return &StateManager{
		state:       make(map[string]*api.StateEntry),
		nodeID:      nodeID,
		subscribers: make([]chan struct{}, 0),
	}
}

func (sm *StateManager) GetVersion() int64 {
	sm.RLock()
	defer sm.RUnlock()
	return sm.version
}

func (sm *StateManager) Get(key string) (interface{}, bool) {
	sm.RLock()
	defer sm.RUnlock()
	if entry, exists := sm.state[key]; exists {
		return entry.Data, true
	}
	return nil, false
}

func (sm *StateManager) Set(key string, value interface{}) error {
	update := map[string]interface{}{
		key: value,
	}
	return sm.ApplyUpdate(api.ConfigUpdate{
		Update:  update,
		Version: time.Now().UnixNano(),
		NodeID:  sm.nodeID,
		Time:    time.Now().UTC(),
	})
}

func (sm *StateManager) ApplyUpdate(update api.ConfigUpdate) error {
	sm.Lock()
	defer sm.Unlock()

	// Handle complete clear
	if len(update.Update) == 0 {
		sm.state = make(map[string]*api.StateEntry)
		sm.version = update.Version
		sm.notifySubscribers()
		return nil
	}

	// For each top-level key in the update
	for key, value := range update.Update {
		sm.state[key] = &api.StateEntry{
			Data:      value,
			Version:   update.Version,
			NodeID:    update.NodeID,
			Timestamp: update.Time,
		}
	}

	if update.Version > sm.version {
		sm.version = update.Version
	}
	sm.notifySubscribers()
	return nil
}

func (sm *StateManager) GetFullState() map[string]*api.StateEntry {
	sm.RLock()
	defer sm.RUnlock()
	stateCopy := make(map[string]*api.StateEntry, len(sm.state))
	for k, v := range sm.state {
		stateCopy[k] = v
	}
	return stateCopy
}

func (sm *StateManager) Subscribe() chan struct{} {
	sm.Lock()
	defer sm.Unlock()
	ch := make(chan struct{}, 1)
	sm.subscribers = append(sm.subscribers, ch)
	return ch
}

func (sm *StateManager) notifySubscribers() {
	for _, ch := range sm.subscribers {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}

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
