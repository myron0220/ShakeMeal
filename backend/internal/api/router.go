package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/myron0220/shakemeal/internal/api/handlers"
	"github.com/myron0220/shakemeal/internal/api/middleware"
	"go.uber.org/zap"
)

func NewRouter(
	log *zap.Logger,
	restaurantHandler *handlers.RestaurantHandler,
) *gin.Engine {
	r := gin.New()
	r.Use(middleware.Logger(log))
	r.Use(gin.Recovery())

	// Return 405 instead of 404 when the route exists but the method is wrong
	r.HandleMethodNotAllowed = true
	r.NoMethod(func(c *gin.Context) {
		c.JSON(http.StatusMethodNotAllowed, gin.H{"message": "method not allowed"})
	})

	// Return clean JSON for unknown routes
	r.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, gin.H{"message": "not found"})
	})

	// Health check — no auth required
	r.GET("/health", handlers.Health)

	// API v1
	v1 := r.Group("/api/v1")
	{
		v1.GET("/shake", restaurantHandler.Shake)
		// TODO: favorites, history, preferences, auth, webhooks
	}

	return r
}
