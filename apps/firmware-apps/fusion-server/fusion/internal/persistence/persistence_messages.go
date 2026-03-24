package persistence

import (
	"bytes"
	"context"
	"fmt"
	"fusion/internal/api"
	"fusion-services-core/logging"
	"sort"
	"strings"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

// SaveAudioMeta saves the audio metadata in the database bucket.
func (p *Persistence) SaveAudioMeta(meta *api.AudioMetadata) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return err
	}
	existing, err := p.getValue(bucketAudio, meta.Id)
	if err != nil {
		return err
	}
	if bytes.Equal(existing, data) {
		logging.GetLogger().Debug("Audio metadata write skipped: id=%s unchanged", meta.Id)
		return nil
	}

	err = p.db.Update(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketAudio))
		if b == nil {
			return ErrNotFound
		}
		return b.Put([]byte(meta.Id), data)
	})
	if err != nil {
		return err
	}
	return p.updateHash()
}

// GetAudioMetadata fetches metadata by ID.
func (p *Persistence) GetAudioMetadata(id string) (*api.AudioMetadata, error) {
	var out *api.AudioMetadata
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketAudio))
		if b == nil {
			return ErrNotFound
		}

		v := b.Get([]byte(id))
		if v == nil {
			out = nil
			return ErrNotFound
		}

		var m api.AudioMetadata
		if err := json.Unmarshal(v, &m); err != nil {
			return err
		}
		out = &m
		return nil
	})
	return out, err
}

// ListAudioMetadata returns a list of all audio metadata
func (p *Persistence) ListAudioMetadata() ([]*api.AudioMetadata, error) {

	var results []*api.AudioMetadata

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketAudio))
		if b == nil {
			return ErrNotFound
		}

		return b.ForEach(func(_, v []byte) error {
			var m api.AudioMetadata
			if err := json.Unmarshal(v, &m); err != nil {
				return err
			}
			results = append(results, &m)
			return nil
		})
	})

	return results, err
}

// DeleteAudioMetadata removed the audio metadata from the database.
func (p *Persistence) DeleteAudioMetadata(id string) error {
	exists, err := p.keyExists(bucketAudio, id)
	if err != nil {
		return err
	}
	if !exists {
		logging.GetLogger().Debug("Audio metadata delete skipped: id=%s missing", id)
		return nil
	}

	err = p.db.Update(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketAudio))
		if b == nil {
			return ErrNotFound
		}
		return b.Delete([]byte(id))
	})
	if err != nil {
		return err
	}
	return p.updateHash()
}

func (p *Persistence) ListAllTags(ctx context.Context) ([]string, error) {
	// Map lowercase to original form
	tagMap := make(map[string]string)

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketAudio))
		if b == nil {
			return ErrNotFound
		}
		return b.ForEach(func(_, v []byte) error {
			var meta api.AudioMetadata
			if err := json.Unmarshal(v, &meta); err != nil {
				return err
			}
			for _, t := range meta.Tags {
				trimmed := strings.TrimSpace(t)
				if trimmed == "" {
					continue
				}
				lower := strings.ToLower(trimmed)
				if _, exists := tagMap[lower]; !exists {
					// Preserve first-seen casing
					tagMap[lower] = trimmed
				}
			}
			return nil
		})
	})
	if err != nil {
		return nil, err
	}

	// Convert map to slice of preserved originals
	tags := make([]string, 0, len(tagMap))
	for _, original := range tagMap {
		tags = append(tags, original)
	}

	// Sort case-insensitive
	sort.Slice(tags, func(i, j int) bool {
		return strings.ToLower(tags[i]) < strings.ToLower(tags[j])
	})

	return tags, nil
}

func (p *Persistence) GetAudioByDisplayName(name string) (*api.AudioMetadata, error) {
	var result *api.AudioMetadata

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte("audio"))
		if b == nil {
			return fmt.Errorf("bucket not found")
		}

		c := b.Cursor()
		for k, v := c.First(); k != nil; k, v = c.Next() {
			var meta api.AudioMetadata
			if err := json.Unmarshal(v, &meta); err != nil {
				return err
			}
			if meta.DisplayName == name {
				result = &meta
				return nil
			}
		}
		return nil
	})

	if err != nil {
		return nil, err
	}
	return result, nil
}
