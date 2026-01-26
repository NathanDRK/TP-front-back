#!/bin/bash

# Script d'installation et démarrage Kubernetes
# Usage: ./install-and-start-k8s.sh

set -e

echo "🚀 Installation et démarrage de l'application Bookly sur Kubernetes..."
echo ""

# Vérifier si kubectl est installé
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl n'est pas installé"
  echo "   Installez-le avec: brew install kubectl (macOS)"
  exit 1
fi

# Vérifier si minikube est installé
if ! command -v minikube &> /dev/null; then
  echo "📦 Minikube n'est pas installé. Installation..."
  
  # Détecter l'OS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
      echo "   Installation via Homebrew..."
      brew install minikube
    else
      echo "❌ Homebrew n'est pas installé"
      echo "   Installez minikube manuellement: https://minikube.sigs.k8s.io/docs/start/"
      exit 1
    fi
  else
    echo "❌ Installation automatique non supportée pour cet OS"
    echo "   Installez minikube manuellement: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
  fi
fi

echo "✅ Minikube est installé"
echo ""

# Vérifier si Docker est accessible
if ! docker ps &> /dev/null; then
  echo "❌ Docker n'est pas accessible"
  echo "   Veuillez démarrer Docker Desktop et réessayer"
  exit 1
fi

echo "✅ Docker est accessible"
echo ""

# Maintenant lancer le script de démarrage
echo "🚀 Lancement du déploiement..."
./start-k8s.sh
