package errorutil

import "errors"

// Firmware-related sentinel errors
var (
	// ErrReleaseNotFound indicates that the requested firmware release was not found
	ErrReleaseNotFound = errors.New("release not found")

	// ErrVersionExists indicates that a firmware version already exists for the platform
	ErrVersionExists = errors.New("a newer or equal version already exists for this platform")

	// ErrInvalidVersion indicates that the firmware version format is invalid
	ErrInvalidVersion = errors.New("invalid version format")
)
