package server

import (
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/utils"
	"io"
	"net/http"
	"os"
	"strings"

	json "github.com/goccy/go-json"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	droConditionedOutputStateKey   = "dro_conditioned_output"
	fusionConnectAdditionsStateKey = "fusion_connect_additions"
)

func (s *FusionServer) GetDSPDeploymentPackage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	var pkg model.DeviceConfigurationPackage

	if value, exists := s.handler.StateManager.Get(droConditionedOutputStateKey); exists {
		var output model.DroConditionedOutput
		if err := decodeTypedJSON(value, &output); err != nil {
			http.Error(w, fmt.Sprintf("Error decoding %s: %v", droConditionedOutputStateKey, err), http.StatusInternalServerError)
			return
		}
		pkg.DroConditionedOutput = &output
	}

	if value, exists := s.handler.StateManager.Get(fusionConnectAdditionsStateKey); exists {
		var additions model.FusionConnectAdditions
		if err := decodeTypedJSON(value, &additions); err != nil {
			http.Error(w, fmt.Sprintf("Error decoding %s: %v", fusionConnectAdditionsStateKey, err), http.StatusInternalServerError)
			return
		}
		pkg.FusionConnectAdditions = &additions
	}

	if err := writeProtoJSON(w, &pkg); err != nil {
		http.Error(w, fmt.Sprintf("Error encoding DSP deployment package: %v", err), http.StatusInternalServerError)
	}
}

func (s *FusionServer) PutDSPDeploymentPackage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePut(w, r) {
		return
	}
	defer r.Body.Close()

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading body: %v", err), http.StatusBadRequest)
		return
	}

	var request model.DeviceConfigurationPackage
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
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

	resp := &model.DeviceConfigurationPackagePutResponse{Status: "success"}
	if diff == nil {
		resp.Status = "noop"
	} else {
		updates, err := structpb.NewStruct(diff)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error encoding response diff: %v", err), http.StatusInternalServerError)
			return
		}
		resp.Updates = updates
	}

	if err := writeProtoJSON(w, resp); err != nil {
		http.Error(w, fmt.Sprintf("Error encoding DSP deployment package response: %v", err), http.StatusInternalServerError)
	}
}

func buildDSPDeploymentStatePatch(request *model.DeviceConfigurationPackage) (map[string]any, error) {
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

func projectAudioSettings(settings *model.FusionConnectAudioSettings) (map[string]any, error) {
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
	var (
		data []byte
		err  error
	)
	if msg, ok := value.(proto.Message); ok {
		data, err = serverProtoJSONMarshalOptions.Marshal(msg)
	} else {
		data, err = json.Marshal(value)
	}
	if err != nil {
		return nil, err
	}

	var decoded any
	if err := json.Unmarshal(data, &decoded); err != nil {
		return nil, err
	}
	return decoded, nil
}

func decodeTypedJSON(input any, target proto.Message) error {
	data, err := json.Marshal(input)
	if err != nil {
		return err
	}
	return serverProtoJSONUnmarshalOptions.Unmarshal(data, target)
}

func deviceInfoToProto(info api.DeviceInfo) *model.DeviceInfo {
	return &model.DeviceInfo{
		Address:                  info.Address,
		Id:                       info.Id,
		Location:                 info.Location,
		Name:                     info.Name,
		ModelName:                info.ModelName,
		MacAddress:               info.MacAddress,
		SerialNumber:             info.SerialNumber,
		IsPrimary:                info.IsPrimaryNode,
		FirmwareVersion:          info.SoftwareVersion,
		IsDeviceCertificateValid: info.IsDeviceCertificateValid,
	}
}

func devicePatchFromProto(patch *model.DevicePatch) api.DevicePatch {
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
	response := &model.DeviceListResponse{
		Devices: make([]*model.DeviceInfo, 0, len(info)),
	}
	for _, device := range info {
		response.Devices = append(response.Devices, deviceInfoToProto(device))
	}

	if err := writeProtoJSON(w, response); err != nil {
		http.Error(w, fmt.Sprintf("Error encoding device info: %v", err), http.StatusInternalServerError)
	}
}

func (s *FusionServer) GetDeviceInfoLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	info := s.handler.HandleGetDeviceInfo()

	if err := writeProtoJSON(w, deviceInfoToProto(info)); err != nil {
		http.Error(w, fmt.Sprintf("Error encoding device info: %v", err), http.StatusInternalServerError)
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

	var patchProto model.DevicePatch
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &patchProto); err != nil {
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

	var patchProto model.DevicePatch
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &patchProto); err != nil {
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
		if os.IsNotExist(err) || errors.Is(err, os.ErrNotExist) || strings.Contains(strings.ToLower(err.Error()), "not found") {
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
		if os.IsNotExist(err) || errors.Is(err, os.ErrNotExist) || strings.Contains(strings.ToLower(err.Error()), "not found") {
			http.Error(w, fmt.Sprintf("Error setting device certificate: %v", err), http.StatusNotFound)
			return
		}
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
		if os.IsNotExist(err) || errors.Is(err, os.ErrNotExist) || strings.Contains(strings.ToLower(err.Error()), "not found") {
			http.Error(w, fmt.Sprintf("Error resetting device certificate: %v", err), http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Error resetting device certificate: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
