package server

import (
	"fmt"
	"slices"
	"sync"
)

const (
	VersionRollback = "binary_rollback"
	VersionUpdate   = "binary_update"
	UpdateChunk     = "binary_chunk"
	UpdateMetadata  = "binary_metadata"
)

type BinaryAssembler struct {
	chunks   map[int64][]byte // Map of offset to chunk data
	size     int64            // Expected total size from metadata
	received int64            // Bytes received so far
	mu       sync.Mutex       // Protect concurrent access
}

type BinaryChunk struct {
	Data   []byte `json:"data"`   // The actual chunk of binary data
	Offset int64  `json:"offset"` // Position in the file for reassembly
	Final  bool   `json:"final"`  // Indicates if this is the last chunk
}

func IsValidBinaryUpdateType(updateType string) bool {
	switch updateType {
	case VersionRollback, VersionUpdate, UpdateChunk, UpdateMetadata:
		return true
	default:
		return false
	}
}

func NewBinaryAssembler(expectedSize int64) *BinaryAssembler {
	return &BinaryAssembler{
		chunks: make(map[int64][]byte),
		size:   expectedSize,
	}
}

func (ba *BinaryAssembler) AddChunk(chunk BinaryChunk) error {
	ba.mu.Lock()
	defer ba.mu.Unlock()

	ba.chunks[chunk.Offset] = chunk.Data
	ba.received += int64(len(chunk.Data))

	return nil
}

func (ba *BinaryAssembler) IsComplete() bool {
	ba.mu.Lock()
	defer ba.mu.Unlock()

	return ba.received >= ba.size
}

func (ba *BinaryAssembler) Assemble() ([]byte, error) {
	ba.mu.Lock()
	defer ba.mu.Unlock()

	if ba.received < ba.size {
		return nil, fmt.Errorf("incomplete binary: received %d of %d bytes", ba.received, ba.size)
	}

	// Create the final binary
	binary := make([]byte, ba.size)

	// Sort offsets for ordered assembly
	offsets := make([]int64, 0, len(ba.chunks))
	for offset := range ba.chunks {
		offsets = append(offsets, offset)
	}
	slices.Sort(offsets)

	// Copy chunks in order
	for _, offset := range offsets {
		copy(binary[offset:], ba.chunks[offset])
	}

	return binary, nil
}
