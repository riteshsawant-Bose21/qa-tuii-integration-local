package validation

import (
	"errors"
	"fmt"
	"regexp"
)

func ValidateFirmwareVersionFormat(version string) error {
	// Matches traditional MAJOR.MINOR.PATCH and optional pre-release tags like -alpha.1
	versionPattern := `^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-(?:0|[1-9]\d*|[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9]\d*|[A-Za-z-][0-9A-Za-z-]*))*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$`
	match, err := regexp.MatchString(versionPattern, version)
	if err != nil {
		return fmt.Errorf("failed to validate version format: %v", err)
	}
	if !match {
		return errors.New("firmware version must be in format MAJOR.MINOR.PATCH or a valid Semantic Version (e.g. 1.0.0-alpha.1)")
	}
	return nil
}
