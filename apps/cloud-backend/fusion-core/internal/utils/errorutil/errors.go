// Package errorutil provides common error handling utilities and error message constants.
package errorutil

import "errors"

// ErrUnauthorized is the sentinel error for unauthorized access.
var ErrUnauthorized = errors.New(MsgUnauthorized)

// ErrForbidden is the sentinel error for forbidden access.
var ErrForbidden = errors.New(MsgForbidden)

// General Messages
const (
	MsgUnauthorized        = "Unauthorized"
	MsgAccessDenied        = "Access denied"
	MsgInternalServerError = "Internal Server Error"
	MsgBadRequest          = "Bad Request"
	MsgForbidden           = "Forbidden"
	MsgInvalidRequestBody  = "Invalid request body"
	MsgInvalidToken        = "Invalid token"
)
