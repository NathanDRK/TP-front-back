# 🚀 Guide pour lancer le projet avec Kubernetes

## Option 1: Minikube (Recommandé)

### Installation de Minikube

**Sur macOS avec Homebrew:**
```bash
# Si vous avez des problèmes de permissions, exécutez d'abord:
sudo chown -R $(whoami) /opt/homebrew /Users/$(whoami)/Library/Caches/Homebrew /Users/$(whoami)/Library/Logs/Homebrew

# Puis installez minikube
brew install minikube
```

**Installation manuelle (tous OS):**
```bash
# Télécharger depuis: https://minikube.sigs.k8s.io/docs/start/
# Ou via curl:
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
```

### Démarrage

Une fois minikube installé:
```bash
cd "/Users/nathdrk/Documents/Dev/Projet/TP front-back"
./start-k8s.sh
```

---

## Option 2: Docker Desktop avec Kubernetes

### Activer Kubernetes dans Docker Desktop

1. Ouvrir Docker Desktop
2. Aller dans Settings → Kubernetes
3. Cocher "Enable Kubernetes"
4. Cliquer sur "Apply & Restart"

### Démarrage

```bash
cd "/Users/nathdrk/Documents/Dev/Projet/TP front-back"

# Configurer kubectl pour utiliser Docker Desktop
kubectl config use-context docker-desktop

# Builder les images (Docker Desktop utilise le daemon Docker normal)
docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite
docker build -t tpfront-back-api-books:latest ./bookly-hybrid
docker build \
  --build-arg VITE_API_URL=http://api-core:3000 \
  --build-arg VITE_BOOKS_URL=http://api-books:4000 \
  -t tpfront-back-frontend:latest ./frontend-react-api

# Charger les images dans Kubernetes (Docker Desktop)
# Note: Docker Desktop partage les images avec Kubernetes automatiquement

# Installer l'Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Installer metrics-server (pour HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Déployer l'application
cd k8s
kubectl apply -k .

# Configurer imagePullPolicy (Docker Desktop partage les images)
kubectl patch deployment api-core -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-core","imagePullPolicy":"IfNotPresent"}]}}}}'
kubectl patch deployment api-books -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-books","imagePullPolicy":"IfNotPresent"}]}}}}'
kubectl patch deployment frontend -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","imagePullPolicy":"IfNotPresent"}]}}}}'

# Vérifier
kubectl get pods -n bookly-app
```

---

## Option 3: Kind (Kubernetes in Docker)

### Installation

```bash
brew install kind
# Ou télécharger depuis: https://kind.sigs.k8s.io/docs/user/quick-start/
```

### Création du cluster et déploiement

```bash
cd "/Users/nathdrk/Documents/Dev/Projet/TP front-back"

# Créer un cluster kind
kind create cluster --name bookly

# Configurer kubectl
kubectl cluster-info --context kind-bookly

# Builder les images et les charger dans kind
docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite
docker build -t tpfront-back-api-books:latest ./bookly-hybrid
docker build \
  --build-arg VITE_API_URL=http://api-core:3000 \
  --build-arg VITE_BOOKS_URL=http://api-books:4000 \
  -t tpfront-back-frontend:latest ./frontend-react-api

# Charger les images dans kind
kind load docker-image tpfront-back-api-core:latest --name bookly
kind load docker-image tpfront-back-api-books:latest --name bookly
kind load docker-image tpfront-back-frontend:latest --name bookly

# Installer l'Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Installer metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Déployer l'application
cd k8s
kubectl apply -k .

# Configurer imagePullPolicy
kubectl patch deployment api-core -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-core","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment api-books -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-books","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment frontend -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","imagePullPolicy":"Never"}]}}}}'

# Vérifier
kubectl get pods -n bookly-app
```

---

## 🎯 Recommandation

**Pour débuter rapidement:** Utilisez **Docker Desktop avec Kubernetes** (Option 2)
- Pas d'installation supplémentaire
- Intégration native
- Facile à utiliser

**Pour un environnement plus proche de la production:** Utilisez **Minikube** (Option 1)
- Plus de contrôle
- Fonctionnalités complètes
- Bon pour apprendre

---

## ✅ Vérification après déploiement

```bash
# Voir tous les pods
kubectl get pods -n bookly-app

# Voir les services
kubectl get svc -n bookly-app

# Voir l'Ingress
kubectl get ingress -n bookly-app

# Accéder via port-forward
kubectl port-forward svc/frontend 8080:80 -n bookly-app
# Puis ouvrir: http://localhost:8080
```

---

## 🆘 Dépannage

### Les pods restent en "Pending"
- Vérifier les ressources disponibles: `kubectl describe node`
- Vérifier les événements: `kubectl get events -n bookly-app`

### Les pods crashent
- Voir les logs: `kubectl logs <pod-name> -n bookly-app`
- Décrire le pod: `kubectl describe pod <pod-name> -n bookly-app`

### Les images ne sont pas trouvées
- Vérifier que les images sont buildées: `docker images | grep tpfront-back`
- Vérifier imagePullPolicy dans les Deployments
- Pour minikube: `eval $(minikube docker-env)` puis rebuilder
