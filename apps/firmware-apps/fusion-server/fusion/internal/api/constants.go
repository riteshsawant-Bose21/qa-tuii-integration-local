package api

import "time"

const (
	AdminPort          = "9090"
	HTTPPort           = "8080"
	MessageTriggerPort = 7949
	SAPPort            = "9875" // As defined: https://datatracker.ietf.org/doc/html/rfc2974
	UDPPort            = "7947"
	VIPNotifierPort    = 7948

	ContentType  = "Content-Type"
	JsonMIMEType = "application/json"
	Protocol     = "http://"

	HTTPTimeout = 5 * time.Second

	AudioFilesLocation = "/var/lib/fusion/audio"

	MessageIDKey        = "id"
	MessagePathKey      = "path"
	MessagePriorityKey  = "priority"
	MessageTimestampKey = "timestamp"
	MessageZonesKey     = "zones"

	SnapshotIDKey = "snapshot_id"
)
