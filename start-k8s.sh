#!/bin/bash

# Script de démarrage complet pour Kubernetes avec minikube
# Usage: ./start-k8s.sh

set -e

echo "🚀 Démarrage de l'application Bookly sur Kubernetes (minikube)..."
echo ""

# Étape 1: Démarrer minikube
echo "📦 Étape 1/6: Démarrage de minikube..."
if ! minikube status &> /dev/null; then
  echo "   Démarrage de minikube (cela peut prendre quelques minutes)..."
  minikube start
else
  echo "   ✅ Minikube est déjà démarré"
fi

# Afficher le statut
echo ""
minikube status
echo ""

# Étape 2: Activer les addons nécessaires
echo "📦 Étape 2/6: Activation des addons minikube..."
minikube addons enable ingress
minikube addons enable metrics-server
echo "   ✅ Addons activés"
echo ""

# Étape 3: Configurer Docker pour utiliser le daemon de minikube
echo "📦 Étape 3/6: Configuration de Docker pour minikube..."
eval $(minikube docker-env)
echo "   ✅ Docker configuré pour minikube"
echo ""

# Étape 4: Build des images Docker dans minikube
echo "📦 Étape 4/6: Construction des images Docker..."
echo "   Build de api-core..."
docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite
echo "   Build de api-books..."
docker build -t tpfront-back-api-books:latest ./bookly-hybrid
echo "   Build de frontend..."
docker build \
  --build-arg VITE_API_URL=http://api-core:3000 \
  --build-arg VITE_BOOKS_URL=http://api-books:4000 \
  -t tpfront-back-frontend:latest ./frontend-react-api
echo "   ✅ Images construites"
echo ""

# Étape 5: Déployer l'application
echo "📦 Étape 5/6: Déploiement de l'application..."
cd k8s

# Appliquer tous les manifestes avec Kustomize
echo "   Application des manifestes Kubernetes..."
kubectl apply -k .

# Modifier les Deployments pour utiliser imagePullPolicy: Never (pour minikube)
echo "   Configuration des Deployments pour minikube..."
kubectl patch deployment api-core -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-core","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment api-books -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-books","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment frontend -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","imagePullPolicy":"Never"}]}}}}'

cd ..
echo "   ✅ Manifestes appliqués"
echo ""

# Étape 6: Attendre que les pods soient prêts
echo "📦 Étape 6/6: Attente du démarrage des pods..."
echo "   (Cela peut prendre 1-2 minutes)"
sleep 10

# Vérifier le statut
echo ""
echo "📊 Statut des pods:"
kubectl get pods -n bookly-app

echo ""
echo "⏳ Attente que tous les pods soient prêts..."
kubectl wait --for=condition=ready pod --all -n bookly-app --timeout=300s || true

echo ""
echo "📊 Statut final:"
kubectl get pods -n bookly-app
echo ""

# Afficher les services et ingress
echo "📊 Services:"
kubectl get svc -n bookly-app
echo ""

echo "📊 Ingress:"
kubectl get ingress -n bookly-app
echo ""

# Obtenir l'IP de minikube
MINIKUBE_IP=$(minikube ip)
echo "✅ Application déployée !"
echo ""
echo "🌐 Accès à l'application:"
echo ""
echo "   Option 1: Port-forward (recommandé pour tests)"
echo "   kubectl port-forward svc/frontend 8080:80 -n bookly-app"
echo "   Puis ouvrir: http://localhost:8080"
echo ""
echo "   Option 2: Via Ingress (après configuration /etc/hosts)"
echo "   Ajouter dans /etc/hosts: $MINIKUBE_IP bookly.local"
echo "   Puis ouvrir: http://bookly.local"
echo ""
echo "📝 Commandes utiles:"
echo "   - Logs: kubectl logs -f deployment/api-core -n bookly-app"
echo "   - Redémarrer: kubectl rollout restart deployment/api-core -n bookly-app"
echo "   - Supprimer: kubectl delete namespace bookly-app"
echo "   - Arrêter minikube: minikube stop"
