# ==============================================================================
# Docker Image Configuration
# ==============================================================================
DOCKER_USERNAME   ?= tdksoft341
IMAGE_NAME        ?= tdk-banking-app
IMAGE_TAG         ?= v1.0.0
IMAGE_FULL        := $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)

# Nom du service web défini dans docker-compose.yml
WEB_SERVICE := web

# ==============================================================================
# Color Definitions
# ==============================================================================
GREEN             := \033[0;32m
RED               := \033[0;31m
YELLOW            := \033[0;33m
BLUE              := \033[0;34m
NC                := \033[0m

# ==============================================================================
# PHONY Targets Declaration
# ==============================================================================
.PHONY: help image-build image-debug-build docker-login image-push image-run \
		up build migrate createsuperuser down clean all run test collectstatic

# ==============================================================================
# Help Target
# ==============================================================================
help: ## Display this help message
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# ------------------------------------------------------------------------------
# 🚀 Développement Local (sans Docker)
# ------------------------------------------------------------------------------

run: ## Lance l'application en mode développement local
	@echo "$(BLUE)🚀 Starting bankingsystem on port 8000...$(NC)"
	cd src && python manage.py runserver 8000

test: ## Execute les tests
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	cd src && python manage.py test

collectstatic: ## Collecte les fichiers statiques
	@echo "$(BLUE)📦 Collecting static files...$(NC)"
	cd src && python manage.py collectstatic --noinput

migrate-local: ## Applique les migrations en local
	@echo "$(BLUE)🛠️ Applying migrations...$(NC)"
	cd src && python manage.py migrate

createsuperuser-local: ## Crée un superutilisateur en local
	@echo "$(BLUE)👤 Creating superuser...$(NC)"
	cd src && python manage.py createsuperuser

# ------------------------------------------------------------------------------
# 📦 Docker Compose Targets (Développement Local avec Docker)
# ------------------------------------------------------------------------------

# Construit l'image de l'application web via Docker Compose.
build:
	@echo "$(BLUE)🏗️ Construction de l'image Docker pour Compose...$(NC)"
	docker compose build $(WEB_SERVICE)

# Démarre tous les services en mode détaché (dépend de 'build' si l'image n'existe pas).
up: build ## Build l'image et démarre les conteneurs (web, redis, celery)
	@echo "$(BLUE)🚀 Démarrage des services...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✅ Services démarrés:"
	@echo "   - Web: http://localhost:8000"
	@echo "   - Redis: localhost:6379"
	@echo "   - Celery worker: running"
	@echo "   - Celery beat: running$(NC)"

# Exécute les migrations de la base de données.
migrate: up ## Applique les migrations Django
	@echo "$(BLUE)🛠️ Application des migrations de base de données...$(NC)"
	docker compose exec $(WEB_SERVICE) python manage.py migrate

# Collecte les fichiers statiques dans le conteneur
collectstatic-docker: up ## Collecte les fichiers statiques dans Docker
	@echo "$(BLUE)📦 Collecting static files in container...$(NC)"
	docker compose exec $(WEB_SERVICE) python manage.py collectstatic --noinput

# Crée un super-utilisateur Django (interactif).
createsuperuser: up ## Crée un super-utilisateur (interactif)
	@echo "$(BLUE)👤 Création du super-utilisateur (suivez les invites)...$(NC)"
	docker compose exec $(WEB_SERVICE) python manage.py createsuperuser

# Affiche les logs des services
logs: ## Affiche les logs des services
	@echo "$(BLUE)📋 Affichage des logs...$(NC)"
	docker compose logs -f

# Arrête et supprime les conteneurs (garde les données).
down: ## Arrête et supprime les conteneurs
	@echo "$(YELLOW)🛑 Arrêt des services...$(NC)"
	docker compose down

# Arrête les services et supprime les volumes (réinitialisation complète).
clean: down ## Nettoyage complet (supprime les conteneurs ET les volumes de données)
	@echo "$(YELLOW)🧹 Suppression des volumes de données...$(NC)"
	docker compose down -v
	@echo "$(YELLOW)🗑️  Nettoyage des images unused...$(NC)"
	docker image prune -f

# Target pour le setup initial complet.
all: up migrate collectstatic-docker createsuperuser ## Setup initial complet (build, up, migrate, collectstatic, createsuperuser)
	@echo "$(GREEN)✨ Configuration initiale complète. Votre application est accessible sur http://localhost:8000$(NC)"

# ------------------------------------------------------------------------------
# 🔧 Utilitaires Docker Compose
# ------------------------------------------------------------------------------

shell: up ## Ouvre un shell dans le conteneur web
	@echo "$(BLUE)🐚 Ouverture d'un shell dans le conteneur...$(NC)"
	docker compose exec $(WEB_SERVICE) /bin/bash

db-shell: up ## Ouvre un shell SQLite dans le conteneur
	@echo "$(BLUE)🗄️  Ouverture d'un shell SQLite...$(NC)"
	docker compose exec $(WEB_SERVICE) sqlite3 /app/db.sqlite3

celery-logs: ## Affiche les logs de Celery
	@echo "$(BLUE)📋 Affichage des logs Celery...$(NC)"
	docker compose logs -f celery

# ------------------------------------------------------------------------------
# ☁️ Docker Hub/Image Management Targets (Production/CI)
# ------------------------------------------------------------------------------

image-build: ## Build l'image pour le push/run direct (utilise IMAGE_FULL)
	@echo "$(GREEN)🏗️ Building final image: $(IMAGE_FULL)$(NC)"
	docker build -t $(IMAGE_FULL) .

image-debug-build: ## Build l'image avec sortie détaillée
	@echo "$(GREEN)🐛 Debug build...$(NC)"
	docker build --progress=plain --no-cache -t $(IMAGE_FULL) .

docker-login: ## Login à Docker Hub
	@echo "$(GREEN)🔐 Logging in to Docker Hub...$(NC)"
	@if [ -z "$$DOCKERHUB_TOKEN" ]; then \
		echo "$(RED)❌ Error: DOCKERHUB_TOKEN environment variable is not set$(NC)"; \
		echo "$(YELLOW)💡 Tip: Run 'export DOCKERHUB_TOKEN=your_token' first$(NC)"; \
		exit 1; \
	fi
	@echo "$$DOCKERHUB_TOKEN" | docker login -u "$(DOCKER_USERNAME)" --password-stdin

image-push: image-build ## Build et push l'image vers Docker Hub
	@echo "$(GREEN)📤 Pushing Docker image: $(IMAGE_FULL)$(NC)"
	docker push $(IMAGE_FULL)

image-run: image-build ## Lance le conteneur seul (sans compose/base de données)
	@echo "$(GREEN)🎯 Starting $(IMAGE_NAME) on port 8000 (standalone)...$(NC)"
	@echo "$(YELLOW)⚠️  Note: Running without database - for testing only$(NC)"
	docker run --rm -p 8000:8000 $(IMAGE_FULL)

# ------------------------------------------------------------------------------
# 🧹 Nettoyage
# ------------------------------------------------------------------------------

prune: ## Nettoyage Docker complet (images, conteneurs, volumes)
	@echo "$(YELLOW)🧹 Nettoyage Docker complet...$(NC)"
	docker system prune -f
	docker volume prune -f

status: ## Affiche le statut des conteneurs
	@echo "$(BLUE)📊 Statut des services:$(NC)"
	docker compose ps

# ------------------------------------------------------------------------------
# 🚀 Déploiement Rapide
# ------------------------------------------------------------------------------

quick-deploy: image-build image-push ## Build et déploie rapidement l'image
	@echo "$(GREEN)⚡ Déploiement rapide terminé: $(IMAGE_FULL)$(NC)"
	@echo "$(GREEN)📦 Image disponible sur Docker Hub$(NC)"

# ------------------------------------------------------------------------------
# 🔧 Réparation des permissions
# ------------------------------------------------------------------------------

fix-permissions: ## Répare les permissions de la base de données
	@echo "$(YELLOW)🔧 Réparation des permissions...$(NC)"
	@if [ -f "./src/db.sqlite3" ]; then \
		chmod 666 ./src/db.sqlite3; \
		echo "$(GREEN)✅ Permissions de db.sqlite3 réparées$(NC)"; \
	else \
		echo "$(YELLOW)ℹ️  Aucune base de données trouvée$(NC)"; \
	fi

reset-db: clean ## Réinitialise complètement la base de données
	@echo "$(YELLOW)🗑️  Réinitialisation de la base de données...$(NC)"
	@if [ -f "./src/db.sqlite3" ]; then \
		rm -f ./src/db.sqlite3; \
		echo "$(GREEN)✅ Base de données supprimée$(NC)"; \
	fi
	@mkdir -p ./data
	@echo "$(GREEN)✅ Dossier data créé$(NC)"

# Mettez à jour la cible 'all' pour inclure la réparation des permissions
all: fix-permissions up migrate collectstatic-docker createsuperuser ## Setup initial complet
	@echo "$(GREEN)✨ Configuration initiale complète. Votre application est accessible sur http://localhost:8000$(NC)"



# ==============================================================================
# ==============================================================================
# Kubernetes Targets
# ==============================================================================
K8S_NAMESPACE ?= banking-app
K8S_DIR ?= k8s

# ------------------------------------------------------------------------------
# ☸️ Kubernetes Deployment
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ☸️ Kubernetes Deployment
# ------------------------------------------------------------------------------

k8s-deploy: k8s-push-image k8s-apply ## Déploie sur Kubernetes (build, push, apply)

k8s-push-image: image-push ## Push l'image pour Kubernetes
	@echo "$(GREEN)📦 Image pushed to registry, ready for Kubernetes$(NC)"

k8s-apply: ## Applique la configuration Kubernetes
	@echo "$(BLUE)☸️ Applying Kubernetes configuration...$(NC)"
	kubectl apply -f $(K8S_DIR)/namespace.yaml
	kubectl apply -f $(K8S_DIR)/configmap.yaml
	kubectl apply -f $(K8S_DIR)/secret.yaml
	kubectl apply -f $(K8S_DIR)/deployment.yaml
	kubectl apply -f $(K8S_DIR)/service.yaml
	kubectl apply -f $(K8S_DIR)/celery/
	kubectl apply -f $(K8S_DIR)/ingress.yaml
	@echo "$(GREEN)✅ Kubernetes configuration applied$(NC)"

k8s-wait: ## Attend que les pods soient prêts
	@echo "$(BLUE)⏳ Waiting for pods to be ready...$(NC)"
	@echo "$(YELLOW)Waiting for banking-app pods...$(NC)"
	kubectl wait --for=condition=ready pod -l app=banking-app -n $(K8S_NAMESPACE) --timeout=300s
	@echo "$(YELLOW)Waiting for redis pod...$(NC)"
	kubectl wait --for=condition=ready pod -l app=redis -n $(K8S_NAMESPACE) --timeout=180s
	@echo "$(YELLOW)Waiting for celery pods...$(NC)"
	kubectl wait --for=condition=ready pod -l app=celery-worker -n $(K8S_NAMESPACE) --timeout=180s
	kubectl wait --for=condition=ready pod -l app=celery-beat -n $(K8S_NAMESPACE) --timeout=180s
	@echo "$(GREEN)✅ All pods are ready$(NC)"

k8s-delete: ## Supprime le déploiement Kubernetes
	@echo "$(YELLOW)🗑️ Deleting Kubernetes resources...$(NC)"
	kubectl delete -f $(K8S_DIR)/ingress.yaml --ignore-not-found=true
	kubectl delete -f $(K8S_DIR)/celery/ --ignore-not-found=true
	kubectl delete -f $(K8S_DIR)/service.yaml --ignore-not-found=true
	kubectl delete -f $(K8S_DIR)/deployment.yaml --ignore-not-found=true
	kubectl delete -f $(K8S_DIR)/secret.yaml --ignore-not-found=true
	kubectl delete -f $(K8S_DIR)/configmap.yaml --ignore-not-found=true
	kubectl delete -f $(K8S_DIR)/namespace.yaml --ignore-not-found=true

k8s-logs: ## Affiche les logs de l'application
	@echo "$(BLUE)📋 Application logs:$(NC)"
	@POD_NAME=$$(kubectl get pods -n $(K8S_NAMESPACE) -l app=banking-app -o jsonpath='{.items[0].metadata.name}') && \
	kubectl logs -n $(K8S_NAMESPACE) $$POD_NAME -f

k8s-status: ## Affiche le statut du déploiement
	@echo "$(BLUE)📊 Kubernetes status:$(NC)"
	kubectl get pods,svc,ing -n $(K8S_NAMESPACE)

k8s-migrate: k8s-wait ## Exécute les migrations Django dans Kubernetes
	@echo "$(BLUE)🛠️ Running migrations in Kubernetes...$(NC)"
	@POD_NAME=$$(kubectl get pods -n $(K8S_NAMESPACE) -l app=banking-app -o jsonpath='{.items[0].metadata.name}') && \
	kubectl exec -n $(K8S_NAMESPACE) $$POD_NAME -- python manage.py migrate

k8s-collectstatic: k8s-wait ## Collecte les fichiers statiques dans Kubernetes
	@echo "$(BLUE)📦 Collecting static files in Kubernetes...$(NC)"
	@POD_NAME=$$(kubectl get pods -n $(K8S_NAMESPACE) -l app=banking-app -o jsonpath='{.items[0].metadata.name}') && \
	kubectl exec -n $(K8S_NAMESPACE) $$POD_NAME -- python manage.py collectstatic --noinput

k8s-createsuperuser: k8s-wait ## Crée un superuser dans Kubernetes
	@echo "$(BLUE)👤 Creating superuser in Kubernetes...$(NC)"
	@POD_NAME=$$(kubectl get pods -n $(K8S_NAMESPACE) -l app=banking-app -o jsonpath='{.items[0].metadata.name}') && \
	kubectl exec -n $(K8S_NAMESPACE) $$POD_NAME -it -- python manage.py createsuperuser

k8s-shell: k8s-wait ## Ouvre un shell dans le pod
	@echo "$(BLUE)🐚 Opening shell in pod...$(NC)"
	@POD_NAME=$$(kubectl get pods -n $(K8S_NAMESPACE) -l app=banking-app -o jsonpath='{.items[0].metadata.name}') && \
	kubectl exec -n $(K8S_NAMESPACE) $$POD_NAME -it -- /bin/bash

k8s-full-deploy: k8s-deploy k8s-wait k8s-migrate k8s-collectstatic ## Déploiement complet sur Kubernetes
	@echo "$(GREEN)✨ Kubernetes deployment complete!$(NC)"
	@make k8s-status


# ------------------------------------------------------------------------------
# 🔧 Kubernetes Repair Targets
# ------------------------------------------------------------------------------

k8s-clean-restart: ## Nettoie et redémarre tous les pods
	@echo "$(YELLOW)🧹 Cleaning and restarting all pods...$(NC)"
	kubectl delete pods -n $(K8S_NAMESPACE) --all
	@sleep 20
	@make k8s-status

k8s-fix-allowed-hosts: ## Corrige le problème ALLOWED_HOSTS
	@echo "$(BLUE)🔧 Fixing ALLOWED_HOSTS issue...$(NC)"
	kubectl apply -f $(K8S_DIR)/configmap.yaml
	kubectl rollout restart deployment -n $(K8S_NAMESPACE) banking-app
	kubectl rollout restart deployment -n $(K8S_NAMESPACE) celery-worker
	kubectl rollout restart deployment -n $(K8S_NAMESPACE) celery-beat
	@sleep 30
	@make k8s-status
	

k8s-test-health: ## Teste le health check de l'application
	@echo "$(BLUE)🏥 Testing application health...$(NC)"
	@POD_NAME=$$(kubectl get pods -n $(K8S_NAMESPACE) -l app=banking-app -o jsonpath='{.items[0].metadata.name}' --field-selector=status.phase=Running 2>/dev/null) && \
	if [ -n "$$POD_NAME" ]; then \
		echo "Testing health check internally..."; \
		kubectl exec -n $(K8S_NAMESPACE) $$POD_NAME -- curl -s http://localhost:8000/health-check/; \
		echo ""; \
		echo "Testing health check externally..."; \
		kubectl port-forward -n $(K8S_NAMESPACE) svc/banking-app-service 8080:8000 > /dev/null 2>&1 & \
		sleep 3; \
		curl -s http://localhost:8080/health-check/; \
		echo ""; \
		pkill -f "kubectl port-forward"; \
	else \
		echo "$(RED)❌ No running banking-app pods found$(NC)"; \
	fi

k8s-complete-fix: k8s-fix-allowed-hosts k8s-clean-restart k8s-test-health ## Correction complète du déploiement
	@echo "$(GREEN)✅ Complete fix applied$(NC)"