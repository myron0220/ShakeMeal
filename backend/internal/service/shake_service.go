package service

import (
	"context"
	"math/rand"

	"github.com/myron0220/shakemeal/internal/domain"
	"github.com/myron0220/shakemeal/internal/providers"
	"github.com/myron0220/shakemeal/internal/utils/apperrors"
)

type ShakeService struct {
	places providers.PlacesProvider
}

func NewShakeService(places providers.PlacesProvider) *ShakeService {
	return &ShakeService{places: places}
}

// RandomRestaurant fetches nearby restaurants and returns one at random.
// The exclude list is treated as a soft preference — if excluding already-seen
// restaurants would empty the pool, we reset and pick from the full list so
// the user never hits a dead end.
func (s *ShakeService) RandomRestaurant(ctx context.Context, req *domain.ShakeRequest) (*domain.Restaurant, error) {
	req.SetDefaults()

	all, err := s.places.NearbyRestaurants(ctx, providers.NearbyRequest{
		Lat:         req.Lat,
		Lng:         req.Lng,
		RadiusM:     req.RadiusM,
		Cuisines:    req.Cuisines,
		PriceLevels: req.PriceLevels,
	})
	if err != nil {
		return nil, apperrors.Internal(err)
	}

	if len(all) == 0 {
		return nil, apperrors.NotFound(apperrors.ErrNoRestaurantsFound.Error())
	}

	// Try to pick from unseen restaurants first.
	candidates := all
	if len(req.Exclude) > 0 {
		excludeSet := make(map[string]bool, len(req.Exclude))
		for _, id := range req.Exclude {
			excludeSet[id] = true
		}
		filtered := make([]domain.Restaurant, 0, len(all))
		for _, r := range all {
			if !excludeSet[r.ID] {
				filtered = append(filtered, r)
			}
		}
		// Only apply the filter if it leaves at least one option.
		// Otherwise fall back to the full list so the user never gets stuck.
		if len(filtered) > 0 {
			candidates = filtered
		}
	}

	picked := candidates[rand.Intn(len(candidates))]
	return &picked, nil
}
