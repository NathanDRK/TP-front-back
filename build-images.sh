#!/bin/bash

# Script de build intelligent avec gestion du rate limit
# Usage: ./build-images.sh

set -e

echo "🐳 Build des images Docker..."
echo ""

# Vérifier si Docker est accessible
if ! docker ps &> /dev/null; then
  echo "❌ Docker n'est pas accessible"
  exit 1
fi

# Fonction pour vérifier si une image existe
image_exists() {
  docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$1"
}

# Vérifier les images de base en cache
echo "🔍 Vérification des images de base..."
NODE_CACHED=false
NGINX_CACHED=false

if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "node:20-alpine"; then
  NODE_CACHED=true
  echo "✅ node:20-alpine trouvé en cache"
else
  echo "⚠️  node:20-alpine non trouvé en cache"
fi

if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "nginx:1.27-alpine"; then
  NGINX_CACHED=true
  echo "✅ nginx:1.27-alpine trouvé en cache"
else
  echo "⚠️  nginx:1.27-alpine non trouvé en cache"
fi

echo ""

# Vérifier si l'utilisateur est authentifié
AUTHENTICATED=false
if docker info 2>/dev/null | grep -q "Username"; then
  AUTHENTICATED=true
  echo "✅ Authentifié à Docker Hub (limite: 200 pulls/6h)"
else
  echo "⚠️  Non authentifié à Docker Hub (limite: 100 pulls/6h)"
  echo "   Pour augmenter la limite: docker login"
fi
echo ""

# Vérifier si les images de l'app sont déjà buildées
echo "🔍 Vérification des images de l'application..."
ALL_BUILT=true

if ! image_exists "tpfront-back-api-core:latest"; then
  ALL_BUILT=false
  echo "   ⚠️  tpfront-back-api-core:latest manquante"
fi

if ! image_exists "tpfront-back-api-books:latest"; then
  ALL_BUILT=false
  echo "   ⚠️  tpfront-back-api-books:latest manquante"
fi

if ! image_exists "tpfront-back-frontend:latest"; then
  ALL_BUILT=false
  echo "   ⚠️  tpfront-back-frontend:latest manquante"
fi

if [ "$ALL_BUILT" = true ]; then
  echo "✅ Toutes les images sont déjà buildées"
  echo ""
  docker images | grep tpfront-back
  exit 0
fi

echo ""

# Si les images de base ne sont pas en cache et non authentifié, avertir
if [ "$NODE_CACHED" = false ] && [ "$AUTHENTICATED" = false ]; then
  echo "⚠️  ATTENTION: Rate limit possible"
  echo ""
  echo "Options:"
  echo "1. S'authentifier: docker login (recommandé)"
  echo "2. Continuer et espérer que le cache fonctionne"
  echo "3. Attendre 1-2 heures pour que le rate limit se réinitialise"
  echo ""
  read -p "Continuer? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Arrêt. Authentifiez-vous avec 'docker login' puis relancez."
    exit 1
  fi
fi

# Build des images
echo "📦 Construction des images..."
echo ""

# API Core
if ! image_exists "tpfront-back-api-core:latest"; then
  echo "📦 Build de api-core..."
  if docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite; then
    echo "✅ api-core buildée"
  else
    echo "❌ Erreur lors du build de api-core"
    echo "   Cause probable: Rate limit Docker Hub"
    echo ""
    echo "Solutions:"
    echo "1. docker login (double la limite)"
    echo "2. Attendre 1-2 heures"
    echo "3. Utiliser: ./build-with-retry.sh"
    exit 1
  fi
else
  echo "✅ api-core déjà buildée"
fi

# API Books
if ! image_exists "tpfront-back-api-books:latest"; then
  echo "📦 Build de api-books..."
  if docker build -t tpfront-back-api-books:latest ./bookly-hybrid; then
    echo "✅ api-books buildée"
  else
    echo "❌ Erreur lors du build de api-books"
    echo "   Cause probable: Rate limit Docker Hub"
    exit 1
  fi
else
  echo "✅ api-books déjà buildée"
fi

# Frontend
if ! image_exists "tpfront-back-frontend:latest"; then
  echo "📦 Build de frontend..."
  if docker build \
    --build-arg VITE_API_URL=http://api-core:3000 \
    --build-arg VITE_BOOKS_URL=http://api-books:4000 \
    -t tpfront-back-frontend:latest ./frontend-react-api; then
    echo "✅ frontend buildée"
  else
    echo "❌ Erreur lors du build de frontend"
    echo "   Cause probable: Rate limit Docker Hub"
    exit 1
  fi
else
  echo "✅ frontend déjà buildée"
fi

echo ""
echo "✅ Toutes les images ont été construites avec succès !"
echo ""
echo "📋 Images disponibles:"
docker images | grep tpfront-back
