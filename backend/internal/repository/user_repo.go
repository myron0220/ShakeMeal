package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/myron0220/shakemeal/internal/domain"
)

// UserRepo handles all user persistence.
type UserRepo struct {
	db *pgxpool.Pool
}

func NewUserRepo(db *pgxpool.Pool) *UserRepo {
	return &UserRepo{db: db}
}

// FindByAppleID returns the user with the given Apple subject ID, or nil if not found.
func (r *UserRepo) FindByAppleID(ctx context.Context, appleID string) (*domain.User, error) {
	u := &domain.User{}
	err := r.db.QueryRow(ctx, `
		SELECT id, apple_id, device_id, email, name, is_pro, created_at, deleted_at
		FROM users
		WHERE apple_id = $1 AND deleted_at IS NULL
	`, appleID).Scan(
		&u.ID, &u.AppleID, &u.DeviceID,
		&u.Email, &u.Name, &u.IsPro,
		&u.CreatedAt, &u.DeletedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return u, nil
}

// FindByDeviceID returns the user with the given device ID, or nil if not found.
func (r *UserRepo) FindByDeviceID(ctx context.Context, deviceID string) (*domain.User, error) {
	u := &domain.User{}
	err := r.db.QueryRow(ctx, `
		SELECT id, apple_id, device_id, email, name, is_pro, created_at, deleted_at
		FROM users
		WHERE device_id = $1 AND deleted_at IS NULL
	`, deviceID).Scan(
		&u.ID, &u.AppleID, &u.DeviceID,
		&u.Email, &u.Name, &u.IsPro,
		&u.CreatedAt, &u.DeletedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return u, nil
}

// Create inserts a new user and populates ID + CreatedAt from the DB.
func (r *UserRepo) Create(ctx context.Context, u *domain.User) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO users (apple_id, device_id, email, name)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`, u.AppleID, u.DeviceID, u.Email, u.Name).Scan(&u.ID, &u.CreatedAt)
}

// LinkAppleID attaches an Apple ID (and optional email/name) to an existing user.
func (r *UserRepo) LinkAppleID(ctx context.Context, userID, appleID string, email, name *string) error {
	_, err := r.db.Exec(ctx, `
		UPDATE users
		SET apple_id = $1,
		    email    = COALESCE($2, email),
		    name     = COALESCE($3, name)
		WHERE id = $4
	`, appleID, email, name, userID)
	return err
}
