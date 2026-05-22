package jwtutil

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims is the payload embedded in every ShakeMeal JWT.
type Claims struct {
	UserID    string `json:"user_id"`
	TokenType string `json:"token_type"` // "access" | "refresh"
	jwt.RegisteredClaims
}

const (
	accessExpiry  = 24 * time.Hour
	refreshExpiry = 30 * 24 * time.Hour
)

// GenerateAccess returns a short-lived access token for the given user.
func GenerateAccess(userID, secret string) (string, error) {
	return generate(userID, "access", accessExpiry, secret)
}

// GenerateRefresh returns a long-lived refresh token for the given user.
func GenerateRefresh(userID, secret string) (string, error) {
	return generate(userID, "refresh", refreshExpiry, secret)
}

func generate(userID, tokenType string, expiry time.Duration, secret string) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID:    userID,
		TokenType: tokenType,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(expiry)),
			Issuer:    "shakemeal",
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// Verify parses and validates a token, returning its claims.
func Verify(tokenStr, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	}, jwt.WithExpirationRequired())

	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}
	return claims, nil
}
