package validation

import (
	"errors"
	"regexp"
	"strconv"
	"strings"
)

var (
	// Matches traditional MAJOR.MINOR.PATCH
	mainVersionPattern = regexp.MustCompile(`^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$`)
	// Matches pre-release tags like -alpha.1 also
	firmwareVersionPattern = regexp.MustCompile(`^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-(?:0|[1-9]\d*|[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9]\d*|[A-Za-z-][0-9A-Za-z-]*))*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$`)
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
	if !firmwareVersionPattern.MatchString(version) {
		return errors.New("firmware version must be in format MAJOR.MINOR.PATCH or a valid Semantic Version (e.g. 1.0.0-alpha.1)")
	}
	return nil
}

// ValidateMainVersionFormat validates that a version string is in the strict MAJOR.MINOR.PATCH format.
func ValidateMainVersionFormat(version string) error {
	if !mainVersionPattern.MatchString(version) {
		return errors.New("version must be in the strict MAJOR.MINOR.PATCH format (e.g., 1.2.3)")
	}
	return nil
}

// IsVersionGreaterOrEqual compares two semantic versions following SemVer 2.0.0 spec.
// currently it just compares the major.minor.patch and ignores the prerelease tag, since this is just used to compare the compatibility versions, which do not have prerelease tags
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
	return true
}
