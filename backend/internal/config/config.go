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
	PlacesCacheTTLMinutes int    `mapstructure:"PLACES_CACHE_TTL_MINUTES"`
}

func Load() (*Config, error) {
	viper.SetConfigFile(".env")
	viper.AutomaticEnv()

	// Defaults
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("ENV", "development")
	viper.SetDefault("PLACES_CACHE_TTL_MINUTES", 10)

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
