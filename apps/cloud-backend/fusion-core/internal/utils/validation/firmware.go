package validation

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

type ParsedVersion struct {
	Major          int
	Minor          int
	Patch          int
	PrereleaseFlag string
	PrereleaseVer  int
}

func ParseSemanticVersion(version string) (*ParsedVersion, error) {
	if err := ValidateFirmwareVersionFormat(version); err != nil {
		return nil, err
	}

	mainParts := strings.SplitN(version, "-", 2)
	versionNums := strings.Split(mainParts[0], ".")

	major, _ := strconv.Atoi(versionNums[0])
	minor, _ := strconv.Atoi(versionNums[1])
	patch, _ := strconv.Atoi(versionNums[2])

	prereleaseFlag := ""
	prereleaseVer := 0

	if len(mainParts) > 1 {
		prereleaseParts := strings.SplitN(mainParts[1], ".", 2)
		prereleaseFlag = prereleaseParts[0]
		if len(prereleaseParts) > 1 {
			prereleaseVer, _ = strconv.Atoi(prereleaseParts[1])
		}
	}

	return &ParsedVersion{
		Major:          major,
		Minor:          minor,
		Patch:          patch,
		PrereleaseFlag: prereleaseFlag,
		PrereleaseVer:  prereleaseVer,
	}, nil
}

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

// ValidateMainVersionFormat validates that a version string is in the strict MAJOR.MINOR.PATCH format.
func ValidateMainVersionFormat(version string) error {
	if version == "" {
		return nil // Allow empty string
	}
	versionPattern := `^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$`
	match, err := regexp.MatchString(versionPattern, version)
	if err != nil {
		return fmt.Errorf("failed to validate version format: %v", err)
	}
	if !match {
		return errors.New("version must be in the strict MAJOR.MINOR.PATCH format (e.g., 1.2.3)")
	}
	return nil
}

// IsVersionGreaterOrEqual compares two semantic versions following SemVer 2.0.0 spec.
// Prerelease versions have lower precedence than normal versions (1.0.0-alpha < 1.0.0).
// When both have prereleases, they're compared: alpha < beta < rc, then by numeric version.
func IsVersionGreaterOrEqual(v1, v2 *ParsedVersion) bool {
	// Compare major.minor.patch first
	if v1.Major != v2.Major {
		return v1.Major > v2.Major
	}
	if v1.Minor != v2.Minor {
		return v1.Minor > v2.Minor
	}
	if v1.Patch != v2.Patch {
		return v1.Patch > v2.Patch
	}

	// Major.Minor.Patch are equal, now compare prerelease
	// Per SemVer: a version without prerelease has higher precedence than one with prerelease
	// e.g., 1.0.0 > 1.0.0-alpha
	if v1.PrereleaseFlag == "" && v2.PrereleaseFlag == "" {
		return true // Equal versions
	}
	if v1.PrereleaseFlag == "" && v2.PrereleaseFlag != "" {
		return true // v1 (stable) > v2 (prerelease)
	}
	if v1.PrereleaseFlag != "" && v2.PrereleaseFlag == "" {
		return false // v1 (prerelease) < v2 (stable)
	}

	// Both have prerelease tags, compare them
	// Precedence: alpha < beta < rc (alphabetically works for common tags)
	if v1.PrereleaseFlag != v2.PrereleaseFlag {
		return v1.PrereleaseFlag > v2.PrereleaseFlag
	}

	// Same prerelease flag, compare numeric version
	return v1.PrereleaseVer >= v2.PrereleaseVer
}
