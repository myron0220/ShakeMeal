package providers

import (
	"context"
	"math/rand"

	"github.com/myron0220/shakemeal/internal/domain"
)

// MockPlacesProvider returns hardcoded restaurants — used when no API key is set.
type MockPlacesProvider struct{}

func boolPtr(b bool) *bool { return &b }

func NewMockPlacesProvider() *MockPlacesProvider {
	return &MockPlacesProvider{}
}

// Real restaurants near 3900 Confederation Pkwy, Mississauga, ON
var mockRestaurants = []domain.Restaurant{
	// ── Japanese ──────────────────────────────────────────────────────
	{ID: "mock-001", Name: "Kinton Ramen", Address: "4026 Confederation Pkwy, Mississauga, ON", Cuisine: "Japanese",
		Rating: 4.4, PriceLevel: 2, Latitude: 43.5935, Longitude: -79.6423, DistanceMeters: 150,
		PhotoURL: "https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-005", Name: "Gyubee Japanese Grill", Address: "4559 Hurontario St, Mississauga, ON", Cuisine: "Japanese BBQ",
		Rating: 4.3, PriceLevel: 3, Latitude: 43.6097, Longitude: -79.6290, DistanceMeters: 2200,
		PhotoURL: "https://images.unsplash.com/photo-1544025162-d76694265947?w=800", IsOpen: boolPtr(false)},
	{ID: "mock-011", Name: "Sushi Masaki Saito", Address: "388 King St W, Toronto, ON", Cuisine: "Sushi",
		Rating: 4.9, PriceLevel: 4, Latitude: 43.6453, Longitude: -79.3985, DistanceMeters: 3100,
		PhotoURL: "https://images.unsplash.com/photo-1553621042-f6e147245754?w=800", IsOpen: boolPtr(true)},

	// ── Middle Eastern ────────────────────────────────────────────────
	{ID: "mock-002", Name: "Osmow's Shawarma", Address: "100 City Centre Dr, Mississauga, ON", Cuisine: "Middle Eastern",
		Rating: 4.5, PriceLevel: 1, Latitude: 43.5920, Longitude: -79.6440, DistanceMeters: 280,
		PhotoURL: "https://images.unsplash.com/photo-1561043433-aaf687c4cf04?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-012", Name: "Byblos", Address: "11 Duncan St, Toronto, ON", Cuisine: "Middle Eastern",
		Rating: 4.6, PriceLevel: 3, Latitude: 43.6472, Longitude: -79.3924, DistanceMeters: 4200,
		PhotoURL: "https://images.unsplash.com/photo-1515443961218-a51367888e4b?w=800", IsOpen: boolPtr(false)},

	// ── Canadian / Casual ─────────────────────────────────────────────
	{ID: "mock-003", Name: "Moxies", Address: "100 City Centre Dr, Mississauga, ON", Cuisine: "Canadian",
		Rating: 4.0, PriceLevel: 3, Latitude: 43.5927, Longitude: -79.6445, DistanceMeters: 320,
		PhotoURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-013", Name: "The Burger's Priest", Address: "1844 Queen St E, Toronto, ON", Cuisine: "Burgers",
		Rating: 4.5, PriceLevel: 1, Latitude: 43.6687, Longitude: -79.3017, DistanceMeters: 5800,
		PhotoURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-014", Name: "Smoke's Poutinerie", Address: "2667 Hurontario St, Mississauga, ON", Cuisine: "Canadian",
		Rating: 4.2, PriceLevel: 1, Latitude: 43.5634, Longitude: -79.6312, DistanceMeters: 3600,
		PhotoURL: "https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?w=800", IsOpen: boolPtr(false)},

	// ── Italian ───────────────────────────────────────────────────────
	{ID: "mock-004", Name: "Scaddabush Italian Kitchen", Address: "209 Rathburn Rd W, Mississauga, ON", Cuisine: "Italian",
		Rating: 4.6, PriceLevel: 3, Latitude: 43.5892, Longitude: -79.6390, DistanceMeters: 650,
		PhotoURL: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-015", Name: "Terroni", Address: "720 Queen St W, Toronto, ON", Cuisine: "Italian",
		Rating: 4.4, PriceLevel: 3, Latitude: 43.6481, Longitude: -79.4097, DistanceMeters: 4900,
		PhotoURL: "https://images.unsplash.com/photo-1595295333158-4742f28fbd85?w=800", IsOpen: boolPtr(true)},

	// ── Indian ────────────────────────────────────────────────────────
	{ID: "mock-006", Name: "Punjabi By Nature", Address: "2980 Drew Rd, Mississauga, ON", Cuisine: "Indian",
		Rating: 4.3, PriceLevel: 2, Latitude: 43.7034, Longitude: -79.6612, DistanceMeters: 1800,
		PhotoURL: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-016", Name: "Lahore Tikka House", Address: "1365 Gerrard St E, Toronto, ON", Cuisine: "Indian",
		Rating: 4.5, PriceLevel: 1, Latitude: 43.6703, Longitude: -79.3321, DistanceMeters: 6200,
		PhotoURL: "https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=800", IsOpen: boolPtr(false)},

	// ── Chinese ───────────────────────────────────────────────────────
	{ID: "mock-007", Name: "Dragon Dynasty", Address: "2301 Brimley Rd, Scarborough, ON", Cuisine: "Chinese",
		Rating: 4.2, PriceLevel: 2, Latitude: 43.7742, Longitude: -79.2639, DistanceMeters: 4100,
		PhotoURL: "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-017", Name: "Mother's Dumplings", Address: "421 Spadina Ave, Toronto, ON", Cuisine: "Chinese",
		Rating: 4.6, PriceLevel: 1, Latitude: 43.6549, Longitude: -79.3973, DistanceMeters: 3800,
		PhotoURL: "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=800", IsOpen: boolPtr(true)},

	// ── Mexican ───────────────────────────────────────────────────────
	{ID: "mock-008", Name: "El Catrin", Address: "18 Tank House Lane, Toronto, ON", Cuisine: "Mexican",
		Rating: 4.4, PriceLevel: 3, Latitude: 43.6503, Longitude: -79.3610, DistanceMeters: 5500,
		PhotoURL: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-018", Name: "Seven Lives", Address: "69 Kensington Ave, Toronto, ON", Cuisine: "Mexican",
		Rating: 4.7, PriceLevel: 1, Latitude: 43.6543, Longitude: -79.4009, DistanceMeters: 4600,
		PhotoURL: "https://images.unsplash.com/photo-1552332386-f8dd00dc2f85?w=800", IsOpen: boolPtr(false)},

	// ── Thai ──────────────────────────────────────────────────────────
	{ID: "mock-009", Name: "Khao San Road", Address: "326 Adelaide St W, Toronto, ON", Cuisine: "Thai",
		Rating: 4.5, PriceLevel: 2, Latitude: 43.6474, Longitude: -79.3939, DistanceMeters: 4300,
		PhotoURL: "https://images.unsplash.com/photo-1562565652-a0d8f0c59eb4?w=800", IsOpen: boolPtr(true)},

	// ── Korean ────────────────────────────────────────────────────────
	{ID: "mock-010", Name: "Owl of Minerva", Address: "5324 Yonge St, Toronto, ON", Cuisine: "Korean",
		Rating: 4.3, PriceLevel: 2, Latitude: 43.7742, Longitude: -79.4145, DistanceMeters: 5100,
		PhotoURL: "https://images.unsplash.com/photo-1583623025817-d180a2221d0a?w=800", IsOpen: boolPtr(true)},
	{ID: "mock-019", Name: "Hangang Korean BBQ", Address: "656 Bloor St W, Toronto, ON", Cuisine: "Korean BBQ",
		Rating: 4.4, PriceLevel: 2, Latitude: 43.6645, Longitude: -79.4148, DistanceMeters: 4700,
		PhotoURL: "https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800", IsOpen: boolPtr(false)},

	// ── Vietnamese ────────────────────────────────────────────────────
	{ID: "mock-020", Name: "Pho Dau Bo", Address: "3650 Victoria Park Ave, Scarborough, ON", Cuisine: "Vietnamese",
		Rating: 4.4, PriceLevel: 1, Latitude: 43.7820, Longitude: -79.3103, DistanceMeters: 5300,
		PhotoURL: "https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800", IsOpen: boolPtr(true)},

	// ── Pizza ─────────────────────────────────────────────────────────
	{ID: "mock-021", Name: "Pizza Libretto", Address: "221 Ossington Ave, Toronto, ON", Cuisine: "Pizza",
		Rating: 4.5, PriceLevel: 2, Latitude: 43.6483, Longitude: -79.4245, DistanceMeters: 5700,
		PhotoURL: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800", IsOpen: boolPtr(true)},

	// ── Brunch / Café ─────────────────────────────────────────────────
	{ID: "mock-022", Name: "Lady Marmalade", Address: "898 Queen St E, Toronto, ON", Cuisine: "Brunch",
		Rating: 4.4, PriceLevel: 2, Latitude: 43.6599, Longitude: -79.3408, DistanceMeters: 6100,
		PhotoURL: "https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=800", IsOpen: boolPtr(true)},
}

func (m *MockPlacesProvider) NearbyRestaurants(_ context.Context, _ NearbyRequest) ([]domain.Restaurant, error) {
	list := make([]domain.Restaurant, len(mockRestaurants))
	copy(list, mockRestaurants)
	rand.Shuffle(len(list), func(i, j int) { list[i], list[j] = list[j], list[i] })
	return list, nil
}

func (m *MockPlacesProvider) PhotoURL(_ string, _ int) string { return "" }
