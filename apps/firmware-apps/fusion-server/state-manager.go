package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sort"
	"sync"
	"time"
)

type StateEntry struct {
	Value     interface{} `json:"value"`
	Timestamp time.Time   `json:"timestamp"`
	NodeID    string      `json:"node_id"`
	Version   int64       `json:"version"`
}

type StateManager struct {
	sync.RWMutex
	state     map[string]*StateEntry
	nodeID    string
	version   int64
	logger    *log.Logger
	listeners []chan StateUpdate
}

type StateUpdate struct {
	Key     string      `json:"key"`
	Value   interface{} `json:"value"`
	Version int64       `json:"version"`
	NodeID  string      `json:"node_id"`
}

func NewStateManager(nodeID string) *StateManager {
	return &StateManager{
		state:     make(map[string]*StateEntry),
		nodeID:    nodeID,
		version:   0,
		logger:    log.New(os.Stdout, fmt.Sprintf("[STATE-%s] ", nodeID), log.LstdFlags),
		listeners: make([]chan StateUpdate, 0),
	}
}

func (sm *StateManager) Set(key string, value interface{}) error {
	sm.Lock()
	defer sm.Unlock()

	sm.version++
	entry := &StateEntry{
		Value:     value,
		Timestamp: time.Now().UTC(),
		NodeID:    sm.nodeID,
		Version:   sm.version,
	}

	sm.state[key] = entry
	sm.notifyListeners(StateUpdate{
		Key:     key,
		Value:   value,
		Version: sm.version,
		NodeID:  sm.nodeID,
	})

	return nil
}

func (sm *StateManager) Get(key string) (interface{}, bool) {
	sm.RLock()
	defer sm.RUnlock()

	if entry, exists := sm.state[key]; exists {
		return entry.Value, true
	}
	return nil, false
}

func (sm *StateManager) GetFullState() map[string]*StateEntry {
	sm.RLock()
	defer sm.RUnlock()

	stateCopy := make(map[string]*StateEntry)
	for k, v := range sm.state {
		stateCopy[k] = v
	}
	return stateCopy
}

func (sm *StateManager) Subscribe() chan StateUpdate {
	sm.Lock()
	defer sm.Unlock()

	ch := make(chan StateUpdate, 100)
	sm.listeners = append(sm.listeners, ch)
	return ch
}

func (sm *StateManager) notifyListeners(update StateUpdate) {
	for _, listener := range sm.listeners {
		select {
		case listener <- update:
		default:
			// Skip if channel is full
		}
	}
}

func (sm *StateManager) MergeRemoteState(remoteState map[string]*StateEntry, sourceNodeID string) {
	sm.Lock()
	defer sm.Unlock()

	if debugMode {
		sm.logger.Printf("\n=== STARTING STATE MERGE FROM %s ===\n", sourceNodeID)
	}

	for key, remoteEntry := range remoteState {
		localEntry, exists := sm.state[key]

		if !exists {
			sm.logStateChange("SYNC NEW", key, remoteEntry,
				fmt.Sprintf("New key from node %s", sourceNodeID))
			sm.state[key] = remoteEntry
			continue
		}

		if remoteEntry.Version > localEntry.Version {
			sm.logStateChange("SYNC UPDATE", key, remoteEntry,
				fmt.Sprintf("Remote version %d > local version %d from node %s",
					remoteEntry.Version, localEntry.Version, sourceNodeID))
			sm.state[key] = remoteEntry
			continue
		}

		if remoteEntry.Version == localEntry.Version &&
			remoteEntry.Timestamp.After(localEntry.Timestamp) {
			sm.logStateChange("SYNC TIMESTAMP", key, remoteEntry,
				fmt.Sprintf("Same version %d but remote timestamp newer from node %s",
					remoteEntry.Version, sourceNodeID))
			sm.state[key] = remoteEntry
			continue
		}

		if debugMode {

			sm.logger.Printf(`
		
		[SYNC SKIP]
		Key: %s
		Remote Version: %d
		Local Version: %d
		Remote Node: %s
		Reason: Local version newer or equal`,

				key, remoteEntry.Version, localEntry.Version, sourceNodeID)
		}
	}

	if debugMode {
		sm.logger.Printf("\n=== COMPLETED STATE MERGE FROM %s ===\n", sourceNodeID)
	}
}

func (sm *StateManager) VerifyState() string {
	sm.RLock()
	defer sm.RUnlock()

	// Sort keys for consistent hashing
	keys := make([]string, 0, len(sm.state))
	for k := range sm.state {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	// Create hash of sorted state
	hasher := sha256.New()
	for _, k := range keys {
		entry := sm.state[k]
		data, _ := json.Marshal(struct {
			Key   string
			Entry *StateEntry
		}{k, entry})
		hasher.Write(data)
	}

	return fmt.Sprintf("%x", hasher.Sum(nil))
}

func (sm *StateManager) ApplyUpdate(update ConfigUpdate) error {
	sm.Lock()
	defer sm.Unlock()

	entry := &StateEntry{
		Value:     update.Value,
		Timestamp: update.Time,
		NodeID:    update.NodeID,
		Version:   update.Version,
	}

	if entry.Timestamp.IsZero() {
		entry.Timestamp = time.Now().UTC()
	}

	currentEntry, exists := sm.state[update.Key]
	if !exists {
		sm.state[update.Key] = entry
		if update.Version > sm.version {
			sm.version = update.Version
		}

		sm.logStateChange("NEW VALUE", update.Key, entry, "Key did not exist previously")
		sm.notifyListeners(StateUpdate{
			Key:     update.Key,
			Value:   update.Value,
			Version: update.Version,
			NodeID:  update.NodeID,
		})
		return nil
	}

	if update.Version > currentEntry.Version {
		sm.logStateChange("UPDATE", update.Key, entry,
			fmt.Sprintf("New version %d > current version %d",
				update.Version, currentEntry.Version))

		sm.state[update.Key] = entry
		if update.Version > sm.version {
			sm.version = update.Version
		}

		sm.notifyListeners(StateUpdate{
			Key:     update.Key,
			Value:   update.Value,
			Version: update.Version,
			NodeID:  update.NodeID,
		})
		return nil
	}

	if update.Version == currentEntry.Version && entry.Timestamp.After(currentEntry.Timestamp) {
		sm.logStateChange("TIMESTAMP UPDATE", update.Key, entry,
			fmt.Sprintf("Same version %d but newer timestamp %v > %v",
				update.Version, entry.Timestamp, currentEntry.Timestamp))

		sm.state[update.Key] = entry
		sm.notifyListeners(StateUpdate{
			Key:     update.Key,
			Value:   update.Value,
			Version: update.Version,
			NodeID:  update.NodeID,
		})
		return nil
	}

	if debugMode {
		sm.logger.Printf(`
	[STATE CHANGE REJECTED]
	Key: %s
	Attempted Value: %+v
	Attempted Version: %d
	Current Version: %d
	Reason: Version not newer than current`,
			update.Key, update.Value, update.Version, currentEntry.Version)
	}

	return fmt.Errorf("update rejected: current version %d >= update version %d",
		currentEntry.Version, update.Version)
}

func (sm *StateManager) logStateChange(operation string, key string, entry *StateEntry, reason string) {

	if !debugMode {
		return
	}

	valueJSON, err := json.MarshalIndent(entry.Value, "", "  ")
	if err != nil {
		valueJSON = []byte(fmt.Sprintf("error marshaling value: %v", err))
	}

	sm.logger.Printf(`
[STATE CHANGE] %s
Key: %s
Value: %s
Version: %d
Node: %s
Timestamp: %s
Reason: %s
Current Total Entries: %d
`,
		operation,
		key,
		string(valueJSON),
		entry.Version,
		entry.NodeID,
		entry.Timestamp.Format(time.RFC3339),
		reason,
		len(sm.state))
}

func (sm *StateManager) StartStateDumping(interval time.Duration) {

	if !debugMode {
		return
	}

	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for {
			<-ticker.C
			sm.DumpFullState()
		}
	}()
}

func (sm *StateManager) DumpFullState() {
	sm.RLock()
	defer sm.RUnlock()

	var keys []string
	for k := range sm.state {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	sm.logger.Printf("\n=== FULL STATE DUMP ===\nTotal Entries: %d\nGlobal Version: %d\n",
		len(sm.state), sm.version)

	for _, key := range keys {
		entry := sm.state[key]
		valueJSON, err := json.MarshalIndent(entry.Value, "", "  ")
		if err != nil {
			valueJSON = []byte(fmt.Sprintf("error marshaling value: %v", err))
		}

		sm.logger.Printf(`
Entry:
  Key: %s
  Value: %s
  Version: %d
  Node: %s
  Age: %s
  Last Updated: %s`,
			key,
			string(valueJSON),
			entry.Version,
			entry.NodeID,
			time.Since(entry.Timestamp).Round(time.Second),
			entry.Timestamp.Format(time.RFC3339))
	}
	sm.logger.Printf("\n=== END STATE DUMP ===\n")
}
