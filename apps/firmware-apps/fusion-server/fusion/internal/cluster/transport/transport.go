package transport

import (
	"fmt"

	"github.com/hashicorp/memberlist"
)

// ClusterTransport abstracts the underlying cluster transport so components
// (like the pubsub Hub) don't need to depend directly on memberlist.
type ClusterTransport interface {
	LocalNode() *memberlist.Node
	Members() []*memberlist.Node
	SendReliable(node *memberlist.Node, msg []byte) error
}

// MemberlistTransport is a concrete adapter over *memberlist.Memberlist.
type MemberlistTransport struct {
	ml *memberlist.Memberlist
}

// NewMemberlistTransport wraps a memberlist instance in a ClusterTransport.
func NewMemberlistTransport(ml *memberlist.Memberlist) *MemberlistTransport {
	return &MemberlistTransport{ml: ml}
}

func (t *MemberlistTransport) LocalNode() *memberlist.Node {
	if t == nil || t.ml == nil {
		return nil
	}
	return t.ml.LocalNode()
}

func (t *MemberlistTransport) Members() []*memberlist.Node {
	if t == nil || t.ml == nil {
		return nil
	}
	return t.ml.Members()
}

func (t *MemberlistTransport) SendReliable(n *memberlist.Node, msg []byte) error {
	if t == nil || t.ml == nil {
		return fmt.Errorf("memberlist transport not initialized")
	}
	return t.ml.SendReliable(n, msg)
}
