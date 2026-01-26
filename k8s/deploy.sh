#!/bin/bash

# Script de déploiement Kubernetes pour l'application Bookly
# Usage: ./deploy.sh [apply|delete]

set -e

ACTION=${1:-apply}

if [ "$ACTION" = "apply" ]; then
  echo "🚀 Déploiement de l'application Bookly sur Kubernetes..."
  
  # Vérifier que kubectl est configuré
  if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Erreur: kubectl n'est pas configuré ou le cluster n'est pas accessible"
    exit 1
  fi
  
  # Appliquer tous les manifestes
  kubectl apply -k .
  
  echo "✅ Déploiement terminé !"
  echo ""
  echo "📊 Vérification du statut :"
  kubectl get pods -n bookly-app
  echo ""
  echo "🌐 Pour accéder à l'application :"
  echo "   - Ingress: kubectl get ingress -n bookly-app"
  echo "   - Port-forward: kubectl port-forward svc/frontend 8080:80 -n bookly-app"
  
elif [ "$ACTION" = "delete" ]; then
  echo "🗑️  Suppression de l'application Bookly..."
  kubectl delete -k .
  echo "✅ Suppression terminée"
  
else
  echo "Usage: $0 [apply|delete]"
  exit 1
fi
