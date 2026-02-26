package cloudfs

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iot"
	"github.com/aws/aws-sdk-go-v2/service/iot/types"
	"go.uber.org/zap"
)

// IoT defines the interface for AWS IoT operations
type IoT interface {
	// Methods for IoT operations can be defined here
	CreateCertificateFromCsr(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error)
	RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error
	AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error
	AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error
	DetatchCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error
	SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error
	DetatchPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error
}

// IoTClient is a concrete implementation of the IoT interface using AWS SDK
type IoTClient struct {
	Client *iot.Client
}

// NewIoTClient creates a new instance of the IoTClient with the provided AWS region and logger
func NewIoTClient(ctx context.Context, region string, logger *zap.Logger) (IoTClient, error) {
	// 2. Load default AWS configuration (handles authentication and region from environment variables, etc.)
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		logger.Error("failed to load SDK config", zap.Error(err))
	}

	// 3. Create an AWS IoT client
	client := iot.NewFromConfig(cfg)

	return IoTClient{
		Client: client,
	}, nil
}

// CreateCertificateFromCsr creates a certificate in AWS IoT from a given CSR (Certificate Signing Request).
func (c IoTClient) CreateCertificateFromCsr(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error) {
	input := &iot.CreateCertificateFromCsrInput{
		CertificateSigningRequest: csrPem,
		SetAsActive:               true,
	}

	result, err := c.Client.CreateCertificateFromCsr(ctx, input)
	if err != nil {
		logger.Error("failed to create certificate from CSR", zap.Error(err))
		return nil, nil, nil, err
	}

	return result.CertificatePem, result.CertificateId, result.CertificateArn, nil
}

// RegisterThing registers a new thing in AWS IoT with the given thing name.
func (c IoTClient) RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error {
	input := &iot.CreateThingInput{
		ThingName: &thingName,
	}

	_, err := c.Client.CreateThing(ctx, input)
	if err != nil {
		logger.Error("failed to create thing", zap.Error(err))
		return err
	}

	return nil
}

// AttachCertificateToThing attaches a certificate to a thing in AWS IoT.
func (c IoTClient) AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.AttachThingPrincipalInput{
		Principal: &certificateArn,
		ThingName: &thingName,
	}

	_, err := c.Client.AttachThingPrincipal(ctx, input)
	if err != nil {
		logger.Error("failed to attach certificate to thing", zap.Error(err))
		return err
	}

	return nil
}

// AttachPolicyToCertificate attaches a policy to a certificate in AWS IoT.
func (c IoTClient) AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.AttachPolicyInput{
		PolicyName: &policyName,
		Target:     &certificateArn,
	}

	_, err := c.Client.AttachPolicy(ctx, input)
	if err != nil {
		logger.Error("failed to attach policy to certificate", zap.Error(err))
		return err
	}

	return nil
}

// DetatchCertificateFromThing detaches a certificate from a thing in AWS IoT.
func (c IoTClient) DetatchCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.DetachThingPrincipalInput{
		Principal: &certificateArn,
		ThingName: &thingName,
	}

	_, err := c.Client.DetachThingPrincipal(ctx, input)
	if err != nil {
		logger.Error("failed to detach certificate from thing", zap.Error(err))
		return err
	}

	return nil
}

// SetCertificateInactive sets a certificate to inactive in AWS IoT.
func (c IoTClient) SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error {
	input := &iot.UpdateCertificateInput{
		CertificateId: &certificateId,
		NewStatus:     types.CertificateStatusInactive,
	}

	_, err := c.Client.UpdateCertificate(ctx, input)
	if err != nil {
		logger.Error("failed to set certificate inactive", zap.Error(err))
		return err
	}

	return nil
}

// DetatchPolicyFromCertificate detaches a policy from a certificate in AWS IoT.
func (c IoTClient) DetatchPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	input := &iot.DetachPolicyInput{
		PolicyName: &policyName,
		Target:     &certificateArn,
	}

	_, err := c.Client.DetachPolicy(ctx, input)
	if err != nil {
		logger.Error("failed to detach policy from certificate", zap.Error(err))
		return err
	}

	return nil
}
