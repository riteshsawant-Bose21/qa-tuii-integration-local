package api

import "time"

const (
	AudioFilesLocation = "/var/lib/fusion/audio"

	AdminPort          = "9090"
	ControllerPort     = "7950"
	HTTPPort           = "8080"
	MessageTriggerPort = 7949
	SAPPort            = "9875" // As defined: https://datatracker.ietf.org/doc/html/rfc2974
	UDPPort            = "7947"

	ContentType  = "Content-Type"
	JsonMIMEType = "application/json"
	Protocol     = "http://"

	FusionEpoch   = "_fusion_epoch"
	FusionVersion = "_fusion_version"

	HTTPTimeout = 5 * time.Second

	MessageIDKey        = "id"
	MessagePriorityKey  = "priority"
	MessageTimestampKey = "timestamp"
	MessageZonesKey     = "zones"

	SnapshotIDKey = "snapshot_id"
)
