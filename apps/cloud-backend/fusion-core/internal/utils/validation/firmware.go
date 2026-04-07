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
	// Bundle version: MAJOR.MINOR.PATCH OR MAJOR.MINOR.PATCH-tag[.number][+build].
	// Build metadata is allowed only when a prerelease tag is present.
	bundleVersionPattern = regexp.MustCompile(`^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([A-Za-z][0-9A-Za-z-]*)(?:\.(0|[1-9]\d*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?)?$`)
)

type ParsedVersion struct {
	Major         int
	Minor         int
	Patch         int
	Prerelease    string // Full prerelease string: "beta.1", "dev.2", "" for stable
	PrereleaseTag string // Channel tag: "beta", "rc", "alpha", "" for stable
	PrereleaseNum int    // Numeric part for ordering: 0, 1, 5... -1 if absent
	Build         string // Build metadata (ignored in comparisons per SemVer)
}

func ParseSemanticVersion(version string) (*ParsedVersion, error) {
	if err := ValidateBundleVersionFormat(version); err != nil {
		return nil, err
	}

	// Step 1: Strip +build metadata
	build := ""
	core := version
	if plusIdx := strings.Index(version, "+"); plusIdx != -1 {
		build = version[plusIdx+1:]
		core = version[:plusIdx]
	}

	// Step 2: Split core into main version and prerelease
	prerelease := ""
	mainVersion := core
	if dashIdx := strings.Index(core, "-"); dashIdx != -1 {
		prerelease = core[dashIdx+1:]
		mainVersion = core[:dashIdx]
	}

	// Step 3: Parse MAJOR.MINOR.PATCH
	versionNums := strings.Split(mainVersion, ".")
	major, _ := strconv.Atoi(versionNums[0])
	minor, _ := strconv.Atoi(versionNums[1])
	patch, _ := strconv.Atoi(versionNums[2])

	// Extract prerelease tag and number
	prereleaseTag := ""
	prereleaseNum := -1
	if prerelease != "" {
		parts := strings.SplitN(prerelease, ".", 2)
		prereleaseTag = parts[0]
		if len(parts) > 1 {
			if n, err := strconv.Atoi(parts[1]); err == nil {
				prereleaseNum = n
			}
		}
	}

	return &ParsedVersion{
		Major:         major,
		Minor:         minor,
		Patch:         patch,
		Prerelease:    prerelease,
		PrereleaseTag: prereleaseTag,
		PrereleaseNum: prereleaseNum,
		Build:         build,
	}, nil
}

func ValidateBundleVersionFormat(version string) error {
	if !bundleVersionPattern.MatchString(version) {
		return errors.New("bundle version must be MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-tag[.number][+build]")
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
