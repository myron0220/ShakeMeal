package service

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/myron0220/shakemeal/internal/domain"
	"github.com/myron0220/shakemeal/internal/repository"
	"github.com/myron0220/shakemeal/internal/utils/apperrors"
	"github.com/myron0220/shakemeal/internal/utils/jwtutil"
)

// AuthService handles Sign in with Apple and JWT issuance.
type AuthService struct {
	users         *repository.UserRepo
	jwtSecret     string
	appleBundleID string
}

func NewAuthService(users *repository.UserRepo, jwtSecret, appleBundleID string) *AuthService {
	return &AuthService{
		users:         users,
		jwtSecret:     jwtSecret,
		appleBundleID: appleBundleID,
	}
}

// TokenPair holds an access token and a refresh token.
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"` // seconds until access token expires
}

// ── Public API ────────────────────────────────────────────────────────────────

// SignInWithApple verifies the Apple identity token, finds or creates the user,
// and returns the user record plus a fresh token pair.
func (s *AuthService) SignInWithApple(ctx context.Context, identityToken, fullName string) (*domain.User, *TokenPair, error) {
	appleUserID, email, err := s.verifyAppleToken(identityToken)
	if err != nil {
		return nil, nil, apperrors.BadRequest("invalid Apple identity token: " + err.Error())
	}

	user, err := s.users.FindByAppleID(ctx, appleUserID)
	if err != nil {
		return nil, nil, apperrors.Internal(err)
	}

	if user == nil {
		// First sign-in — create the account.
		user = &domain.User{AppleID: &appleUserID}
		if email != "" {
			user.Email = &email
		}
		if fullName != "" {
			user.Name = &fullName
		}
		if err := s.users.Create(ctx, user); err != nil {
			return nil, nil, apperrors.Internal(err)
		}
	}

	pair, err := s.mintTokenPair(user.ID)
	if err != nil {
		return nil, nil, apperrors.Internal(err)
	}
	return user, pair, nil
}

// RefreshTokens validates a refresh token and issues a new token pair.
func (s *AuthService) RefreshTokens(ctx context.Context, refreshToken string) (*TokenPair, error) {
	claims, err := jwtutil.Verify(refreshToken, s.jwtSecret)
	if err != nil {
		return nil, apperrors.Unauthorized()
	}
	if claims.TokenType != "refresh" {
		return nil, apperrors.Unauthorized()
	}
	pair, err := s.mintTokenPair(claims.UserID)
	if err != nil {
		return nil, apperrors.Internal(err)
	}
	return pair, nil
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func (s *AuthService) mintTokenPair(userID string) (*TokenPair, error) {
	access, err := jwtutil.GenerateAccess(userID, s.jwtSecret)
	if err != nil {
		return nil, err
	}
	refresh, err := jwtutil.GenerateRefresh(userID, s.jwtSecret)
	if err != nil {
		return nil, err
	}
	return &TokenPair{
		AccessToken:  access,
		RefreshToken: refresh,
		ExpiresIn:    int((24 * time.Hour).Seconds()),
	}, nil
}

// ── Apple JWKS verification (no extra deps — uses stdlib crypto) ──────────────

type appleJWKS struct {
	Keys []appleJWK `json:"keys"`
}

type appleJWK struct {
	Kid string `json:"kid"`
	N   string `json:"n"`
	E   string `json:"e"`
}

// verifyAppleToken validates an Apple identity token and returns (appleUserID, email).
// It fetches Apple's public keys live so it always works with key rotations.
func (s *AuthService) verifyAppleToken(identityToken string) (userID, email string, err error) {
	// 1. Parse header without validation to get the key ID.
	p := jwt.NewParser()
	unverified, _, parseErr := p.ParseUnverified(identityToken, jwt.MapClaims{})
	if parseErr != nil {
		return "", "", errors.New("malformed token")
	}
	kid, ok := unverified.Header["kid"].(string)
	if !ok || kid == "" {
		return "", "", errors.New("missing kid in token header")
	}

	// 2. Fetch Apple's public key matching this kid.
	pubKey, err := s.fetchAppleKey(kid)
	if err != nil {
		return "", "", err
	}

	// 3. Parse and fully verify the token.
	token, err := jwt.Parse(identityToken,
		func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
			}
			return pubKey, nil
		},
		jwt.WithIssuer("https://appleid.apple.com"),
		jwt.WithAudience(s.appleBundleID),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		return "", "", fmt.Errorf("token verification failed: %w", err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "", errors.New("invalid token claims")
	}

	sub, _ := claims["sub"].(string)
	if sub == "" {
		return "", "", errors.New("missing sub claim")
	}
	emailVal, _ := claims["email"].(string)
	return sub, emailVal, nil
}

// fetchAppleKey downloads Apple's JWKS and returns the RSA public key for the given kid.
func (s *AuthService) fetchAppleKey(kid string) (*rsa.PublicKey, error) {
	resp, err := http.Get("https://appleid.apple.com/auth/keys") //nolint:noctx
	if err != nil {
		return nil, errors.New("failed to fetch Apple public keys")
	}
	defer resp.Body.Close()

	var jwks appleJWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, errors.New("failed to parse Apple JWKS")
	}

	for _, key := range jwks.Keys {
		if key.Kid == kid {
			return decodeRSAPublicKey(key.N, key.E)
		}
	}
	return nil, fmt.Errorf("no Apple public key found for kid %q", kid)
}

// decodeRSAPublicKey parses the base64url-encoded modulus and exponent from a JWK.
func decodeRSAPublicKey(nStr, eStr string) (*rsa.PublicKey, error) {
	nBytes, err := base64.RawURLEncoding.DecodeString(nStr)
	if err != nil {
		return nil, errors.New("invalid RSA modulus encoding")
	}
	eBytes, err := base64.RawURLEncoding.DecodeString(eStr)
	if err != nil {
		return nil, errors.New("invalid RSA exponent encoding")
	}
	n := new(big.Int).SetBytes(nBytes)
	e := new(big.Int).SetBytes(eBytes)
	return &rsa.PublicKey{N: n, E: int(e.Int64())}, nil
}
