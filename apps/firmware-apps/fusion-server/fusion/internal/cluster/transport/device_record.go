package transport

import model "fusion/internal/gen/proto/fusion"

// DeviceRecord is the internal cluster-safe representation used for device
// list aggregation and target lookups. It avoids carrying protobuf message
// state through the broader transport and handler surfaces.
type DeviceRecord struct {
	Address                  string
	Id                       string
	Location                 string
	Name                     string
	ModelName                string
	MacAddress               string
	SerialNumber             string
	IsPrimary                bool
	SoftwareUpdateVersion    string
	IsDeviceCertificateValid bool
	FusionMonorepoBranch     string
	FusionMonorepoCommitHash string
	BuildNumber              string
	PreReleaseTag            string
	VrrpPriority             int32
	Lan1MacAddress           string
	Lan2MacAddress           string
	WifiMacAddress           string
	BluetoothMacAddress      string
}

func NewDeviceRecordFromProto(info *model.DeviceInfo) DeviceRecord {
	if info == nil {
		return DeviceRecord{}
	}

	return DeviceRecord{
		Address:                  info.Address,
		Id:                       info.Id,
		Location:                 info.Location,
		Name:                     info.Name,
		ModelName:                info.ModelName,
		MacAddress:               info.MacAddress,
		SerialNumber:             info.SerialNumber,
		IsPrimary:                info.IsPrimary,
		SoftwareUpdateVersion:    info.SoftwareUpdateVersion,
		IsDeviceCertificateValid: info.IsDeviceCertificateValid,
		FusionMonorepoBranch:     info.FusionMonorepoBranch,
		FusionMonorepoCommitHash: info.FusionMonorepoCommitHash,
		BuildNumber:              info.BuildNumber,
		PreReleaseTag:            info.PreReleaseTag,
		VrrpPriority:             info.VrrpPriority,
		Lan1MacAddress:           info.Lan1MacAddress,
		Lan2MacAddress:           info.Lan2MacAddress,
		WifiMacAddress:           info.WifiMacAddress,
		BluetoothMacAddress:      info.BluetoothMacAddress,
	}
}

func (d DeviceRecord) ToProto() *model.DeviceInfo {
	return &model.DeviceInfo{
		Address:                  d.Address,
		Id:                       d.Id,
		Location:                 d.Location,
		Name:                     d.Name,
		ModelName:                d.ModelName,
		MacAddress:               d.MacAddress,
		SerialNumber:             d.SerialNumber,
		IsPrimary:                d.IsPrimary,
		SoftwareUpdateVersion:    d.SoftwareUpdateVersion,
		IsDeviceCertificateValid: d.IsDeviceCertificateValid,
		FusionMonorepoBranch:     d.FusionMonorepoBranch,
		FusionMonorepoCommitHash: d.FusionMonorepoCommitHash,
		BuildNumber:              d.BuildNumber,
		PreReleaseTag:            d.PreReleaseTag,
		VrrpPriority:             d.VrrpPriority,
		Lan1MacAddress:           d.Lan1MacAddress,
		Lan2MacAddress:           d.Lan2MacAddress,
		WifiMacAddress:           d.WifiMacAddress,
		BluetoothMacAddress:      d.BluetoothMacAddress,
	}
}
