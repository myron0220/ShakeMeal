package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"go.uber.org/zap"

	"github.com/myron0220/shakemeal/internal/api"
	"github.com/myron0220/shakemeal/internal/api/handlers"
	"github.com/myron0220/shakemeal/internal/config"
	"github.com/myron0220/shakemeal/internal/providers"
	"github.com/myron0220/shakemeal/internal/repository"
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

	// ── Database (optional — auth routes disabled when not configured) ───────
	var authHandler *handlers.AuthHandler
	if cfg.DatabaseURL != "" {
		db, err := pgxpool.New(context.Background(), cfg.DatabaseURL)
		if err != nil {
			log.Fatal("failed to connect to database", zap.Error(err))
		}
		if err := db.Ping(context.Background()); err != nil {
			log.Fatal("database ping failed", zap.Error(err))
		}
		defer db.Close()
		log.Info("database connected")

		if cfg.JWTSecret == "" {
			log.Fatal("JWT_SECRET must be set when DATABASE_URL is configured")
		}

		userRepo := repository.NewUserRepo(db)
		authSvc := service.NewAuthService(userRepo, cfg.JWTSecret, cfg.AppleBundleID)
		authHandler = handlers.NewAuthHandler(authSvc)
		log.Info("auth enabled",
			zap.String("apple_bundle_id", cfg.AppleBundleID),
		)
	} else {
		log.Warn("DATABASE_URL not set — auth endpoints disabled")
	}

	// ── Places provider ──────────────────────────────────────────────────────
	var placesProvider providers.PlacesProvider
	if cfg.GooglePlacesAPIKey == "" || cfg.GooglePlacesAPIKey == "your_key_here" {
		log.Warn("GOOGLE_PLACES_API_KEY not set — using mock provider")
		placesProvider = providers.NewMockPlacesProvider()
	} else {
		placesProvider = providers.NewGooglePlacesProvider(cfg.GooglePlacesAPIKey)
	}

	// ── Services & handlers ──────────────────────────────────────────────────
	shakeSvc := service.NewShakeService(placesProvider)
	restaurantHandler := handlers.NewRestaurantHandler(shakeSvc)

	// ── Router ───────────────────────────────────────────────────────────────
	router := api.NewRouter(log, restaurantHandler, authHandler, cfg.JWTSecret)

	// ── HTTP Server ──────────────────────────────────────────────────────────
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Info("server listening", zap.String("addr", srv.Addr))
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal("server error", zap.Error(err))
		}
	}()

	// ── Graceful shutdown ────────────────────────────────────────────────────
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
