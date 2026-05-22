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
