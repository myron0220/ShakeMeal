DROP INDEX IF EXISTS users_phone_unique;
DROP INDEX IF EXISTS users_email_unique;
ALTER TABLE users DROP COLUMN IF EXISTS password_hash;
ALTER TABLE users DROP COLUMN IF EXISTS phone;
