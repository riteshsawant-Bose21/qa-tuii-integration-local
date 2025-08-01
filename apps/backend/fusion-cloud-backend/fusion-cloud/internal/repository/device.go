package repository

import (
	"database/sql"
	"fmt"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/xyte"
)

type DeviceRepository struct {
	db      *sql.DB
	xyteSVC *xyte.Client
}

func NewDevice(db *sql.DB, xyteService *xyte.Client) *DeviceRepository {
	return &DeviceRepository{
		db:      db,
		xyteSVC: xyteService,
	}
}

// ClaimDevice claims a device using the XYTE service.
func (o *DeviceRepository) ClaimDevice(dvcObj *model.ClaimDeviceRequest) (*model.Device, error) {
	dvc, err := o.xyteSVC.ClaimDevice(dvcObj)
	if err != nil {
		return nil, fmt.Errorf("xyte client error :%w", err)
	}

	return dvc, nil
}

func (o *DeviceRepository) GetAllDevices() (*model.Device, error) {
	devices, err := o.xyteSVC.GetAllDevices()
	if err != nil {
		return nil, fmt.Errorf("xyte client error :%w", err)
	}

	if devices == nil {
		return nil, fmt.Errorf("no devices found")
	}

	return devices, nil
}

// GetDeviceHistories retrieves the history of a device by its ID.
func (o *DeviceRepository) GetDeviceHistories(device *model.DeviceRequest) (*model.DeviceHistory, error) {
	histories, err := o.xyteSVC.GetDeviceHistories(device)
	if err != nil {
		return nil, fmt.Errorf("xyte client error :%w", err)
	}

	if histories == nil {
		return nil, fmt.Errorf("no device histories found for id: %s", device.ID)
	}

	return histories, nil
}
