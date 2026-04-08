package iot

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/iot"
	"github.com/aws/aws-sdk-go-v2/service/iot/types"
	"github.com/aws/aws-sdk-go-v2/service/iotdataplane"
	"go.uber.org/zap"
)

// IoT defines the interface for AWS IoT operations
type IoT interface {
	// Methods for IoT operations can be defined here
	CreateCertificateFromCSR(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error)
	RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error
	DeleteThing(ctx context.Context, thingName string, logger *zap.Logger) error
	AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error
	AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error
	DetachCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error
	SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error
	DetachPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error
	Publish(ctx context.Context, topic string, payload []byte, logger *zap.Logger) error
}

// IoTClient is a concrete implementation of the IoT interface using AWS SDK
type IoTClient struct {
	Client     *iot.Client
	DataClient *iotdataplane.Client
}

// NewIoTClient creates a new instance of the IoTClient with the provided AWS region, IoT endpoint, and logger
func NewIoTClient(ctx context.Context, awsConfig aws.Config, iotEndpoint string, logger *zap.Logger) (IoTClient, error) {

	// Create an AWS IoT client (control plane)
	client := iot.NewFromConfig(awsConfig)

	// Ensure the IoT endpoint has the https:// prefix
	if !strings.HasPrefix(iotEndpoint, "https://") && !strings.HasPrefix(iotEndpoint, "http://") {
		iotEndpoint = "https://" + iotEndpoint
	}

	// Create an AWS IoT Data Plane client (for MQTT publish)
	dataClient := iotdataplane.NewFromConfig(awsConfig, func(o *iotdataplane.Options) {
		o.BaseEndpoint = &iotEndpoint
	})

	return IoTClient{
		Client:     client,
		DataClient: dataClient,
	}, nil
}

// CreateCertificateFromCSR creates a certificate in AWS IoT from a given CSR (Certificate Signing Request).
func (c IoTClient) CreateCertificateFromCSR(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error) {
	if csrPem == nil || *csrPem == "" {
		return nil, nil, nil, fmt.Errorf(errorutil.ErrMsgCSRPemEmpty)
	}
	input := &iot.CreateCertificateFromCsrInput{
		CertificateSigningRequest: csrPem,
		SetAsActive:               true,
	}

	result, err := c.Client.CreateCertificateFromCsr(ctx, input)
	if err != nil {
		var invalidReq *types.InvalidRequestException
		if errors.As(err, &invalidReq) {
			logger.Error("CSR violates IoT constraints", zap.Error(err))
			return nil, nil, nil, fmt.Errorf(errorutil.ErrMsgInvalidCSR)
		}
		logger.Error("failed to create certificate from CSR", zap.Error(err))
		return nil, nil, nil, fmt.Errorf("failed to create certificate from CSR: %w", err)
	}

	return result.CertificatePem, result.CertificateId, result.CertificateArn, nil
}

// RegisterThing registers a new thing in AWS IoT with the given thing name.
func (c IoTClient) RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error {
	if thingName == "" {
		return fmt.Errorf(errorutil.ErrMsgThingNameEmpty)
	}
	input := &iot.CreateThingInput{
		ThingName: &thingName,
	}

	_, err := c.Client.CreateThing(ctx, input)
	if err != nil {
		logger.Error("failed to create thing", zap.String("thingName", thingName), zap.Error(err))
		return fmt.Errorf("failed to create thing %s: %w", thingName, err)
	}

	return nil
}

// DeleteThing deletes a thing from AWS IoT.
func (c IoTClient) DeleteThing(ctx context.Context, thingName string, logger *zap.Logger) error {
	if thingName == "" {
		return fmt.Errorf(errorutil.ErrMsgThingNameEmpty)
	}
	input := &iot.DeleteThingInput{
		ThingName: &thingName,
	}

	_, err := c.Client.DeleteThing(ctx, input)
	if err != nil {
		logger.Error("failed to delete thing", zap.String("thingName", thingName), zap.Error(err))
		return fmt.Errorf("failed to delete thing %s: %w", thingName, err)
	}

	return nil
}

// AttachCertificateToThing attaches a certificate to a thing in AWS IoT.
func (c IoTClient) AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	if thingName == "" {
		return fmt.Errorf(errorutil.ErrMsgThingNameEmpty)
	}
	if certificateArn == "" {
		return fmt.Errorf(errorutil.ErrMsgCertificateArnEmpty)
	}
	input := &iot.AttachThingPrincipalInput{
		Principal: &certificateArn,
		ThingName: &thingName,
	}

	_, err := c.Client.AttachThingPrincipal(ctx, input)
	if err != nil {
		logger.Error("failed to attach certificate to thing", zap.String("thingName", thingName), zap.String("certificateArn", certificateArn), zap.Error(err))
		return fmt.Errorf("failed to attach certificate to thing %s (cert: %s): %w", thingName, certificateArn, err)
	}

	return nil
}

// AttachPolicyToCertificate attaches a policy to a certificate in AWS IoT.
func (c IoTClient) AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	if policyName == "" {
		return fmt.Errorf(errorutil.ErrMsgPolicyNameEmpty)
	}
	if certificateArn == "" {
		return fmt.Errorf(errorutil.ErrMsgCertificateArnEmpty)
	}
	input := &iot.AttachPolicyInput{
		PolicyName: &policyName,
		Target:     &certificateArn,
	}

	_, err := c.Client.AttachPolicy(ctx, input)
	if err != nil {
		logger.Error("failed to attach policy to certificate", zap.String("policyName", policyName), zap.String("certificateArn", certificateArn), zap.Error(err))
		return fmt.Errorf("failed to attach policy %s to certificate %s: %w", policyName, certificateArn, err)
	}

	return nil
}

// DetachCertificateFromThing detaches a certificate from a thing in AWS IoT.
func (c IoTClient) DetachCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	if thingName == "" {
		return fmt.Errorf(errorutil.ErrMsgThingNameEmpty)
	}
	if certificateArn == "" {
		return fmt.Errorf(errorutil.ErrMsgCertificateArnEmpty)
	}
	input := &iot.DetachThingPrincipalInput{
		Principal: &certificateArn,
		ThingName: &thingName,
	}

	_, err := c.Client.DetachThingPrincipal(ctx, input)
	if err != nil {
		logger.Error("failed to detach certificate from thing", zap.String("thingName", thingName), zap.String("certificateArn", certificateArn), zap.Error(err))
		return fmt.Errorf("failed to detach certificate from thing %s (cert: %s): %w", thingName, certificateArn, err)
	}

	return nil
}

// SetCertificateInactive sets a certificate to inactive in AWS IoT.
func (c IoTClient) SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error {
	if certificateId == "" {
		return fmt.Errorf(errorutil.ErrMsgCertificateIDEmpty)
	}
	input := &iot.UpdateCertificateInput{
		CertificateId: &certificateId,
		NewStatus:     types.CertificateStatusInactive,
	}

	_, err := c.Client.UpdateCertificate(ctx, input)
	if err != nil {
		logger.Error("failed to set certificate inactive", zap.String("certificateId", certificateId), zap.Error(err))
		return fmt.Errorf("failed to set certificate inactive %s: %w", certificateId, err)
	}

	return nil
}

// DetachPolicyFromCertificate detaches a policy from a certificate in AWS IoT.
func (c IoTClient) DetachPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	if policyName == "" {
		return fmt.Errorf(errorutil.ErrMsgPolicyNameEmpty)
	}
	if certificateArn == "" {
		return fmt.Errorf(errorutil.ErrMsgCertificateArnEmpty)
	}
	input := &iot.DetachPolicyInput{
		PolicyName: &policyName,
		Target:     &certificateArn,
	}

	_, err := c.Client.DetachPolicy(ctx, input)
	if err != nil {
		logger.Error("failed to detach policy from certificate", zap.String("policyName", policyName), zap.String("certificateArn", certificateArn), zap.Error(err))
		return fmt.Errorf("failed to detach policy %s from certificate %s: %w", policyName, certificateArn, err)
	}

	return nil
}

// Publish publishes a message to a specified topic in AWS IoT.
func (c IoTClient) Publish(ctx context.Context, topic string, payload []byte, logger *zap.Logger) error {
	if topic == "" {
		return fmt.Errorf(errorutil.ErrMsgTopicEmpty)
	}
	input := &iotdataplane.PublishInput{
		Topic:   &topic,
		Qos:     0,
		Payload: payload,
	}

	_, err := c.DataClient.Publish(ctx, input)
	if err != nil {
		logger.Error("failed to publish message to topic", zap.String("topic", topic), zap.Error(err))
		return fmt.Errorf("failed to publish message to topic %s: %w", topic, err)
	}

	return nil
}
