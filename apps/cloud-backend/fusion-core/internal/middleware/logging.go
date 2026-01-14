package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func RequestLoggerMiddleware(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()

		c.Next()

		duration := time.Since(startTime)
		clientIP := c.ClientIP()
		method := c.Request.Method
		path := c.Request.URL.Path
		statusCode := c.Writer.Status()

		logger.Info("Request",
			zap.String("method", method),
			zap.String("path", path),
			zap.String("clientIP", clientIP),
			zap.Int("statusCode", statusCode),
			zap.Duration("duration", duration),
		)
	}
}
