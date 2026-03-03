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

func IsVersionGreaterOrEqual(v1, v2 *ParsedVersion) bool {
	if v1.Major != v2.Major {
		return v1.Major > v2.Major
	}
	if v1.Minor != v2.Minor {
		return v1.Minor > v2.Minor
	}
	return v1.Patch >= v2.Patch
}
