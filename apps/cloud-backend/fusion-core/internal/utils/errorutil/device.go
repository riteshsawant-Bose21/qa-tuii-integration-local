package errorutil

import "errors"

// Sentinel errors for use with errors.Is.
var (
	// Business logic errors
	ErrDeviceAlreadyExists    = errors.New(ErrMsgDeviceAlreadyExists)
	ErrDeviceUniqueConstraint = errors.New(ErrMsgDeviceUniqueConstraint)
	ErrDeviceNotFound         = errors.New(ErrMsgDeviceNotFound)
	ErrDeviceNotClaimed       = errors.New(ErrMsgDeviceNotClaimed)
	ErrDeviceAlreadyClaimed   = errors.New(ErrMsgDeviceAlreadyClaimed)
	ErrDeviceRequestInvalid   = errors.New(ErrMsgDeviceRequestInvalid)
	ErrCommandNotFound        = errors.New(ErrMsgCommandNotFound)
	ErrInvalidCSR             = errors.New(ErrMsgInvalidCSR)

	// Validation / nil-input errors
	ErrCSRPemEmpty            = errors.New(ErrMsgCSRPemEmpty)
	ErrThingNameEmpty         = errors.New(ErrMsgThingNameEmpty)
	ErrCertificateArnEmpty    = errors.New(ErrMsgCertificateArnEmpty)
	ErrPolicyNameEmpty        = errors.New(ErrMsgPolicyNameEmpty)
	ErrCertificateIDEmpty     = errors.New(ErrMsgCertificateIDEmpty)
	ErrTopicEmpty             = errors.New(ErrMsgTopicEmpty)
	ErrDeviceIDEmpty          = errors.New(ErrMsgDeviceIDEmpty)
	ErrDeviceUUIDEmpty        = errors.New(ErrMsgDeviceUUIDEmpty)
	ErrAccountIDEmpty         = errors.New(ErrMsgAccountIDEmpty)
	ErrCertIDEmpty            = errors.New(ErrMsgCertIDEmpty)
	ErrCertArnEmpty           = errors.New(ErrMsgCertArnEmpty)
	ErrProjectIDEmpty         = errors.New(ErrMsgProjectIDEmpty)
	ErrCommandIDEmpty         = errors.New(ErrMsgCommandIDEmpty)
	ErrStatusEmpty            = errors.New(ErrMsgStatusEmpty)
	ErrDeviceCreateReqNil     = errors.New(ErrMsgDeviceCreateReqNil)
	ErrBulkDeviceCreateReqNil = errors.New(ErrMsgBulkDeviceCreateReqNil)
	ErrDeviceUpdateReqNil     = errors.New(ErrMsgDeviceUpdateReqNil)
	ErrDeviceClaimReqNil      = errors.New(ErrMsgDeviceClaimReqNil)
	ErrDeviceRotateCertReqNil = errors.New(ErrMsgDeviceRotateCertReqNil)
	ErrCommandReqNil          = errors.New(ErrMsgCommandReqNil)
)

// Validation Error Messages
const (
	ErrMsgDeviceAlreadyExists    = "device with the given ID already exists"
	ErrMsgDeviceUniqueConstraint = "device already exists with one or more of the provided unique fields"
	ErrMsgDeviceNotFound         = "device not found"
	ErrMsgDeviceNotClaimed       = "device is not claimed"
	ErrMsgDeviceAlreadyClaimed   = "device is already claimed"
	ErrMsgDeviceRequestInvalid   = "invalid device request"
	ErrMsgCommandNotFound        = "command not found"

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
