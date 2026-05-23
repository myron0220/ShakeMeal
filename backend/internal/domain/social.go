package domain

import "time"

// Favorite represents a restaurant saved by a user.
type Favorite struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	PlaceID    string    `json:"place_id"`
	Name       string    `json:"name"`
	Address    string    `json:"address"`
	Cuisine    string    `json:"cuisine"`
	Rating     float64   `json:"rating"`
	PriceLevel int       `json:"price_level"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	CreatedAt  time.Time `json:"created_at"`
}

// HistoryItem represents one shake result the user acted on.
type HistoryItem struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	PlaceID    string    `json:"place_id"`
	Name       string    `json:"name"`
	Address    string    `json:"address"`
	Cuisine    string    `json:"cuisine"`
	Rating     float64   `json:"rating"`
	PriceLevel int       `json:"price_level"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	ShookAt    time.Time `json:"shook_at"`
}
