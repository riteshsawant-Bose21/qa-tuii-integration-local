package api

import (
	model "fusion/internal/gen/proto/fusion"

	"github.com/hashicorp/memberlist"
)

// MemberMetadata associates a member to its database metadata.
type MemberMetadata struct {
	Member   *memberlist.Node
	Metadata *model.DatabaseMetadata
}
