#!/bin/bash

# Script de build avec gestion du rate limit Docker Hub
# Usage: ./build-with-retry.sh

set -e

echo "🐳 Build des images Docker avec gestion du rate limit..."
echo ""

# Fonction pour vérifier si une image existe localement
check_local_image() {
  docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$1"
}

# Fonction pour build avec retry
build_with_retry() {
  local context=$1
  local image_name=$2
  local build_args=$3
  local max_retries=3
  local retry_count=0
  
  while [ $retry_count -lt $max_retries ]; do
    echo "📦 Build de $image_name (tentative $((retry_count + 1))/$max_retries)..."
    
    if [ -n "$build_args" ]; then
      docker build $build_args -t "$image_name" "$context" && return 0
    else
      docker build -t "$image_name" "$context" && return 0
    fi
    
    if [ $? -ne 0 ]; then
      retry_count=$((retry_count + 1))
      if [ $retry_count -lt $max_retries ]; then
        echo "⏳ Rate limit atteint. Attente de 60 secondes avant de réessayer..."
        sleep 60
      fi
    fi
  done
  
  echo "❌ Échec du build après $max_retries tentatives"
  return 1
}

# Vérifier si Docker est accessible
if ! docker ps &> /dev/null; then
  echo "❌ Docker n'est pas accessible"
  exit 1
fi

# Option 1: Vérifier si les images de base sont en cache
echo "🔍 Vérification des images en cache..."
if check_local_image "node:20-alpine"; then
  echo "✅ node:20-alpine trouvé en cache local"
else
  echo "⚠️  node:20-alpine non trouvé en cache"
  echo "   Tentative de pull (peut échouer si rate limit)..."
  docker pull node:20-alpine || echo "   ⚠️  Pull échoué, le build utilisera le pull automatique"
fi

if check_local_image "nginx:1.27-alpine"; then
  echo "✅ nginx:1.27-alpine trouvé en cache local"
else
  echo "⚠️  nginx:1.27-alpine non trouvé en cache"
  docker pull nginx:1.27-alpine || echo "   ⚠️  Pull échoué, le build utilisera le pull automatique"
fi

echo ""

# Build des images de l'application
echo "📦 Construction des images de l'application..."

# API Core
build_with_retry "./tp-mvc-poo-lite" "tpfront-back-api-core:latest" ""

# API Books
build_with_retry "./bookly-hybrid" "tpfront-back-api-books:latest" ""

# Frontend
build_with_retry "./frontend-react-api" "tpfront-back-frontend:latest" "--build-arg VITE_API_URL=http://api-core:3000 --build-arg VITE_BOOKS_URL=http://api-books:4000"

echo ""
echo "✅ Toutes les images ont été construites avec succès !"
echo ""
echo "📋 Images disponibles:"
docker images | grep tpfront-back
