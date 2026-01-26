#!/bin/bash

# Script pour corriger les URLs du frontend pour Kubernetes
# Usage: ./fix-frontend-urls.sh [ingress|port-forward]

set -e

METHOD=${1:-ingress}

echo "🔧 Correction des URLs du frontend pour Kubernetes..."
echo ""

if [ "$METHOD" = "ingress" ]; then
  echo "📦 Méthode: Ingress (recommandé)"
  echo ""
  
  # Obtenir l'IP de l'Ingress
  INGRESS_IP=$(kubectl get ingress -n bookly-app bookly-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  
  if [ -z "$INGRESS_IP" ]; then
    # Pour Docker Desktop, utiliser localhost
    INGRESS_IP="localhost"
    echo "⚠️  IP Ingress non trouvée, utilisation de localhost"
  fi
  
  echo "🌐 URLs Ingress détectées:"
  echo "   Frontend: http://$INGRESS_IP (ou http://bookly.local si configuré)"
  echo "   API Core: http://$INGRESS_IP/api/core"
  echo "   API Books: http://$INGRESS_IP/api/books"
  echo ""
  
  # Le problème: le client API ajoute le path, donc /api/core/api/users devient /api/core/api/users
  # Il faut rebuilder le frontend avec les bonnes URLs
  
  echo "📦 Rebuild du frontend avec les URLs Ingress..."
  docker build \
    --build-arg VITE_API_URL=http://$INGRESS_IP/api/core \
    --build-arg VITE_BOOKS_URL=http://$INGRESS_IP/api/books \
    -t tpfront-back-frontend:latest ./frontend-react-api
  
  echo "✅ Frontend rebuildé"
  echo ""
  echo "🔄 Redéploiement du frontend..."
  kubectl rollout restart deployment/frontend -n bookly-app
  kubectl rollout status deployment/frontend -n bookly-app --timeout=120s
  
  echo ""
  echo "✅ Frontend redéployé avec les nouvelles URLs"
  echo ""
  echo "🌐 Accès:"
  echo "   Si vous avez configuré /etc/hosts: http://bookly.local"
  echo "   Sinon, utilisez port-forward: kubectl port-forward svc/frontend 8080:80 -n bookly-app"
  
elif [ "$METHOD" = "port-forward" ]; then
  echo "📦 Méthode: Port-forward (pour tests rapides)"
  echo ""
  echo "Cette méthode expose les services directement sur localhost"
  echo ""
  echo "📦 Rebuild du frontend avec localhost..."
  docker build \
    --build-arg VITE_API_URL=http://localhost:3000 \
    --build-arg VITE_BOOKS_URL=http://localhost:4000 \
    -t tpfront-back-frontend:latest ./frontend-react-api
  
  echo "✅ Frontend rebuildé"
  echo ""
  echo "🔄 Redéploiement du frontend..."
  kubectl rollout restart deployment/frontend -n bookly-app
  kubectl rollout status deployment/frontend -n bookly-app --timeout=120s
  
  echo ""
  echo "✅ Frontend redéployé"
  echo ""
  echo "🌐 Pour accéder à l'application, ouvrez 3 terminaux:"
  echo ""
  echo "Terminal 1 (Frontend):"
  echo "  kubectl port-forward svc/frontend 8080:80 -n bookly-app"
  echo ""
  echo "Terminal 2 (API Core):"
  echo "  kubectl port-forward svc/api-core 3000:3000 -n bookly-app"
  echo ""
  echo "Terminal 3 (API Books):"
  echo "  kubectl port-forward svc/api-books 4000:4000 -n bookly-app"
  echo ""
  echo "Puis ouvrir: http://localhost:8080"
  
else
  echo "Usage: $0 [ingress|port-forward]"
  exit 1
fi
