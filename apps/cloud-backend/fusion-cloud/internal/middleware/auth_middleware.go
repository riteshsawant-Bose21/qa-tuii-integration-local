package middleware

import (
	"context"
	"net/http"
	"strings"

	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/utils"
	"fusion-cloud/internal/utils/jwtutil"
)

type contextKey string

const userCtxKey = contextKey("user")

func JWTAuthMiddleware(jwtManager *jwtutil.JWTManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
				utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgMissingOrInvalidAuthHeader, nil)
				return
			}

			token := strings.TrimPrefix(authHeader, "Bearer ")
			claims, err := jwtManager.VerifyAccessToken(token)
			if err != nil {
				utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgInvalidOrExpiredToken, nil)
				return
			}

			// Add user ID/email to request context
			ctx := context.WithValue(r.Context(), userCtxKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// Retrieve user claims from context
func GetUserFromContext(ctx context.Context) (*jwtutil.UserClaims, bool) {
	user, ok := ctx.Value(userCtxKey).(*jwtutil.UserClaims)
	return user, ok
}
