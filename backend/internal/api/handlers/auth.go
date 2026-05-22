package handlers

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/myron0220/shakemeal/internal/service"
	"github.com/myron0220/shakemeal/internal/utils/apperrors"
)

// AuthHandler handles authentication endpoints.
type AuthHandler struct {
	auth *service.AuthService
}

func NewAuthHandler(auth *service.AuthService) *AuthHandler {
	return &AuthHandler{auth: auth}
}

// ── Request / Response shapes ─────────────────────────────────────────────────

type appleSignInRequest struct {
	IdentityToken string `json:"identity_token" binding:"required"`
	FullName      string `json:"full_name"` // only present on the very first sign-in
}

type registerRequest struct {
	// Identifier is either an email address or a phone number (+1234567890).
	Identifier string `json:"identifier" binding:"required"`
	Password   string `json:"password"   binding:"required"`
	Name       string `json:"name"`
}

type loginRequest struct {
	Identifier string `json:"identifier" binding:"required"`
	Password   string `json:"password"   binding:"required"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// AppleSignIn verifies an Apple identity token and returns the user + token pair.
// POST /api/v1/auth/apple
func (h *AuthHandler) AppleSignIn(c *gin.Context) {
	var req appleSignInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": apperrors.FormatValidationError(err)})
		return
	}

	user, tokens, err := h.auth.SignInWithApple(c.Request.Context(), req.IdentityToken, req.FullName)
	if err != nil {
		respondError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

// Register creates a new account with email/phone + password.
// POST /api/v1/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": apperrors.FormatValidationError(err)})
		return
	}

	user, tokens, err := h.auth.Register(c.Request.Context(), req.Identifier, req.Password, req.Name)
	if err != nil {
		respondError(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

// Login authenticates with email/phone + password and returns a token pair.
// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": apperrors.FormatValidationError(err)})
		return
	}

	user, tokens, err := h.auth.Login(c.Request.Context(), req.Identifier, req.Password)
	if err != nil {
		respondError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

// Refresh issues a new token pair given a valid refresh token.
// POST /api/v1/auth/refresh
func (h *AuthHandler) Refresh(c *gin.Context) {
	var req refreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "refresh_token is required"})
		return
	}

	tokens, err := h.auth.RefreshTokens(c.Request.Context(), req.RefreshToken)
	if err != nil {
		respondError(c, err)
		return
	}

	c.JSON(http.StatusOK, tokens)
}

// ── shared error helper ───────────────────────────────────────────────────────

func respondError(c *gin.Context, err error) {
	var appErr *apperrors.AppError
	if errors.As(err, &appErr) {
		c.JSON(appErr.Code, appErr)
		return
	}
	c.JSON(http.StatusInternalServerError, gin.H{"message": "internal server error"})
}
