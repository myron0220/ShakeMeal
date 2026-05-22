CREATE TABLE places_cache (
    cache_key   VARCHAR(255) PRIMARY KEY,  -- lat3dp:lng3dp:radius:cuisine:price
    data        JSONB NOT NULL,            -- []domain.Restaurant serialised
    cached_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_places_cache_cached_at ON places_cache(cached_at);
