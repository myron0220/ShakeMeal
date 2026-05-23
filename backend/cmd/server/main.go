package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"sort"
	"strings"
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

	// ── Database (optional — auth/favorites/history disabled when not configured)
	var authHandler      *handlers.AuthHandler
	var meHandler        *handlers.MeHandler
	var favoritesHandler *handlers.FavoritesHandler
	var historyHandler   *handlers.HistoryHandler

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

		// ── Auto-migrate ─────────────────────────────────────────────────────
		if err := runMigrations(context.Background(), db, log); err != nil {
			log.Fatal("migrations failed", zap.Error(err))
		}

		if cfg.JWTSecret == "" {
			log.Fatal("JWT_SECRET must be set when DATABASE_URL is configured")
		}

		userRepo     := repository.NewUserRepo(db)
		favsRepo     := repository.NewFavoritesRepo(db)
		historyRepo  := repository.NewHistoryRepo(db)

		authSvc      := service.NewAuthService(userRepo, cfg.JWTSecret, cfg.AppleBundleID)
		authHandler      = handlers.NewAuthHandler(authSvc)
		meHandler        = handlers.NewMeHandler(userRepo)
		favoritesHandler = handlers.NewFavoritesHandler(favsRepo)
		historyHandler   = handlers.NewHistoryHandler(historyRepo)

		log.Info("auth + favorites + history enabled",
			zap.String("apple_bundle_id", cfg.AppleBundleID),
		)
	} else {
		log.Warn("DATABASE_URL not set — auth/favorites/history endpoints disabled")
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
	router := api.NewRouter(log, restaurantHandler, authHandler, meHandler, favoritesHandler, historyHandler, cfg.JWTSecret)

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

// runMigrations runs all *.up.sql files in the migrations/ directory in order.
func runMigrations(ctx context.Context, db *pgxpool.Pool, log *zap.Logger) error {
	entries, err := filepath.Glob("migrations/*.up.sql")
	if err != nil {
		return err
	}
	sort.Strings(entries)

	for _, f := range entries {
		sql, err := os.ReadFile(f)
		if err != nil {
			return err
		}
		// Skip empty files
		if len(strings.TrimSpace(string(sql))) == 0 {
			continue
		}
		if _, err := db.Exec(ctx, string(sql)); err != nil {
			// Ignore "already exists" errors so re-deploys are safe
			if !strings.Contains(err.Error(), "already exists") {
				return err
			}
		}
		log.Info("migration applied", zap.String("file", f))
	}
	return nil
}
