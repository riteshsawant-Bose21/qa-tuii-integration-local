package server

import (
	stdjson "encoding/json"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/utils"
	"io"
	"net/http"
	"os"

	json "github.com/goccy/go-json"
	"google.golang.org/protobuf/encoding/protojson"
)

const (
	droConditionedOutputStateKey   = "dro_conditioned_output"
	fusionConnectAdditionsStateKey = "fusion_connect_additions"
)

func (s *FusionServer) GetDSPDeploymentPackage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	var pkg fusionpb.DeviceConfigurationPackage

	if value, exists := s.handler.StateManager.Get(droConditionedOutputStateKey); exists {
		if err := decodeTypedJSON(value, &pkg.DroConditionedOutput); err != nil {
			http.Error(w, fmt.Sprintf("Error decoding %s: %v", droConditionedOutputStateKey, err), http.StatusInternalServerError)
			return
		}
	}

	if value, exists := s.handler.StateManager.Get(fusionConnectAdditionsStateKey); exists {
		if err := decodeTypedJSON(value, &pkg.FusionConnectAdditions); err != nil {
			http.Error(w, fmt.Sprintf("Error decoding %s: %v", fusionConnectAdditionsStateKey, err), http.StatusInternalServerError)
			return
		}
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := stdjson.NewEncoder(w).Encode(pkg); err != nil {
		logging.GetLogger().Error("Error encoding DSP deployment package: %v", err)
	}
}

func (s *FusionServer) PutDSPDeploymentPackage(w http.ResponseWriter, r *http.Request) {
	type putResponse struct {
		Status  string         `json:"status"`
		Updates map[string]any `json:"updates,omitempty"`
	}

	if !utils.RequirePut(w, r) {
		return
	}
	defer r.Body.Close()

	var request fusionpb.DeviceConfigurationPackage
	if err := stdjson.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	if request.DroConditionedOutput == nil {
		http.Error(w, "dro_conditioned_output is required", http.StatusBadRequest)
		return
	}
	if request.FusionConnectAdditions == nil {
		http.Error(w, "fusion_connect_additions is required", http.StatusBadRequest)
		return
	}
	if request.FusionConnectAdditions.Settings == nil {
		http.Error(w, "fusion_connect_additions.settings is required", http.StatusBadRequest)
		return
	}

	update, err := buildDSPDeploymentStatePatch(&request)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid DSP deployment package: %v", err), http.StatusBadRequest)
		return
	}

	diff, err := s.handler.HandleHTTPPatch(update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp := putResponse{Status: "success", Updates: diff}
	if diff == nil {
		resp.Status = "noop"
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		logging.GetLogger().Error("Error encoding DSP deployment package response: %v", err)
	}
}

func buildDSPDeploymentStatePatch(request *fusionpb.DeviceConfigurationPackage) (map[string]any, error) {
	if request == nil || request.DroConditionedOutput == nil || request.FusionConnectAdditions == nil || request.FusionConnectAdditions.Settings == nil {
		return nil, fmt.Errorf("DSP deployment package is incomplete")
	}

	droConditionedOutput, err := encodeTypedJSON(request.DroConditionedOutput)
	if err != nil {
		return nil, fmt.Errorf("encode dro_conditioned_output: %w", err)
	}

	fusionConnectAdditions, err := encodeTypedJSON(request.FusionConnectAdditions)
	if err != nil {
		return nil, fmt.Errorf("encode fusion_connect_additions: %w", err)
	}

	devices, err := encodeTypedJSON(request.DroConditionedOutput.Devices)
	if err != nil {
		return nil, fmt.Errorf("encode devices: %w", err)
	}

	audioStreams, err := encodeTypedJSON(request.FusionConnectAdditions.AudioStreams)
	if err != nil {
		return nil, fmt.Errorf("encode audio_streams: %w", err)
	}

	settings, err := projectAudioSettings(request.FusionConnectAdditions.Settings)
	if err != nil {
		return nil, fmt.Errorf("project settings: %w", err)
	}

	return map[string]any{
		droConditionedOutputStateKey:   droConditionedOutput,
		fusionConnectAdditionsStateKey: fusionConnectAdditions,
		"devices":                      devices,
		"audio_streams":                audioStreams,
		"settings":                     settings,
	}, nil
}

func projectAudioSettings(settings *fusionpb.FusionConnectAudioSettings) (map[string]any, error) {
	if settings == nil {
		return nil, fmt.Errorf("settings are nil")
	}

	audio := make(map[string]any, len(settings.Audio))
	for blockID, block := range settings.Audio {
		if block == nil {
			audio[blockID] = map[string]any{}
			continue
		}

		projectedBlock := make(map[string]any, len(block.Parameters))
		for param, value := range block.Parameters {
			if value == nil {
				projectedBlock[param] = nil
				continue
			}
			projectedBlock[param] = value.AsInterface()
		}
		audio[blockID] = projectedBlock
	}

	return map[string]any{
		"audio": audio,
	}, nil
}

func encodeTypedJSON(value any) (any, error) {
	data, err := stdjson.Marshal(value)
	if err != nil {
		return nil, err
	}

	var decoded any
	if err := stdjson.Unmarshal(data, &decoded); err != nil {
		return nil, err
	}
	return decoded, nil
}

func decodeTypedJSON(input any, target any) error {
	data, err := stdjson.Marshal(input)
	if err != nil {
		return err
	}
	return stdjson.Unmarshal(data, target)
}

func deviceInfoToProto(info api.DeviceInfo) *fusionpb.DeviceInfo {
	return &fusionpb.DeviceInfo{
		Address:                  info.Address,
		Id:                       info.Id,
		Location:                 info.Location,
		Name:                     info.Name,
		ModelName:                info.ModelName,
		MacAddress:               info.MacAddress,
		SerialNumber:             info.SerialNumber,
		IsPrimary:                info.IsPrimaryNode,
		FirmwareVersion:          info.FirmwareVersion,
		IsDeviceCertificateValid: info.IsDeviceCertificateValid,
	}
}

func devicePatchFromProto(patch *fusionpb.DevicePatch) api.DevicePatch {
	if patch == nil {
		return api.DevicePatch{}
	}

	var out api.DevicePatch
	if patch.Id != nil {
		out.Id = patch.Id
	}
	if patch.Location != nil {
		out.Location = patch.Location
	}
	if patch.Name != nil {
		out.Name = patch.Name
	}
	return out
}

func (s *FusionServer) GetDevicesInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	info := s.handler.HandleGetDevicesInfo()
	response := &fusionpb.DeviceListResponse{
		Devices: make([]*fusionpb.DeviceInfo, 0, len(info)),
	}
	for _, device := range info {
		response.Devices = append(response.Devices, deviceInfoToProto(device))
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := stdjson.NewEncoder(w).Encode(response); err != nil {
		logging.GetLogger().Error("Error encoding device info: %v", err)
	}

}

func (s *FusionServer) GetDeviceInfoLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	info := s.handler.HandleGetDeviceInfo()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := stdjson.NewEncoder(w).Encode(deviceInfoToProto(info)); err != nil {
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

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading body: %v", err), http.StatusInternalServerError)
		return
	}

	var patchProto fusionpb.DevicePatch
	if err := protojson.Unmarshal(body, &patchProto); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	patch := devicePatchFromProto(&patchProto)
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

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading body: %v", err), http.StatusInternalServerError)
		return
	}

	var patchProto fusionpb.DevicePatch
	if err := protojson.Unmarshal(body, &patchProto); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	patch := devicePatchFromProto(&patchProto)
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
