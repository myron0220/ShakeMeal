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

// RandomRestaurant fetches nearby restaurants and returns one at random,
// excluding any place_ids the caller has already seen.
func (s *ShakeService) RandomRestaurant(ctx context.Context, req *domain.ShakeRequest) (*domain.Restaurant, error) {
	req.SetDefaults()

	nearby, err := s.places.NearbyRestaurants(ctx, providers.NearbyRequest{
		Lat:         req.Lat,
		Lng:         req.Lng,
		RadiusM:     req.RadiusM,
		Cuisines:    req.Cuisines,
		PriceLevels: req.PriceLevels,
	})
	if err != nil {
		return nil, apperrors.Internal(err)
	}

	// Filter out excluded place IDs
	if len(req.Exclude) > 0 {
		excludeSet := make(map[string]bool, len(req.Exclude))
		for _, id := range req.Exclude {
			excludeSet[id] = true
		}
		filtered := nearby[:0]
		for _, r := range nearby {
			if !excludeSet[r.ID] {
				filtered = append(filtered, r)
			}
		}
		nearby = filtered
	}

	if len(nearby) == 0 {
		return nil, apperrors.NotFound(apperrors.ErrNoRestaurantsFound.Error())
	}

	// Pick one at random
	picked := nearby[rand.Intn(len(nearby))]
	return &picked, nil
}
