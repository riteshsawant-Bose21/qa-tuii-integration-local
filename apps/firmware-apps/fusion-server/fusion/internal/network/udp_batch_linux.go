//go:build linux

package network

import (
	"net"
	"unsafe"

	"golang.org/x/sys/unix"
)

// iovec matches the C struct iovec for scatter/gather I/O.
type iovec struct {
	Base *byte
	Len  uint64
}

// msghdr matches the C struct msghdr (for sendmsg/sendmmsg).
type msghdr struct {
	Name       *byte
	Namelen    uint32
	_          [4]byte
	Iov        *iovec
	Iovlen     uint64
	Control    *byte
	Controllen uint64
	Flags      int32
	_          [4]byte
}

// mmsghdr matches the C struct mmsghdr (for sendmmsg).
type mmsghdr struct {
	Hdr msghdr
	Len uint32
	_   [4]byte
}

// sendBatch sends the same payload to multiple destinations in a single
// sendmmsg syscall, reducing per-datagram kernel transition overhead.
// Returns the indices of targets that failed.
func sendBatch(fd int, payload []byte, targets []clientTarget) []int {
	n := len(targets)
	if n == 0 {
		return nil
	}

	msgs := make([]mmsghdr, n)
	iovecs := make([]iovec, n)
	addrs := make([]unix.RawSockaddrInet4, n)

	payloadPtr := &payload[0]
	payloadLen := uint64(len(payload))

	for i, t := range targets {
		ip4 := t.addr.IP.To4()
		if ip4 == nil {
			continue
		}

		addrs[i].Family = unix.AF_INET
		p := uint16(t.addr.Port)
		addrs[i].Port = (p >> 8) | (p << 8)
		copy(addrs[i].Addr[:], ip4)

		iovecs[i].Base = payloadPtr
		iovecs[i].Len = payloadLen

		msgs[i].Hdr.Name = (*byte)(unsafe.Pointer(&addrs[i]))
		msgs[i].Hdr.Namelen = unix.SizeofSockaddrInet4
		msgs[i].Hdr.Iov = &iovecs[i]
		msgs[i].Hdr.Iovlen = 1
	}

	sent, err := doSendmmsg(fd, msgs)
	if err != nil {
		failed := make([]int, n)
		for i := range failed {
			failed[i] = i
		}
		return failed
	}

	if sent < n {
		failed := make([]int, 0, n-sent)
		for i := sent; i < n; i++ {
			failed = append(failed, i)
		}
		return failed
	}

	return nil
}

func doSendmmsg(fd int, msgs []mmsghdr) (int, error) {
	n, _, errno := unix.Syscall6(
		unix.SYS_SENDMMSG,
		uintptr(fd),
		uintptr(unsafe.Pointer(&msgs[0])),
		uintptr(len(msgs)),
		0,
		0,
		0,
	)
	if errno != 0 {
		return int(n), errno
	}
	return int(n), nil
}

// extractUDPConnFd extracts the raw file descriptor from a *net.UDPConn.
func extractUDPConnFd(conn *net.UDPConn) (int, error) {
	rawConn, err := conn.SyscallConn()
	if err != nil {
		return -1, err
	}

	var fd int
	err = rawConn.Control(func(f uintptr) {
		fd = int(f)
	})
	if err != nil {
		return -1, err
	}
	return fd, nil
}
