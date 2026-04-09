package app

import (
	"net/http"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
	"fusion/internal/utils"
)

func (app *App) HandleUDPStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	if !app.config.UDPDiagnostics {
		http.NotFound(w, r)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(app.UDPServer.Stats())
}
