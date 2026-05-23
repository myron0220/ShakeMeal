package config

import (
	"github.com/spf13/viper"
)

type Config struct {
	Port                  string `mapstructure:"PORT"`
	Env                   string `mapstructure:"ENV"`
	DatabaseURL           string `mapstructure:"DATABASE_URL"`
	GooglePlacesAPIKey    string `mapstructure:"GOOGLE_PLACES_API_KEY"`
	JWTSecret             string `mapstructure:"JWT_SECRET"`
	AppleBundleID         string `mapstructure:"APPLE_BUNDLE_ID"`
	PlacesCacheTTLMinutes int    `mapstructure:"PLACES_CACHE_TTL_MINUTES"`
}

func Load() (*Config, error) {
	viper.SetConfigFile(".env")
	viper.AutomaticEnv()

	// Explicitly bind every env var so viper.Unmarshal picks them up.
	// AutomaticEnv() alone does NOT populate Unmarshal — this is a known
	// Viper limitation. Without BindEnv the secrets set on Fly.io are
	// silently ignored and auth/db routes never register.
	for _, key := range []string{
		"PORT", "ENV",
		"DATABASE_URL",
		"JWT_SECRET",
		"GOOGLE_PLACES_API_KEY",
		"APPLE_BUNDLE_ID",
		"PLACES_CACHE_TTL_MINUTES",
	} {
		_ = viper.BindEnv(key)
	}

	// Defaults
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("ENV", "development")
	viper.SetDefault("PLACES_CACHE_TTL_MINUTES", 10)
	viper.SetDefault("APPLE_BUNDLE_ID", "com.shakemeal.app")

	// Read .env file — ignore error if not present (env vars take over)
	_ = viper.ReadInConfig()

	cfg := &Config{}
	if err := viper.Unmarshal(cfg); err != nil {
		return nil, err
	}
	return cfg, nil
}

func (c *Config) IsDevelopment() bool {
	return c.Env == "development"
}
