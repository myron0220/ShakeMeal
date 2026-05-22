package providers

import (
	"context"

	"github.com/myron0220/shakemeal/internal/domain"
)

// PlacesProvider is the interface all restaurant data providers must implement.
// Swap Google ↔ Foursquare without touching service layer.
type PlacesProvider interface {
	// NearbyRestaurants returns restaurants matching the criteria.
	NearbyRestaurants(ctx context.Context, req NearbyRequest) ([]domain.Restaurant, error)

	// PhotoURL resolves a provider-specific photo reference into a full URL.
	PhotoURL(photoRef string, maxWidth int) string
}

type NearbyRequest struct {
	Lat         float64
	Lng         float64
	RadiusM     int
	Cuisines    []string
	PriceLevels []int
}
