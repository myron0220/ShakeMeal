package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/myron0220/shakemeal/internal/repository"
	"github.com/myron0220/shakemeal/internal/utils/apperrors"
)

type MeHandler struct {
	users *repository.UserRepo
}

func NewMeHandler(users *repository.UserRepo) *MeHandler {
	return &MeHandler{users: users}
}

// GET /api/v1/auth/me — returns the profile of the currently authenticated user.
func (h *MeHandler) Get(c *gin.Context) {
	userID := c.GetString("user_id")
	user, err := h.users.FindByID(c.Request.Context(), userID)
	if err != nil {
		respondError(c, apperrors.Internal(err))
		return
	}
	if user == nil {
		respondError(c, apperrors.Unauthorized())
		return
	}
	c.JSON(http.StatusOK, gin.H{"user": user})
}
