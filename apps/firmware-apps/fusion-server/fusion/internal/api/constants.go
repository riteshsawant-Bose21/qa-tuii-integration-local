package api

import (
	"os"
	"time"
)

const (
	ContentType  = "Content-Type"
	JsonMIMEType = "application/json"
	TextMIMEType = "text/plain"
)

const (
	AdminPort               = "9090"
	ControllerPort          = "7950"
	HTTPPort                = "8080"
	MessageTriggerPort      = 7949
	SAPPort                 = "9875" // As defined: https://datatracker.ietf.org/doc/html/rfc2974
	UDPPort                 = "7947"
	TelemetryCoreZMQPort    = "5678" // ZMQ PUB port on each device's telemetry core
	TelemetryCoreFilterPort = "9999" // UDP port for update_filter_req on each device's telemetry core
)

var (
	AudioFilesLocation      = getenvDefault("FUSION_AUDIO_DIR", "/persist/fusion/audio")
	DefaultIdentityFilePath = getenvDefault("FUSION_IDENTITY_DIR", "/persist/pki/")
	DefaultCAFileName       = "AmazonRootCA1.pem"
	DefaultCSRFileName      = "device.csr"
	DefaultCertFileName     = "device.x509.cert"
	DefaultKeyFileName      = "device.key"
	SoftwareUpdateInfoPath  = "/etc/buildinfo"
	SwUpdateInfoPath        = "/etc/swupdate-status"
	SerialPath              = "/sys/firmware/devicetree/base/serial-number"
)

const (
	FusionEpoch     = "_fusion_epoch"
	FusionMessageID = "_fusion_msg_id"
	FusionOperation = "_fusion_op"
	FusionClear     = "_fusion_clear"
	FusionSentAtNS  = "_fusion_sent_at_ns"
	FusionVersion   = "_fusion_version"
)

const (
	HTTPTimeout       = 5 * time.Second
	HTTPUploadTimeout = 60 * time.Second
)

const (
	MessageIDKey        = "id"
	MessagePriorityKey  = "priority"
	MessageTimestampKey = "timestamp"
	MessageZonesKey     = "zones"
)

const (
	MaxSoftwareUpdateUploadBytes = 300 << 20 // 300 MB
	MinFreeSpaceBuffer           = 100 << 20 // 100 MB minimum free space buffer
	ModelUnknown                 = "Unknown"
	Protocol                     = "http://"
	SoftwareUpdateOTAPath        = "/mnt/ota"
	Unknown                      = "Unknown"
)

const (
	SceneIDKey              = "scene_id"
	SceneSetIDKey           = "set_id"
	SnapshotIDKey           = "snapshot_id"
	SnapshotDefinitionIDKey = "snapshot_definition_id"
)

// RECOVERY_STATUS enum values from SWUpdate
const (
	SWUpdateStatusIdle       SWUpdateStatus = 0
	SWUpdateStatusStart      SWUpdateStatus = 1
	SWUpdateStatusRun        SWUpdateStatus = 2
	SWUpdateStatusSuccess    SWUpdateStatus = 3
	SWUpdateStatusFailure    SWUpdateStatus = 4
	SWUpdateStatusDownload   SWUpdateStatus = 5
	SWUpdateStatusDone       SWUpdateStatus = 6
	SWUpdateStatusSubprocess SWUpdateStatus = 7
	SWUpdateStatusProgress   SWUpdateStatus = 8
)

// SWUpdate progress socket constants
const (
	SWUpdateConnectAckSize   = 8
	SWUpdateExpectedAckMagic = "ACK"
	SWUpdateMsgSizeV200      = 2408
	SWUpdateMsgSizeV210      = 2416
	SWUpdateProgressAPIV200  = uint32(0x00020000)
	SWUpdateProgressAPIV210  = uint32(0x00020100)
	SWUpdateSocketPath       = "/tmp/swupdateprog"
)

// SWUpdate progress message byte offsets
const (
	SWUpdateOffAPIVersion   = 0
	SWUpdateOffStatus       = 4
	SWUpdateOffDwlPercent   = 8
	SWUpdateOffDwlBytes     = 12
	SWUpdateOffNSteps       = 20
	SWUpdateOffCurStep      = 24
	SWUpdateOffCurPercent   = 28
	SWUpdateOffCurImage     = 32
	SWUpdateOffHndName      = 288
	SWUpdateOffSource       = 352
	SWUpdateOffInfoLen      = 356
	SWUpdateOffInfo         = 360
	SWUpdateOffSerialNumber = 2408
)

const (
	VIPHighPriority        = "high"
	VIPvrrpHighPriority    = 120
	VIPDefaultPriority     = "default"
	VIPvrrpDefaultPriority = 100
	VIPLowPriority         = "low"
	VIPvrrpLowPriority     = 90
)

const (
	// WS Request types (client -> server)
	WSMsgTypeConfiguration         = "config"
	WSMsgTypeDeviceByID            = "device_by_id"
	WSMsgTypeDevices               = "devices"
	WSMsgTypeError                 = "error"
	WSMsgTypeListSoftwareUpdates   = "list_sw_update_files"
	WSMsgTypeMeterData             = "meter_data"
	WSMsgTypePatchConfiguration    = "patch_config"
	WSMsgTypePing                  = "ping"
	WSMsgTypePong                  = "pong"
	WSMsgTypeStartUpdate           = "start_update"
	WSMsgTypeSubscribeMeterData    = "subscribe_meter_data"
	WSMsgTypeSwUpdateInfo          = "sw_update_info"
	WSMsgTypeUnsubscribeConfig     = "unsubscribe_config"
	WSMsgTypeUnsubscribeDevices    = "unsubscribe_devices"
	WSMsgTypeUnsubscribeMeterData  = "unsubscribe_meter_data"
	WSMsgTypeUpdateDeviceInfo      = "update_device_info"
	WSMsgTypeUpdateMeterDataFilter = "update_meter_data_filter"
	WSMsgTypeUpdateProgress        = "update_progress"

	// WS event types (server -> client)
	WSMsgTypeConfigUpdate = "config_update"
	WSMsgTypeDeviceUpdate = "device_update"

	// WS topic names
	WSTopicConfigUpdates = "config_updates"
	WSTopicDeviceUpdates = "device_updates"
	WSTopicMeterData     = "meter_data"

	// WebSocket response data field keys
	WSDataFieldDeviceData = "device_data"
	WSDataFieldDeviceID   = "device_id"

	WSCurrentVersion = 1

	WSStatusEvent   = "event"
	WSStatusError   = "error"
	WSStatusSuccess = "success"

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
	WSCodeUpdateStarted = 3005 // Software update started successfully

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

func getenvDefault(key string, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
