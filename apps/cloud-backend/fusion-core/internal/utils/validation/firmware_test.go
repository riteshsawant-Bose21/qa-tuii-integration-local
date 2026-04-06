package validation

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestValidateBundleVersionFormat(t *testing.T) {
	tests := []struct {
		name    string
		version string
		valid   bool
	}{
		// ---- Valid: stable releases ----
		{name: "stable simple", version: "1.0.0", valid: true},
		{name: "stable with zeroes", version: "0.0.0", valid: true},
		{name: "stable large numbers", version: "999.999.999", valid: true},
		{name: "stable typical", version: "2.14.3", valid: true},

		// ---- Valid: prerelease tag only ----
		{name: "prerelease alpha", version: "1.0.0-alpha", valid: true},
		{name: "prerelease beta", version: "1.0.0-beta", valid: true},
		{name: "prerelease rc", version: "1.0.0-rc", valid: true},
		{name: "prerelease dev", version: "1.0.0-dev", valid: true},
		{name: "prerelease with hyphens", version: "1.0.0-pre-release", valid: true},
		{name: "prerelease alphanumeric tag", version: "1.0.0-beta2x", valid: true},

		// ---- Valid: prerelease tag + numeric suffix ----
		{name: "prerelease beta.0", version: "1.0.0-beta.0", valid: true},
		{name: "prerelease beta.1", version: "1.0.0-beta.1", valid: true},
		{name: "prerelease rc.42", version: "2.0.0-rc.42", valid: true},
		{name: "prerelease alpha.100", version: "0.1.0-alpha.100", valid: true},

		// ---- Valid: prerelease + build metadata ----
		{name: "prerelease with build", version: "1.0.0-beta+build", valid: true},
		{name: "prerelease with dotted build", version: "1.0.0-rc+build.456", valid: true},
		{name: "prerelease num with build", version: "1.0.0-beta.1+build.456", valid: true},
		{name: "prerelease with multi-dot build", version: "1.0.0-alpha.3+sha.abc123.20260401", valid: true},

		// ---- Invalid: leading zeroes ----
		{name: "leading zero major", version: "01.0.0", valid: false},
		{name: "leading zero minor", version: "1.01.0", valid: false},
		{name: "leading zero patch", version: "1.0.01", valid: false},
		{name: "leading zero prerelease num", version: "1.0.0-beta.01", valid: false},

		// ---- Invalid: stable + build metadata (disallowed) ----
		{name: "stable with build", version: "1.0.0+build.42", valid: false},
		{name: "stable with simple build", version: "1.0.0+123", valid: false},

		// ---- Invalid: missing components ----
		{name: "only major.minor", version: "1.0", valid: false},
		{name: "only major", version: "1", valid: false},
		{name: "empty string", version: "", valid: false},
		{name: "four components", version: "1.0.0.0", valid: false},

		// ---- Invalid: bad characters / formats ----
		{name: "spaces in version", version: "1.0.0 -beta", valid: false},
		{name: "v prefix", version: "v1.0.0", valid: false},
		{name: "letters in version", version: "1.0.a", valid: false},
		{name: "negative number", version: "-1.0.0", valid: false},
		{name: "prerelease starting with digit", version: "1.0.0-0beta", valid: false},
		{name: "prerelease starting with number", version: "1.0.0-123", valid: false},
		{name: "empty prerelease tag", version: "1.0.0-", valid: false},
		{name: "empty build metadata", version: "1.0.0-beta+", valid: false},
		{name: "double dash", version: "1.0.0--beta", valid: false},
		{name: "trailing dot in prerelease", version: "1.0.0-beta.", valid: false},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateBundleVersionFormat(tc.version)
			if tc.valid {
				assert.NoError(t, err, "expected %q to be valid", tc.version)
			} else {
				assert.Error(t, err, "expected %q to be invalid", tc.version)
			}
		})
	}
}

func TestParseSemanticVersion(t *testing.T) {
	tests := []struct {
		name        string
		version     string
		wantMajor   int
		wantMinor   int
		wantPatch   int
		wantPreTag  string
		wantPreNum  int
		wantBuild   string
		wantPreFull string
	}{
		{
			name: "stable release", version: "1.2.3",
			wantMajor: 1, wantMinor: 2, wantPatch: 3,
			wantPreTag: "", wantPreNum: -1, wantBuild: "", wantPreFull: "",
		},
		{
			name: "prerelease tag only", version: "1.0.0-beta",
			wantMajor: 1, wantMinor: 0, wantPatch: 0,
			wantPreTag: "beta", wantPreNum: -1, wantBuild: "", wantPreFull: "beta",
		},
		{
			name: "prerelease tag with zero", version: "1.0.0-beta.0",
			wantMajor: 1, wantMinor: 0, wantPatch: 0,
			wantPreTag: "beta", wantPreNum: 0, wantBuild: "", wantPreFull: "beta.0",
		},
		{
			name: "prerelease tag with number", version: "2.5.1-rc.3",
			wantMajor: 2, wantMinor: 5, wantPatch: 1,
			wantPreTag: "rc", wantPreNum: 3, wantBuild: "", wantPreFull: "rc.3",
		},
		{
			name: "prerelease with build", version: "1.0.0-alpha.1+build.789",
			wantMajor: 1, wantMinor: 0, wantPatch: 0,
			wantPreTag: "alpha", wantPreNum: 1, wantBuild: "build.789", wantPreFull: "alpha.1",
		},
		{
			name: "prerelease tag-only with build", version: "3.0.0-rc+sha.abc123",
			wantMajor: 3, wantMinor: 0, wantPatch: 0,
			wantPreTag: "rc", wantPreNum: -1, wantBuild: "sha.abc123", wantPreFull: "rc",
		},
		{
			name: "all zeroes", version: "0.0.0",
			wantMajor: 0, wantMinor: 0, wantPatch: 0,
			wantPreTag: "", wantPreNum: -1, wantBuild: "", wantPreFull: "",
		},
		{
			name: "hyphenated prerelease tag", version: "1.0.0-pre-release",
			wantMajor: 1, wantMinor: 0, wantPatch: 0,
			wantPreTag: "pre-release", wantPreNum: -1, wantBuild: "", wantPreFull: "pre-release",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			v, err := ParseSemanticVersion(tc.version)
			require.NoError(t, err)
			assert.Equal(t, tc.wantMajor, v.Major)
			assert.Equal(t, tc.wantMinor, v.Minor)
			assert.Equal(t, tc.wantPatch, v.Patch)
			assert.Equal(t, tc.wantPreTag, v.PrereleaseTag)
			assert.Equal(t, tc.wantPreNum, v.PrereleaseNum)
			assert.Equal(t, tc.wantBuild, v.Build)
			assert.Equal(t, tc.wantPreFull, v.Prerelease)
		})
	}
}

func TestParseSemanticVersion_Invalid(t *testing.T) {
	invalids := []string{
		"", "abc", "1.0", "1.0.0+build", "v1.0.0", "1.0.0-123",
	}
	for _, v := range invalids {
		t.Run(v, func(t *testing.T) {
			_, err := ParseSemanticVersion(v)
			assert.Error(t, err, "expected parse to fail for %q", v)
		})
	}
}

func TestIsVersionGreaterOrEqual(t *testing.T) {
	tests := []struct {
		name string
		v1   string
		v2   string
		want bool
	}{
		{name: "equal versions", v1: "1.0.0", v2: "1.0.0", want: true},
		{name: "major greater", v1: "2.0.0", v2: "1.9.9", want: true},
		{name: "major less", v1: "1.0.0", v2: "2.0.0", want: false},
		{name: "minor greater", v1: "1.2.0", v2: "1.1.9", want: true},
		{name: "minor less", v1: "1.1.0", v2: "1.2.0", want: false},
		{name: "patch greater", v1: "1.0.2", v2: "1.0.1", want: true},
		{name: "patch less", v1: "1.0.0", v2: "1.0.1", want: false},
		{name: "prerelease ignored in comparison", v1: "1.0.0-beta.1", v2: "1.0.0-rc.2", want: true},
		{name: "equal with different prerelease", v1: "2.0.0-alpha", v2: "2.0.0-beta.5", want: true},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			v1, err := ParseSemanticVersion(tc.v1)
			require.NoError(t, err)
			v2, err := ParseSemanticVersion(tc.v2)
			require.NoError(t, err)
			assert.Equal(t, tc.want, IsVersionGreaterOrEqual(v1, v2))
		})
	}
}
