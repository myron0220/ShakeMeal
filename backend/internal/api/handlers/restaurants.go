package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/myron0220/shakemeal/internal/domain"
	"github.com/myron0220/shakemeal/internal/service"
	"github.com/myron0220/shakemeal/internal/utils/apperrors"
)

type RestaurantHandler struct {
	shakeSvc *service.ShakeService
}

func NewRestaurantHandler(shakeSvc *service.ShakeService) *RestaurantHandler {
	return &RestaurantHandler{shakeSvc: shakeSvc}
}

// Shake handles GET /api/v1/shake
// Returns a single random nearby restaurant.
func (h *RestaurantHandler) Shake(c *gin.Context) {
	var req domain.ShakeRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	restaurant, err := h.shakeSvc.RandomRestaurant(c.Request.Context(), &req)
	if err != nil {
		if appErr, ok := err.(*apperrors.AppError); ok {
			c.JSON(appErr.Code, gin.H{"message": appErr.Message})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"message": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, restaurant)
}
