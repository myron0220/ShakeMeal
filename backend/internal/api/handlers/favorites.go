package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/myron0220/shakemeal/internal/domain"
	"github.com/myron0220/shakemeal/internal/repository"
	"github.com/myron0220/shakemeal/internal/utils/apperrors"
)

type FavoritesHandler struct {
	repo *repository.FavoritesRepo
}

func NewFavoritesHandler(repo *repository.FavoritesRepo) *FavoritesHandler {
	return &FavoritesHandler{repo: repo}
}

// GET /api/v1/favorites
func (h *FavoritesHandler) List(c *gin.Context) {
	userID := c.GetString("user_id")
	favs, err := h.repo.List(c.Request.Context(), userID)
	if err != nil {
		respondError(c, apperrors.Internal(err))
		return
	}
	if favs == nil {
		favs = []domain.Favorite{}
	}
	c.JSON(http.StatusOK, gin.H{"favorites": favs})
}

// POST /api/v1/favorites
func (h *FavoritesHandler) Add(c *gin.Context) {
	userID := c.GetString("user_id")

	var req struct {
		PlaceID    string  `json:"place_id"    binding:"required"`
		Name       string  `json:"name"        binding:"required"`
		Address    string  `json:"address"`
		Cuisine    string  `json:"cuisine"`
		Rating     float64 `json:"rating"`
		PriceLevel int     `json:"price_level"`
		Latitude   float64 `json:"latitude"`
		Longitude  float64 `json:"longitude"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": apperrors.FormatValidationError(err)})
		return
	}

	fav := &domain.Favorite{
		UserID:     userID,
		PlaceID:    req.PlaceID,
		Name:       req.Name,
		Address:    req.Address,
		Cuisine:    req.Cuisine,
		Rating:     req.Rating,
		PriceLevel: req.PriceLevel,
		Latitude:   req.Latitude,
		Longitude:  req.Longitude,
	}
	if err := h.repo.Add(c.Request.Context(), fav); err != nil {
		respondError(c, apperrors.Internal(err))
		return
	}
	c.JSON(http.StatusCreated, fav)
}

// DELETE /api/v1/favorites/:place_id
func (h *FavoritesHandler) Remove(c *gin.Context) {
	userID  := c.GetString("user_id")
	placeID := c.Param("place_id")
	if err := h.repo.Remove(c.Request.Context(), userID, placeID); err != nil {
		respondError(c, apperrors.Internal(err))
		return
	}
	c.Status(http.StatusNoContent)
}
