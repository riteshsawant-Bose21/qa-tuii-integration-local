package api

import (
	model "fusion/internal/gen/proto/fusion"

	"github.com/hashicorp/memberlist"
)

// DeviceRuntimeInfo extends the public device contract with internal build and
// VRRP metadata. Public API and cluster notification paths should prefer
// model.DeviceInfo directly.
type DeviceRuntimeInfo struct {
	model.DeviceInfo
	FusionMonorepoBranch     string `json:"fusion_monorepo_branch,omitempty"`
	FusionMonorepoCommitHash string `json:"fusion_monorepo_commit_hash,omitempty"`
	JenkinsBuildNumber       string `json:"jenkins_build_number,omitempty"`
	PreReleaseTag            string `json:"pre_release_tag,omitempty"`
	VrrpPriority             int    `json:"vrrp_priority"`
}

// MemberMetadata associates a member to its database metadata.
type MemberMetadata struct {
	Member   *memberlist.Node
	Metadata model.DatabaseMetadata
}
