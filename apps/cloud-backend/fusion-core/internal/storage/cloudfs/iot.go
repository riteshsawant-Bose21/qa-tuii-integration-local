package cloudfs

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iot"
	"go.uber.org/zap"
)

type IoT interface {
	// Methods for IoT operations can be defined here
	CreateCertificateFromCsr(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error)
	RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error
	AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error
	AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error
}

type IoTClient struct {
	Client *iot.Client
}

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
