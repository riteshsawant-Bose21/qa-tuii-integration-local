package auth

import (
	context "context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"sync"
	"time"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

type AuthValidator interface {
	ValidateToken(tokenString string) (*jwt.MapClaims, error)
	ExtractUserEmail(claims *jwt.MapClaims) (string, error)
}

type JWKS struct {
	Keys []JWK `json:"keys"`
}

type JWK struct {
	Kty string   `json:"kty"`
	Kid string   `json:"kid"`
	Use string   `json:"use"`
	N   string   `json:"n"`
	E   string   `json:"e"`
	X5c []string `json:"x5c"`
}

type Auth0Validator struct {
	domain    string
	jwksCache map[string]*rsa.PublicKey
	cacheMu   sync.RWMutex
	cacheTime time.Time
	cacheExp  time.Duration
	fetchMu   sync.Mutex
}

func NewAuth0Validator(domain string) *Auth0Validator {
	return &Auth0Validator{
		domain:    domain,
		jwksCache: make(map[string]*rsa.PublicKey),
		cacheExp:  time.Hour,
	}
}

func (a *Auth0Validator) ValidateToken(tokenString string) (*jwt.MapClaims, error) {
	fmt.Printf("[Lambda-Authorizer] Validating token: %s\n", tokenString)
	tokenString = strings.TrimPrefix(tokenString, "Bearer ")
	tokenString = strings.TrimPrefix(tokenString, "bearer ")
	token, _, err := new(jwt.Parser).ParseUnverified(tokenString, jwt.MapClaims{})
	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}
	kid, ok := token.Header["kid"].(string)
	if !ok {
		return nil, fmt.Errorf("token missing kid header")
	}
	publicKey, err := a.getPublicKey(kid)
	if err != nil {
		return nil, fmt.Errorf("failed to get public key: %w", err)
	}
	parsedToken, err := jwt.ParseWithClaims(tokenString, &jwt.MapClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return publicKey, nil
	}) 
	if err != nil {
		return nil, fmt.Errorf("failed to validate token: %w", err)
	}
	if !parsedToken.Valid {
		return nil, fmt.Errorf("token is not valid")
	}
	claims, ok := parsedToken.Claims.(*jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("failed to get token claims")
	}
	if err := a.validateIssuer(*claims); err != nil {
		return nil, err
	}
	return claims, nil
}

func (a *Auth0Validator) getPublicKey(kid string) (*rsa.PublicKey, error) {
	a.cacheMu.RLock()
	if key, exists := a.jwksCache[kid]; exists && time.Since(a.cacheTime) < a.cacheExp {
		a.cacheMu.RUnlock()
		return key, nil
	}
	a.cacheMu.RUnlock()
	a.fetchMu.Lock()
	defer a.fetchMu.Unlock()
	a.cacheMu.RLock()
	if key, exists := a.jwksCache[kid]; exists && time.Since(a.cacheTime) < a.cacheExp {
		a.cacheMu.RUnlock()
		return key, nil
	}
	a.cacheMu.RUnlock()
	jwks, err := a.fetchJWKS()
	if err != nil {
		return nil, err
	}
	var targetKey *rsa.PublicKey
	a.cacheMu.Lock()
	for _, key := range jwks.Keys {
		if key.Kid != "" {
			publicKey, err := a.jwkToRSAPublicKey(key)
			if err != nil {
				continue
			}
			a.jwksCache[key.Kid] = publicKey
			if key.Kid == kid {
				targetKey = publicKey
			}
		}
	}
	a.cacheTime = time.Now()
	a.cacheMu.Unlock()
	if targetKey != nil {
		return targetKey, nil
	}
	return nil, fmt.Errorf("key with kid %s not found", kid)
}

func (a *Auth0Validator) fetchJWKS() (*JWKS, error) {
	url := fmt.Sprintf("https://%s/.well-known/jwks.json", a.domain)
	fmt.Printf("[Lambda-Authorizer] Fetching JWKS from: %s\n", url)
	
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
		fmt.Printf("[Lambda-Authorizer] JWKS fetch failed: status %d from %s\n", resp.StatusCode, url)
		return nil, fmt.Errorf("failed to fetch JWKS: status %d", resp.StatusCode)
	}
	
	var jwks JWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("failed to decode JWKS: %w", err)
	}
	
	fmt.Printf("[Lambda-Authorizer] Successfully fetched JWKS with %d keys\n", len(jwks.Keys))
	return &jwks, nil
}

func (a *Auth0Validator) jwkToRSAPublicKey(jwk JWK) (*rsa.PublicKey, error) {
	nBytes, err := base64.RawURLEncoding.DecodeString(jwk.N)
	if err != nil {
		return nil, fmt.Errorf("failed to decode modulus: %w", err)
	}
	eBytes, err := base64.RawURLEncoding.DecodeString(jwk.E)
	if err != nil {
		return nil, fmt.Errorf("failed to decode exponent: %w", err)
	}
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

func (a *Auth0Validator) validateIssuer(claims jwt.MapClaims) error {
	iss, ok := claims["iss"].(string)
	if !ok {
		return fmt.Errorf("token missing issuer claim")
	}
	expectedIssuer := fmt.Sprintf("https://%s/", a.domain)
	if iss != expectedIssuer {
		return fmt.Errorf("invalid issuer: expected %s, got %s", expectedIssuer, iss)
	}
	return nil
}

func (a *Auth0Validator) ExtractUserEmail(claims *jwt.MapClaims) (string, error) {
	if email, ok := (*claims)["email"].(string); ok {
		return email, nil
	}
	return "", fmt.Errorf("email not found in token claims")
}