# Guide de démarrage rapide

## 🐳 Option 1: Docker Compose (Recommandé pour débuter)

### Prérequis
- Docker Desktop installé et démarré

### Démarrage
```bash
cd "/Users/nathdrk/Documents/Dev/Projet/TP front-back"
./start.sh
```

Ou manuellement :
```bash
docker compose build
docker compose up -d
```

### Accès
- Frontend: http://localhost:8080
- API Core: http://localhost:3000/api/...
- API Books: http://localhost:4000/api/...

---

## ☸️ Option 2: Kubernetes avec Minikube

### Prérequis
- Minikube installé
- kubectl installé
- Docker Desktop installé

### Démarrage automatique (recommandé)
```bash
cd "/Users/nathdrk/Documents/Dev/Projet/TP front-back"
./start-k8s.sh
```

Ce script va :
1. ✅ Démarrer minikube
2. ✅ Activer ingress et metrics-server
3. ✅ Configurer Docker pour minikube
4. ✅ Builder les images Docker
5. ✅ Déployer l'application
6. ✅ Afficher les URLs d'accès

### Démarrage manuel (étape par étape)

```bash
# 1. Démarrer minikube
minikube start

# 2. Activer les addons
minikube addons enable ingress
minikube addons enable metrics-server

# 3. Configurer Docker pour minikube
eval $(minikube docker-env)

# 4. Builder les images
docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite
docker build -t tpfront-back-api-books:latest ./bookly-hybrid
docker build \
  --build-arg VITE_API_URL=http://api-core:3000 \
  --build-arg VITE_BOOKS_URL=http://api-books:4000 \
  -t tpfront-back-frontend:latest ./frontend-react-api

# 5. Déployer l'application
cd k8s
kubectl apply -k .

# 6. Configurer imagePullPolicy pour minikube
kubectl patch deployment api-core -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-core","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment api-books -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-books","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment frontend -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","imagePullPolicy":"Never"}]}}}}'

# 7. Attendre que les pods soient prêts
kubectl wait --for=condition=ready pod --all -n bookly-app --timeout=300s

# 8. Vérifier le statut
kubectl get pods -n bookly-app
```

### Accès à l'application

**Option 1: Port-forward (recommandé pour tests)**
```bash
kubectl port-forward svc/frontend 8080:80 -n bookly-app
```
Puis ouvrir: http://localhost:8080

**Option 2: Via Ingress**
```bash
# Obtenir l'IP de minikube
minikube ip

# Ajouter dans /etc/hosts (macOS/Linux)
echo "$(minikube ip) bookly.local" | sudo tee -a /etc/hosts

# Ouvrir dans le navigateur
open http://bookly.local
```

### Commandes utiles

```bash
# Voir les logs
kubectl logs -f deployment/api-core -n bookly-app

# Redémarrer un service
kubectl rollout restart deployment/api-core -n bookly-app

# Voir les métriques HPA
kubectl get hpa -n bookly-app

# Supprimer l'application
kubectl delete namespace bookly-app

# Arrêter minikube
minikube stop
```

---

## 🔧 Dépannage

### Docker n'est pas accessible
- Vérifier que Docker Desktop est démarré
- Redémarrer Docker Desktop si nécessaire

### Minikube ne démarre pas
```bash
# Vérifier l'état
minikube status

# Supprimer et recréer si nécessaire
minikube delete
minikube start
```

### Les pods ne démarrent pas
```bash
# Voir les événements
kubectl get events -n bookly-app --sort-by='.lastTimestamp'

# Décrire un pod pour voir les erreurs
kubectl describe pod <pod-name> -n bookly-app

# Voir les logs
kubectl logs <pod-name> -n bookly-app
```

### Les images ne sont pas trouvées
- Vérifier que Docker est configuré pour minikube: `eval $(minikube docker-env)`
- Rebuilder les images après avoir configuré Docker
- Vérifier que `imagePullPolicy: Never` est configuré dans les Deployments

---

## 📚 Documentation complète

- **Docker Compose**: Voir `README.md` à la racine
- **Kubernetes**: Voir `k8s/README.md` pour la documentation complète
