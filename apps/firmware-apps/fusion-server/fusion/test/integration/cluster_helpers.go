//go:build integration
// +build integration

package integration

// import (
// 	"context"
// 	"encoding/json"
// 	"fmt"
// 	"net/http"
// 	"time"
// )

// type Member struct {
// 	Name string `json:"name"`
// 	Addr string `json:"addr"`
// }

// // GetMembersFromURL queries a specific node for its view of cluster members.
// func GetMembersFromURL(ctx context.Context, nodeBaseURL string) ([]Member, error) {
// 	req, err := http.NewRequestWithContext(ctx, http.MethodGet, nodeBaseURL+"/cluster/members", nil)
// 	if err != nil {
// 		return nil, err
// 	}
// 	resp, err := httpClient.Do(req)
// 	if err != nil {
// 		return nil, err
// 	}
// 	defer resp.Body.Close()
// 	if resp.StatusCode != http.StatusOK {
// 		return nil, fmt.Errorf("members status=%d", resp.StatusCode)
// 	}
// 	var ms []Member
// 	if err := json.NewDecoder(resp.Body).Decode(&ms); err != nil {
// 		return nil, err
// 	}
// 	return ms, nil
// }

// // GetMembersFromAny tries multiple node URLs until one responds.
// func GetMembersFromAny(ctx context.Context, urls []string) ([]Member, error) {
// 	var lastErr error

// 	if len(urls) == 0 {
// 		lastErr = fmt.Errorf("no node URLs provided")
// 	}
// 	for _, u := range urls {
// 		ms, err := GetMembersFromURL(ctx, u)
// 		if err == nil {
// 			return ms, nil
// 		}
// 		lastErr = err
// 	}
// 	return nil, lastErr
// }

// // GetVIPAddr fetches the VIP address from the cluster via VIP base URL.
// func GetVIPAddr(ctx context.Context, env Env) (string, error) {
// 	req, err := http.NewRequestWithContext(ctx, http.MethodGet, env.BaseURL()+"/devices/vip", nil)
// 	if err != nil {
// 		return "", err
// 	}
// 	resp, err := httpClient.Do(req)
// 	if err != nil {
// 		return "", err
// 	}
// 	defer resp.Body.Close()
// 	if resp.StatusCode != http.StatusOK {
// 		return "", fmt.Errorf("vip status=%d", resp.StatusCode)
// 	}
// 	var out struct {
// 		VIP string `json:"vip"`
// 	}
// 	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
// 		return "", err
// 	}
// 	return out.VIP, nil
// }
