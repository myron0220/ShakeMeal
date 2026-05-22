CREATE TABLE favorites (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    place_id    VARCHAR(255) NOT NULL,
    name        VARCHAR(255) NOT NULL,
    address     TEXT,
    cuisine     VARCHAR(100),
    rating      DECIMAL(2,1),
    price_level INT,
    latitude    DECIMAL(10,8),
    longitude   DECIMAL(11,8),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, place_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
