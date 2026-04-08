package app

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"fusion/internal/api"
	"fusion/internal/utils"

	"github.com/brutella/dnssd"
	json "github.com/goccy/go-json"
	"github.com/gorilla/mux"
)

type mdnsResolveResponse struct {
	Host     string   `json:"host"`
	IPs      []string `json:"ips"`
	Instance string   `json:"instance"`
	Port     int      `json:"port"`
}

// HandleResolveLocalMDNS resolves a Fusion mDNS service from inside the node.
// This is intended for integration tests so they can verify guest-side
// discovery using only REST calls.
func (app *App) HandleResolveLocalMDNS(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	service := mux.Vars(r)["service"]
	if service == "" {
		http.Error(w, "missing service name", http.StatusBadRequest)
		return
	}

	instance := fmt.Sprintf("%s._fusion._tcp.local.", service)
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	svc, err := dnssd.LookupInstance(ctx, instance)
	if err != nil {
		http.Error(w, fmt.Sprintf("resolve %s: %v", instance, err), http.StatusGatewayTimeout)
		return
	}

	ips := make([]string, 0, len(svc.IPs))
	for _, ip := range svc.IPs {
		ips = append(ips, ip.String())
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	_ = json.NewEncoder(w).Encode(mdnsResolveResponse{
		Host:     svc.Hostname(),
		IPs:      ips,
		Instance: svc.ServiceInstanceName(),
		Port:     svc.Port,
	})
}
