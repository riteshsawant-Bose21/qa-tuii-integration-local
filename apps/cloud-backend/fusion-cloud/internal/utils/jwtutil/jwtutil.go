package jwtutil

import (
	"fusion-cloud/internal/utils"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type JWTManager struct {
	accessSecret    string
	refreshSecret   string
	accessTokenTTL  time.Duration
	refreshTokenTTL time.Duration
}

type UserClaims struct {
	UserID int64  `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// NewJWTManager creates a new JWTManager
func NewJWTManager(accessSecret, refreshSecret string, accessTTL, refreshTTL time.Duration) *JWTManager {
	return &JWTManager{
		accessSecret:    accessSecret,
		refreshSecret:   refreshSecret,
		accessTokenTTL:  accessTTL,
		refreshTokenTTL: refreshTTL,
	}
}

// GenerateAccessToken creates a signed access token
func (j *JWTManager) GenerateAccessToken(userId int64, email string) (string, error) {
	claims := &UserClaims{
		UserID: userId,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(j.accessTokenTTL)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(j.accessSecret))
}

// GenerateRefreshToken creates a signed refresh token
func (j *JWTManager) GenerateRefreshToken(userId int64, email string) (string, error) {
	claims := &UserClaims{
		UserID: userId,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(j.refreshTokenTTL)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(j.refreshSecret))
}

// VerifyAccessToken parses and validates the access token
func (j *JWTManager) VerifyAccessToken(tokenStr string) (*UserClaims, error) {
	return j.verifyToken(tokenStr, j.accessSecret)
}

// VerifyRefreshToken parses and validates the refresh token
func (j *JWTManager) VerifyRefreshToken(tokenStr string) (*UserClaims, error) {
	return j.verifyToken(tokenStr, j.refreshSecret)
}

// Internal method for verifying a token
func (j *JWTManager) verifyToken(tokenStr, secret string) (*UserClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &UserClaims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*UserClaims)
	if !ok || !token.Valid {
		return nil, utils.ErrInvalidToken
	}

	return claims, nil
}
