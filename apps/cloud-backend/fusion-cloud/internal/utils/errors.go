package utils

import "errors"

var (
	ErrBadRequest          = errors.New("bad request")
	ErrUnauthorized        = errors.New("unauthorized access")
	ErrInternalServerError = errors.New("internal server error")

	ErrValidation = errors.New("validation error")

	ErrUserAlreadyExists  = errors.New("user already exists")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserNotFound       = errors.New("user not found")
	ErrInvalidToken       = errors.New("invalid token")
	ErrTokenExpired       = errors.New("token expired")

	ErrProjectAlreadyExists = errors.New("project already exists")
	ErrProjectNotFound      = errors.New("project not found")
	ErrOrganizationNotFound = errors.New("organization not found")
	ErrDeviceNotFound       = errors.New("device not found")
	ErrSpaceNotFound        = errors.New("space not found")

	ErrFileNotFound        = errors.New("file not found")
	ErrFileUploadFailed   = errors.New("file upload failed")
)
