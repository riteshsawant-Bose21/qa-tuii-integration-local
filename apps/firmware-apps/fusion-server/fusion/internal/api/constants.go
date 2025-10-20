package api

const (
	AdminPort       = "9090"
	HTTPPort        = "8080"
	SAPPort         = "9875" // As defined: https://datatracker.ietf.org/doc/html/rfc2974
	UDPPort         = "7947"
	VIPNotifierPort = 7948

	ContentType  = "Content-Type"
	JsonMIMEType = "application/json"
	Protocol     = "http://"

	AudioFilesLocation = "/var/lib/fusion/audio"

	MessageIDKey  = "message_id"
	SnapshotIDKey = "snapshot_id"
)
