package authorizer

import (
	"context"
	"strings"
	"fmt"
)

// HandleRequestAuthorizer supports API Gateway REQUEST authorizer events
func HandleRequestAuthorizer(ctx context.Context, event map[string]interface{}) (map[string]interface{}, error) {
	// Extract token from headers (case-insensitive)
	headers, _ := event["headers"].(map[string]interface{})
	token := ""
	for k, v := range headers {
		if strings.ToLower(k) == "authorization" {
			token, _ = v.(string)
			break
		}
	}
	if strings.TrimSpace(token) == "" {
		return denyResponse("anonymous", "No token provided"), nil
	}

	claims, err := validator.ValidateToken(token)
	fmt.Printf("[Lambda-Authorizer] Recived claims: %v\n", claims)
	if err != nil {
		fmt.Printf("[Lambda-Authorizer] Token validation failed: %v - Denying request\n", err)
		return denyResponse("anonymous", "Invalid token"), nil
	}

	email, err := validator.ExtractUserEmail(claims)
	fmt.Printf("[Lambda-Authorizer] Extracted email: %s\n", email)
	if err != nil {
		return denyResponse("anonymous", "No email in token"), nil
	}

	// Extract HTTP method and path from event
	method := ""
	if rc, ok := event["requestContext"].(map[string]interface{}); ok {
		if http, ok := rc["http"].(map[string]interface{}); ok {
			method, _ = http["method"].(string)
		}
	}
	path, _ := event["rawPath"].(string)
	if method == "" || path == "" {
		return denyResponse(email, "Missing method or path"), nil
	}
	fmt.Printf("[Lambda-Authorizer] Checking permissions for %s %s\n", method, path)

	hasPermission, userCtx, err := permissionChecker.CheckEndpointPermissionWithContext(ctx, email, method, path)
	fmt.Printf("[Lambda-Authorizer] Permission check result: %v, userCtx: %v, error: %v\n", hasPermission, userCtx, err)

	if err != nil || !hasPermission {
		return denyResponse(email, "Permission denied"), nil
	}

	contextMap := map[string]interface{}{
		"userId":          userCtx.UserID,
		"userEmail":       userCtx.Email,
		"userRole":        userCtx.Role,
		"accountId":       userCtx.AccountID,
		"accountName":     userCtx.AccountName,
		"accountType":     userCtx.AccountType,
		"roleId":          userCtx.RoleID,
		// "userPermissions": userCtx.Permissions, // e.g. comma-separated or JSON
	}

	return map[string]interface{}{
		"principalId": email,
		"policyDocument": map[string]interface{}{
			"Version": "2012-10-17",
			"Statement": []map[string]interface{}{
				{
					"Action":   "execute-api:Invoke",
					"Effect":   "Allow",
					"Resource": "*",
				},
			},
		},
		"context": contextMap,
	}, nil
}

func denyResponse(principal, msg string) map[string]interface{} {
	return map[string]interface{}{
		"principalId": principal,
		"policyDocument": map[string]interface{}{
			"Version": "2012-10-17",
			"Statement": []map[string]interface{}{
				{
					"Action":   "execute-api:Invoke",
					"Effect":   "Deny",
					"Resource": "*",
				},
			},
		},
		"context": map[string]interface{}{"error": msg},
	}
}
