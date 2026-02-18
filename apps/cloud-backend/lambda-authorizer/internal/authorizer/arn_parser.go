package authorizer

import (
	"fmt"
	"strings"
)

// ParsedARN represents a parsed API Gateway method ARN
type ParsedARN struct {
	Region     string
	AccountID  string
	APIID      string
	Stage      string
	HTTPMethod string
	Resource   string
}

// ParseMethodARN parses an API Gateway method ARN
// Format: arn:aws:execute-api:region:account-id:api-id/stage/method/resource-path
func ParseMethodARN(methodArn string) (*ParsedARN, error) {
	parts := strings.Split(methodArn, ":")
	if len(parts) < 6 {
		return nil, fmt.Errorf("invalid method ARN format: %s", methodArn)
	}

	// Parts: [arn, aws, execute-api, region, account-id, api-id/stage/method/resource-path]
	region := parts[3]
	accountID := parts[4]

	// Parse api-id/stage/method/resource-path
	apiPath := parts[5]
	pathParts := strings.SplitN(apiPath, "/", 4)

	if len(pathParts) < 3 {
		return nil, fmt.Errorf("invalid API path in ARN: %s", apiPath)
	}

	apiID := pathParts[0]
	stage := pathParts[1]
	httpMethod := pathParts[2]

	// Resource path might be empty or contain multiple segments
	resource := ""
	if len(pathParts) == 4 {
		resource = "/" + pathParts[3]
	} else {
		resource = "/"
	}

	return &ParsedARN{
		Region:     region,
		AccountID:  accountID,
		APIID:      apiID,
		Stage:      stage,
		HTTPMethod: httpMethod,
		Resource:   resource,
	}, nil
}

// GetPermissionKey returns the key for permission lookup (e.g., "GET:/api/v1/projects")
func (p *ParsedARN) GetPermissionKey() string {
	return fmt.Sprintf("%s:%s", strings.ToUpper(p.HTTPMethod), p.Resource)
}