package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/myron0220/shakemeal/internal/domain"
)

type HistoryRepo struct {
	db *pgxpool.Pool
}

func NewHistoryRepo(db *pgxpool.Pool) *HistoryRepo {
	return &HistoryRepo{db: db}
}

// List returns shake history for a user, newest first (max 100).
func (r *HistoryRepo) List(ctx context.Context, userID string) ([]domain.HistoryItem, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, user_id, place_id, name, address, cuisine,
		       rating, price_level, latitude, longitude, shook_at
		FROM shake_history
		WHERE user_id = $1
		ORDER BY shook_at DESC
		LIMIT 100
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []domain.HistoryItem
	for rows.Next() {
		var h domain.HistoryItem
		if err := rows.Scan(
			&h.ID, &h.UserID, &h.PlaceID, &h.Name, &h.Address, &h.Cuisine,
			&h.Rating, &h.PriceLevel, &h.Latitude, &h.Longitude, &h.ShookAt,
		); err != nil {
			return nil, err
		}
		out = append(out, h)
	}
	return out, rows.Err()
}

// Add records a new history entry.
func (r *HistoryRepo) Add(ctx context.Context, h *domain.HistoryItem) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO shake_history (user_id, place_id, name, address, cuisine,
		                           rating, price_level, latitude, longitude)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		RETURNING id, shook_at
	`, h.UserID, h.PlaceID, h.Name, h.Address, h.Cuisine,
		h.Rating, h.PriceLevel, h.Latitude, h.Longitude,
	).Scan(&h.ID, &h.ShookAt)
}
