#!/bin/bash

# Script de démarrage automatique Kubernetes (détecte la meilleure option)
# Usage: ./start-k8s-auto.sh

set -e

echo "🚀 Démarrage automatique de l'application Bookly sur Kubernetes..."
echo ""

# Vérifier si kubectl est installé
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl n'est pas installé"
  echo "   Installez-le avec: brew install kubectl"
  exit 1
fi

# Vérifier si Docker est accessible
if ! docker ps &> /dev/null; then
  echo "❌ Docker n'est pas accessible"
  echo "   Veuillez démarrer Docker Desktop et réessayer"
  exit 1
fi

echo "✅ Docker est accessible"
echo ""

# Détecter le contexte Kubernetes disponible
KUBE_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")

if [ -n "$KUBE_CONTEXT" ]; then
  echo "✅ Contexte Kubernetes trouvé: $KUBE_CONTEXT"
  
  # Vérifier si le cluster est accessible
  if kubectl cluster-info &> /dev/null; then
    echo "✅ Cluster Kubernetes accessible"
    echo ""
    
    # Détecter le type de cluster
    if [[ "$KUBE_CONTEXT" == *"docker-desktop"* ]] || [[ "$KUBE_CONTEXT" == *"docker"* ]]; then
      echo "📦 Détection: Docker Desktop avec Kubernetes"
      echo ""
      
      # Builder les images avec le script intelligent
      if [ -f "./build-images.sh" ]; then
        ./build-images.sh
      else
        echo "📦 Construction des images Docker..."
        docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite || {
          echo "❌ Erreur: Rate limit Docker Hub"
          echo "   Solutions: docker login ou attendez 1-2h"
          exit 1
        }
        docker build -t tpfront-back-api-books:latest ./bookly-hybrid || {
          echo "❌ Erreur: Rate limit Docker Hub"
          exit 1
        }
        docker build \
          --build-arg VITE_API_URL=http://api-core:3000 \
          --build-arg VITE_BOOKS_URL=http://api-books:4000 \
          -t tpfront-back-frontend:latest ./frontend-react-api || {
          echo "❌ Erreur: Rate limit Docker Hub"
          exit 1
        }
      fi
      echo ""
      
      # Vérifier si ingress-nginx est installé
      if ! kubectl get namespace ingress-nginx &> /dev/null; then
        echo "📦 Installation de l'Ingress Controller..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
        echo "⏳ Attente que l'Ingress Controller soit prêt (cela peut prendre 1-2 minutes)..."
        # Attendre que le deployment soit prêt
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=180s || echo "⚠️  Timeout, mais continuons..."
        # Attendre un peu plus pour que le webhook soit prêt
        sleep 15
        echo "✅ Ingress Controller prêt"
      else
        echo "✅ Ingress Controller déjà installé"
      fi
      
      # Vérifier si metrics-server est installé
      if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        echo "📦 Installation de metrics-server..."
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
      fi
      
      # Déployer l'application (sans Ingress d'abord)
      echo "📦 Déploiement de l'application..."
      cd k8s
      
      # Appliquer tous les manifestes sauf l'Ingress
      kubectl apply -f namespace.yaml
      kubectl apply -f configmap.yaml
      kubectl apply -f configmap-postgres-init.yaml
      kubectl apply -f secret.yaml
      kubectl apply -f pvc-postgres.yaml
      kubectl apply -f pvc-mongo.yaml
      kubectl apply -f deployment-postgres.yaml
      kubectl apply -f deployment-mongo.yaml
      kubectl apply -f deployment-api-core.yaml
      kubectl apply -f deployment-api-books.yaml
      kubectl apply -f deployment-frontend.yaml
      kubectl apply -f service-postgres.yaml
      kubectl apply -f service-mongo.yaml
      kubectl apply -f service-api-core.yaml
      kubectl apply -f service-api-books.yaml
      kubectl apply -f service-frontend.yaml
      kubectl apply -f hpa-api-core.yaml
      kubectl apply -f hpa-api-books.yaml
      kubectl apply -f hpa-frontend.yaml
      
      # Appliquer l'Ingress en dernier (après que le webhook soit prêt)
      echo "📦 Création de l'Ingress..."
      if kubectl apply -f ingress.yaml; then
        echo "✅ Ingress créé"
      else
        echo "⚠️  Erreur lors de la création de l'Ingress (webhook pas encore prêt)"
        echo "   L'application fonctionne, mais l'Ingress sera créé plus tard"
        echo "   Vous pouvez le créer manuellement avec: kubectl apply -f k8s/ingress.yaml"
      fi
      
      # Configurer imagePullPolicy pour Docker Desktop
      kubectl patch deployment api-core -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-core","imagePullPolicy":"IfNotPresent"}]}}}}' 2>/dev/null || true
      kubectl patch deployment api-books -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-books","imagePullPolicy":"IfNotPresent"}]}}}}' 2>/dev/null || true
      kubectl patch deployment frontend -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","imagePullPolicy":"IfNotPresent"}]}}}}' 2>/dev/null || true
      
      cd ..
      
    elif [[ "$KUBE_CONTEXT" == *"minikube"* ]]; then
      echo "📦 Détection: Minikube"
      echo ""
      echo "   Utilisation du script start-k8s.sh..."
      ./start-k8s.sh
      exit 0
      
    elif [[ "$KUBE_CONTEXT" == *"kind"* ]]; then
      echo "📦 Détection: Kind"
      echo ""
      echo "   Chargement des images dans kind..."
      kind load docker-image tpfront-back-api-core:latest 2>/dev/null || true
      kind load docker-image tpfront-back-api-books:latest 2>/dev/null || true
      kind load docker-image tpfront-back-frontend:latest 2>/dev/null || true
      
      cd k8s
      kubectl apply -k .
      
      kubectl patch deployment api-core -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-core","imagePullPolicy":"Never"}]}}}}' 2>/dev/null || true
      kubectl patch deployment api-books -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-books","imagePullPolicy":"Never"}]}}}}' 2>/dev/null || true
      kubectl patch deployment frontend -n bookly-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","imagePullPolicy":"Never"}]}}}}' 2>/dev/null || true
      
      cd ..
    else
      echo "📦 Cluster Kubernetes détecté: $KUBE_CONTEXT"
      echo ""
      echo "   Déploiement standard..."
      cd k8s
      kubectl apply -k .
      cd ..
    fi
    
    echo ""
    echo "⏳ Attente du démarrage des pods..."
    sleep 10
    
    echo ""
    echo "📊 Statut des pods:"
    kubectl get pods -n bookly-app
    
    echo ""
    echo "✅ Application déployée !"
    echo ""
    echo "🌐 Accès à l'application:"
    echo "   kubectl port-forward svc/frontend 8080:80 -n bookly-app"
    echo "   Puis ouvrir: http://localhost:8080"
    
  else
    echo "❌ Le cluster Kubernetes n'est pas accessible"
    echo "   Vérifiez que le cluster est démarré"
    exit 1
  fi
  
else
  echo "❌ Aucun contexte Kubernetes configuré"
  echo ""
  echo "Options disponibles:"
  echo "1. Activer Kubernetes dans Docker Desktop (Settings → Kubernetes)"
  echo "2. Installer et démarrer minikube: brew install minikube && minikube start"
  echo "3. Installer kind: brew install kind && kind create cluster"
  echo ""
  echo "Voir LANCER-KUBERNETES.md pour plus de détails"
  exit 1
fi
