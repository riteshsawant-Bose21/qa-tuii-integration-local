package main

import "time"

type ConfigUpdate struct {
	Key     string      `json:"key"`
	Value   interface{} `json:"value"`
	Version int64       `json:"version"`
	NodeID  string      `json:"node_id"`
	Time    time.Time   `json:"timestamp"`
}
