#!/bin/bash

# Solution rapide pour corriger l'erreur "Failed to fetch"
# Rebuild le frontend avec localhost et configure port-forward

set -e

echo "🔧 Correction rapide de l'erreur 'Failed to fetch'..."
echo ""

# 1. Rebuilder le frontend avec localhost
echo "📦 Rebuild du frontend avec localhost..."
docker build \
  --build-arg VITE_API_URL=http://localhost:3000 \
  --build-arg VITE_BOOKS_URL=http://localhost:4000 \
  -t tpfront-back-frontend:latest ./frontend-react-api

echo "✅ Frontend rebuildé"
echo ""

# 2. Redéployer le frontend
echo "🔄 Redéploiement du frontend..."
kubectl rollout restart deployment/frontend -n bookly-app
echo "⏳ Attente du redéploiement..."
kubectl rollout status deployment/frontend -n bookly-app --timeout=120s

echo ""
echo "✅ Frontend redéployé"
echo ""

# 3. Instructions pour port-forward
echo "🌐 Pour accéder à l'application:"
echo ""
echo "Ouvrez 3 terminaux et exécutez dans chacun:"
echo ""
echo "Terminal 1:"
echo "  kubectl port-forward svc/frontend 8080:80 -n bookly-app"
echo ""
echo "Terminal 2:"
echo "  kubectl port-forward svc/api-core 3000:3000 -n bookly-app"
echo ""
echo "Terminal 3:"
echo "  kubectl port-forward svc/api-books 4000:4000 -n bookly-app"
echo ""
echo "Puis ouvrez: http://localhost:8080"
echo ""
