package authorizer

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"strings"

	"github.com/BoseProfessional/lambda-authorizer/internal/auth"
	"github.com/BoseProfessional/lambda-authorizer/internal/config"
	"github.com/BoseProfessional/lambda-authorizer/internal/permissions"

	"github.com/aws/aws-lambda-go/events"
)

var (
	validator         auth.AuthValidator
	permissionChecker permissions.PermissionChecker
	initErr           error
)

func init() {
	fmt.Println("[Lambda-Authorizer] Initializing Lambda authorizer...")

	cfg := config.Config{
		Auth0Domain:  os.Getenv("AUTH0_DOMAIN"),
		DatabaseHost: os.Getenv("DB_HOST"),
		DatabasePort: os.Getenv("DB_PORT"),
		DatabaseUser: os.Getenv("DB_USER"),
		DatabasePass: os.Getenv("DB_PASS"),
		DatabaseName: os.Getenv("DB_NAME"),
		DatabaseSSL:  os.Getenv("DB_SSLMODE"),
	}

	fmt.Printf("[Lambda-Authorizer] Config loaded - Auth0Domain: %s, DB Host: %s:%s\n",
		cfg.Auth0Domain, cfg.DatabaseHost, cfg.DatabasePort)

	fmt.Println("[Lambda-Authorizer] Initializing Auth0 validator...")
	validator = auth.NewAuth0Validator(cfg.Auth0Domain)

	fmt.Printf("[Lambda-Authorizer] Connecting to database - user=%s host=%s port=%s dbname=%s sslmode=%s\n",
		cfg.DatabaseUser, cfg.DatabaseHost, cfg.DatabasePort, cfg.DatabaseName, cfg.DatabaseSSL)

	// Build DSN with proper formatting
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.DatabaseHost,
		cfg.DatabasePort,
		cfg.DatabaseUser,
		cfg.DatabasePass,
		cfg.DatabaseName,
		cfg.DatabaseSSL,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		fmt.Printf("[Lambda-Authorizer] ERROR: Failed to open database connection: %v\n", err)
		initErr = err
		return
	}

	fmt.Println("[Lambda-Authorizer] Testing database connection with Ping...")
	if err := db.Ping(); err != nil {
		fmt.Printf("[Lambda-Authorizer] ERROR: Failed to ping database: %v\n", err)
		initErr = err
		return
	}

	fmt.Println("[Lambda-Authorizer] Database connection successful!")
	permissionChecker = permissions.NewSQLPermissionChecker(db)
	fmt.Println("[Lambda-Authorizer] Initialization complete!")
}

// GeneratePolicy creates an IAM policy document for API Gateway
func GeneratePolicy(principalID, effect, resource string) events.APIGatewayCustomAuthorizerResponse {
	return events.APIGatewayCustomAuthorizerResponse{
		PrincipalID: principalID,
		PolicyDocument: events.APIGatewayCustomAuthorizerPolicy{
			Version: "2012-10-17",
			Statement: []events.IAMPolicyStatement{
				{
					Action:   []string{"execute-api:Invoke"},
					Effect:   effect,
					Resource: []string{resource},
				},
			},
		},
	}
}

// Handle is the Lambda entry point for the custom authorizer
func Handle(ctx context.Context, event events.APIGatewayCustomAuthorizerRequest) (events.APIGatewayCustomAuthorizerResponse, error) {
	fmt.Printf("[Lambda-Authorizer] Received event: %s\n", event)

	if initErr != nil {
		fmt.Printf("[Lambda-Authorizer] Init error: %v - Denying request\n", initErr)
		return GeneratePolicy("anonymous", "Deny", event.MethodArn), nil
	}


	       token := event.AuthorizationToken
	       // Support both TOKEN and REQUEST authorizer event shapes
	    //    if token == "" && event.Headers != nil {
		//        // Try to extract from headers (REQUEST authorizer)
		//        authHeader := event.Headers["authorization"]
		//        if authHeader == "" {
		// 	       authHeader = event.Headers["Authorization"]
		//        }
		//        if strings.HasPrefix(authHeader, "Bearer ") {
		// 	       token = strings.TrimPrefix(authHeader, "Bearer ")
		//        } else {
		// 	       token = authHeader
		//        }
		//        token = strings.TrimSpace(token)
	    //    }
	       fmt.Printf("[Lambda-Authorizer] Token received: %v\n", token != "" && len(token) > 10)

	       if strings.TrimSpace(token) == "" {
		       fmt.Println("[Lambda-Authorizer] Empty token - Denying request")
		       return GeneratePolicy("anonymous", "Deny", event.MethodArn), nil
	       }

	       claims, err := validator.ValidateToken(token)
	       if err != nil {
		       fmt.Printf("[Lambda-Authorizer] Token validation failed: %v - Denying request\n", err)
		       return GeneratePolicy("anonymous", "Deny", event.MethodArn), nil
	       }

	email, err := validator.ExtractUserEmail(claims)
	if err != nil {
		fmt.Printf("[Lambda-Authorizer] Failed to extract email: %v - Denying request\n", err)
		return GeneratePolicy("anonymous", "Deny", event.MethodArn), nil
	}

	fmt.Printf("[Lambda-Authorizer] User email extracted: %s\n", email)

	// Parse method ARN to extract HTTP method and resource path
	parsedARN, err := ParseMethodARN(event.MethodArn)
	if err != nil {
		fmt.Printf("[Lambda-Authorizer] Failed to parse method ARN: %v - Denying request\n", err)
		return GeneratePolicy(email, "Deny", event.MethodArn), nil
	}

	fmt.Printf("[Lambda-Authorizer] Parsed ARN - Method: %s, Resource: %s\n", parsedARN.HTTPMethod, parsedARN.Resource)

	// Check if user has the required permission for this specific endpoint
	hasPermission, userCtx, err := permissionChecker.CheckEndpointPermissionWithContext(ctx, email, parsedARN.HTTPMethod, parsedARN.Resource)
	if err != nil {
		fmt.Printf("[Lambda-Authorizer] Failed to check endpoint permission: %v - Denying request\n", err)
		return GeneratePolicy(email, "Deny", event.MethodArn), nil
	}

	if !hasPermission {
		fmt.Printf("[Lambda-Authorizer] User %s does not have permission for %s %s - Denying request\n",
			email, parsedARN.HTTPMethod, parsedARN.Resource)
		return GeneratePolicy(email, "Deny", event.MethodArn), nil
	}

	// Add user context to response for API Gateway to inject as headers
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

	fmt.Printf("[Lambda-Authorizer] User %s has permission for %s %s - Allowing request\n",
		email, parsedARN.HTTPMethod, parsedARN.Resource)
	return events.APIGatewayCustomAuthorizerResponse{
		PrincipalID: email,
		PolicyDocument: events.APIGatewayCustomAuthorizerPolicy{
			Version: "2012-10-17",
			Statement: []events.IAMPolicyStatement{{
				Action:   []string{"execute-api:Invoke"},
				Effect:   "Allow",
				Resource: []string{event.MethodArn},
			}},
		},
		Context: contextMap,
	}, nil
}