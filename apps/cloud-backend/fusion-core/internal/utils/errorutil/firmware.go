package errorutil

import "errors"

// Firmware-related sentinel errors
var (
	// ErrBundleNotFound indicates that the requested firmware bundle was not found
	ErrBundleNotFound = errors.New("bundle not found")

	// ErrVersionExists indicates that a firmware version already exists for the platform
	ErrVersionExists = errors.New("a newer or equal version already exists for this platform")

	// ErrInvalidVersion indicates that the firmware version format is invalid
	ErrInvalidVersion = errors.New("invalid version format")

	// ErrInvalidChannel indicates that the distribution channel is invalid
	ErrInvalidChannel = errors.New("invalid distribution channel")

	// ErrInvalidReleaseStatus indicates that the release status is not suitable for the operation
	ErrInvalidReleaseStatus = errors.New("invalid release status for this operation")
)
