package middleware

import (
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const RequestIDKey = "requestID"

func RequestLoggerMiddleware(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Generate a unique request ID
		requestID := uuid.New().String()

		var user *types.UserAuthorizationResponse

		userAuth, authExists := c.Get("user_auth")
		if authExists {
			user = userAuth.(*types.UserAuthorizationResponse)
		}

		// Store request ID in context
		c.Set(RequestIDKey, requestID)

		// Create a logger with the request ID field
		requestLogger := logger.With(zap.String("requestID", requestID))

		// Store the logger in context for use in handlers
		c.Set("logger", requestLogger)

		startTime := time.Now()

		c.Next()

		duration := time.Since(startTime)
		clientIP := c.ClientIP()
		method := c.Request.Method
		path := c.Request.URL.Path
		statusCode := c.Writer.Status()

		// Build log fields
		logFields := []zap.Field{
			zap.String("method", method),
			zap.String("path", path),
			zap.String("clientIP", clientIP),
			zap.String("userAgent", c.Request.UserAgent()),
			zap.Int("statusCode", statusCode),
			zap.Duration("duration", duration),
		}

		// Add user fields only if user is not nil
		if authExists {
			logFields = append(logFields,
				zap.String("userEmail", user.User.Email),
				zap.String("userID", user.User.ID),
				zap.String("accountID", user.Account.ID),
			)
		}

		requestLogger.Info("Request completed", logFields...)
	}
}
