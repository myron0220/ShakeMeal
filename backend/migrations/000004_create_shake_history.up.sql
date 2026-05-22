CREATE TABLE shake_history (
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
    shook_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_history_user_id ON shake_history(user_id);
CREATE INDEX idx_history_shook_at ON shake_history(shook_at DESC);
