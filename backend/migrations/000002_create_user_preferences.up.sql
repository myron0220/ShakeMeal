CREATE TABLE user_preferences (
    user_id        UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    default_radius INT NOT NULL DEFAULT 1000,
    cuisines       TEXT[] NOT NULL DEFAULT '{}',
    price_levels   INT[]  NOT NULL DEFAULT '{}',
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
