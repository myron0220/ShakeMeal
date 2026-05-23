package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/myron0220/shakemeal/internal/domain"
)

type FavoritesRepo struct {
	db *pgxpool.Pool
}

func NewFavoritesRepo(db *pgxpool.Pool) *FavoritesRepo {
	return &FavoritesRepo{db: db}
}

// List returns all favorites for a user, newest first.
func (r *FavoritesRepo) List(ctx context.Context, userID string) ([]domain.Favorite, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, user_id, place_id, name, address, cuisine,
		       rating, price_level, latitude, longitude, created_at
		FROM favorites
		WHERE user_id = $1
		ORDER BY created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []domain.Favorite
	for rows.Next() {
		var f domain.Favorite
		if err := rows.Scan(
			&f.ID, &f.UserID, &f.PlaceID, &f.Name, &f.Address, &f.Cuisine,
			&f.Rating, &f.PriceLevel, &f.Latitude, &f.Longitude, &f.CreatedAt,
		); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// Add inserts a favorite. On duplicate (same user+place_id) it is a no-op
// but still returns the existing row so the caller always gets a valid ID.
func (r *FavoritesRepo) Add(ctx context.Context, f *domain.Favorite) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO favorites (user_id, place_id, name, address, cuisine,
		                       rating, price_level, latitude, longitude)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		ON CONFLICT (user_id, place_id) DO UPDATE
		    SET created_at = favorites.created_at
		RETURNING id, created_at
	`, f.UserID, f.PlaceID, f.Name, f.Address, f.Cuisine,
		f.Rating, f.PriceLevel, f.Latitude, f.Longitude,
	).Scan(&f.ID, &f.CreatedAt)
}

// Remove deletes a favorite by place_id for the given user.
func (r *FavoritesRepo) Remove(ctx context.Context, userID, placeID string) error {
	_, err := r.db.Exec(ctx, `
		DELETE FROM favorites WHERE user_id = $1 AND place_id = $2
	`, userID, placeID)
	return err
}

// IsFavorited checks whether a place is already favorited by the user.
func (r *FavoritesRepo) IsFavorited(ctx context.Context, userID, placeID string) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM favorites WHERE user_id=$1 AND place_id=$2)
	`, userID, placeID).Scan(&exists)
	return exists, err
}
