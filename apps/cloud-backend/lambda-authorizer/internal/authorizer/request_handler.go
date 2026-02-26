package authorizer

import (
	"context"
	"strings"
	"time"

	"github.com/BoseProfessional/lambda-authorizer/internal/logger"
)

// HandleRequestAuthorizer supports API Gateway REQUEST authorizer events
func HandleRequestAuthorizer(ctx context.Context, event map[string]interface{}) (map[string]interface{}, error) {
	startTime := time.Now()
	
	// Extract request ID from context for structured logging
	requestID := extractRequestID(event)
	log := logger.NewLogger(requestID)

	log.Info("Processing authorization request")

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
		log.LogAuthAttempt("", "", "", false, "No token provided")
		return denyResponse("anonymous", "No token provided"), nil
	}

	claims, err := validator.ValidateToken(token)

	if err != nil {
		log.Error("Token validation failed", err)
		log.LogAuthAttempt("", "", "", false, "Invalid token")
		return denyResponse("anonymous", "Invalid token"), nil
	}

	email, err := validator.ExtractUserEmail(claims)

	if err != nil {
		log.Error("Failed to extract email from token", err)
		return denyResponse("anonymous", "No email in token"), nil
	}

	log.WithFields("Token validated successfully", logger.LogLevelInfo, map[string]interface{}{
		"email": email,
	})

	// Extract HTTP method and path from event
	method := ""
	if rc, ok := event["requestContext"].(map[string]interface{}); ok {
		if http, ok := rc["http"].(map[string]interface{}); ok {
			method, _ = http["method"].(string)
		}
	}

	path, _ := event["rawPath"].(string)
	if method == "" || path == "" {
		log.LogAuthAttempt(email, method, path, false, "Missing method or path")
		return denyResponse(email, "Missing method or path"), nil
	}

	// Check permissions with timing
	permCheckStart := time.Now()
	hasPermission, userCtx, err := permissionChecker.CheckEndpointPermissionWithContext(ctx, email, method, path)
	permCheckDuration := time.Since(permCheckStart).Milliseconds()

	if err != nil {
		log.Error("Permission check failed", err)
		log.LogAuthZDecision(email, method, path, false, "Permission check error", permCheckDuration)
		return denyResponse(email, "Permission denied"), nil
	}

	if !hasPermission {
		log.LogAuthZDecision(email, method, path, false, "Insufficient permissions", permCheckDuration)
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

	// Log successful authorization with full context
	totalDuration := time.Since(startTime).Milliseconds()
	log.LogUserContext(email, method, path, contextMap, totalDuration)

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

// extractRequestID extracts the request ID from the Lambda event
func extractRequestID(event map[string]interface{}) string {
	if rc, ok := event["requestContext"].(map[string]interface{}); ok {
		if reqID, ok := rc["requestId"].(string); ok {
			return reqID
		}
	}
	return "UNKNOWN"
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
