package model

type SpaceRequest struct {
	ID       string `json:"id,omitempty"`
	Name     string `json:"name"`
	ParentID string `json:"parent_id"`
}
type UpdateSpaceRequest struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	ParentID string `json:"parent_id"`
}

type SpaceUpdateResponse struct {
	ID       int64       `json:"id"`
	Name     string      `json:"name"`
	ParentID int64       `json:"parent_id"`
	Config   SpaceConfig `json:"config"`
}

type SpaceConfig struct {
	Img                     interface{} `json:"img"`
	PriorityFactor          int64       `json:"priority_factor"`
	InheritLocation         bool        `json:"inherit_location"`
	TemperatureUnits        string      `json:"temperature_units"`
	InheritPriorityFactor   bool        `json:"inherit_priority_factor"`
	InheritTemperatureUnits bool        `json:"inherit_temperature_units"`
}

type Space struct {
	Items    []Item      `json:"items"`
	NextPage interface{} `json:"next_page"`
}

type Item struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	ParentID *int64 `json:"parent_id"`
	Config   Config `json:"config"`
	Path     string `json:"path"`
}

type Config struct {
	Img                     string           `json:"img"`
	Location                ConfigLocation   `json:"location"`
	PriorityFactor          int64            `json:"priority_factor"`
	TemperatureUnits        TemperatureUnits `json:"temperature_units"`
	InheritImg              *bool            `json:"inherit_img,omitempty"`
	InheritLocation         *bool            `json:"inherit_location,omitempty"`
	InheritPriorityFactor   *bool            `json:"inherit_priority_factor,omitempty"`
	InheritTemperatureUnits *bool            `json:"inherit_temperature_units,omitempty"`
}

type ConfigLocation struct {
	Location    LocationLocation `json:"location"`
	UTCOffset   int64            `json:"utc_offset"`
	Description Description      `json:"description"`
	RegionName  RegionName       `json:"region_name"`
}

type LocationLocation struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

type Description string

type RegionName string

type TemperatureUnits string
