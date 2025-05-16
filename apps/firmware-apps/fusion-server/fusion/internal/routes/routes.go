package routes

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"net/http"

	"github.com/gorilla/mux"
)

var (
	Endpoints []string
)

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

	SetupDeviceName = "/device/setup"

	ExportDataEndport  = "/exportData"
	ImportDataEndport  = "/importData"
	ExportStateEndport = "/exportState"
	ImportStateEndport = "/importState"
)

func RegisterPrivateEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc) {
	RegisterEndpoint(router, method, pattern, handler, false)
}

func RegisterPrivateGET(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPrivateEndpoint(router, "GET", pattern, handler)
}

func RegisterPrivatePOST(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPrivateEndpoint(router, "POST", pattern, handler)
}

func RegisterPublicEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc) {
	RegisterEndpoint(router, method, pattern, handler, true)
}

func RegisterPublicDELETE(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPublicEndpoint(router, "DELETE", pattern, handler)
}

func RegisterPublicGET(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPublicEndpoint(router, "GET", pattern, handler)
}

func RegisterPublicPATCH(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPublicEndpoint(router, "PATCH", pattern, handler)
}

func RegisterPublicPOST(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPublicEndpoint(router, "POST", pattern, handler)
}

func RegisterPublicPUT(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPublicEndpoint(router, "PUT", pattern, handler)
}

// RegisterEndpoint registers a handler and tracks the endpoint.
func RegisterEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc, public bool) {
	if public {
		Endpoints = append(Endpoints, fmt.Sprintf("%s %s", method, pattern))
	}
	router.HandleFunc(pattern, handler).Methods(method)
}

func ListRegisteredEndpoints(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]any{"routes": Endpoints})
}
