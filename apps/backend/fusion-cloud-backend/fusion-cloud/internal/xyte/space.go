package xyte

import (
	"encoding/json"
	"fmt"
	"fusion-cloud/internal/model"
	"io"
	"net/http"
	"strings"
)

func (c *Client) GetAllSpaces() (*model.Space, error) {
	resp, err := c.MakeRequest("spaces", http.MethodGet, nil, nil)
	if err != nil {
		return nil, fmt.Errorf("error making POST request: %w", err)
	}
	defer resp.Close()

	var spaces *model.Space
	if err := json.NewDecoder(resp).Decode(&spaces); err != nil {
		return nil, fmt.Errorf("error decode json: %w", err)
	}

	return spaces, nil
}
func (c *Client) CreateSpace(space *model.SpaceRequest) (*model.Space, error) {
	payloadBytes, err := json.Marshal(space)
	if err != nil {
		return nil, fmt.Errorf("error marshaling payload: %w", err)
	}
	payload := strings.NewReader(string(payloadBytes))
	resp, err := c.MakeRequest("spaces", http.MethodPost, payload, nil)
	if err != nil {
		return nil, fmt.Errorf("error making POST request: %w", err)
	}
	defer resp.Close()
	var s model.Space
	bodyBytes, err := io.ReadAll(resp)
	if err != nil {
		return nil, fmt.Errorf("error reading response body: %w", err)
	}
	if err := json.Unmarshal(bodyBytes, &s); err != nil {
		return nil, fmt.Errorf("error decode json: %w", err)
	}

	return &s, nil
}

func (c *Client) UpdateSpace(space *model.SpaceRequest) (bool, error) {
	if space.ID == "" {
		return false, fmt.Errorf("id cannot be empty")
	}
	payloadBytes, err := json.Marshal(space)
	if err != nil {
		return false, fmt.Errorf("error marshaling payload: %w", err)
	}
	payload := strings.NewReader(string(payloadBytes))

	url := fmt.Sprintf("spaces/%s", space.ID)
	fmt.Println("URL:", url)
	resp, err := c.MakeRequest(url, http.MethodPut, payload, nil)
	if err != nil {
		return false, fmt.Errorf("error making POST request: %w", err)
	}
	defer resp.Close()

	return true, nil
}

func (c *Client) DeleteSpace(id string) error {
	url := fmt.Sprintf("spaces/%s", id)
	resp, err := c.MakeRequest(url, http.MethodDelete, nil, nil)
	if err != nil {
		return fmt.Errorf("error making DELETE request: %w", err)
	}
	defer resp.Close()

	return nil
}
