package providers

import (
	"context"
	"math/rand"

	"github.com/myron0220/shakemeal/internal/domain"
)

// MockPlacesProvider returns hardcoded restaurants — used when no API key is set.
type MockPlacesProvider struct{}

func NewMockPlacesProvider() *MockPlacesProvider {
	return &MockPlacesProvider{}
}

var mockRestaurants = []domain.Restaurant{
	{ID: "mock-001", Name: "Golden Dragon", Address: "123 Main St", Cuisine: "Chinese",
		Rating: 4.5, PriceLevel: 2, Latitude: 37.7749, Longitude: -122.4194, DistanceMeters: 350},
	{ID: "mock-002", Name: "Sakura Ramen", Address: "456 Oak Ave", Cuisine: "Japanese",
		Rating: 4.8, PriceLevel: 2, Latitude: 37.7750, Longitude: -122.4180, DistanceMeters: 600},
	{ID: "mock-003", Name: "Taco Loco", Address: "789 Pine Rd", Cuisine: "Mexican",
		Rating: 4.2, PriceLevel: 1, Latitude: 37.7760, Longitude: -122.4200, DistanceMeters: 900},
	{ID: "mock-004", Name: "Bella Italia", Address: "321 Elm St", Cuisine: "Italian",
		Rating: 4.6, PriceLevel: 3, Latitude: 37.7745, Longitude: -122.4210, DistanceMeters: 450},
	{ID: "mock-005", Name: "Spice Garden", Address: "654 Maple Ave", Cuisine: "Indian",
		Rating: 4.3, PriceLevel: 2, Latitude: 37.7755, Longitude: -122.4185, DistanceMeters: 750},
}

func (m *MockPlacesProvider) NearbyRestaurants(_ context.Context, _ NearbyRequest) ([]domain.Restaurant, error) {
	// Shuffle and return all mock restaurants
	list := make([]domain.Restaurant, len(mockRestaurants))
	copy(list, mockRestaurants)
	rand.Shuffle(len(list), func(i, j int) { list[i], list[j] = list[j], list[i] })
	return list, nil
}

func (m *MockPlacesProvider) PhotoURL(_ string, _ int) string { return "" }
