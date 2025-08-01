package service

import (
	"fmt"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/utils"
	"fusion-cloud/internal/utils/jwtutil"
)

type Device struct {
	repo       *repository.DeviceRepository
	jwtManager *jwtutil.JWTManager
}

func NewDevice(deviceRepo *repository.DeviceRepository, jwt *jwtutil.JWTManager) *Device {
	return &Device{
		repo:       deviceRepo,
		jwtManager: jwt,
	}
}

func (o *Device) ClaimDevice(dvcObj *model.ClaimDeviceRequest) (*model.Device, error) {
	device, err := o.repo.ClaimDevice(dvcObj)
	if err != nil {
		return nil, fmt.Errorf("error while getting device in service: %v", err)
	}
	if device == nil {
		return nil, utils.ErrDeviceNotFound
	}
	return device, nil
}

func (o *Device) GetDevices() (*model.Device, error) {
	devices, err := o.repo.GetAllDevices()
	if err != nil {
		return nil, fmt.Errorf("error while getting devices in service: %v", err)
	}
	if devices == nil {
		return nil, utils.ErrDeviceNotFound
	}
	return devices, nil
}

func (o *Device) GetDeviceHistories(device *model.DeviceRequest) (*model.DeviceHistory, error) {
	histories, err := o.repo.GetDeviceHistories(device)
	if err != nil {
		return nil, fmt.Errorf("error while getting device histories in service: %v", err)
	}
	if histories == nil {
		return nil, utils.ErrDeviceNotFound
	}
	return histories, nil
}
