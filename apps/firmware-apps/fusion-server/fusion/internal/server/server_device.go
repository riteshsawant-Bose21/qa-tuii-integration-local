package server

import (
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/utils"
	"io"
	"net/http"
	"os"

	json "github.com/goccy/go-json"
)

func (s *FusionServer) GetDevicesInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	info := s.handler.HandleGetDevicesInfo()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(info); err != nil {
		logging.GetLogger().Error("Error encoding device info: %v", err)
	}

}

func (s *FusionServer) GetDeviceInfoLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	info := s.handler.HandleGetDeviceInfo()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(info); err != nil {
		logging.GetLogger().Error("Error encoding device info: %v", err)
	}
}

func (c *FusionServer) UpdateDeviceInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePatch(w, r) {
		return
	}
	defer r.Body.Close()

	deviceId, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var patch api.DevicePatch
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	if err := c.handler.HandleUpdateDeviceInfo(deviceId, patch); err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (c *FusionServer) UpdateDeviceInfoLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePatch(w, r) {
		return
	}
	defer r.Body.Close()

	var patch api.DevicePatch
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	if err := c.handler.HandleUpdateDeviceInfoLocal(patch); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (c *FusionServer) GetCSR(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	deviceID, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	csr, err := c.handler.HandleGetCSR(deviceID)
	if err != nil {
		if os.IsNotExist(err) {
			http.Error(w, err.Error(), http.StatusNotFound)
		} else {
			http.Error(w, fmt.Sprintf("Error getting CSR: %v", err), http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set(api.ContentType, api.TextMIMEType)
	w.Write(csr)
}

func (c *FusionServer) SetDeviceCertificate(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	deviceId, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	certBytes, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading certificate: %v", err), http.StatusBadRequest)
		return
	}

	err = c.handler.HandleSetDeviceCertificate(deviceId, certBytes)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error setting device certificate: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (c *FusionServer) ResetDeviceCertificate(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	deviceId, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err = c.handler.ResetDeviceCertificate(deviceId)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error resetting device certificate: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
