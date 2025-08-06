package xyte

import (
	"encoding/json"
	"fmt"
	"fusion-cloud/internal/model"
	"io"
	"net/http"
)

func (c *Client) GetOrganizationDetails() (*model.Organization, error) {
	body := io.Reader(nil) // No body needed for GET request
	resp, err := c.MakeRequest("info", http.MethodGet, body, nil)
	if err != nil {
		return nil, fmt.Errorf("error making GET request: %w", err)
	}
	defer resp.Close()
	var s model.Organization
	bodyBytes, err := io.ReadAll(resp)
	if err != nil {
		return nil, fmt.Errorf("error reading response body: %w", err)
	}
	if err := json.Unmarshal(bodyBytes, &s); err != nil {
		return nil, fmt.Errorf("error decode json: %w", err)
	}

	return &s, nil
}
