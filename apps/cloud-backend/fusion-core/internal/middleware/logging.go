package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const RequestIDKey = "requestID"

func RequestLoggerMiddleware(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Generate a unique request ID
		requestID := uuid.New().String()

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

		requestLogger.Info("Request completed",
			zap.String("method", method),
			zap.String("path", path),
			zap.String("clientIP", clientIP),
			zap.Int("statusCode", statusCode),
			zap.Duration("duration", duration),
		)
	}
}
