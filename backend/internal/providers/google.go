package providers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/myron0220/shakemeal/internal/domain"
)

const (
	googlePlacesBaseURL = "https://maps.googleapis.com/maps/api/place"
	googlePhotoBaseURL  = "https://maps.googleapis.com/maps/api/place/photo"
)

type GooglePlacesProvider struct {
	apiKey     string
	httpClient *http.Client
}

func NewGooglePlacesProvider(apiKey string) *GooglePlacesProvider {
	return &GooglePlacesProvider{
		apiKey: apiKey,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// NearbyRestaurants calls Google Places Nearby Search API.
func (g *GooglePlacesProvider) NearbyRestaurants(ctx context.Context, req NearbyRequest) ([]domain.Restaurant, error) {
	params := url.Values{}
	params.Set("location", fmt.Sprintf("%f,%f", req.Lat, req.Lng))
	params.Set("radius", fmt.Sprintf("%d", req.RadiusM))
	params.Set("type", "restaurant")
	params.Set("key", g.apiKey)

	if len(req.PriceLevels) > 0 {
		max := 0
		for _, p := range req.PriceLevels {
			if p > max {
				max = p
			}
		}
		params.Set("maxprice", fmt.Sprintf("%d", max))
	}

	if len(req.Cuisines) > 0 {
		params.Set("keyword", strings.Join(req.Cuisines, " "))
	}

	endpoint := fmt.Sprintf("%s/nearbysearch/json?%s", googlePlacesBaseURL, params.Encode())

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}

	resp, err := g.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var result googleNearbyResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	if result.Status != "OK" && result.Status != "ZERO_RESULTS" {
		return nil, fmt.Errorf("google places API error: %s", result.Status)
	}

	return g.mapResults(result.Results, req.Lat, req.Lng), nil
}

// PhotoURL resolves a photo reference into a full Google Places photo URL.
func (g *GooglePlacesProvider) PhotoURL(photoRef string, maxWidth int) string {
	if photoRef == "" {
		return ""
	}
	params := url.Values{}
	params.Set("maxwidth", fmt.Sprintf("%d", maxWidth))
	params.Set("photo_reference", photoRef)
	params.Set("key", g.apiKey)
	return fmt.Sprintf("%s?%s", googlePhotoBaseURL, params.Encode())
}

func (g *GooglePlacesProvider) mapResults(results []googlePlace, originLat, originLng float64) []domain.Restaurant {
	restaurants := make([]domain.Restaurant, 0, len(results))
	for _, p := range results {
		if p.BusinessStatus != "" && p.BusinessStatus != "OPERATIONAL" {
			continue
		}
		photoURL := ""
		if len(p.Photos) > 0 {
			photoURL = g.PhotoURL(p.Photos[0].PhotoReference, 800)
		}
		cuisine := extractCuisine(p.Types)
		isOpen := p.OpeningHours != nil && p.OpeningHours.OpenNow
		r := domain.Restaurant{
			ID:             p.PlaceID,
			Name:           p.Name,
			Address:        p.Vicinity,
			Cuisine:        cuisine,
			Rating:         p.Rating,
			PriceLevel:     p.PriceLevel,
			PhotoURL:       photoURL,
			Latitude:       p.Geometry.Location.Lat,
			Longitude:      p.Geometry.Location.Lng,
			DistanceMeters: haversineDistance(originLat, originLng, p.Geometry.Location.Lat, p.Geometry.Location.Lng),
			IsOpen:         &isOpen,
		}
		restaurants = append(restaurants, r)
	}
	return restaurants
}

func extractCuisine(types []string) string {
	skip := map[string]bool{
		"restaurant": true, "food": true, "point_of_interest": true,
		"establishment": true, "store": true,
	}
	for _, t := range types {
		if !skip[t] {
			return strings.ReplaceAll(strings.Title(strings.ToLower(t)), "_", " ")
		}
	}
	return "Restaurant"
}

// haversineDistance returns approximate distance in meters between two coordinates.
func haversineDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371000
	toRad := math.Pi / 180
	dLat := (lat2 - lat1) * toRad
	dLng := (lng2 - lng1) * toRad
	a := math.Pow(math.Sin(dLat/2), 2) +
		math.Cos(lat1*toRad)*math.Cos(lat2*toRad)*math.Pow(math.Sin(dLng/2), 2)
	return R * 2 * math.Asin(math.Sqrt(a))
}

// ── Google API response types ────────────────────────────────────────────────

type googleNearbyResponse struct {
	Results []googlePlace `json:"results"`
	Status  string        `json:"status"`
}

type googlePlace struct {
	PlaceID        string        `json:"place_id"`
	Name           string        `json:"name"`
	Vicinity       string        `json:"vicinity"`
	Rating         float64       `json:"rating"`
	PriceLevel     int           `json:"price_level"`
	Types          []string      `json:"types"`
	BusinessStatus string        `json:"business_status"`
	Geometry       googleGeom    `json:"geometry"`
	Photos         []googlePhoto `json:"photos"`
	OpeningHours   *struct {
		OpenNow bool `json:"open_now"`
	} `json:"opening_hours"`
}

type googleGeom struct {
	Location struct {
		Lat float64 `json:"lat"`
		Lng float64 `json:"lng"`
	} `json:"location"`
}

type googlePhoto struct {
	PhotoReference string `json:"photo_reference"`
}
