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
	TextMIMEType = "text/plain"
	Protocol     = "http://"

	FusionEpoch     = "_fusion_epoch"
	FusionVersion   = "_fusion_version"
	FusionMessageID = "_fusion_msg_id"
	FusionOperation = "_fusion_op"

	HTTPTimeout = 5 * time.Second

	MessageIDKey        = "id"
	MessagePriorityKey  = "priority"
	MessageTimestampKey = "timestamp"
	MessageZonesKey     = "zones"

	SnapshotIDKey = "snapshot_id"

	// Request types
	WSMsgTypeDevices            = "devices"
	WSMsgTypeDeviceByID         = "device_by_id"
	WSMsgTypeUpdateDeviceInfo   = "update_device_info"
	WSMsgTypeDeviceUpdate       = "device_update"
	WSMsgTypeUnsubscribeDevices = "unsubscribe_devices"
	WSMsgTypePing               = "ping"
	WSMsgTypePong               = "pong"
	WSMsgTypeError              = "error"

	// WebSocket response data field keys
	WSDataFieldDeviceID   = "device_id"
	WSDataFieldDeviceData = "device_data"

	WSCurrentVersion = 1

	WSStatusSuccess = "success"
	WSStatusError   = "error"
	WSStatusEvent   = "event"

	// Standard WebSocket close codes (1xxx)
	WSCodeNormalClosure = 1000 // Normal closure (for connection close only)
	WSCodeProtocolError = 1002 // Protocol error (for connection close only)
	WSCodeInternalError = 1011 // Internal server error (for connection close only)

	// Application success codes (3xxx) - Available for framework use
	WSCodeOK            = 3000 // Success response
	WSCodeUpdated       = 3001 // Resource updated successfully
	WSCodeConnected     = 3002 // Connection established
	WSCodePong          = 3003 // Pong response
	WSCodeDeviceUpdated = 3004 // Device updated (for push notifications)

	// Application client error codes (4xxx) - Available for private use
	WSCodeInvalidJSON      = 4000 // Invalid JSON in request
	WSCodeMissingField     = 4001 // Required field missing
	WSCodeInvalidType      = 4002 // Invalid message type
	WSCodeInvalidPayload   = 4003 // Invalid request payload
	WSCodeMissingDeviceID  = 4004 // Device ID missing
	WSCodeDeviceNotFound   = 4005 // Device not found
	WSCodeUpdateFailed     = 4006 // Update operation failed
	WSCodeApplicationError = 4500 // General application error
)
