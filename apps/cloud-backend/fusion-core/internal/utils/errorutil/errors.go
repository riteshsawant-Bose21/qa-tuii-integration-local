// Package errorutil provides common error handling utilities and error message constants.
package errorutil

// General Messages
const (
	MsgUnauthorized              = "Unauthorized"
	ErrMsgDeviceAlreadyExists    = "device with the given ID already exists"
	ErrMsgDeviceUniqueConstraint = "device already exists with one or more of the provided unique fields"
	ErrMsgDeviceNotFound         = "device not found"
	ErrMsgDeviceNotClaimed       = "device is not claimed"
	ErrMsgDeviceAlreadyClaimed   = "device is already claimed"
	ErrMsgDeviceRequestInvalid   = "invalid device request"
	ErrMsgCommandNotFound        = "command not found"
	MsgAccessDenied              = "Access denied"
	MsgInternalServerError       = "Internal Server Error"
	MsgBadRequest                = "Bad Request"
	MsgForbidden                 = "Forbidden"
	MsgInvalidRequestBody        = "Invalid request body"
	MsgInvalidToken              = "Invalid token"
)

// Validation Error Messages
const (
	ErrMsgCSRPemEmpty            = "csrPem cannot be empty"
	ErrMsgInvalidCSR             = "invalid CSR"
	ErrMsgThingNameEmpty         = "thingName cannot be empty"
	ErrMsgCertificateArnEmpty    = "certificateArn cannot be empty"
	ErrMsgPolicyNameEmpty        = "policyName cannot be empty"
	ErrMsgCertificateIDEmpty     = "certificateId cannot be empty"
	ErrMsgTopicEmpty             = "topic cannot be empty"
	ErrMsgDeviceIDEmpty          = "deviceID cannot be empty"
	ErrMsgDeviceUUIDEmpty        = "deviceUUID cannot be empty"
	ErrMsgAccountIDEmpty         = "accountID cannot be empty"
	ErrMsgCertIDEmpty            = "certID cannot be empty"
	ErrMsgCertArnEmpty           = "certArn cannot be empty"
	ErrMsgProjectIDEmpty         = "projectID cannot be empty"
	ErrMsgCommandIDEmpty         = "commandID cannot be empty"
	ErrMsgStatusEmpty            = "status cannot be empty"
	ErrMsgDeviceCreateReqNil     = "device create request cannot be nil"
	ErrMsgBulkDeviceCreateReqNil = "bulk device create request cannot be nil"
	ErrMsgDeviceUpdateReqNil     = "device update request cannot be nil"
	ErrMsgDeviceClaimReqNil      = "device claim request cannot be nil"
	ErrMsgDeviceRotateCertReqNil = "device rotate cert request cannot be nil"
	ErrMsgCommandReqNil          = "command request cannot be nil"
	ErrMsgInvalidCommandType     = "invalid command type"
)
