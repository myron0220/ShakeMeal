package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.uber.org/zap"

	"github.com/myron0220/shakemeal/internal/api"
	"github.com/myron0220/shakemeal/internal/api/handlers"
	"github.com/myron0220/shakemeal/internal/config"
	"github.com/myron0220/shakemeal/internal/providers"
	"github.com/myron0220/shakemeal/internal/service"
)

func main() {
	// ── Logger ──────────────────────────────────────────────────────────────
	log, _ := zap.NewProduction()
	defer log.Sync()

	// ── Config ──────────────────────────────────────────────────────────────
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("failed to load config", zap.Error(err))
	}
	log.Info("starting shakemeal API",
		zap.String("env", cfg.Env),
		zap.String("port", cfg.Port),
	)

	// ── Providers ───────────────────────────────────────────────────────────
	// Use mock provider when no Google API key is configured (local dev).
	var placesProvider providers.PlacesProvider
	if cfg.GooglePlacesAPIKey == "" || cfg.GooglePlacesAPIKey == "your_key_here" {
		log.Warn("GOOGLE_PLACES_API_KEY not set — using mock provider")
		placesProvider = providers.NewMockPlacesProvider()
	} else {
		placesProvider = providers.NewGooglePlacesProvider(cfg.GooglePlacesAPIKey)
	}

	// ── Services ────────────────────────────────────────────────────────────
	shakeSvc := service.NewShakeService(placesProvider)

	// ── Handlers ────────────────────────────────────────────────────────────
	restaurantHandler := handlers.NewRestaurantHandler(shakeSvc)

	// ── Router ──────────────────────────────────────────────────────────────
	router := api.NewRouter(log, restaurantHandler)

	// ── HTTP Server ─────────────────────────────────────────────────────────
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start in background
	go func() {
		log.Info("server listening", zap.String("addr", srv.Addr))
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal("server error", zap.Error(err))
		}
	}()

	// ── Graceful Shutdown ───────────────────────────────────────────────────
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Error("shutdown error", zap.Error(err))
	}
	log.Info("server stopped")
}
