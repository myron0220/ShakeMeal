.PHONY: run build test migrate migrate-down docker-up docker-down tidy

# ── Local dev ────────────────────────────────────────────────────────────────

run:
	go run ./cmd/server

build:
	go build -o bin/shakemeal ./cmd/server

test:
	go test ./... -v

tidy:
	go mod tidy

# ── Database migrations (requires migrate CLI) ───────────────────────────────
# Install: brew install golang-migrate

migrate:
	migrate -path ./migrations -database "$$DATABASE_URL" up

migrate-down:
	migrate -path ./migrations -database "$$DATABASE_URL" down 1

migrate-reset:
	migrate -path ./migrations -database "$$DATABASE_URL" drop -f

# ── Docker ───────────────────────────────────────────────────────────────────

docker-up:
	docker-compose -f docker/docker-compose.yml up --build

docker-down:
	docker-compose -f docker/docker-compose.yml down

docker-db:
	docker-compose -f docker/docker-compose.yml up postgres
