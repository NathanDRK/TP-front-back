#!/bin/bash

# Script de démarrage de l'application Bookly
# Usage: ./start.sh

set -e

echo "🚀 Démarrage de l'application Bookly..."
echo ""

# Vérifier que Docker est en cours d'exécution
if ! docker ps &> /dev/null; then
  echo "❌ Erreur: Docker n'est pas en cours d'exécution"
  echo "   Veuillez démarrer Docker Desktop et réessayer"
  exit 1
fi

echo "✅ Docker est accessible"
echo ""

# Build des images
echo "📦 Construction des images Docker..."
docker compose build

echo ""
echo "🚀 Démarrage des services..."
docker compose up -d

echo ""
echo "⏳ Attente du démarrage des services..."
sleep 5

# Vérifier le statut
echo ""
echo "📊 Statut des services:"
docker compose ps

echo ""
echo "✅ Application démarrée !"
echo ""
echo "🌐 Accès à l'application:"
echo "   - Frontend: http://localhost:8080"
echo "   - API Core: http://localhost:3000/api/..."
echo "   - API Books: http://localhost:4000/api/..."
echo ""
echo "📝 Commandes utiles:"
echo "   - Voir les logs: docker compose logs -f [service]"
echo "   - Arrêter: docker compose down"
echo "   - Redémarrer: docker compose restart [service]"
