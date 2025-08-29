package fusion

type Budget struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
}

type Project struct {
	ID             string                 `json:"id"`
	OrganizationID string                 `json:"organization_id"`
	Name           string                 `json:"name"`
	Description    string                 `json:"description"`
	Venue          string                 `json:"venue"`
	VenueType      string                 `json:"venue_type"`
	Application    string                 `json:"application"`
	Budget         Budget                 `json:"budget"`
	MetaData       map[string]interface{} `json:"meta_data"`
	ProjectFileURL string                 `json:"project_file_url"`
}
