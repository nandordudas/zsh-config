.PHONY: test help

# Run the test suite
test:
	bash ./scripts/test.sh

help:
	@echo "zsh-config Makefile targets:"
	@echo "  make test    Run the test suite"
	@echo "  make help    Show this help message"
