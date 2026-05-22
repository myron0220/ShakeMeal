-- Add email/phone+password auth support
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone         VARCHAR(32);
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(256);

-- Partial unique indexes: NULLs don't conflict, but two rows can't share the same value.
CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique ON users (email)
    WHERE email IS NOT NULL AND deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS users_phone_unique ON users (phone)
    WHERE phone IS NOT NULL AND deleted_at IS NULL;
