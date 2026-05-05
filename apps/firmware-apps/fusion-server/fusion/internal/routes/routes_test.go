package routes

import (
	"net/http"
	"testing"

	"github.com/gorilla/mux"
)

func TestRegisterEndpointTracksFullPattern(t *testing.T) {
	originalEndpoints := Endpoints
	t.Cleanup(func() {
		Endpoints = originalEndpoints
	})
	Endpoints = nil

	RegisterPublicPOST(mux.NewRouter(), SnapshotsActivateEndpoint, func(w http.ResponseWriter, r *http.Request) {})

	got := Endpoints
	want := []string{"POST /snapshots/activate/{id}"}
	if len(got) != len(want) || got[0] != want[0] {
		t.Fatalf("Endpoints = %v, want %v", got, want)
	}
}
