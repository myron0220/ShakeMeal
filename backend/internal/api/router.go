package api

import (
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
