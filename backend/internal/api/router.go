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
	authHandler *handlers.AuthHandler, // nil when DB is not configured
	jwtSecret string,
) *gin.Engine {
	r := gin.New()
	r.Use(middleware.Logger(log))
	r.Use(gin.Recovery())

	r.HandleMethodNotAllowed = true
	r.NoMethod(func(c *gin.Context) {
		c.JSON(http.StatusMethodNotAllowed, gin.H{"message": "method not allowed"})
	})
	r.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, gin.H{"message": "not found"})
	})

	// Health — no auth required
	r.GET("/health", handlers.Health)

	v1 := r.Group("/api/v1")
	{
		// ── Public ────────────────────────────────────────────────────────────
		v1.GET("/shake", restaurantHandler.Shake)

		// ── Auth ──────────────────────────────────────────────────────────────
		if authHandler != nil {
			auth := v1.Group("/auth")
			{
				auth.POST("/apple", authHandler.AppleSignIn)
				auth.POST("/refresh", authHandler.Refresh)
			}
		}

		// ── Protected (requires valid JWT) ────────────────────────────────────
		if jwtSecret != "" {
			protected := v1.Group("/")
			protected.Use(middleware.RequireAuth(jwtSecret))
			{
				// TODO: favorites, history, preferences
				// protected.GET("/favorites",  favHandler.List)
				// protected.POST("/favorites", favHandler.Add)
				// ...
			}
		}
	}

	return r
}
