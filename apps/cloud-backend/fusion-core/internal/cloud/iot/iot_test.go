package cloudfs

import (
	"context"
	"errors"
	"testing"

	"github.com/aws/aws-sdk-go-v2/service/iot"
	"github.com/aws/aws-sdk-go-v2/service/iot/types"
	"github.com/stretchr/testify/assert"
	"go.uber.org/zap"
)

// mockIoTClient implements mockIoTAPI for testing
type mockIoTClient struct {
	createCertificateFromCsrFunc func(ctx context.Context, params *iot.CreateCertificateFromCsrInput, optFns ...func(*iot.Options)) (*iot.CreateCertificateFromCsrOutput, error)
	createThingFunc              func(ctx context.Context, params *iot.CreateThingInput, optFns ...func(*iot.Options)) (*iot.CreateThingOutput, error)
	attachThingPrincipalFunc     func(ctx context.Context, params *iot.AttachThingPrincipalInput, optFns ...func(*iot.Options)) (*iot.AttachThingPrincipalOutput, error)
	attachPolicyFunc             func(ctx context.Context, params *iot.AttachPolicyInput, optFns ...func(*iot.Options)) (*iot.AttachPolicyOutput, error)
	detachThingPrincipalFunc     func(ctx context.Context, params *iot.DetachThingPrincipalInput, optFns ...func(*iot.Options)) (*iot.DetachThingPrincipalOutput, error)
	updateCertificateFunc        func(ctx context.Context, params *iot.UpdateCertificateInput, optFns ...func(*iot.Options)) (*iot.UpdateCertificateOutput, error)
	detachPolicyFunc             func(ctx context.Context, params *iot.DetachPolicyInput, optFns ...func(*iot.Options)) (*iot.DetachPolicyOutput, error)
}

func (m *mockIoTClient) CreateCertificateFromCsr(ctx context.Context, params *iot.CreateCertificateFromCsrInput, optFns ...func(*iot.Options)) (*iot.CreateCertificateFromCsrOutput, error) {
	return m.createCertificateFromCsrFunc(ctx, params, optFns...)
}

func (m *mockIoTClient) CreateThing(ctx context.Context, params *iot.CreateThingInput, optFns ...func(*iot.Options)) (*iot.CreateThingOutput, error) {
	return m.createThingFunc(ctx, params, optFns...)
}

func (m *mockIoTClient) AttachThingPrincipal(ctx context.Context, params *iot.AttachThingPrincipalInput, optFns ...func(*iot.Options)) (*iot.AttachThingPrincipalOutput, error) {
	return m.attachThingPrincipalFunc(ctx, params, optFns...)
}

func (m *mockIoTClient) AttachPolicy(ctx context.Context, params *iot.AttachPolicyInput, optFns ...func(*iot.Options)) (*iot.AttachPolicyOutput, error) {
	return m.attachPolicyFunc(ctx, params, optFns...)
}

func (m *mockIoTClient) DetachThingPrincipal(ctx context.Context, params *iot.DetachThingPrincipalInput, optFns ...func(*iot.Options)) (*iot.DetachThingPrincipalOutput, error) {
	return m.detachThingPrincipalFunc(ctx, params, optFns...)
}

func (m *mockIoTClient) UpdateCertificate(ctx context.Context, params *iot.UpdateCertificateInput, optFns ...func(*iot.Options)) (*iot.UpdateCertificateOutput, error) {
	return m.updateCertificateFunc(ctx, params, optFns...)
}

func (m *mockIoTClient) DetachPolicy(ctx context.Context, params *iot.DetachPolicyInput, optFns ...func(*iot.Options)) (*iot.DetachPolicyOutput, error) {
	return m.detachPolicyFunc(ctx, params, optFns...)
}

// testableIoTClient wraps mockIoTClient for testing
type testableIoTClient struct {
	mock *mockIoTClient
}

func (c *testableIoTClient) CreateCertificateFromCsr(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error) {
	input := &iot.CreateCertificateFromCsrInput{
		CertificateSigningRequest: csrPem,
		SetAsActive:               true,
	}

	result, err := c.mock.CreateCertificateFromCsr(ctx, input)
	if err != nil {
		logger.Error("failed to create certificate from CSR", zap.Error(err))
		return nil, nil, nil, err
	}

	return result.CertificatePem, result.CertificateId, result.CertificateArn, nil
}

func (c *testableIoTClient) RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error {
	input := &iot.CreateThingInput{
		ThingName: &thingName,
	}

	_, err := c.mock.CreateThing(ctx, input)
	if err != nil {
		logger.Error("failed to create thing", zap.Error(err))
		return err
	}

	return nil
}

func (c *testableIoTClient) AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.AttachThingPrincipalInput{
		Principal: &certificateArn,
		ThingName: &thingName,
	}

	_, err := c.mock.AttachThingPrincipal(ctx, input)
	if err != nil {
		logger.Error("failed to attach certificate to thing", zap.Error(err))
		return err
	}

	return nil
}

func (c *testableIoTClient) AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.AttachPolicyInput{
		PolicyName: &policyName,
		Target:     &certificateArn,
	}

	_, err := c.mock.AttachPolicy(ctx, input)
	if err != nil {
		logger.Error("failed to attach policy to certificate", zap.Error(err))
		return err
	}

	return nil
}

func (c *testableIoTClient) DetatchCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.DetachThingPrincipalInput{
		Principal: &certificateArn,
		ThingName: &thingName,
	}

	_, err := c.mock.DetachThingPrincipal(ctx, input)
	if err != nil {
		logger.Error("failed to detach certificate from thing", zap.Error(err))
		return err
	}

	return nil
}

func (c *testableIoTClient) SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error {
	input := &iot.UpdateCertificateInput{
		CertificateId: &certificateId,
		NewStatus:     types.CertificateStatusInactive,
	}

	_, err := c.mock.UpdateCertificate(ctx, input)
	if err != nil {
		logger.Error("failed to set certificate inactive", zap.Error(err))
		return err
	}

	return nil
}

func (c *testableIoTClient) DetatchPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.DetachPolicyInput{
		PolicyName: &policyName,
		Target:     &certificateArn,
	}

	_, err := c.mock.DetachPolicy(ctx, input)
	if err != nil {
		logger.Error("failed to detach policy from certificate", zap.Error(err))
		return err
	}

	return nil
}

// Test constants
const (
	testCSRPem         = "-----BEGIN CERTIFICATE REQUEST-----\nMIIBkTCB+wIBADBSMQsw...\n-----END CERTIFICATE REQUEST-----"
	testCertificatePem = "-----BEGIN CERTIFICATE-----\nMIIBkTCB+wIB...\n-----END CERTIFICATE-----"
	testCertificateId  = "cert-12345678"
	testCertificateArn = "arn:aws:iot:us-east-1:123456789012:cert/cert-12345678"
	testThingName      = "test-device-001"
	testPolicyName     = "FusionDevicePolicy"
)

func TestCreateCertificateFromCsr_Success(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	csrPem := testCSRPem
	expectedCertPem := testCertificatePem
	expectedCertId := testCertificateId
	expectedCertArn := testCertificateArn

	mockClient := &mockIoTClient{
		createCertificateFromCsrFunc: func(_ context.Context, params *iot.CreateCertificateFromCsrInput, _ ...func(*iot.Options)) (*iot.CreateCertificateFromCsrOutput, error) {
			assert.Equal(t, &csrPem, params.CertificateSigningRequest)
			assert.True(t, params.SetAsActive)
			return &iot.CreateCertificateFromCsrOutput{
				CertificatePem: &expectedCertPem,
				CertificateId:  &expectedCertId,
				CertificateArn: &expectedCertArn,
			}, nil
		},
	}

	client := &testableIoTClient{mock: mockClient}
	certPem, certId, certArn, err := client.CreateCertificateFromCsr(ctx, &csrPem, logger)

	assert.NoError(t, err)
	assert.Equal(t, &expectedCertPem, certPem)
	assert.Equal(t, &expectedCertId, certId)
	assert.Equal(t, &expectedCertArn, certArn)
}

func TestCreateCertificateFromCsr_Error(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	csrPem := testCSRPem
	expectedErr := errors.New("AWS IoT error: invalid CSR")

	mockClient := &mockIoTClient{
		createCertificateFromCsrFunc: func(_ context.Context, _ *iot.CreateCertificateFromCsrInput, _ ...func(*iot.Options)) (*iot.CreateCertificateFromCsrOutput, error) {
			return nil, expectedErr
		},
	}

	client := &testableIoTClient{mock: mockClient}
	certPem, certId, certArn, err := client.CreateCertificateFromCsr(ctx, &csrPem, logger)

	assert.Error(t, err)
	assert.Equal(t, expectedErr, err)
	assert.Nil(t, certPem)
	assert.Nil(t, certId)
	assert.Nil(t, certArn)
}

func TestRegisterThing_Success(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()

	mockClient := &mockIoTClient{
		createThingFunc: func(_ context.Context, params *iot.CreateThingInput, _ ...func(*iot.Options)) (*iot.CreateThingOutput, error) {
			assert.Equal(t, testThingName, *params.ThingName)
			return &iot.CreateThingOutput{
				ThingName: params.ThingName,
			}, nil
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.RegisterThing(ctx, testThingName, logger)

	assert.NoError(t, err)
}

func TestRegisterThing_Error(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	expectedErr := errors.New("AWS IoT error: thing already exists")

	mockClient := &mockIoTClient{
		createThingFunc: func(_ context.Context, _ *iot.CreateThingInput, _ ...func(*iot.Options)) (*iot.CreateThingOutput, error) {
			return nil, expectedErr
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.RegisterThing(ctx, testThingName, logger)

	assert.Error(t, err)
	assert.Equal(t, expectedErr, err)
}

func TestAttachCertificateToThing_Success(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()

	mockClient := &mockIoTClient{
		attachThingPrincipalFunc: func(_ context.Context, params *iot.AttachThingPrincipalInput, _ ...func(*iot.Options)) (*iot.AttachThingPrincipalOutput, error) {
			assert.Equal(t, testThingName, *params.ThingName)
			assert.Equal(t, testCertificateArn, *params.Principal)
			return &iot.AttachThingPrincipalOutput{}, nil
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.AttachCertificateToThing(ctx, testThingName, testCertificateArn, logger)

	assert.NoError(t, err)
}

func TestAttachCertificateToThing_Error(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	expectedErr := errors.New("AWS IoT error: certificate not found")

	mockClient := &mockIoTClient{
		attachThingPrincipalFunc: func(_ context.Context, _ *iot.AttachThingPrincipalInput, _ ...func(*iot.Options)) (*iot.AttachThingPrincipalOutput, error) {
			return nil, expectedErr
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.AttachCertificateToThing(ctx, testThingName, testCertificateArn, logger)

	assert.Error(t, err)
	assert.Equal(t, expectedErr, err)
}

func TestAttachPolicyToCertificate_Success(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()

	mockClient := &mockIoTClient{
		attachPolicyFunc: func(_ context.Context, params *iot.AttachPolicyInput, _ ...func(*iot.Options)) (*iot.AttachPolicyOutput, error) {
			assert.Equal(t, testPolicyName, *params.PolicyName)
			assert.Equal(t, testCertificateArn, *params.Target)
			return &iot.AttachPolicyOutput{}, nil
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.AttachPolicyToCertificate(ctx, testPolicyName, testCertificateArn, logger)

	assert.NoError(t, err)
}

func TestAttachPolicyToCertificate_Error(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	expectedErr := errors.New("AWS IoT error: policy not found")

	mockClient := &mockIoTClient{
		attachPolicyFunc: func(_ context.Context, _ *iot.AttachPolicyInput, _ ...func(*iot.Options)) (*iot.AttachPolicyOutput, error) {
			return nil, expectedErr
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.AttachPolicyToCertificate(ctx, testPolicyName, testCertificateArn, logger)

	assert.Error(t, err)
	assert.Equal(t, expectedErr, err)
}

func TestDetatchCertificateFromThing_Success(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()

	mockClient := &mockIoTClient{
		detachThingPrincipalFunc: func(_ context.Context, params *iot.DetachThingPrincipalInput, _ ...func(*iot.Options)) (*iot.DetachThingPrincipalOutput, error) {
			assert.Equal(t, testThingName, *params.ThingName)
			assert.Equal(t, testCertificateArn, *params.Principal)
			return &iot.DetachThingPrincipalOutput{}, nil
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.DetatchCertificateFromThing(ctx, testThingName, testCertificateArn, logger)

	assert.NoError(t, err)
}

func TestDetatchCertificateFromThing_Error(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	expectedErr := errors.New("AWS IoT error: certificate not attached to thing")

	mockClient := &mockIoTClient{
		detachThingPrincipalFunc: func(_ context.Context, _ *iot.DetachThingPrincipalInput, _ ...func(*iot.Options)) (*iot.DetachThingPrincipalOutput, error) {
			return nil, expectedErr
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.DetatchCertificateFromThing(ctx, testThingName, testCertificateArn, logger)

	assert.Error(t, err)
	assert.Equal(t, expectedErr, err)
}

func TestSetCertificateInactive_Success(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()

	mockClient := &mockIoTClient{
		updateCertificateFunc: func(_ context.Context, params *iot.UpdateCertificateInput, _ ...func(*iot.Options)) (*iot.UpdateCertificateOutput, error) {
			assert.Equal(t, testCertificateId, *params.CertificateId)
			assert.Equal(t, types.CertificateStatusInactive, params.NewStatus)
			return &iot.UpdateCertificateOutput{}, nil
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.SetCertificateInactive(ctx, testCertificateId, logger)

	assert.NoError(t, err)
}

func TestSetCertificateInactive_Error(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	expectedErr := errors.New("AWS IoT error: certificate not found")

	mockClient := &mockIoTClient{
		updateCertificateFunc: func(_ context.Context, _ *iot.UpdateCertificateInput, _ ...func(*iot.Options)) (*iot.UpdateCertificateOutput, error) {
			return nil, expectedErr
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.SetCertificateInactive(ctx, testCertificateId, logger)

	assert.Error(t, err)
	assert.Equal(t, expectedErr, err)
}

func TestDetatchPolicyFromCertificate_Success(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()

	mockClient := &mockIoTClient{
		detachPolicyFunc: func(_ context.Context, params *iot.DetachPolicyInput, _ ...func(*iot.Options)) (*iot.DetachPolicyOutput, error) {
			assert.Equal(t, testPolicyName, *params.PolicyName)
			assert.Equal(t, testCertificateArn, *params.Target)
			return &iot.DetachPolicyOutput{}, nil
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.DetatchPolicyFromCertificate(ctx, testPolicyName, testCertificateArn, logger)

	assert.NoError(t, err)
}

func TestDetatchPolicyFromCertificate_Error(t *testing.T) {
	logger := zap.NewNop()
	ctx := context.Background()
	expectedErr := errors.New("AWS IoT error: policy not attached to certificate")

	mockClient := &mockIoTClient{
		detachPolicyFunc: func(_ context.Context, _ *iot.DetachPolicyInput, _ ...func(*iot.Options)) (*iot.DetachPolicyOutput, error) {
			return nil, expectedErr
		},
	}

	client := &testableIoTClient{mock: mockClient}
	err := client.DetatchPolicyFromCertificate(ctx, testPolicyName, testCertificateArn, logger)

	assert.Error(t, err)
	assert.Equal(t, expectedErr, err)
}

// Table-driven tests for comprehensive coverage
func TestIoTOperations_TableDriven(t *testing.T) {
	tests := []struct {
		name          string
		operation     string
		setupMock     func() *mockIoTClient
		execute       func(client *testableIoTClient, ctx context.Context, logger *zap.Logger) error
		expectError   bool
		errorContains string
	}{
		{
			name:      "RegisterThing with empty name",
			operation: "RegisterThing",
			setupMock: func() *mockIoTClient {
				return &mockIoTClient{
					createThingFunc: func(_ context.Context, params *iot.CreateThingInput, _ ...func(*iot.Options)) (*iot.CreateThingOutput, error) {
						if *params.ThingName == "" {
							return nil, errors.New("thing name cannot be empty")
						}
						return &iot.CreateThingOutput{}, nil
					},
				}
			},
			execute: func(client *testableIoTClient, ctx context.Context, logger *zap.Logger) error {
				return client.RegisterThing(ctx, "", logger)
			},
			expectError:   true,
			errorContains: "thing name cannot be empty",
		},
		{
			name:      "AttachCertificateToThing with valid inputs",
			operation: "AttachCertificateToThing",
			setupMock: func() *mockIoTClient {
				return &mockIoTClient{
					attachThingPrincipalFunc: func(_ context.Context, _ *iot.AttachThingPrincipalInput, _ ...func(*iot.Options)) (*iot.AttachThingPrincipalOutput, error) {
						return &iot.AttachThingPrincipalOutput{}, nil
					},
				}
			},
			execute: func(client *testableIoTClient, ctx context.Context, logger *zap.Logger) error {
				return client.AttachCertificateToThing(ctx, testThingName, testCertificateArn, logger)
			},
			expectError: false,
		},
		{
			name:      "SetCertificateInactive with invalid certificate ID",
			operation: "SetCertificateInactive",
			setupMock: func() *mockIoTClient {
				return &mockIoTClient{
					updateCertificateFunc: func(_ context.Context, _ *iot.UpdateCertificateInput, _ ...func(*iot.Options)) (*iot.UpdateCertificateOutput, error) {
						return nil, errors.New("ResourceNotFoundException: certificate not found")
					},
				}
			},
			execute: func(client *testableIoTClient, ctx context.Context, logger *zap.Logger) error {
				return client.SetCertificateInactive(ctx, "invalid-cert-id", logger)
			},
			expectError:   true,
			errorContains: "ResourceNotFoundException",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			logger := zap.NewNop()
			ctx := context.Background()
			mockClient := tc.setupMock()
			client := &testableIoTClient{mock: mockClient}

			err := tc.execute(client, ctx, logger)

			if tc.expectError {
				assert.Error(t, err)
				if tc.errorContains != "" {
					assert.Contains(t, err.Error(), tc.errorContains)
				}
			} else {
				assert.NoError(t, err)
			}
		})
	}
}
