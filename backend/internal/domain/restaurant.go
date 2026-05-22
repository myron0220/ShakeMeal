package domain

// Restaurant is the core domain model returned by the shake endpoint.
type Restaurant struct {
	ID             string   `json:"id"`             // Google place_id
	Name           string   `json:"name"`
	Address        string   `json:"address"`
	Cuisine        string   `json:"cuisine"`
	Rating         float64  `json:"rating"`
	PriceLevel     int      `json:"price_level"`    // 1-4
	PhotoURL       string   `json:"photo_url"`      // resolved Google photo URL
	Latitude       float64  `json:"latitude"`
	Longitude      float64  `json:"longitude"`
	DistanceMeters float64  `json:"distance_meters"`
	IsOpen         *bool    `json:"is_open"`
}

// ShakeRequest holds the validated query params for GET /api/v1/shake.
type ShakeRequest struct {
	Lat         float64  `form:"lat"      binding:"required"`
	Lng         float64  `form:"lng"      binding:"required"`
	RadiusM     int      `form:"radius"   binding:"omitempty,min=100,max=50000"`
	Cuisines    []string `form:"cuisine"  binding:"omitempty"`
	PriceLevels []int    `form:"price"    binding:"omitempty"`
	Exclude     []string `form:"exclude"  binding:"omitempty"` // place_ids to skip
}

func (r *ShakeRequest) SetDefaults() {
	if r.RadiusM == 0 {
		r.RadiusM = 1000
	}
}
