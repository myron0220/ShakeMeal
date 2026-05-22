CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_id   VARCHAR(255) UNIQUE,
    device_id  VARCHAR(255) UNIQUE,
    email      VARCHAR(255) UNIQUE,
    name       VARCHAR(255),
    is_pro     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_users_apple_id  ON users(apple_id)  WHERE apple_id  IS NOT NULL;
CREATE INDEX idx_users_device_id ON users(device_id) WHERE device_id IS NOT NULL;
