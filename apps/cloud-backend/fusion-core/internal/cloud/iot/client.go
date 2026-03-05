package iot

import (
	"context"
	"strings"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iot"
	"github.com/aws/aws-sdk-go-v2/service/iot/types"
	"github.com/aws/aws-sdk-go-v2/service/iotdataplane"
	"go.uber.org/zap"
)

// IoT defines the interface for AWS IoT operations
type IoT interface {
	// Methods for IoT operations can be defined here
	CreateCertificateFromCsr(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error)
	RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error
	DeleteThing(ctx context.Context, thingName string, logger *zap.Logger) error
	AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error
	AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error
	DetatchCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error
	SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error
	DetatchPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error
	Publish(ctx context.Context, topic string, payload []byte, logger *zap.Logger) error
}

// IoTClient is a concrete implementation of the IoT interface using AWS SDK
type IoTClient struct {
	Client     *iot.Client
	DataClient *iotdataplane.Client
}

// NewIoTClient creates a new instance of the IoTClient with the provided AWS region, IoT endpoint, and logger
func NewIoTClient(ctx context.Context, region string, iotEndpoint string, logger *zap.Logger) (IoTClient, error) {
	// Load default AWS configuration (handles authentication and region from environment variables, etc.)
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		logger.Error("failed to load SDK config", zap.Error(err))
		return IoTClient{}, err
	}

	// Create an AWS IoT client (control plane)
	client := iot.NewFromConfig(cfg)

	// Ensure the IoT endpoint has the https:// prefix
	if !strings.HasPrefix(iotEndpoint, "https://") && !strings.HasPrefix(iotEndpoint, "http://") {
		iotEndpoint = "https://" + iotEndpoint
	}

	// Create an AWS IoT Data Plane client (for MQTT publish)
	dataClient := iotdataplane.NewFromConfig(cfg, func(o *iotdataplane.Options) {
		o.BaseEndpoint = &iotEndpoint
	})

	return IoTClient{
		Client:     client,
		DataClient: dataClient,
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

// DeleteThing deletes a thing from AWS IoT.
func (c IoTClient) DeleteThing(ctx context.Context, thingName string, logger *zap.Logger) error {
	input := &iot.DeleteThingInput{
		ThingName: &thingName,
	}

	_, err := c.Client.DeleteThing(ctx, input)
	if err != nil {
		logger.Error("failed to delete thing", zap.Error(err))
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

// Publish publishes a message to a specified topic in AWS IoT.
func (c IoTClient) Publish(ctx context.Context, topic string, payload []byte, logger *zap.Logger) error {
	input := &iotdataplane.PublishInput{
		Topic:   &topic,
		Qos:     0,
		Payload: payload,
	}

	_, err := c.DataClient.Publish(ctx, input)
	if err != nil {
		logger.Error("failed to publish message to topic", zap.Error(err))
		return err
	}

	return nil
}
