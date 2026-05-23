package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/myron0220/shakemeal/internal/domain"
	"github.com/myron0220/shakemeal/internal/repository"
	"github.com/myron0220/shakemeal/internal/utils/apperrors"
)

type HistoryHandler struct {
	repo *repository.HistoryRepo
}

func NewHistoryHandler(repo *repository.HistoryRepo) *HistoryHandler {
	return &HistoryHandler{repo: repo}
}

// GET /api/v1/history
func (h *HistoryHandler) List(c *gin.Context) {
	userID := c.GetString("user_id")
	items, err := h.repo.List(c.Request.Context(), userID)
	if err != nil {
		respondError(c, apperrors.Internal(err))
		return
	}
	if items == nil {
		items = []domain.HistoryItem{}
	}
	c.JSON(http.StatusOK, gin.H{"history": items})
}

// POST /api/v1/history
func (h *HistoryHandler) Add(c *gin.Context) {
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

	item := &domain.HistoryItem{
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
	if err := h.repo.Add(c.Request.Context(), item); err != nil {
		respondError(c, apperrors.Internal(err))
		return
	}
	c.JSON(http.StatusCreated, item)
}
