package routes

const (
	RootEndpoint        = "/"
	EndpointsEndpoint   = "/endpoints"
	MembersEndpoint     = "/members"
	MetadataEndpoint    = "/metadata"
	VersionEndpoint     = "/version"
	UploadAudioEndpoint = "/uploadAudio"
	WebsocketEndpoint   = "/ws"

	ValueEndpoint = "/value"

	SnapshotsEndpoint             = "/snapshots"
	SnapshotsNameEndpoint         = "/snapshots/{name}"
	SnapshotsNameActivateEndpoint = "/snapshots/{name}/activate"

	TasksEndpoint          = "/tasks"
	TasksHistoryEndpoint   = "/tasks/history"
	TasksIdEndpoint        = "/tasks/{id}"
	TasksIdDisableEndpoint = "/tasks/{id}/enable"
	TasksIdEnableEndpoint  = "/tasks/{id}/enable"

	ClusterLatencyNetworkEndpoint              = "/cluster/latency/network"
	ClusterLatencyNetworkLocalEndpoint         = "/cluster/latency/network/local"
	ClusterLatencyNetworkFailuresEndpoint      = "/cluster/latency/network/failures"
	ClusterLatencyNetworkFailuresLocalEndpoint = "/cluster/latency/network/failures/local"
	ClusterLatencyStatusEndpoint               = "/cluster/latency/status"
	ClusterLatencyStatusLocalEndpoint          = "/cluster/latency/status/local"
	ClusterLatencySyncEndpoint                 = "/cluster/latency/sync"
	ClusterLatencySyncLocalEndpoint            = "/cluster/latency/sync/local"
	ClusterLatencySyncAveragesEndpoint         = "/cluster/latency/sync/averages"
	ClusterLatencySyncAveragesLocalEndpoint    = "/cluster/latency/sync/averages/local"
	ClusterNTPSkewEndpoint                     = "/cluster/ntp-skew"
	ClusterStatusEndpoint                      = "/cluster/status"

	HealthEndpoint = "/health"

	MetricsEndpoint = "/metrics"

	ExportDataEndport  = "/exportData"
	ImportDataEndport  = "/importData"
	ExportStateEndport = "/exportState"
	ImportStateEndport = "/importState"
)
