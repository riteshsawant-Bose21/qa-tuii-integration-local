package transport

import (
	"fusion/internal/api"

	"github.com/hashicorp/memberlist"
)

// ClusterInterface abstracts the underlying cluster transport so components
// (like the pubsub Hub) don't need to depend directly on memberlist.
type ClusterInterface interface {
	LocalNode() *memberlist.Node
	MemberListMembers() []*memberlist.Node
	SendReliable(node *memberlist.Node, msg []byte) error
	PostGenericToAdmin(endpoint string, localFn func() error) error
	GetAllDevicesInfo() []api.DeviceInfo
	GetDeviceInfoLocal() api.DeviceInfo

	//device_id is the id for which the patch needs to be applied.
	//device_id is also a field in the patch and can be updated.
	UpdateDeviceInfo(device_id string, patch *api.DevicePatch) error
	UpdateDeviceInfoLocal(patch *api.DevicePatch) error
	HostIsLocal(addr string) bool
}
