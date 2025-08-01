package xyte

import (
	"context"
	"fmt"
	"io"
	"net/http"
)

type HTTPClient interface {
	Do(req *http.Request) (*http.Response, error)
}

type Client struct {
	httpClient HTTPClient
	baseURL    string
	APIKey     string
}

func NewClient(httpClient HTTPClient, url, apiKey string) *Client {
	return &Client{
		httpClient: httpClient,
		baseURL:    url,
		APIKey:     apiKey,
	}
}

func (c *Client) MakeRequest(url string, method string, body io.Reader, params map[string]string) (io.ReadCloser, error) {
	fullURL := c.baseURL + url

	// Add query parameters if provided
	if params != nil && (method == http.MethodGet || method == http.MethodDelete) {
		q := ""
		for k, v := range params {
			if q == "" {
				q = "?"
			} else {
				q += "&"
			}
			q += fmt.Sprintf("%s=%s", k, v)
		}
		fullURL += q
	}

	fmt.Printf("Making %s request to %s\n", method, fullURL)
	req, err := http.NewRequestWithContext(context.TODO(), method, fullURL, body)
	if err != nil {
		return nil, fmt.Errorf("error when building http request :%w", err)
	}
	// Set headers
	req.Header.Add("accept", "application/json")
	req.Header.Add("Authorization", c.APIKey)
	if method == http.MethodPost || method == http.MethodPut {
		req.Header.Add("Content-Type", "application/json")
	}

	res, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error when making http request :%w", err)
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Status code", res.StatusCode)
		b, _ := io.ReadAll(res.Body)
		return nil, fmt.Errorf("unexpected status %d: %s", res.StatusCode, b)
	}

	// Don't read and print the body here, just return it for the caller to handle
	return res.Body, nil
}
