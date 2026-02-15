package validation

import (
	"errors"
	"fmt"
	"regexp"
)

func ValidateFirmwareVersionFormat(version string) error {
	versionPattern := `^\d+\.\d+\.\d+$`
	match, err := regexp.MatchString(versionPattern, version)
	if err != nil {
		return fmt.Errorf("failed to validate version format: %v", err)
	}
	if !match {
		return errors.New("firmware version must be in format MAJOR.MINOR.PATCH")
	}
	return nil
}
