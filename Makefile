.PHONY: docker-build docker-run test clean

# Load versions from .docker/versions.env
include .docker/versions.env

# Build Docker image with versions from .docker/versions.env
docker-build:
	docker build \
		--build-arg DELTA_VER=$(DELTA_VER) \
		--build-arg DUST_VER=$(DUST_VER) \
		--build-arg PROCS_VER=$(PROCS_VER) \
		--build-arg DIRENV_VER=$(DIRENV_VER) \
		--build-arg FASTFETCH_VER=$(FASTFETCH_VER) \
		--build-arg GO_VER=$(GO_VER) \
		-f .docker/Dockerfile \
		-t zsh-config-test .

# Run the Docker image interactively
docker-run: docker-build
	docker run -it --rm zsh-config-test

# Run local tests without Docker
test:
	bash ./scripts/test.sh

# Clean up Docker image
clean:
	docker rmi zsh-config-test 2>/dev/null || true

# Show current versions
versions:
	@echo "Tool versions from .docker/versions.env:"
	@grep -v '^#' .docker/versions.env | grep -v '^$$'

.PHONY: help
help:
	@echo "zsh-config Makefile targets:"
	@echo "  make docker-build     Build Docker image with versions from .docker/versions.env"
	@echo "  make docker-run       Build and run Docker image interactively"
	@echo "  make test             Run local test suite"
	@echo "  make versions         Show current tool versions"
	@echo "  make clean            Remove Docker image"
	@echo "  make help             Show this help message"
