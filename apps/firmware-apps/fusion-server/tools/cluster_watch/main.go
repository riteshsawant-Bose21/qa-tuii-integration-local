package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"
)

type DeviceInfo struct {
	Address      string `json:"address"`
	ID           string `json:"id"`
	Name         string `json:"name"`
	IsPrimary    bool   `json:"is_primary"`
	ModelName    string `json:"model_name"`
	VrrpPriority int32  `json:"vrrp_priority"`
}

type DeviceListResponse struct {
	Devices []*DeviceInfo `json:"devices"`
}

type ClusterMember struct {
	Name    string          `json:"name"`
	Address string          `json:"address"`
	Port    uint16          `json:"port"`
	State   memberNodeState `json:"state"`
}

func (m *ClusterMember) UnmarshalJSON(data []byte) error {
	type rawMember struct {
		NameLower    string          `json:"name"`
		NameUpper    string          `json:"Name"`
		AddressLower string          `json:"address"`
		AddressUpper string          `json:"Address"`
		Addr         string          `json:"Addr"`
		PortLower    uint16          `json:"port"`
		PortUpper    uint16          `json:"Port"`
		StateLower   memberNodeState `json:"state"`
		StateUpper   memberNodeState `json:"State"`
	}

	var raw rawMember
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}

	m.Name = firstNonEmpty(raw.NameLower, raw.NameUpper)
	m.Address = firstNonEmpty(raw.AddressLower, raw.AddressUpper, raw.Addr)
	if raw.PortLower != 0 {
		m.Port = raw.PortLower
	} else {
		m.Port = raw.PortUpper
	}
	if raw.StateLower != "" {
		m.State = raw.StateLower
	} else {
		m.State = raw.StateUpper
	}
	return nil
}

type memberNodeState string

func (s *memberNodeState) UnmarshalJSON(data []byte) error {
	var stringValue string
	if err := json.Unmarshal(data, &stringValue); err == nil {
		*s = memberNodeState(strings.ToUpper(strings.TrimSpace(stringValue)))
		return nil
	}

	var numericValue int
	if err := json.Unmarshal(data, &numericValue); err == nil {
		switch numericValue {
		case 0:
			*s = "ALIVE"
		case 1:
			*s = "SUSPECT"
		case 2:
			*s = "DEAD"
		case 3:
			*s = "LEFT"
		default:
			*s = memberNodeState(fmt.Sprintf("UNKNOWN_%d", numericValue))
		}
		return nil
	}

	return fmt.Errorf("unsupported member state JSON: %s", string(data))
}

type EndpointSnapshot struct {
	Label             string
	BaseURL           string
	Devices           []DeviceInfo
	DeviceSignature   string
	PrimaryCount      int
	PrimaryAddresses  []string
	AliveMembers      []string
	AliveMemberSig    string
	DevicesErr        error
	ClusterMembersErr error
	LastObservedAt    time.Time
}

type Issue struct {
	Kind    string
	Details string
}

type WatchConfig struct {
	VIPBaseURL     string
	NodeBaseURLs   []string
	DiscoverNodes  bool
	LogPath        string
	Interval       time.Duration
	RequestTimeout time.Duration
	Duration       time.Duration
	FailAfter      time.Duration
	ShowOK         bool
}

type WatchState string

const (
	WatchStateOK       WatchState = "OK"
	WatchStateDiverged WatchState = "DIVERGED"
)

type OutageEpisode struct {
	Start  time.Time
	End    time.Time
	Reason string
	Active bool
}

func main() {
	cfg, err := parseFlags()
	if err != nil {
		fmt.Fprintf(os.Stderr, "cluster_watch: %v\n", err)
		os.Exit(2)
	}

	if err := run(cfg); err != nil {
		fmt.Fprintf(os.Stderr, "cluster_watch: %v\n", err)
		os.Exit(1)
	}
}

func parseFlags() (WatchConfig, error) {
	var cfg WatchConfig
	var vip string
	var nodes string

	flag.StringVar(&vip, "vip", "", "VIP base URL, for example http://192.168.2.100:8080")
	flag.StringVar(&nodes, "nodes", "", "comma-separated direct node base URLs, for example http://192.168.2.131:8080,http://192.168.2.132:8080")
	flag.BoolVar(&cfg.DiscoverNodes, "discover-nodes", true, "auto-discover direct node URLs from VIP /devices")
	flag.StringVar(&cfg.LogPath, "log-file", "", "path to write the watcher log; default is a timestamped file under build/")
	flag.DurationVar(&cfg.Interval, "interval", time.Second, "poll interval")
	flag.DurationVar(&cfg.RequestTimeout, "timeout", 3*time.Second, "per-request timeout")
	flag.DurationVar(&cfg.Duration, "duration", 0, "total run duration; 0 means run until interrupted")
	flag.DurationVar(&cfg.FailAfter, "fail-after", 5*time.Second, "exit non-zero if the same unhealthy state persists for at least this long; 0 disables fail-fast")
	flag.BoolVar(&cfg.ShowOK, "show-ok", false, "print healthy snapshots every interval, not only on state changes")
	flag.Parse()

	if strings.TrimSpace(vip) == "" {
		return cfg, errors.New("missing -vip")
	}

	normalizedVIP, err := normalizeBaseURL(vip)
	if err != nil {
		return cfg, fmt.Errorf("invalid -vip: %w", err)
	}
	cfg.VIPBaseURL = normalizedVIP

	nodeURLs := splitCSV(nodes)
	if len(nodeURLs) == 0 && !cfg.DiscoverNodes {
		return cfg, errors.New("missing -nodes; or enable -discover-nodes")
	}
	for _, raw := range nodeURLs {
		normalized, err := normalizeBaseURL(raw)
		if err != nil {
			return cfg, fmt.Errorf("invalid node URL %q: %w", raw, err)
		}
		cfg.NodeBaseURLs = append(cfg.NodeBaseURLs, normalized)
	}

	if cfg.Interval <= 0 {
		return cfg, errors.New("-interval must be > 0")
	}
	if cfg.RequestTimeout <= 0 {
		return cfg, errors.New("-timeout must be > 0")
	}
	if cfg.Duration < 0 {
		return cfg, errors.New("-duration must be >= 0")
	}
	if cfg.FailAfter < 0 {
		return cfg, errors.New("-fail-after must be >= 0")
	}
	if strings.TrimSpace(cfg.LogPath) == "" {
		cfg.LogPath = defaultLogPath()
	}

	return cfg, nil
}

func run(cfg WatchConfig) error {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	if cfg.Duration > 0 {
		var timeoutCancel context.CancelFunc
		ctx, timeoutCancel = context.WithTimeout(ctx, cfg.Duration)
		defer timeoutCancel()
	}

	client := &http.Client{Timeout: cfg.RequestTimeout}
	targets := buildTargets(cfg, nil)
	ticker := time.NewTicker(cfg.Interval)
	defer ticker.Stop()
	writer, closeWriter, err := newLogWriter(cfg.LogPath)
	if err != nil {
		return err
	}
	defer closeWriter()

	var (
		lastSummary          string
		unhealthySince       time.Time
		lastIssueFingerprint string
		lastState            WatchState
		haveState            bool
		lastStateChange      time.Time
		outage               OutageEpisode
	)

	printStart(writer, cfg, targets)

	for {
		snapshots := collectSnapshots(ctx, client, targets)
		if cfg.DiscoverNodes {
			discoveredTargets := buildTargets(cfg, discoverNodeBaseURLs(cfg, snapshots))
			if targetsChanged(targets, discoveredTargets) {
				targets = discoveredTargets
				snapshots = collectSnapshots(ctx, client, targets)
			}
		}
		issues := evaluateSnapshots(snapshots)
		now := time.Now()
		summary := renderSummary(now, snapshots, issues)

		changed := summary != lastSummary
		healthy := len(issues) == 0
		currentState := WatchStateDiverged
		if healthy {
			currentState = WatchStateOK
		}

		if changed || cfg.ShowOK || !healthy {
			fmt.Fprintln(writer, summary)
			lastSummary = summary
		}

		if !haveState {
			haveState = true
			lastState = currentState
			lastStateChange = now
			fmt.Fprintf(writer, "[%s] transition: initial_state=%s\n", now.Format(time.RFC3339), currentState)
		} else if currentState != lastState {
			previousState := lastState
			previousDuration := now.Sub(lastStateChange).Round(time.Millisecond)
			fmt.Fprintf(writer,
				"[%s] transition: %s -> %s after %s\n",
				now.Format(time.RFC3339),
				previousState,
				currentState,
				previousDuration,
			)
			if previousState == WatchStateDiverged && currentState == WatchStateOK {
				fmt.Fprintf(writer,
					"[%s] recovery: diverged_window=%s\n",
					now.Format(time.RFC3339),
					previousDuration,
				)
			}
			lastState = currentState
			lastStateChange = now
		}

		outageNow, outageReason := detectOutage(snapshots)
		if outageNow && !outage.Active {
			outage = OutageEpisode{
				Start:  now,
				Reason: outageReason,
				Active: true,
			}
			fmt.Fprintf(writer,
				"[%s] outage_start: reason=%s\n",
				now.Format(time.RFC3339),
				outageReason,
			)
		} else if outageNow && outage.Active && outageReason != outage.Reason {
			fmt.Fprintf(writer,
				"[%s] outage_update: previous_reason=%s new_reason=%s elapsed=%s\n",
				now.Format(time.RFC3339),
				outage.Reason,
				outageReason,
				now.Sub(outage.Start).Round(time.Millisecond),
			)
			outage.Reason = outageReason
		} else if !outageNow && outage.Active {
			outage.End = now
			fmt.Fprintf(writer,
				"[%s] outage_end: reason=%s duration=%s\n",
				now.Format(time.RFC3339),
				outage.Reason,
				outage.End.Sub(outage.Start).Round(time.Millisecond),
			)
			outage = OutageEpisode{}
		}

		issueFingerprint := fingerprintIssues(issues)
		if healthy {
			unhealthySince = time.Time{}
			lastIssueFingerprint = ""
		} else {
			if issueFingerprint != lastIssueFingerprint {
				unhealthySince = now
				lastIssueFingerprint = issueFingerprint
			}
			if cfg.FailAfter > 0 && !unhealthySince.IsZero() && now.Sub(unhealthySince) >= cfg.FailAfter {
				return fmt.Errorf("unhealthy state persisted for %s", now.Sub(unhealthySince).Round(time.Second))
			}
		}

		select {
		case <-ctx.Done():
			if errors.Is(ctx.Err(), context.DeadlineExceeded) {
				fmt.Fprintf(writer, "[%s] cluster_watch finished: duration elapsed\n", time.Now().Format(time.RFC3339))
				return nil
			}
			fmt.Fprintf(writer, "[%s] cluster_watch finished: signal received\n", time.Now().Format(time.RFC3339))
			return nil
		case <-ticker.C:
		}
	}
}

func buildTargets(cfg WatchConfig, discovered []string) []struct {
	Label   string
	BaseURL string
} {
	targets := []struct {
		Label   string
		BaseURL string
	}{
		{Label: "vip", BaseURL: cfg.VIPBaseURL},
	}

	seen := map[string]struct{}{cfg.VIPBaseURL: {}}
	for i, baseURL := range cfg.NodeBaseURLs {
		if _, ok := seen[baseURL]; ok {
			continue
		}
		seen[baseURL] = struct{}{}
		targets = append(targets, struct {
			Label   string
			BaseURL string
		}{
			Label:   fmt.Sprintf("node-%d", i+1),
			BaseURL: baseURL,
		})
	}
	for _, baseURL := range discovered {
		if _, ok := seen[baseURL]; ok {
			continue
		}
		seen[baseURL] = struct{}{}
		targets = append(targets, struct {
			Label   string
			BaseURL string
		}{
			Label:   fmt.Sprintf("node-%d", len(targets)),
			BaseURL: baseURL,
		})
	}
	return targets
}

func discoverNodeBaseURLs(cfg WatchConfig, snapshots []EndpointSnapshot) []string {
	var vipSnapshot *EndpointSnapshot
	for i := range snapshots {
		if snapshots[i].Label == "vip" {
			vipSnapshot = &snapshots[i]
			break
		}
	}
	if vipSnapshot == nil || vipSnapshot.DevicesErr != nil {
		return nil
	}

	parsedVIP, err := url.Parse(cfg.VIPBaseURL)
	if err != nil {
		return nil
	}
	port := parsedVIP.Port()
	if port == "" {
		switch parsedVIP.Scheme {
		case "https":
			port = "443"
		default:
			port = "80"
		}
	}

	var out []string
	for _, device := range vipSnapshot.Devices {
		if strings.TrimSpace(device.Address) == "" {
			continue
		}
		out = append(out, fmt.Sprintf("%s://%s:%s", parsedVIP.Scheme, device.Address, port))
	}
	sort.Strings(out)
	return out
}

func targetsChanged(
	a []struct {
		Label   string
		BaseURL string
	},
	b []struct {
		Label   string
		BaseURL string
	},
) bool {
	if len(a) != len(b) {
		return true
	}
	for i := range a {
		if a[i].BaseURL != b[i].BaseURL || a[i].Label != b[i].Label {
			return true
		}
	}
	return false
}

func collectSnapshots(
	ctx context.Context,
	client *http.Client,
	targets []struct {
		Label   string
		BaseURL string
	},
) []EndpointSnapshot {
	snapshots := make([]EndpointSnapshot, 0, len(targets))
	for _, target := range targets {
		snapshots = append(snapshots, collectSnapshot(ctx, client, target.Label, target.BaseURL))
	}
	return snapshots
}

func collectSnapshot(ctx context.Context, client *http.Client, label, baseURL string) EndpointSnapshot {
	snapshot := EndpointSnapshot{
		Label:          label,
		BaseURL:        baseURL,
		LastObservedAt: time.Now(),
	}

	devices, err := fetchDevices(ctx, client, baseURL)
	if err != nil {
		snapshot.DevicesErr = err
	} else {
		snapshot.Devices = devices
		snapshot.DeviceSignature = deviceSignature(devices)
		snapshot.PrimaryCount, snapshot.PrimaryAddresses = primarySummary(devices)
	}

	members, err := fetchClusterMembers(ctx, client, baseURL)
	if err != nil {
		snapshot.ClusterMembersErr = err
	} else {
		snapshot.AliveMembers = aliveMemberAddresses(members)
		snapshot.AliveMemberSig = strings.Join(snapshot.AliveMembers, ",")
	}

	return snapshot
}

func fetchDevices(ctx context.Context, client *http.Client, baseURL string) ([]DeviceInfo, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, baseURL+"/devices", nil)
	if err != nil {
		return nil, err
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GET /devices status=%d", resp.StatusCode)
	}

	var wrapped DeviceListResponse
	if err := json.NewDecoder(resp.Body).Decode(&wrapped); err == nil && wrapped.Devices != nil {
		out := make([]DeviceInfo, 0, len(wrapped.Devices))
		for _, device := range wrapped.Devices {
			if device == nil {
				continue
			}
			out = append(out, *device)
		}
		return out, nil
	}

	resp.Body.Close()
	req, err = http.NewRequestWithContext(ctx, http.MethodGet, baseURL+"/devices", nil)
	if err != nil {
		return nil, err
	}
	resp, err = client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GET /devices status=%d", resp.StatusCode)
	}

	var legacy []DeviceInfo
	if err := json.NewDecoder(resp.Body).Decode(&legacy); err == nil {
		return legacy, nil
	}

	return nil, errors.New("GET /devices returned an unexpected JSON shape")
}

func fetchClusterMembers(ctx context.Context, client *http.Client, baseURL string) ([]ClusterMember, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, baseURL+"/cluster/members", nil)
	if err != nil {
		return nil, err
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GET /cluster/members status=%d", resp.StatusCode)
	}

	var members []ClusterMember
	if err := json.NewDecoder(resp.Body).Decode(&members); err != nil {
		return nil, err
	}
	return members, nil
}

func evaluateSnapshots(snapshots []EndpointSnapshot) []Issue {
	var issues []Issue

	for _, snapshot := range snapshots {
		if snapshot.DevicesErr != nil {
			issues = append(issues, Issue{
				Kind:    "devices_unreachable",
				Details: fmt.Sprintf("%s %s: %v", snapshot.Label, snapshot.BaseURL, snapshot.DevicesErr),
			})
		}
		if snapshot.ClusterMembersErr != nil {
			issues = append(issues, Issue{
				Kind:    "members_unreachable",
				Details: fmt.Sprintf("%s %s: %v", snapshot.Label, snapshot.BaseURL, snapshot.ClusterMembersErr),
			})
		}
		if snapshot.DevicesErr == nil && snapshot.PrimaryCount != 1 {
			issues = append(issues, Issue{
				Kind:    "primary_count",
				Details: fmt.Sprintf("%s %s: primary_count=%d primary_addrs=%v", snapshot.Label, snapshot.BaseURL, snapshot.PrimaryCount, snapshot.PrimaryAddresses),
			})
		}
	}

	successful := successfulSnapshots(snapshots)
	if len(successful) < 2 {
		return issues
	}

	deviceRef := successful[0]
	for _, snapshot := range successful[1:] {
		if snapshot.DeviceSignature != deviceRef.DeviceSignature {
			issues = append(issues, Issue{
				Kind: "device_divergence",
				Details: fmt.Sprintf("%s sees [%s] but %s sees [%s]",
					deviceRef.Label, deviceRef.DeviceSignature, snapshot.Label, snapshot.DeviceSignature),
			})
		}
	}

	memberRef := firstMembersSnapshot(successful)
	if memberRef != nil {
		for _, snapshot := range successful {
			if snapshot.AliveMemberSig == "" {
				continue
			}
			if snapshot.AliveMemberSig != memberRef.AliveMemberSig {
				issues = append(issues, Issue{
					Kind: "member_divergence",
					Details: fmt.Sprintf("%s alive_members=[%s] but %s alive_members=[%s]",
						memberRef.Label, memberRef.AliveMemberSig, snapshot.Label, snapshot.AliveMemberSig),
				})
			}
		}
	}

	return issues
}

func successfulSnapshots(snapshots []EndpointSnapshot) []EndpointSnapshot {
	out := make([]EndpointSnapshot, 0, len(snapshots))
	for _, snapshot := range snapshots {
		if snapshot.DevicesErr == nil {
			out = append(out, snapshot)
		}
	}
	return out
}

func firstMembersSnapshot(snapshots []EndpointSnapshot) *EndpointSnapshot {
	for i := range snapshots {
		if snapshots[i].ClusterMembersErr == nil && snapshots[i].AliveMemberSig != "" {
			return &snapshots[i]
		}
	}
	return nil
}

func renderSummary(now time.Time, snapshots []EndpointSnapshot, issues []Issue) string {
	var b strings.Builder
	if len(issues) == 0 {
		fmt.Fprintf(&b, "[%s] OK", now.Format(time.RFC3339))
	} else {
		fmt.Fprintf(&b, "[%s] DIVERGED", now.Format(time.RFC3339))
	}

	for _, snapshot := range snapshots {
		fmt.Fprintf(&b, "\n  %s %s", snapshot.Label, snapshot.BaseURL)
		if snapshot.DevicesErr != nil {
			fmt.Fprintf(&b, " devices_err=%q", snapshot.DevicesErr)
		} else {
			fmt.Fprintf(&b, " devices=%d primary_count=%d primary=%s",
				len(snapshot.Devices),
				snapshot.PrimaryCount,
				strings.Join(snapshot.PrimaryAddresses, ","))
			if snapshot.DeviceSignature != "" {
				fmt.Fprintf(&b, " sig=%s", snapshot.DeviceSignature)
			}
		}
		if snapshot.ClusterMembersErr != nil {
			fmt.Fprintf(&b, " members_err=%q", snapshot.ClusterMembersErr)
		} else if snapshot.AliveMemberSig != "" {
			fmt.Fprintf(&b, " alive_members=%s", snapshot.AliveMemberSig)
		}
	}

	for _, issue := range issues {
		fmt.Fprintf(&b, "\n  issue[%s] %s", issue.Kind, issue.Details)
	}

	return b.String()
}

func fingerprintIssues(issues []Issue) string {
	if len(issues) == 0 {
		return ""
	}
	parts := make([]string, 0, len(issues))
	for _, issue := range issues {
		parts = append(parts, issue.Kind+"|"+issue.Details)
	}
	sort.Strings(parts)
	return strings.Join(parts, "\n")
}

func detectOutage(snapshots []EndpointSnapshot) (bool, string) {
	for _, snapshot := range snapshots {
		if snapshot.Label != "vip" {
			continue
		}
		if snapshot.DevicesErr != nil && snapshot.ClusterMembersErr != nil {
			return true, "vip_unreachable"
		}
		if snapshot.DevicesErr != nil {
			return true, "vip_devices_unreachable"
		}
		if snapshot.ClusterMembersErr != nil {
			return true, "vip_members_unreachable"
		}
	}
	return false, ""
}

func deviceSignature(devices []DeviceInfo) string {
	parts := make([]string, 0, len(devices))
	for _, device := range devices {
		parts = append(parts, fmt.Sprintf("%s/%s/%s/%v/%d",
			device.Address,
			device.ID,
			device.ModelName,
			device.IsPrimary,
			device.VrrpPriority,
		))
	}
	sort.Strings(parts)
	return strings.Join(parts, ",")
}

func primarySummary(devices []DeviceInfo) (int, []string) {
	primaries := make([]string, 0, 1)
	for _, device := range devices {
		if device.IsPrimary {
			primaries = append(primaries, device.Address)
		}
	}
	sort.Strings(primaries)
	return len(primaries), primaries
}

func aliveMemberAddresses(members []ClusterMember) []string {
	alive := make([]string, 0, len(members))
	for _, member := range members {
		if strings.EqualFold(string(member.State), "ALIVE") {
			alive = append(alive, member.Address)
		}
	}
	sort.Strings(alive)
	return alive
}

func splitCSV(input string) []string {
	rawParts := strings.Split(input, ",")
	out := make([]string, 0, len(rawParts))
	for _, part := range rawParts {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func normalizeBaseURL(raw string) (string, error) {
	parsed, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		return "", err
	}
	if parsed.Scheme == "" || parsed.Host == "" {
		return "", fmt.Errorf("must include scheme and host")
	}
	parsed.Path = strings.TrimRight(parsed.Path, "/")
	parsed.RawQuery = ""
	parsed.Fragment = ""
	return parsed.String(), nil
}

func defaultLogPath() string {
	timestamp := time.Now().Format("20060102_150405")
	return filepath.Join("build", fmt.Sprintf("cluster_watch_%s.log", timestamp))
}

func newLogWriter(path string) (io.Writer, func(), error) {
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return nil, func() {}, fmt.Errorf("create log directory: %w", err)
	}

	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, func() {}, fmt.Errorf("open log file %s: %w", path, err)
	}

	return io.MultiWriter(os.Stdout, file), func() {
		_ = file.Close()
	}, nil
}

func printStart(
	writer io.Writer,
	cfg WatchConfig,
	targets []struct {
		Label   string
		BaseURL string
	},
) {
	fmt.Fprintf(writer, "cluster_watch starting\n")
	fmt.Fprintf(writer, "  interval      : %s\n", cfg.Interval)
	fmt.Fprintf(writer, "  timeout       : %s\n", cfg.RequestTimeout)
	if cfg.Duration > 0 {
		fmt.Fprintf(writer, "  duration      : %s\n", cfg.Duration)
	} else {
		fmt.Fprintf(writer, "  duration      : until interrupted\n")
	}
	if cfg.FailAfter > 0 {
		fmt.Fprintf(writer, "  fail-after    : %s\n", cfg.FailAfter)
	} else {
		fmt.Fprintf(writer, "  fail-after    : disabled\n")
	}
	fmt.Fprintf(writer, "  discover      : %v\n", cfg.DiscoverNodes)
	fmt.Fprintf(writer, "  log-file      : %s\n", cfg.LogPath)
	for _, target := range targets {
		fmt.Fprintf(writer, "  target        : %s %s\n", target.Label, target.BaseURL)
	}
}
