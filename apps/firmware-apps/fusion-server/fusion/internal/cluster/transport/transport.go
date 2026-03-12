package transport

import (
	"github.com/hashicorp/memberlist"
)

// ClusterInterface abstracts the underlying cluster transport so components
// (like the pubsub Hub) don't need to depend directly on memberlist.
type ClusterInterface interface {
	LocalNode() *memberlist.Node
	MemberListMembers() []*memberlist.Node
	SendReliable(node *memberlist.Node, msg []byte) error
	PostGenericToAdmin(endpoint string, localFn func() error) error
}
