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

// Mock restaurants near 3900 Confederation Pkwy, Mississauga, ON (Square One area)
var mockRestaurants = []domain.Restaurant{
	{ID: "mock-001", Name: "Golden Dragon", Address: "4 Robert Speck Pkwy, Mississauga, ON", Cuisine: "Chinese",
		Rating: 4.5, PriceLevel: 2, Latitude: 43.5961, Longitude: -79.6441, DistanceMeters: 350,
		PhotoURL: "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800"},
	{ID: "mock-002", Name: "Sakura Ramen", Address: "325 Burnhamthorpe Rd W, Mississauga, ON", Cuisine: "Japanese",
		Rating: 4.8, PriceLevel: 2, Latitude: 43.5875, Longitude: -79.6380, DistanceMeters: 600,
		PhotoURL: "https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800"},
	{ID: "mock-003", Name: "Taco Loco", Address: "151 City Centre Dr, Mississauga, ON", Cuisine: "Mexican",
		Rating: 4.2, PriceLevel: 1, Latitude: 43.5850, Longitude: -79.6500, DistanceMeters: 900,
		PhotoURL: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800"},
	{ID: "mock-004", Name: "Bella Italia", Address: "100 City Centre Dr, Mississauga, ON", Cuisine: "Italian",
		Rating: 4.6, PriceLevel: 3, Latitude: 43.5895, Longitude: -79.6480, DistanceMeters: 450,
		PhotoURL: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800"},
	{ID: "mock-005", Name: "Spice Garden", Address: "77 Confederation Pkwy, Mississauga, ON", Cuisine: "Indian",
		Rating: 4.3, PriceLevel: 2, Latitude: 43.5970, Longitude: -79.6350, DistanceMeters: 750,
		PhotoURL: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800"},
}

func (m *MockPlacesProvider) NearbyRestaurants(_ context.Context, _ NearbyRequest) ([]domain.Restaurant, error) {
	// Shuffle and return all mock restaurants
	list := make([]domain.Restaurant, len(mockRestaurants))
	copy(list, mockRestaurants)
	rand.Shuffle(len(list), func(i, j int) { list[i], list[j] = list[j], list[i] })
	return list, nil
}

func (m *MockPlacesProvider) PhotoURL(_ string, _ int) string { return "" }
