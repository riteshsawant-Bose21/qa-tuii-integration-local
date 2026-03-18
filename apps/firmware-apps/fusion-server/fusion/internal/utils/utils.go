package utils

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"io"
	"mime/multipart"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"reflect"
	"strconv"

	"github.com/gibson042/canonicaljson-go"
	"github.com/gorilla/mux"
)

// IoT device identity constants
const (
	DefaultIdentityFilePath = "/var/lib/device-identity/"
	DefaultCAFileName       = "AmazonRootCA1.pem"
	DefaultCSRFileName      = "device.csr"
	DefaultCertFileName     = "device.x509.cert"
	DefaultKeyFileName      = "device.key"
)

// FileExists returns true if the given path exists and is not a directory.
func FileExists(path string) (bool, error) {
	info, err := os.Stat(path)
	if err == nil {
		// Check it’s not a directory
		return !info.IsDir(), nil
	}

	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}

func IsDeleteRequest(r *http.Request) bool {
	return r.Method == http.MethodDelete
}

func IsGetRequest(r *http.Request) bool {
	return r.Method == http.MethodGet
}

func IsPatchRequest(r *http.Request) bool {
	return r.Method == http.MethodPatch
}

func IsPostRequest(r *http.Request) bool {
	return r.Method == http.MethodPost
}

func IsPutRequest(r *http.Request) bool {
	return r.Method == http.MethodPut
}

// RequireMethod checks the HTTP method and returns true if it matches, false otherwise.
func RequireMethod(w http.ResponseWriter, r *http.Request, method string) bool {
	if r.Method != method {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return false
	}
	return true
}

func RequireDelete(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodDelete)
}

func RequireGet(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodGet)
}

func RequirePatch(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodPatch)
}

func RequirePost(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodPost)
}

func RequirePut(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodPut)
}

// JSONChecksum returns a SHA-256 hash of JSON data.
func JSONChecksum(v any) (string, error) {

	// canonicaljson is used to ensure deterministic ordering
	b, err := canonicaljson.Marshal(v)
	if err != nil {
		return "", fmt.Errorf("canonical marshal failed: %w", err)
	}
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:]), nil
}

// FileChecksum returns a SHA-256 hash of the file at path.
func FileChecksum(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

// VerifyChecksum validates the checksum.
func VerifyChecksum(file multipart.File, expectedChecksum string) bool {

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return false
	}

	actualChecksum := hex.EncodeToString(hash.Sum(nil))
	return actualChecksum == expectedChecksum
}

func ensureArrayCapacity(parent map[string]any, parentKey string, index int) {
	existingArray, exists := parent[parentKey].([]any)
	if !exists {
		parent[parentKey] = make([]any, index+1)
		return
	}
	if index < len(existingArray) {
		return
	}
	newArray := make([]any, index+1)
	copy(newArray, existingArray)
	parent[parentKey] = newArray
}

func isMap(v any) bool {
	_, ok := v.(map[string]any)
	return ok
}

func isArray(v any) bool {
	_, ok := v.([]any)
	return ok
}

// ExtractValue pulls the named value from mux
func ExtractValue(r *http.Request, value string) (string, error) {
	name := mux.Vars(r)[value]
	if name == "" {
		return "", fmt.Errorf("%s is required", value)
	}
	return filepath.Base(name), nil
}

// ExtractId pulls the "id" var from mux and returns an error if it’s missing.
func ExtractId(r *http.Request) (string, error) {
	return ExtractValue(r, "id")
}

// ExtractName pulls the “name” var from mux and returns an error if it’s missing.
func ExtractName(r *http.Request) (string, error) {
	return ExtractValue(r, "name")

}

// DeepCopy recursively copies maps, slices, and arrays.
// It supports arbitrary nesting of map[string]any, []any, and primitive values.
func DeepCopy(src any) any {
	switch v := src.(type) {
	case nil:
		return nil

	// Fast paths for JSON-y shapes
	case map[string]any:
		if v == nil {
			return map[string]any(nil)
		}
		cp := make(map[string]any, len(v))
		for key, val := range v {
			cp[key] = DeepCopy(val)
		}
		return cp

	case []any:
		if v == nil {
			return []any(nil)
		}
		cp := make([]any, len(v))
		for i, val := range v {
			cp[i] = DeepCopy(val)
		}
		return cp

	// Useful common typed slices
	case []byte:
		if v == nil {
			return []byte(nil)
		}
		cp := make([]byte, len(v))
		copy(cp, v)
		return cp
	case []string:
		if v == nil {
			return []string(nil)
		}
		cp := make([]string, len(v))
		copy(cp, v)
		return cp
	case []int:
		if v == nil {
			return []int(nil)
		}
		cp := make([]int, len(v))
		copy(cp, v)
		return cp
	case []float64:
		if v == nil {
			return []float64(nil)
		}
		cp := make([]float64, len(v))
		copy(cp, v)
		return cp

	default:
		return v
	}
}

// SendUDPMessage marshals the payload as JSON and sends it to the given address.
func SendUDPMessage(addr *net.UDPAddr, payload any) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal UDP payload: %w", err)
	}

	conn, err := net.ListenPacket("udp4", "")
	if err != nil {
		return fmt.Errorf("failed to open UDP socket: %w", err)
	}
	defer conn.Close()

	if _, err := conn.WriteTo(data, addr); err != nil {
		return fmt.Errorf("failed to send UDP packet: %w", err)
	}
	return nil
}

func FlattenState(state map[string]*api.StateEntry) map[string]any {
	result := make(map[string]any, len(state))
	for k, e := range state {
		if e != nil {
			result[k] = e.Data
		}
	}
	return result
}

// CalculateDiff recursively compares two data structures (maps or slices) and returns the differences.
// If the data is not equal, it returns the updated data.
func CalculateDiff(before, after any) map[string]any {

	// -----------------------------
	// MAP CASE
	// -----------------------------
	bmap, bIsMap := before.(map[string]any)
	amap, aIsMap := after.(map[string]any)
	if bIsMap || aIsMap {

		// before is not map but after is → treat before as empty map
		if !bIsMap && aIsMap {
			bmap = map[string]any{}
		}

		// before is map but after is not → primitive replace
		if bIsMap && !aIsMap {
			return map[string]any{"": after}
		}

		diff := map[string]any{}
		keys := make(map[string]bool)

		for k := range bmap {
			keys[k] = true
		}
		for k := range amap {
			keys[k] = true
		}

		for k := range keys {
			sub := CalculateDiff(bmap[k], amap[k])
			if sub == nil {
				continue
			}

			if val, ok := unwrapPrimitiveDiff(sub); ok {
				diff[k] = val
			} else {
				diff[k] = sub
			}
		}

		if len(diff) == 0 {
			return nil
		}
		return diff
	}

	// -----------------------------
	// ARRAY CASE
	// -----------------------------
	barr, bIsArr := before.([]any)
	aarr, aIsArr := after.([]any)
	if bIsArr || aIsArr {

		// before not array → treat as empty
		if !bIsArr && aIsArr {
			barr = []any{}
		}

		// after not array → primitive replace
		if bIsArr && !aIsArr {
			return map[string]any{"": after}
		}

		diff := map[string]any{}

		max := min(len(aarr), len(barr))

		for i := 0; i < max; i++ {
			sub := CalculateDiff(barr[i], aarr[i])
			if sub == nil {
				continue
			}

			if val, ok := unwrapPrimitiveDiff(sub); ok {
				diff[strconv.Itoa(i)] = val
			} else {
				diff[strconv.Itoa(i)] = sub
			}
		}

		if len(aarr) > len(barr) {
			for i := len(barr); i < len(aarr); i++ {
				diff[strconv.Itoa(i)] = aarr[i]
			}
		}

		if len(diff) == 0 {
			return nil
		}
		return diff
	}

	// -----------------------------
	// PRIMITIVE CASE
	// -----------------------------
	if reflect.DeepEqual(before, after) {
		return nil
	}
	return map[string]any{"": after}
}

func BuildInternalURL(address, port, endpoint string) string {
	return fmt.Sprintf("%s%s:%s%s", api.Protocol, address, port, endpoint)
}

// GetLocalURL builds a full API URL to the endpoint
func GetLocalURL(addr, endpoint string) string {
	return fmt.Sprintf("%s%s%s", api.Protocol, addr, endpoint)
}

// GetLocalIP returns the primary IP address used for outbound communication
func GetLocalIP() (string, error) {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "", err
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String(), nil
}

func GetLocalIPByInterface(interfaceName string) (string, error) {
	iface, err := net.InterfaceByName(interfaceName)
	if err != nil {
		return "", fmt.Errorf("interface %s not found: %w", interfaceName, err)
	}

	addrs, err := iface.Addrs()
	if err != nil {
		return "", fmt.Errorf("failed to get addresses for interface %s: %w", interfaceName, err)
	}

	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
			if ipNet.IP.To4() != nil { // IPv4
				return ipNet.IP.String(), nil
			}
		}
	}

	return "", fmt.Errorf("no IPv4 address found on interface %s", interfaceName)
}

func unwrapPrimitiveDiff(m map[string]any) (any, bool) {
	if len(m) != 1 {
		return nil, false
	}
	v, ok := m[""]
	if !ok {
		return nil, false
	}
	// Only unwrap true primitives
	switch v.(type) {
	case map[string]any, []any:
		return nil, false
	default:
		return v, true
	}
}
