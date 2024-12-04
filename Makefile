# Terminal colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
BLUE   := $(shell tput -Txterm setaf 4)
RED    := $(shell tput -Txterm setaf 1)

# Python settings
PYTHON_VERSION = 3.13.0
VENV_PATH = .venv

# Help target
.PHONY: help
help: ## Show this help message
	@echo ''
	@echo '${YELLOW}FFmpeg-Python Development Guide${RESET}'
	@echo ''
	@echo '${YELLOW}Quick Start:${RESET}'
	@echo '  One-command setup:'
	@echo '  ${GREEN}make setup${RESET}   - Creates environment and installs all dependencies'
	@echo ''
	@echo '${YELLOW}Development Workflow:${RESET}'
	@echo '  1. ${GREEN}source .venv/bin/activate${RESET} - Activate virtual environment'
	@echo '  2. ${GREEN}make format${RESET}       - Format code before committing'
	@echo '  3. ${GREEN}make lint${RESET}         - Check code style'
	@echo '  4. ${GREEN}make typecheck${RESET}    - Run type checking'
	@echo '  5. ${GREEN}make test${RESET}         - Run tests with coverage'
	@echo '  6. ${GREEN}make check${RESET}        - Run all checks'
	@echo ''
	@echo '${YELLOW}Available Targets:${RESET}'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-15s${GREEN}%s${RESET}\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Create environment and install dependencies
	@echo "${BLUE}Setting up development environment...${RESET}"
	@echo "${BLUE}Using Python ${PYTHON_VERSION}${RESET}"
	pyenv local ${PYTHON_VERSION}
	uv venv
	. ${VENV_PATH}/bin/activate && uv pip install -e ".[dev]"
	@echo "${GREEN}Environment created and dependencies installed${RESET}"
	@echo "${YELLOW}To activate the environment:${RESET}"
	@echo "${GREEN}source ${VENV_PATH}/bin/activate${RESET}"
	@echo "${YELLOW}For PyCharm, set the interpreter to:${RESET}"
	@echo "${GREEN}$(PWD)/${VENV_PATH}/bin/python${RESET}"

.PHONY: install-dev
install-dev: ## Install package in development mode
	@echo "${BLUE}Installing package in development mode...${RESET}"
	uv pip install -e ".[dev]"

.PHONY: test
test: ## Run tests with coverage
	@echo "${BLUE}Running tests with coverage...${RESET}"
	pytest -v --cov=ffmpeg --cov-report=term-missing --cov-fail-under=90

.PHONY: test-fast
test-fast: ## Run tests without coverage
	@echo "${BLUE}Running tests (fast mode)...${RESET}"
	pytest -v

.PHONY: coverage-report
coverage-report: ## Generate HTML coverage report
	@echo "${BLUE}Generating coverage report...${RESET}"
	coverage html
	@echo "${GREEN}Report generated in htmlcov/index.html${RESET}"

.PHONY: lint
lint: ## Check style with ruff
	@echo "${BLUE}Linting code...${RESET}"
	ruff check .

.PHONY: format
format: ## Format code with ruff
	@echo "${BLUE}Formatting code...${RESET}"
	ruff format .

.PHONY: typecheck
typecheck: ## Run static type checking
	@echo "${BLUE}Running type checking...${RESET}"
	mypy ffmpeg
	@echo "${GREEN}Type checking passed!${RESET}"

.PHONY: check
check: format lint typecheck test ## Run all checks (format, lint, typecheck, test)
	@echo "${GREEN}All checks passed!${RESET}"

.PHONY: clean
clean: ## Remove all generated files
	@echo "${BLUE}Cleaning generated files...${RESET}"
	rm -rf .pytest_cache
	rm -rf .ruff_cache
	rm -rf .mypy_cache
	rm -rf .coverage
	rm -rf htmlcov
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	find . -type f -name ".coverage" -delete
	find . -type f -name "coverage.xml" -delete
	@echo "${GREEN}Clean complete!${RESET}"

.PHONY: docs
docs: ## Build documentation
	@echo "${BLUE}Building documentation...${RESET}"
	$(MAKE) -C doc html
	@echo "${GREEN}Documentation built in doc/html/${RESET}"

.PHONY: structure
structure: ## Show current project structure
	@echo "${YELLOW}Current Project Structure:${RESET}"
	@echo "${BLUE}"
	@if command -v tree > /dev/null; then \
		tree -a -I '.git|.venv|__pycache__|*.pyc|*.pyo|*.pyd|.pytest_cache|.ruff_cache|.coverage|htmlcov'; \
	else \
		echo "Note: Install 'tree' for better directory visualization:"; \
		echo "  macOS:     brew install tree"; \
		echo "  Ubuntu:    sudo apt-get install tree"; \
		echo "  Fedora:    sudo dnf install tree"; \
		echo ""; \
		find . -not -path '*/\.*' -not -path '*.pyc' -not -path '*/__pycache__/*' \
			-not -path './.venv/*' -not -path './build/*' -not -path './dist/*' \
			-not -path './*.egg-info/*' \
			| sort \
			| sed -e "s/[^-][^\/]*\// │   /g" -e "s/├── /│── /" -e "s/└── /└── /"; \
	fi
	@echo "${RESET}"

.PHONY: outdated
outdated: ## Show outdated packages
	@echo "${BLUE}Checking for outdated packages...${RESET}"
	. .venv/bin/activate && uv pip list --outdated

.DEFAULT_GOAL := help