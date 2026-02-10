package vip

import (
	"bufio"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

const DefaultConfFile = "keepalived.conf"

var ErrLocalConfigEmpty = errors.New("local config is empty")

// Canonicalize normalizes a VIP string to a plain IPv4 address or returns "".
// "192.168.2.100/24" becomes "192.168.2.100".
func Canonicalize(s string) string {
	if s == "" {
		return ""
	}
	// handle CIDR form
	if ip, _, err := net.ParseCIDR(s); err == nil && ip != nil {
		if v4 := ip.To4(); v4 != nil {
			return v4.String()
		}
		// drop IPv6
		return ""
	}
	// handle plain IP form
	if ip := net.ParseIP(s); ip != nil {
		if v4 := ip.To4(); v4 != nil {
			return v4.String()
		}
	}
	return ""
}

// Validate checks that the string is a valid IP address or CIDR.
func Validate(v string) error {
	v = strings.TrimSpace(v)

	// Try parsing as CIDR (IP/prefix)
	if _, _, err := net.ParseCIDR(v); err == nil {
		return nil
	}

	// If that fails, try parsing as plain IP
	if ip := net.ParseIP(v); ip != nil {
		return nil
	}

	return fmt.Errorf("invalid VIP format: %q", v)
}

// IsLocalVIP compares the VIP (which might be in CIDR format) to the IPs on local interfaces.
func IsLocalVIP(v string) (bool, error) {
	expectedIP := net.ParseIP(v)
	if expectedIP == nil {
		ip, _, err := net.ParseCIDR(v)
		if err != nil {
			return false, err
		}
		expectedIP = ip
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return false, err
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok {
			ip4 := ipnet.IP.To4()
			if ip4 == nil || ip4.IsLoopback() {
				// Skip IPv6 and loopback
				continue
			}
			if ip4.Equal(expectedIP) {
				return true, nil
			}
		}
	}
	//no match found
	return false, nil
}

// LocalForVIP checks whether `vip` (CIDR or plain IP) is assigned on any local interface.
// If so, it returns:
//   - internalAddr: the first non-loopback IPv4 address that is NOT equal to the VIP
//   - vipAddr: the exact Addr where vip was found
//   - ok = true
//
// If vip isn’t present on any interface, it returns (nil, nil, false).
func LocalForVIP(v string) (net.Addr, net.Addr, bool) {
	expectedIP := net.ParseIP(v)
	if expectedIP == nil {
		ip, _, err := net.ParseCIDR(v)
		if err != nil {
			return nil, nil, false
		}
		expectedIP = ip
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return nil, nil, false
	}

	var vipAddr net.Addr
	var internalAddr net.Addr

	for _, addr := range addrs {
		ipnet, ok := addr.(*net.IPNet)
		if !ok {
			continue
		}

		ip4 := ipnet.IP.To4()
		if ip4 == nil || ip4.IsLoopback() {
			// Skip IPv6 and loopback
			continue
		}

		// Match exact VIP
		if expectedIP.To4() != nil && ip4.Equal(expectedIP) {
			vipAddr = &net.IPAddr{IP: ip4}
			continue
		}

		// Save the first non-loopback IPv4 as internal address
		if internalAddr == nil {
			internalAddr = &net.IPAddr{IP: ip4}
		}
	}

	if vipAddr == nil {
		return nil, nil, false
	}

	return internalAddr, vipAddr, true
}

// ReadFromKeepalivedConfig returns the first VIP and whether multiple were found.
func ReadFromKeepalivedConfig(path string) (string, bool, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", false, fmt.Errorf("unable to read config file: %v", err)
	}
	configText := string(data)

	// This regex looks for a block starting with "virtual_ipaddress" and
	// captures everything until the closing brace.
	re := regexp.MustCompile(`virtual_ipaddress\s*{([^}]+)}`)
	matches := re.FindStringSubmatch(configText)
	if len(matches) < 2 {
		return "", false, fmt.Errorf("no virtual_ipaddress block found")
	}

	// Extract the content between braces and split by newline or whitespace
	vipBlock := matches[1]

	// Split lines and remove extra spaces
	lines := strings.Split(vipBlock, "\n")
	var vips []string
	for _, line := range lines {
		v := strings.TrimSpace(line)
		if v != "" {
			vips = append(vips, v)
		}
	}

	if len(vips) == 0 {
		return "", false, fmt.Errorf("no VIP found")
	}

	return vips[0], len(vips) > 1, nil
}

// WriteToKeepalivedConfig updates the VIP in keepalived.conf.
func WriteToKeepalivedConfig(path, newVIP string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("unable to read config file: %w", err)
	}

	lines := strings.Split(string(data), "\n")
	var outLines []string
	parser := vipParser{}

	for _, line := range lines {
		out, _ := parser.processLine(line, newVIP)
		outLines = append(outLines, out...)
	}

	if !parser.found {
		return fmt.Errorf("no virtual_ipaddress block found")
	}
	if parser.inBlock {
		return fmt.Errorf("unterminated virtual_ipaddress block")
	}

	content := strings.Join(outLines, "\n") + "\n"
	if len(strings.TrimSpace(content)) == 0 {
		return fmt.Errorf("refusing to write empty config")
	}

	if err := atomicReplaceConfig(path, content, ".bak"); err != nil {
		return fmt.Errorf("failed to update config file: %w", err)
	}

	return nil
}

// ReadFromLocalConfig reads the VIP from the first line of the local config file.
func ReadFromLocalConfig(appName, confFile string) (string, error) {
	cfgDir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("cannot determine user config directory: %w", err)
	}
	localPath := filepath.Join(cfgDir, appName, confFile)

	f, err := os.Open(localPath)
	if err != nil {
		return "", err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	if !scanner.Scan() {
		return "", ErrLocalConfigEmpty
	}

	vip := strings.TrimSpace(scanner.Text())
	if err := scanner.Err(); err != nil {
		return "", err
	}

	return vip, nil
}

// WriteToLocalConfig writes the VIP to the local config file.
func WriteToLocalConfig(appName, confFile, newVIP string) error {
	cfgDir, err := os.UserConfigDir()
	if err != nil {
		return fmt.Errorf("cannot determine user config directory: %w", err)
	}

	dir := filepath.Join(cfgDir, appName)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("cannot create local config directory: %w", err)
	}

	path := filepath.Join(dir, confFile)
	data := []byte(newVIP + "\n")
	if err := os.WriteFile(path, data, 0o644); err != nil {
		return fmt.Errorf("cannot write local VIP file: %w", err)
	}

	return nil
}

func atomicReplaceConfig(oldPath, newContent, backupSuffix string) error {
	dir := filepath.Dir(oldPath)
	base := filepath.Base(oldPath)

	tmp, err := os.CreateTemp(dir, base+".tmp")
	if err != nil {
		return fmt.Errorf("create temp file: %w", err)
	}
	tmpPath := tmp.Name()
	defer func() {
		tmp.Close()
		os.Remove(tmpPath)
	}()

	// Preserve mode from existing file
	if info, err := os.Stat(oldPath); err == nil {
		if chmodErr := os.Chmod(tmpPath, info.Mode()); chmodErr != nil {
			// Best effort; permissions are not critical for replacing.
		}
	}

	if _, err := tmp.WriteString(newContent); err != nil {
		return fmt.Errorf("write temp config: %w", err)
	}
	if err := tmp.Sync(); err != nil {
		return fmt.Errorf("sync temp config: %w", err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("close temp config: %w", err)
	}

	backupPath := oldPath + backupSuffix
	if err := os.Rename(oldPath, backupPath); err != nil {
		return fmt.Errorf("backup original config: %w", err)
	}

	if err := os.Rename(tmpPath, oldPath); err != nil {
		os.Rename(backupPath, oldPath)
		return fmt.Errorf("replace config file: %w", err)
	}

	return nil
}

type vipParser struct {
	inBlock bool
	found   bool
	indent  string
}

func (p *vipParser) processLine(line, newVIP string) ([]string, bool) {
	trim := strings.TrimSpace(line)

	if !p.inBlock {
		if trim == "virtual_ipaddress {" {
			p.found, p.inBlock = true, true
			if idx := strings.Index(line, "virtual_ipaddress"); idx >= 0 {
				p.indent = line[:idx]
			}
			return []string{
				p.indent + "virtual_ipaddress {",
				p.indent + "  " + newVIP,
			}, false
		}
		return []string{line}, false
	}

	if trim == "}" {
		p.inBlock = false
		return []string{p.indent + "}"}, false
	}

	// Skip old VIP lines inside the block
	return nil, false
}
