package middleware

import (
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const RequestIDKey = "requestID"

// RequestLoggerMiddleware logs HTTP requests to the audit log
func RequestLoggerMiddleware(auditLogger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Generate a unique request ID
		requestID := uuid.New().String()

		// Create an audit logger with the request ID field
		requestAuditLogger := auditLogger.With(zap.String("requestID", requestID))

		// Store the audit logger in context for audit-related logging
		c.Set("auditLogger", requestAuditLogger)

		startTime := time.Now()

		c.Next()

		var user *types.UserAuthorizationResponse

		userAuth, authExists := c.Get("user_auth")
		if authExists {
			user = userAuth.(*types.UserAuthorizationResponse)
		}

		// Store request ID in context
		c.Set(RequestIDKey, requestID)

		duration := time.Since(startTime)
		clientIP := c.ClientIP()
		method := c.Request.Method
		path := c.Request.URL.Path
		statusCode := c.Writer.Status()

		// Build audit log fields for request/response tracking
		logFields := []zap.Field{
			zap.String("type", "http_request"),
			zap.String("method", method),
			zap.String("path", path),
			zap.String("clientIP", clientIP),
			zap.String("userAgent", c.Request.UserAgent()),
			zap.Int("statusCode", statusCode),
			zap.Duration("duration", duration),
		}

		// Add user fields only if user is authenticated
		if authExists {
			logFields = append(logFields,
				zap.String("userEmail", user.User.Email),
				zap.String("userID", user.User.ID),
				zap.String("accountID", user.Account.ID),
			)
		}

		requestAuditLogger.Info("HTTP request completed", logFields...)
	}
}

// ApplicationLoggerMiddleware makes the application logger available in gin context
func ApplicationLoggerMiddleware(appLogger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get request ID from context (set by RequestLoggerMiddleware)
		requestID, exists := c.Get(RequestIDKey)
		if !exists {
			requestID = uuid.New().String()
		}

		// Create application logger with request ID for correlation
		requestAppLogger := appLogger.With(zap.String("requestID", requestID.(string)))

		// Store the application logger in context for general application logging
		c.Set("logger", requestAppLogger)
		c.Set("appLogger", requestAppLogger)

		c.Next()
	}
}
