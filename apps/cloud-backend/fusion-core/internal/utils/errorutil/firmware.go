package errorutil

import "errors"

// Firmware-related sentinel errors
var (
	// ErrBundleNotFound indicates that the requested firmware bundle was not found
	ErrBundleNotFound = errors.New("bundle not found")

	// ErrBundleArtifactNotFound indicates that the physical artifact file for the bundle was not found
	ErrBundleArtifactNotFound = errors.New("bundle artifact not found in storage")

	// ErrVersionExists indicates that a firmware version already exists for the platform
	ErrVersionExists = errors.New("version already exists")

	// ErrBundleNotApprovedForDownload indicates that the bundle exists but has not been approved for download
	ErrBundleNotApprovedForDownload = errors.New("bundle not approved for download")

	// ErrBundleNotApproved indicates that the bundle exists but has not been approved
	ErrBundleNotApproved = errors.New("bundle not approved")
)
