package auth

import (
	"fmt"
	"strconv"
	"strings"
)

// IsResourceOwnerPasswordFlowEnabled checks if the resource owner password flow is enabled
// from the environment variable value
func IsResourceOwnerPasswordFlowEnabled(configValue string) (bool, error) {
	if configValue == "" {
		return false, fmt.Errorf("AUTH0_RESOURCE_OWNER_PASSWORD_FLOW_ENABLED environment variable is not set")
	}

	enabled, err := strconv.ParseBool(strings.ToLower(configValue))
	if err != nil {
		return false, fmt.Errorf("invalid value for AUTH0_RESOURCE_OWNER_PASSWORD_FLOW_ENABLED: %s (expected true/false)", configValue)
	}

	return enabled, nil
}
