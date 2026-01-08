package auth

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Auth0Config holds the configuration for Auth0 JWT validation
type Auth0Config struct {
	Domain string
}

// JWKS represents the JSON Web Key Set
type JWKS struct {
	Keys []JWK `json:"keys"`
}

// JWK represents a JSON Web Key
type JWK struct {
	Kty string   `json:"kty"`
	Kid string   `json:"kid"`
	Use string   `json:"use"`
	N   string   `json:"n"`
	E   string   `json:"e"`
	X5c []string `json:"x5c"`
}

// Auth0Validator handles Auth0 JWT token validation
type Auth0Validator struct {
	config     Auth0Config
	jwksCache  map[string]*rsa.PublicKey
	cacheMu    sync.RWMutex
	cacheTime  time.Time
	cacheExp   time.Duration
	fetchMu    sync.Mutex // Prevents concurrent JWKS fetches
}

// NewAuth0Validator creates a new Auth0 validator
func NewAuth0Validator(config Auth0Config) *Auth0Validator {
	return &Auth0Validator{
		config:    config,
		jwksCache: make(map[string]*rsa.PublicKey),
		cacheExp:  time.Hour, // Cache JWKS for 1 hour
	}
}

// ValidateToken validates an Auth0 JWT token and returns the claims
func (a *Auth0Validator) ValidateToken(tokenString string) (*jwt.MapClaims, error) {
	// Check if token looks like a JWT (should have 3 parts separated by dots)
	tokenParts := strings.Split(tokenString, ".")

	if len(tokenParts) != 3 {
		if len(tokenParts) == 5 {
			return nil, fmt.Errorf("received JWE token (5 segments) but backend expects JWT token (3 segments). Please configure Auth0 to return JWT tokens instead of JWE tokens, or implement JWE decryption")
		}
		return nil, fmt.Errorf("token is not a valid JWT: expected 3 segments, got %d. This might be an opaque token or encrypted JWE token", len(tokenParts))
	}

	// Parse the token without verification first to get the kid
	token, _, err := new(jwt.Parser).ParseUnverified(tokenString, jwt.MapClaims{})
	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	// Get the key ID from token header
	kid, ok := token.Header["kid"].(string)
	if !ok {
		return nil, fmt.Errorf("token missing kid header")
	}

	// Get the public key for this kid
	publicKey, err := a.getPublicKey(kid)
	if err != nil {
		return nil, fmt.Errorf("failed to get public key: %w", err)
	}

	// Parse and validate the token with the public key
	parsedToken, err := jwt.ParseWithClaims(tokenString, &jwt.MapClaims{}, func(token *jwt.Token) (interface{}, error) {
		// Verify the signing method
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return publicKey, nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to validate token: %w", err)
	}

	// Verify token is valid
	if !parsedToken.Valid {
		return nil, fmt.Errorf("token is not valid")
	}

	// Get claims
	claims, ok := parsedToken.Claims.(*jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("failed to get token claims")
	}

	// Validate issuer
	if err := a.validateIssuer(*claims); err != nil {
		return nil, err
	}

	return claims, nil
}

// getPublicKey retrieves the public key from Auth0's JWKS endpoint
func (a *Auth0Validator) getPublicKey(kid string) (*rsa.PublicKey, error) {
	a.cacheMu.RLock()
	// Check if we have a cached key and cache is still valid
	if key, exists := a.jwksCache[kid]; exists && time.Since(a.cacheTime) < a.cacheExp {
		a.cacheMu.RUnlock()
		return key, nil
	}
	a.cacheMu.RUnlock()

	// Use a separate mutex to prevent concurrent JWKS fetches
	a.fetchMu.Lock()
	defer a.fetchMu.Unlock()

	// Double-check: another goroutine might have updated the cache while we were waiting
	a.cacheMu.RLock()
	if key, exists := a.jwksCache[kid]; exists && time.Since(a.cacheTime) < a.cacheExp {
		a.cacheMu.RUnlock()
		return key, nil
	}
	a.cacheMu.RUnlock()

	// Fetch JWKS from Auth0
	jwks, err := a.fetchJWKS()
	if err != nil {
		return nil, err
	}

	// Find the key with matching kid and cache all keys
	var targetKey *rsa.PublicKey
	a.cacheMu.Lock()
	for _, key := range jwks.Keys {
		if key.Kid != "" { // Cache all valid keys
			publicKey, err := a.jwkToRSAPublicKey(key)
			if err != nil {
				continue // Skip invalid keys, don't fail the whole operation
			}
			a.jwksCache[key.Kid] = publicKey
			if key.Kid == kid {
				targetKey = publicKey
			}

			// Cache the key
			a.jwksCache[kid] = publicKey
			a.cacheTime = time.Now()

			return publicKey, nil
		}
	}
	a.cacheTime = time.Now() // Update cache time after successful fetch
	a.cacheMu.Unlock()

	if targetKey != nil {
		return targetKey, nil
	}

	return nil, fmt.Errorf("key with kid %s not found", kid)
}

// fetchJWKS fetches the JWKS from Auth0
func (a *Auth0Validator) fetchJWKS() (*JWKS, error) {
	url := fmt.Sprintf("https://%s/.well-known/jwks.json", a.config.Domain)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch JWKS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch JWKS: status %d", resp.StatusCode)
	}

	var jwks JWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("failed to decode JWKS: %w", err)
	}

	return &jwks, nil
}

// jwkToRSAPublicKey converts a JWK to an RSA public key
func (a *Auth0Validator) jwkToRSAPublicKey(jwk JWK) (*rsa.PublicKey, error) {
	// Decode the modulus
	nBytes, err := base64.RawURLEncoding.DecodeString(jwk.N)
	if err != nil {
		return nil, fmt.Errorf("failed to decode modulus: %w", err)
	}

	// Decode the exponent
	eBytes, err := base64.RawURLEncoding.DecodeString(jwk.E)
	if err != nil {
		return nil, fmt.Errorf("failed to decode exponent: %w", err)
	}

	// Convert bytes to big integers
	n := new(big.Int).SetBytes(nBytes)
	e := 0
	for _, b := range eBytes {
		e = e*256 + int(b)
	}

	return &rsa.PublicKey{
		N: n,
		E: e,
	}, nil
}

// validateIssuer validates the issuer claim
func (a *Auth0Validator) validateIssuer(claims jwt.MapClaims) error {
	iss, ok := claims["iss"].(string)
	if !ok {
		return fmt.Errorf("token missing issuer claim")
	}

	expectedIssuer := fmt.Sprintf("https://%s/", a.config.Domain)
	if iss != expectedIssuer {
		return fmt.Errorf("invalid issuer: expected %s, got %s", expectedIssuer, iss)
	}

	return nil
}

// ExtractUserID extracts the user ID from JWT claims
func ExtractUserID(claims *jwt.MapClaims) (string, error) {
	// Try 'sub' claim first (standard JWT claim)
	if sub, ok := (*claims)["sub"].(string); ok {
		return sub, nil
	}

	// Try 'user_id' claim (Auth0 specific)
	if userID, ok := (*claims)["user_id"].(string); ok {
		return userID, nil
	}

	return "", fmt.Errorf("user ID not found in token claims")
}

// ExtractUserEmail extracts the user email from JWT claims
func ExtractUserEmail(claims *jwt.MapClaims) (string, error) {
	if email, ok := (*claims)["email"].(string); ok {
		return email, nil
	}

	return "", fmt.Errorf("email not found in token claims")
}

// ExtractTokenFromHeader extracts the Bearer token from Authorization header
func ExtractTokenFromHeader(authHeader string) (string, error) {
	if authHeader == "" {
		return "", fmt.Errorf("authorization header is empty")
	}

	// Check if it starts with "Bearer "
	const bearerPrefix = "Bearer "
	if !strings.HasPrefix(authHeader, bearerPrefix) {
		return "", fmt.Errorf("authorization header must start with 'Bearer '")
	}

	// Extract the token part
	token := strings.TrimPrefix(authHeader, bearerPrefix)
	if token == "" {
		return "", fmt.Errorf("token is empty")
	}

	return token, nil
}
