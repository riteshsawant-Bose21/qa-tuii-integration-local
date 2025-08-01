package handler

import (
	"encoding/json"
	"fmt"
	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/middleware"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"
	"net/http"

	"github.com/go-chi/chi/v5"
)

type Device struct {
	svc *service.Device
}

func NewDevice(svc *service.Device) *Device {
	return &Device{
		svc: svc,
	}
}

func (o *Device) RegisterRoutes(r chi.Router) {
	r.Get("/", o.GetDevices)
	r.Post("/claim", o.ClaimDevice)
	r.Get("/histories", o.GetDeviceHistories)
}

// ClaimDevice godoc
// @Summary      claim a device
// @Description  Claim a device by its ID
// @Tags         device
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        device  body model.ClaimDeviceRequest  true  "Device details"
// @Success      200  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /devices/claim [post]
func (o *Device) ClaimDevice(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}
	var dvcObj model.ClaimDeviceRequest
	if err := json.NewDecoder(r.Body).Decode(&dvcObj); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}
	device, err := o.svc.ClaimDevice(&dvcObj)
	if err != nil {
		fmt.Println("Error response returned", err)
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgDeviceClaimFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgDeviceClaimed, device)
}

// GetDevices godoc
// @Summary      get a device
// @Description  Get all devices
// @Tags         device
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /devices [get]
func (o *Device) GetDevices(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	devices, err := o.svc.GetDevices()
	if err != nil {
		fmt.Println("Error response returned", err)
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgGetDeviceFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgGetDevice, devices)
}

// GetDeviceHistories godoc
// @Summary      Get Device Histories
// @Description  Get Device Histories by various filters
// @Tags         device
// @Security     BearerAuth
// @Produce      json
// @Param        device_id  query     string  true   "Device ID"
// @Param        status     query    string  false  "Device status"
// @Param        from       query    string  false  "From time (ISO8601 or timestamp)"
// @Param        to         query    string  false  "To time (ISO8601 or timestamp)"
// @Param        space_id   query    string  false  "Space ID"
// @Param        name       query    string  false  "Device name"
// @Success      200  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /devices/histories [get]
func (o *Device) GetDeviceHistories(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	device := &model.DeviceRequest{}
	if r.URL.Query().Get("status") != "" {
		if r.URL.Query().Get("status") != "online" || r.URL.Query().Get("status") != "offline" ||
			r.URL.Query().Get("status") != "unavailable" || r.URL.Query().Get("status") != "error" {
			utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
			return
		}
		device.Status = r.URL.Query().Get("status")
	}

	if r.URL.Query().Get("from") != "" {
		device.FromTime = r.URL.Query().Get("from")
	}
	if r.URL.Query().Get("to") != "" {
		device.FromTime = r.URL.Query().Get("to")
	}
	if r.URL.Query().Get("device_id") == "" {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}
	device.ID = r.URL.Query().Get("device_id")
	if r.URL.Query().Get("space_id") != "" {
		device.SpaceID = r.URL.Query().Get("space_id")
	}
	if r.URL.Query().Get("name") != "" {
		device.Name = r.URL.Query().Get("name")
	}

	histories, err := o.svc.GetDeviceHistories(device)
	if err != nil {
		fmt.Println("Error response returned", err)
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgDeviceHistoryFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgDeviceHistory, histories)
}