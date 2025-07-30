################################################################################
# GLOBALS
################################################################################

ENV_NAME        = sebastopol-bike-traffic-forecast
PYTHON_VERSION  = 3.10

# Ports
MLFLOW_PORT  = 5000
PREFECT_PORT = 4200
APP_PORT     = 8501


################################################################################
# ENV & QA
################################################################################
.PHONY: create_env requirements clean lint format test

create_env:  ## Conda env
	conda create --name $(ENV_NAME) python=$(PYTHON_VERSION) -y
	@echo ">>> Activate with: conda activate $(ENV_NAME)"

requirements: ## Install Python deps in active env
	python -m pip install --upgrade pip
	pip install -r requirements.txt

clean: ## Remove Python artifacts & caches
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	rm -rf .pytest_cache .ruff_cache .coverage tests/coverage.xml

mlflow-clean: ## Delete local mlruns directory
	rm -rf ./mlruns

lint:   ## Ruff lint
	ruff check . --fix

format: ## Ruff format
	ruff format .
	ruff check . --fix

test:   ## PyTest + coverage
	python -m pytest --cov=src --cov-config=tests/.coveragerc --cov-report=xml:tests/coverage.xml --cov-report=term

################################################################################
# LOCAL (sans Docker)
################################################################################
.PHONY: local-infra local-pipeline local-serve

local-infra:  ## Start MLflow & Prefect locally
	@echo "🚀  Launching MLflow & Prefect"; \
	python -m mlflow server --backend-store-uri ./mlruns --serve-artifacts --host 0.0.0.0 --port $(MLFLOW_PORT) & \
	python -m prefect server start --host 0.0.0.0 --port $(PREFECT_PORT) & \
	echo -n "⏳ Waiting for MLflow & Prefect"; \
	until curl -s http://localhost:$(MLFLOW_PORT)/ >/dev/null && curl -s http://localhost:$(PREFECT_PORT)/api/health >/dev/null; do printf "."; sleep 1; done; \
	echo " ✔ All services are up!"; \
	printf "\n👉 MLflow UI:   http://localhost:$(MLFLOW_PORT)\n"; \
	printf "👉 Prefect UI:  http://localhost:$(PREFECT_PORT)\n\n"

local-pipeline: ## Run pipeline locally (after local-infra)
	@echo "▶️  Launching pipeline …"
	@MLFLOW_TRACKING_URI=http://localhost:$(MLFLOW_PORT) \
	  PREFECT_API_URL=http://localhost:$(PREFECT_PORT)/api \
	  python -m src.run

local-serve:  ## Start Streamlit locally (after local-infra)
	@echo "🚀  Starting Streamlit" ; \
	python -m streamlit run app/app.py --server.address=0.0.0.0 --server.port=$(APP_PORT) & \
	echo -n "   Waiting for Streamlit" ; \
	until curl -s http://localhost:$(APP_PORT)/ >/dev/null 2>&1; do sleep 1; done ; \
	echo " ✔ Streamlit is up" ; \
	printf "\n👉 Streamlit: http://localhost:$(APP_PORT)\n\n" ; \
	wait

local-down: ## Stop all local services by port
	@echo "🛑  Killing processes on ports $(MLFLOW_PORT), $(PREFECT_PORT), $(APP_PORT)…"
	-@lsof -ti tcp:$(MLFLOW_PORT)  | xargs -r kill
	-@lsof -ti tcp:$(PREFECT_PORT) | xargs -r kill
	-@lsof -ti tcp:$(APP_PORT)     | xargs -r kill

################################################################################
# DOCKER
################################################################################
.PHONY: infra pipeline serve down

infra: ## Start MLflow & Prefect via Docker
	@echo "🚀  Launching MLflow & Prefect (Docker)"
	docker compose up -d mlflow prefect
	@echo -n "⏳ Waiting for MLflow & Prefect"
	@until curl -s http://localhost:$(MLFLOW_PORT)/ >/dev/null 2>&1 \
	  && curl -s http://localhost:$(PREFECT_PORT)/api/health >/dev/null 2>&1; do \
		echo -n "."; \
		sleep 1; \
	done
	@echo " ✔ All services are up!"
	@printf "\n👉 MLflow UI: http://localhost:$(MLFLOW_PORT)\n"
	@printf "👉 Prefect UI: http://localhost:$(PREFECT_PORT)\n\n"

pipeline: ## Run pipeline via Docker (after infra)
	@echo "▶️  Launching pipeline (Docker)"
	docker compose up -d pipeline
	@docker compose logs -f --tail=0 pipeline \
	  | sed -e 's#http://mlflow:5000#http://localhost:5000#g' \
	        -e 's#http://prefect:4200#http://localhost:4200#g'

serve: ## Start API & Streamlit via Docker (after pipeline)
	@echo "🚀  Starting Streamlit (Docker)"
	docker compose up -d app
	@printf "👉 Streamlit: http://localhost:$(APP_PORT)\n\n"

down: ## Stop & remove all Docker services & volumes
	docker compose down -v --remove-orphans

################################################################################
# HELP
################################################################################

.DEFAULT_GOAL := help

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
	  awk -F':|##' '{printf "\033[36m%-15s\033[0m %s\n", $$1, $$NF}'
