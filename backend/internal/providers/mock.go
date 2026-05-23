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

// Real restaurants near 3900 Confederation Pkwy, Mississauga, ON L5B 0M3
var mockRestaurants = []domain.Restaurant{
	{ID: "mock-001", Name: "Kinton Ramen", Address: "4026 Confederation Pkwy, Mississauga, ON L5B 0G4", Cuisine: "Japanese",
		Rating: 4.4, PriceLevel: 2, Latitude: 43.5935, Longitude: -79.6423, DistanceMeters: 150,
		PhotoURL: "https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800"},
	{ID: "mock-002", Name: "Osmow's Shawarma", Address: "100 City Centre Dr Unit 1-830, Mississauga, ON L5B 2C9", Cuisine: "Middle Eastern",
		Rating: 4.5, PriceLevel: 1, Latitude: 43.5920, Longitude: -79.6440, DistanceMeters: 280,
		PhotoURL: "https://images.unsplash.com/photo-1561043433-aaf687c4cf04?w=800"},
	{ID: "mock-003", Name: "Moxies", Address: "100 City Centre Dr, Mississauga, ON L5B 2C9", Cuisine: "Canadian",
		Rating: 4.0, PriceLevel: 3, Latitude: 43.5927, Longitude: -79.6445, DistanceMeters: 320,
		PhotoURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800"},
	{ID: "mock-004", Name: "Scaddabush Italian Kitchen & Bar", Address: "209 Rathburn Rd W, Mississauga, ON L5B 4C1", Cuisine: "Italian",
		Rating: 4.6, PriceLevel: 3, Latitude: 43.5892, Longitude: -79.6390, DistanceMeters: 650,
		PhotoURL: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800"},
	{ID: "mock-005", Name: "Gyubee Japanese Grill", Address: "4559 Hurontario St Unit A2, Mississauga, ON L4Z 3L9", Cuisine: "Japanese BBQ",
		Rating: 4.3, PriceLevel: 3, Latitude: 43.6097, Longitude: -79.6290, DistanceMeters: 2200,
		PhotoURL: "https://images.unsplash.com/photo-1544025162-d76694265947?w=800"},
}

func (m *MockPlacesProvider) NearbyRestaurants(_ context.Context, _ NearbyRequest) ([]domain.Restaurant, error) {
	// Shuffle and return all mock restaurants
	list := make([]domain.Restaurant, len(mockRestaurants))
	copy(list, mockRestaurants)
	rand.Shuffle(len(list), func(i, j int) { list[i], list[j] = list[j], list[i] })
	return list, nil
}

func (m *MockPlacesProvider) PhotoURL(_ string, _ int) string { return "" }
