package domain

import "time"

type User struct {
	ID        string     `json:"id" db:"id"`
	AppleID   *string    `json:"apple_id,omitempty" db:"apple_id"`
	DeviceID  *string    `json:"device_id,omitempty" db:"device_id"`
	Email     *string    `json:"email,omitempty" db:"email"`
	Phone     *string    `json:"phone,omitempty" db:"phone"`
	Name      *string    `json:"name,omitempty" db:"name"`
	IsPro     bool       `json:"is_pro" db:"is_pro"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
	DeletedAt *time.Time `json:"-" db:"deleted_at"`
	// PasswordHash is never serialised — kept server-side only.
	PasswordHash *string `json:"-" db:"password_hash"`
}

type UserPreference struct {
	UserID        string   `json:"user_id" db:"user_id"`
	DefaultRadius int      `json:"default_radius" db:"default_radius"`
	Cuisines      []string `json:"cuisines" db:"cuisines"`
	PriceLevels   []int    `json:"price_levels" db:"price_levels"`
}
