// Package errorutil provides common error handling utilities and error message constants.
package errorutil

// General Messages
const (
	MsgUnauthorized            = "Unauthorized"
	ErrMsgDeviceAlreadyExists  = "device with the given ID already exists"
	ErrMsgDeviceNotFound       = "device not found"
	ErrMsgDeviceNotClaimed     = "device is not claimed"
	ErrMsgDeviceAlreadyClaimed = "device is already claimed"
	ErrMsgCommandNotFound      = "command not found"
	MsgAccessDenied            = "Access denied"
	MsgInternalServerError     = "Internal Server Error"
	MsgBadRequest              = "Bad Request"
	MsgForbidden               = "Forbidden"
	MsgInvalidRequestBody      = "Invalid request body"
	MsgInvalidToken            = "Invalid token"
)
