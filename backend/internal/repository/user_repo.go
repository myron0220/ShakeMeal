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

// ── lookup helpers ────────────────────────────────────────────────────────────

func (r *UserRepo) FindByAppleID(ctx context.Context, appleID string) (*domain.User, error) {
	return r.findOne(ctx, `apple_id = $1`, appleID)
}

func (r *UserRepo) FindByDeviceID(ctx context.Context, deviceID string) (*domain.User, error) {
	return r.findOne(ctx, `device_id = $1`, deviceID)
}

func (r *UserRepo) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	return r.findOne(ctx, `email = $1`, email)
}

func (r *UserRepo) FindByPhone(ctx context.Context, phone string) (*domain.User, error) {
	return r.findOne(ctx, `phone = $1`, phone)
}

// findOne runs a single-row SELECT with an arbitrary WHERE clause fragment.
func (r *UserRepo) findOne(ctx context.Context, where string, arg any) (*domain.User, error) {
	u := &domain.User{}
	err := r.db.QueryRow(ctx, `
		SELECT id, apple_id, device_id, email, phone, name, is_pro,
		       password_hash, created_at, deleted_at
		FROM users
		WHERE `+where+` AND deleted_at IS NULL
	`, arg).Scan(
		&u.ID, &u.AppleID, &u.DeviceID,
		&u.Email, &u.Phone, &u.Name, &u.IsPro,
		&u.PasswordHash, &u.CreatedAt, &u.DeletedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return u, nil
}

// ── write helpers ─────────────────────────────────────────────────────────────

// Create inserts a new user (Apple sign-in path — no password).
func (r *UserRepo) Create(ctx context.Context, u *domain.User) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO users (apple_id, device_id, email, name)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`, u.AppleID, u.DeviceID, u.Email, u.Name).Scan(&u.ID, &u.CreatedAt)
}

// CreateWithPassword inserts a new user with an email or phone + bcrypt hash.
func (r *UserRepo) CreateWithPassword(ctx context.Context, u *domain.User) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO users (email, phone, name, password_hash)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`, u.Email, u.Phone, u.Name, u.PasswordHash).Scan(&u.ID, &u.CreatedAt)
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
