# Fintech Microservices Makefile

# Variables
NAMESPACE := fintech-app
REGISTRY := fintech
TAG := latest
KUBECTL := kubectl
HELM := helm
MINIKUBE := minikube
DOCKER := docker

# Colors for prettier output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-30s$(NC) %s\n", $$1, $$2}'

.PHONY: install-dependencies
install-dependencies: ## Install all required dependencies
	@echo "$(GREEN)Installing Python dependencies...$(NC)"
	@pip install -r user-service/requirements.txt
	@pip install -r transaction-service/requirements.txt
	
	# @echo "$(GREEN)Installing kubectl...$(NC)"
	# @if ! command -v kubectl &> /dev/null; then \
	# 	curl -LO "https://dl.k8s.io/release/$(shell curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(shell uname -s | tr '[:upper:]' '[:lower:]')/$(shell uname -m)/kubectl"; \
	# 	chmod +x kubectl; \
	# 	sudo mv kubectl /usr/local/bin/; \
	# fi
	
	# @echo "$(GREEN)Installing Helm...$(NC)"
	# @if ! command -v helm &> /dev/null; then \
	# 	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3; \
	# 	chmod +x get_helm.sh; \
	# 	./get_helm.sh; \
	# 	rm get_helm.sh; \
	# fi
	
	# @echo "$(GREEN)Installing Minikube (for local development)...$(NC)"
	# @if ! command -v minikube &> /dev/null; then \
	# 	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-$(shell uname -s | tr '[:upper:]' '[:lower:]')-$(shell uname -m); \
	# 	sudo install minikube-$(shell uname -s | tr '[:upper:]' '[:lower:]')-$(shell uname -m) /usr/local/bin/minikube; \
	# 	rm minikube-$(shell uname -s | tr '[:upper:]' '[:lower:]')-$(shell uname -m); \
	# fi
	
	@echo "$(GREEN)All dependencies installed!$(NC)"

.PHONY: start-minikube
start-minikube: ## Start Minikube for local development
	@echo "$(GREEN)Starting Minikube...$(NC)"
	@$(MINIKUBE) start --memory=2096 --cpus=2
	@$(MINIKUBE) addons enable ingress
	@echo "$(GREEN)Minikube started successfully!$(NC)"

.PHONY: build-images
build-images: ## Build Docker images for microservices
	@echo "$(GREEN)Building User Service image...$(NC)"
	@$(DOCKER) build -t $(REGISTRY)/user-service:$(TAG) ./user-service/
	
	@echo "$(GREEN)Building Transaction Service image...$(NC)"
	@$(DOCKER) build -t $(REGISTRY)/transaction-service:$(TAG) ./transaction-service/
	
	@echo "$(GREEN)Docker images built successfully!$(NC)"

.PHONY: load-images-minikube
load-images-minikube: build-images ## Load Docker images into Minikube
	@echo "$(GREEN)Loading images into Minikube...$(NC)"
	@$(MINIKUBE) image load $(REGISTRY)/user-service:$(TAG)
	@$(MINIKUBE) image load $(REGISTRY)/transaction-service:$(TAG)
	@echo "$(GREEN)Images loaded successfully!$(NC)"

.PHONY: push-images
push-images: build-images ## Push Docker images to registry
	@echo "$(GREEN)Pushing User Service image...$(NC)"
	@$(DOCKER) push $(REGISTRY)/user-service:$(TAG)
	
	@echo "$(GREEN)Pushing Transaction Service image...$(NC)"
	@$(DOCKER) push $(REGISTRY)/transaction-service:$(TAG)
	
	@echo "$(GREEN)Docker images pushed successfully!$(NC)"

.PHONY: create-namespace
create-namespace: ## Create Kubernetes namespace
	@echo "$(GREEN)Creating namespace $(NAMESPACE)...$(NC)"
	@$(KUBECTL) create namespace $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "$(GREEN)Namespace $(NAMESPACE) created!$(NC)"

.PHONY: install-operators
install-operators: ## Install required Kubernetes operators
	@echo "$(GREEN)Cleaning up any existing KEDA installation...$(NC)"
	@-$(HELM) uninstall keda --namespace keda 2>/dev/null || true
	@-$(KUBECTL) delete namespace keda --wait=false 2>/dev/null || true
	@sleep 15  # Increased cleanup wait time
	
	@echo "$(GREEN)Installing KEDA operator...$(NC)"
	@$(HELM) repo add kedacore https://kedacore.github.io/charts --force-update
	@$(HELM) repo update
	
	@echo "$(GREEN)Installing KEDA with CRDs...$(NC)"
	@$(HELM) install keda kedacore/keda \
		--version 2.0.0 \
		--namespace keda \
		--create-namespace \
		--timeout 5m \
		--set watchNamespace=$(NAMESPACE) \
		--wait \
		--atomic || \
	(echo "$(RED)Failed to install KEDA. Cleaning up...$(NC)" && \
	$(HELM) uninstall keda --namespace keda 2>/dev/null && \
	$(KUBECTL) delete namespace keda --wait=false && \
	exit 1)
	
	@echo "$(GREEN)Verifying KEDA installation...$(NC)"
	@for i in {1..60}; do \
		if $(KUBECTL) get crd scaledobjects.keda.sh -o jsonpath='{.metadata.name}' >/dev/null 2>&1; then \
			echo "$(GREEN)KEDA CRDs are ready!$(NC)"; \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo "$(RED)Timeout waiting for KEDA CRDs$(NC)"; \
			exit 1; \
		fi; \
		echo "$(YELLOW)Waiting for KEDA CRDs... Attempt $$i/60$(NC)"; \
		sleep 5; \
	done

	@echo "$(GREEN)Cleaning up any existing APISIX installation...$(NC)"
	@-$(HELM) uninstall apisix-ingress --namespace $(NAMESPACE) 2>/dev/null || true
	@sleep 5  # Give time for cleanup

	@echo "$(GREEN)Installing APISIX operator and CRDs...$(NC)"
	@$(HELM) repo add apisix https://charts.apiseven.com
	@$(HELM) repo update
	@$(HELM) install apisix-ingress apisix/apisix-ingress-controller \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set image.tag=3.0.0 \
		--set config.apisix.serviceNamespace=$(NAMESPACE)

	@echo "$(GREEN)Waiting for APISIX CRDs to be ready...$(NC)"
	@for i in {1..30}; do \
		if $(KUBECTL) get crd apisixroutes.apisix.apache.org >/dev/null 2>&1; then \
			echo "$(GREEN)APISIX CRDs are ready!$(NC)"; \
			break; \
		fi; \
		if [ $$i -eq 30 ]; then \
			echo "$(RED)Timeout waiting for APISIX CRDs$(NC)"; \
			exit 1; \
		fi; \
		echo "$(YELLOW)Waiting for APISIX CRDs... Attempt $$i/30$(NC)"; \
		sleep 5; \
	done
	
	@echo "$(GREEN)Operators installed successfully!$(NC)"

.PHONY: deploy-db
deploy-db: create-namespace ## Deploy YugabyteDB
	@echo "$(GREEN)Deploying YugabyteDB...$(NC)"
	@$(KUBECTL) apply -f kubernetes/db-secret.yaml
	@$(KUBECTL) apply -f kubernetes/yugabytedb.yaml
	@echo "$(GREEN)YugabyteDB deployed successfully!$(NC)"

.PHONY: deploy-opa
deploy-opa: create-namespace ## Deploy Open Policy Agent
	@echo "$(GREEN)Deploying Open Policy Agent...$(NC)"
	@$(KUBECTL) apply -f kubernetes/policies/opa.yaml
	@echo "$(GREEN)Open Policy Agent deployed successfully!$(NC)"

.PHONY: deploy-services
deploy-services: create-namespace ## Deploy microservices
	@echo "$(GREEN)Deploying ConfigMap...$(NC)"
	@$(KUBECTL) apply -f kubernetes/configmap.yaml
	
	@echo "$(GREEN)Deploying User Service...$(NC)"
	@$(KUBECTL) apply -f kubernetes/user-service.yaml
	
	@echo "$(GREEN)Deploying Transaction Service...$(NC)"
	@$(KUBECTL) apply -f kubernetes/transaction-service.yaml
	
	@echo "$(GREEN)Services deployed successfully!$(NC)"

.PHONY: deploy-keda
deploy-keda: create-namespace ## Deploy KEDA scalers
	@echo "$(GREEN)Checking KEDA installation...$(NC)"
	@if ! $(KUBECTL) get crd scaledobjects.keda.sh -o jsonpath='{.metadata.name}' >/dev/null 2>&1; then \
		echo "$(RED)KEDA CRDs not found. Please run 'make install-operators' first$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)KEDA CRDs verified, deploying scalers...$(NC)"
	@$(KUBECTL) apply -f kubernetes/keda-scaler.yaml
	@echo "$(GREEN)KEDA scalers deployed successfully!$(NC)"

.PHONY: deploy-apisix
deploy-apisix: create-namespace ## Deploy APISIX gateway
	@echo "$(GREEN)Checking APISIX CRDs...$(NC)"
	@if ! $(KUBECTL) get crd apisixroutes.apisix.apache.org >/dev/null 2>&1; then \
		echo "$(RED)APISIX CRDs not found. Please run 'make install-operators' first$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Deploying APISIX gateway...$(NC)"
	@$(KUBECTL) apply -f kubernetes/apisix-deployment.yaml
	@$(KUBECTL) apply -f kubernetes/apisix.yaml || true
	@echo "$(GREEN)APISIX gateway deployed successfully!$(NC)"

.PHONY: deploy-observability
deploy-observability: create-namespace ## Deploy observability stack
	@echo "$(GREEN)Deploying OpenTelemetry Collector...$(NC)"
	@$(KUBECTL) apply -f kubernetes/observability.yaml
	
	@echo "$(GREEN)Deploying Jaeger...$(NC)"
	@$(HELM) repo add jaegertracing https://jaegertracing.github.io/helm-charts
	@$(HELM) repo update
	@$(HELM) install jaeger jaegertracing/jaeger \
		--namespace $(NAMESPACE) \
		--set collector.service.otlp.grpc.name=jaeger-collector \
		--set collector.service.otlp.grpc.port=14250
	
	@echo "$(GREEN)Deploying Prometheus...$(NC)"
	@$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@$(HELM) repo update
	@$(HELM) install prometheus prometheus-community/prometheus \
		--namespace $(NAMESPACE) \
		--set server.persistentVolume.enabled=false
	
	@echo "$(GREEN)Observability stack deployed successfully!$(NC)"

.PHONY: deploy-redis
deploy-redis: create-namespace ## Deploy Redis and transaction workers
	@echo "$(GREEN)Deploying Redis...$(NC)"
	@$(KUBECTL) apply -f kubernetes/observability.yaml
	@echo "$(GREEN)Redis and transaction workers deployed successfully!$(NC)"

.PHONY: deploy-all
deploy-all: deploy-db deploy-opa deploy-services deploy-keda deploy-apisix deploy-observability deploy-redis ## Deploy all components
	@echo "$(GREEN)All components deployed successfully!$(NC)"
	@echo "$(YELLOW)Run 'make port-forward' to access the services$(NC)"

.PHONY: deploy-helm
deploy-helm: ## Deploy using Helm chart
	@echo "$(GREEN)Deploying using Helm chart...$(NC)"
	@$(HELM) install fintech-app ./helm/fintech-app --namespace $(NAMESPACE) --create-namespace
	@echo "$(GREEN)Helm deployment completed successfully!$(NC)"

.PHONY: port-forward
port-forward: ## Forward ports for local access
	@echo "$(GREEN)Setting up port forwarding...$(NC)"
	@echo "$(YELLOW)APISIX API Gateway will be available at http://localhost:8080$(NC)"
	@$(KUBECTL) port-forward svc/apisix 8080:80 -n $(NAMESPACE)

.PHONY: logs-user-service
logs-user-service: ## View logs for User Service
	@$(KUBECTL) logs -f deployment/user-service -n $(NAMESPACE)

.PHONY: logs-transaction-service
logs-transaction-service: ## View logs for Transaction Service
	@$(KUBECTL) logs -f deployment/transaction-service -n $(NAMESPACE)

.PHONY: logs-worker
logs-worker: ## View logs for Transaction Worker
	@$(KUBECTL) logs -f deployment/transaction-worker -n $(NAMESPACE)

.PHONY: run-locally
run-locally: ## Run services locally for development
	@echo "$(GREEN)Starting User Service locally...$(NC)"
	@echo "$(YELLOW)User Service will be available at http://localhost:8000$(NC)"
	@cd user-service && python app.py &
	@echo "$(GREEN)Starting Transaction Service locally...$(NC)"
	@echo "$(YELLOW)Transaction Service will be available at http://localhost:8001$(NC)"
	@cd transaction-service && PORT=8001 python app.py &
	@echo "$(GREEN)Services started successfully!$(NC)"

.PHONY: stop-locally
stop-locally: ## Stop locally running services
	@echo "$(GREEN)Stopping locally running services...$(NC)"
	@-pkill -f "python app.py" || echo "No running services found"
	@echo "$(GREEN)Services stopped!$(NC)"

.PHONY: cleanup
cleanup: ## Remove all deployed resources
	@echo "$(RED)Cleaning up all resources...$(NC)"
	@-$(HELM) uninstall fintech-app -n $(NAMESPACE) 2>/dev/null || true
	@-$(KUBECTL) delete namespace $(NAMESPACE) 2>/dev/null || true
	@echo "$(GREEN)Cleanup completed!$(NC)"

.PHONY: test-create-user
test-create-user: ## Test creating a user
	@echo "$(GREEN)Creating a test user...$(NC)"
	@curl -X POST http://localhost:8080/api/users/ \
		-H "Content-Type: application/json" \
		-d '{"username":"testuser","email":"test@example.com","initial_balance":1000.0}'

.PHONY: test-create-transaction
test-create-transaction: ## Test creating a transaction
	@echo "$(GREEN)Creating a test transaction...$(NC)"
	@curl -X POST http://localhost:8080/api/transactions/ \
		-H "Content-Type: application/json" \
		-d '{"user_id":1,"amount":500.0,"transaction_type":"deposit","description":"Test deposit"}'

.PHONY: full-deploy
full-deploy: install-dependencies start-minikube load-images-minikube install-operators deploy-all ## Complete deployment from scratch
	@echo "$(GREEN)Full deployment completed successfully!$(NC)"
	@echo "$(YELLOW)Run 'make port-forward' to access the services$(NC)"