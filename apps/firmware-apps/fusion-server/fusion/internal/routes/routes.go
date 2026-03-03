package routes

import (
	"fmt"
	"fusion/internal/api"
	"net/http"

	json "github.com/goccy/go-json"

	"github.com/gorilla/mux"
)

var (
	Endpoints []string
)

const (
	//
	// Public
	//

	AudioEndpoint = "/audio"

	ClusterEndpoint                            = "/cluster"
	ClusterLatencyEndpoint                     = ClusterEndpoint + "/latency"
	ClusterLatencyNetworkEndpoint              = ClusterLatencyEndpoint + "/network"
	ClusterLatencyNetworkLocalEndpoint         = ClusterLatencyNetworkEndpoint + "/local"
	ClusterLatencyNetworkFailuresEndpoint      = ClusterLatencyNetworkEndpoint + "/failures"
	ClusterLatencyNetworkFailuresLocalEndpoint = ClusterLatencyNetworkEndpoint + "/failures/local"
	ClusterLatencyStatusEndpoint               = ClusterLatencyEndpoint + "/status"
	ClusterLatencyStatusLocalEndpoint          = ClusterLatencyStatusEndpoint + "/local"
	ClusterLatencySyncEndpoint                 = ClusterLatencyEndpoint + "/sync"
	ClusterLatencySyncLocalEndpoint            = ClusterLatencySyncEndpoint + "/local"
	ClusterLatencySyncAveragesEndpoint         = ClusterLatencySyncEndpoint + "/averages"
	ClusterLatencySyncAveragesLocalEndpoint    = ClusterLatencySyncEndpoint + "/averages/local"
	ClusterMembersEndpoint                     = ClusterEndpoint + "/members"
	ClusterNTPSkewEndpoint                     = ClusterEndpoint + "/ntp-skew"
	ClusterStatusEndpoint                      = ClusterEndpoint + "/status"

	ClusterRebootEndpoint      = ClusterEndpoint + "/reboot"
	ClusterRebootLocalEndpoint = ClusterRebootEndpoint

	ControllersEndpoint       = "/controllers"
	ControllersIDEndpoint     = ControllersEndpoint + "/{id}"
	ControllersIDWinkEndpoint = ControllersEndpoint + "/wink" + "/{id}"

	DeviceEndpoint          = "/device"
	DeviceReloadEndpoint    = DeviceEndpoint + "/reload"
	DeviceReloadVIPEndpoint = DeviceReloadEndpoint + "/vip"
	DeviceIDEndpoint        = DeviceEndpoint + "/{id}"

	DevicesEndpoint       = "/devices"
	DevicesIDEndpoint     = DevicesEndpoint + "/{id}"
	DevicesVIPEndpoint    = DevicesEndpoint + "/vip"
	DevicesSetVIPEndpoint = DevicesVIPEndpoint + "/{vip}"

	EndpointsEndpoint = "/endpoints"

	HealthEndpoint = "/health"

	MetadataEndpoint = "/metadata"

	MetricsEndpoint = "/metrics"

	PAVAEndpoint               = "/pava"
	PAVAAlarmsEndpoint         = PAVAEndpoint + "/alarms"
	PAVADiagnosticsEndpoint    = PAVAEndpoint + "/diagnostics"
	PAVAMessagesEndpoint       = PAVAEndpoint + "/messages"
	PAVAScheduleEndpoint       = PAVAEndpoint + "/schedule"
	PAVAStatusEndpoint         = PAVAEndpoint + "/status"
	PAVAZonesEndpoint          = PAVAEndpoint + "/zones"
	PAVAMessagesIDEndpoint     = PAVAMessagesEndpoint + "/{id}"
	PAVAMessagesTagsEndpoint   = PAVAMessagesEndpoint + "/tags"
	PAVAScheduleIDEndpoint     = PAVAScheduleEndpoint + "/{id}"
	PAVAMessageStreamEndpoint  = PAVAMessagesIDEndpoint + "/stream"
	PAVAMessageTriggerEndpoint = PAVAMessagesIDEndpoint + "/trigger"
	PAVAZoneStatusEndpoint     = PAVAZonesEndpoint + "/status/{name}"

	RootEndpoint = "/"

	SessionsEndpoint   = "/sessions"
	SessionsIdEndpoint = SessionsEndpoint + "/{id}"

	SnapshotsEndpoint         = "/snapshots"
	SnapshotsMetaEndpoint     = SnapshotsEndpoint + "/meta"
	SnapshotsActiveEndpoint   = SnapshotsMetaEndpoint + "/active"
	SnapshotsNameEndpoint     = SnapshotsEndpoint + "/{name}"
	SnapshotsActivateEndpoint = SnapshotsEndpoint + "/activate/{name}"
	SnapshotsUpdateEndpoint   = SnapshotsEndpoint + "/update/{name}"

	TasksEndpoint          = "/tasks"
	TasksHistoryEndpoint   = TasksEndpoint + "/history"
	TasksIdEndpoint        = TasksEndpoint + "/{id}"
	TasksIdDisableEndpoint = TasksIdEndpoint + "/disable"
	TasksIdEnableEndpoint  = TasksIdEndpoint + "/enable"

	ValueEndpoint = "/value"

	VersionEndpoint = "/version"

	WebsocketEndpoint = "/ws"

	//
	// Private
	//

	DataEndpoint  = "/data"
	StateEndpoint = "/state"
)

func RegisterPrivateEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc) {
	RegisterEndpoint(router, method, pattern, handler, false)
}

func RegisterPrivateGET(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPrivateEndpoint(router, "GET", pattern, handler)
}

func RegisterPrivatePATCH(router *mux.Router, pattern string, handler http.HandlerFunc) {
	RegisterPrivateEndpoint(router, "PATCH", pattern, handler)
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
	// Register OPTIONS method for CORS preflight requests
	router.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}).Methods("OPTIONS")
}

func ListRegisteredEndpoints(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]any{"routes": Endpoints})
}
