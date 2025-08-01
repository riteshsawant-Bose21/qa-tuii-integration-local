package model

type ClaimDeviceRequest struct {
	Name    string `json:"name"`
	SpaceID int64  `json:"space_id"`
	CloudID string `json:"cloud_id"`
	Mac     string `json:"mac"`
	SN      string `json:"sn"`
}
type DeviceRequest struct {
	ID       string `json:"device_id"`
	Name     string `json:"name"`
	Status   string `json:"status"`
	FromTime string `json:"from_time"`
	ToTime   string `json:"to_time"`
	SpaceID  string `json:"space_id"`
	CloudID  string `json:"cloud_id"`
}

type Device struct {
	Items    []DeviceItem `json:"items"`
	NextPage interface{}  `json:"next_page"`
}

type DeviceItem struct {
	ID         string      `json:"id"`
	Name       string      `json:"name"`
	Sn         string      `json:"sn"`
	MAC        *string     `json:"mac"`
	CloudID    *string     `json:"cloud_id"`
	Status     Status      `json:"status"`
	LastSeenAt string      `json:"last_seen_at"`
	Details    *Details    `json:"details"`
	State      State       `json:"state"`
	Model      Model       `json:"model"`
	Firmware   Firmware    `json:"firmware"`
	Space      DeviceSpace `json:"space"`
}

type Details struct {
	DHCP            *bool   `json:"DHCP,omitempty"`
	IPAddress       *string `json:"IpAddress,omitempty"`
	ExtraStaticData *int64  `json:"extra_static_data,omitempty"`
}

type Firmware struct {
	Version string `json:"version"`
}

type Model struct {
	ID       string      `json:"id"`
	Name     string      `json:"name"`
	SubModel interface{} `json:"sub_model"`
}

type DeviceSpace struct {
	ID       int64    `json:"id"`
	FullPath FullPath `json:"full_path"`
}

type State struct {
	Status           Status   `json:"status"`
	State            *string  `json:"state,omitempty"`
	Output1          *float64 `json:"Output-1,omitempty"`
	Output2          *float64 `json:"Output-2,omitempty"`
	Output3          *float64 `json:"Output-3,omitempty"`
	Output4          *float64 `json:"Output-4,omitempty"`
	DanteIn1         *float64 `json:"Dante_in-1,omitempty"`
	DanteIn2         *float64 `json:"Dante_in-2,omitempty"`
	DanteIn3         *float64 `json:"Dante_in-3,omitempty"`
	DanteIn4         *float64 `json:"Dante_in-4,omitempty"`
	AnalogIn1        *float64 `json:"Analog_in-1,omitempty"`
	AnalogIn2        *float64 `json:"Analog_in-2,omitempty"`
	AnalogIn3        *float64 `json:"Analog_in-3,omitempty"`
	AnalogIn4        *float64 `json:"Analog_in-4,omitempty"`
	InputType1       *string  `json:"input-type1,omitempty"`
	InputType2       *string  `json:"input-type2,omitempty"`
	InputType3       *string  `json:"input-type3,omitempty"`
	InputType4       *string  `json:"input-type4,omitempty"`
	Clip             *int64   `json:"clip,omitempty"`
	Limit            *int64   `json:"limit,omitempty"`
	Signal           *string  `json:"signal,omitempty"`
	Tempfault        *int64   `json:"tempfault,omitempty"`
	Driverfault      *int64   `json:"driverfault,omitempty"`
	SignalType       *string  `json:"signal_type,omitempty"`
	ModuleCount      *string  `json:"module_count,omitempty"`
	Cc16             *string  `json:"CC-16 ,omitempty"`
	NetRx            *float64 `json:"net_rx,omitempty"`
	NetTx            *float64 `json:"net_tx,omitempty"`
	RAMUsed          *int64   `json:"ram_used,omitempty"`
	DSPMemory        *float64 `json:"dsp-memory,omitempty"`
	SystemLoad       *float64 `json:"system_load,omitempty"`
	DanteSignal      *string  `json:"Dante-signal,omitempty"`
	AnalogIn11       *float64 `json:"analog_in_1-1,omitempty"`
	AnalogIn12       *float64 `json:"analog_in_1-2,omitempty"`
	AnalogIn13       *float64 `json:"analog_in_1-3,omitempty"`
	AnalogIn14       *float64 `json:"analog_in_1-4,omitempty"`
	AnalogIn25       *float64 `json:"analog_in_2-5,omitempty"`
	AnalogIn26       *float64 `json:"analog_in_2-6,omitempty"`
	AnalogIn27       *float64 `json:"analog_in_2-7,omitempty"`
	AnalogIn28       *float64 `json:"analog_in_2-8,omitempty"`
	AnalogIn39       *float64 `json:"analog_in_3-9,omitempty"`
	AnalogIn310      *float64 `json:"analog_in_3-10,omitempty"`
	AnalogIn311      *float64 `json:"analog_in_3-11,omitempty"`
	AnalogIn312      *float64 `json:"analog_in_3-12,omitempty"`
	AnalogOut11      *float64 `json:"analog_out_1-1,omitempty"`
	AnalogOut12      *float64 `json:"analog_out_1-2,omitempty"`
	AnalogOut13      *float64 `json:"analog_out_1-3,omitempty"`
	AnalogOut14      *float64 `json:"analog_out_1-4,omitempty"`
	AnalogOut25      *float64 `json:"analog_out_2-5,omitempty"`
	AnalogOut26      *float64 `json:"analog_out_2-6,omitempty"`
	AnalogOut27      *float64 `json:"analog_out_2-7,omitempty"`
	AnalogOut28      *float64 `json:"analog_out_2-8,omitempty"`
	AmplinkSignal1   *float64 `json:"Amplink-signal1,omitempty"`
	AmplinkSignal2   *float64 `json:"Amplink-signal2,omitempty"`
	AmplinkSignal3   *float64 `json:"Amplink-signal3,omitempty"`
	AmplinkSignal4   *float64 `json:"Amplink-signal4,omitempty"`
	AmplinkSignal5   *float64 `json:"Amplink-signal5,omitempty"`
	AmplinkSignal6   *float64 `json:"Amplink-signal6,omitempty"`
	AmplinkSignal7   *float64 `json:"Amplink-signal7,omitempty"`
	AmplinkSignal8   *float64 `json:"Amplink-signal8,omitempty"`
	LastParameterSet *string  `json:"last_parameter_set,omitempty"`
}

type FullPath string

const (
	OverviewBoseProfessionalLab          FullPath = "Overview/bose-professional lab"
	OverviewBoseProfessionalLabJDProduct FullPath = "Overview/bose-professional lab/JD-Product"
	OverviewBoseProfessionalLabOthers    FullPath = "Overview/bose-professional lab/others"
	OverviewBoseProfessionalLabSujithDev FullPath = "Overview/bose-professional lab/Sujith Dev"
	OverviewBoseProfessionalLabUnsorted  FullPath = "Overview/bose-professional lab/Unsorted"
)

type Status string

const (
	Offline Status = "offline"
	Online  Status = "online"
)

type DeviceHistory struct {
	Items       []DeviceHistoryItem `json:"items"`
	HasNextPage bool                `json:"has_next_page"`
}

type DeviceHistoryItem struct {
	UUID     string               `json:"uuid"`
	CreateAt string               `json:"create_at"`
	Name     DeviceHistoryName    `json:"name"`
	SpaceID  int64                `json:"space_id"`
	Model    string               `json:"model"`
	Partner  DeviceHistoryPartner `json:"partner"`
	State    State                `json:"state"`
}

type DeviceHistoryState struct {
	Status     Status `json:"status"`
	RAMUsed    int64  `json:"ram_used"`
	SystemLoad int64  `json:"system_load"`
}

type DeviceHistoryModel string

type DeviceHistoryName string

type DeviceHistoryPartner string

type DeviceHistoryStatus string