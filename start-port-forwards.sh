#!/bin/bash

# Script pour lancer automatiquement tous les port-forwards
# Usage: ./start-port-forwards.sh

set -e

echo "🌐 Lancement des port-forwards pour l'application..."
echo ""

# Vérifier que les services existent
if ! kubectl get svc frontend -n bookly-app &> /dev/null; then
  echo "❌ Le service frontend n'existe pas. Déployez d'abord l'application."
  exit 1
fi

# Fonction pour nettoyer les processus en arrière-plan
cleanup() {
  echo ""
  echo "🛑 Arrêt des port-forwards..."
  pkill -f "kubectl port-forward.*frontend.*8080" || true
  pkill -f "kubectl port-forward.*api-core.*3000" || true
  pkill -f "kubectl port-forward.*api-books.*4000" || true
  echo "✅ Port-forwards arrêtés"
  exit 0
}

# Capturer Ctrl+C
trap cleanup SIGINT SIGTERM

# Lancer les port-forwards en arrière-plan
echo "🚀 Lancement des port-forwards..."
echo ""

kubectl port-forward svc/frontend 8080:80 -n bookly-app > /dev/null 2>&1 &
PF_FRONTEND_PID=$!

kubectl port-forward svc/api-core 3000:3000 -n bookly-app > /dev/null 2>&1 &
PF_API_CORE_PID=$!

kubectl port-forward svc/api-books 4000:4000 -n bookly-app > /dev/null 2>&1 &
PF_API_BOOKS_PID=$!

# Attendre un peu pour vérifier qu'ils démarrent
sleep 2

# Vérifier que les processus sont toujours actifs
if ! ps -p $PF_FRONTEND_PID > /dev/null || ! ps -p $PF_API_CORE_PID > /dev/null || ! ps -p $PF_API_BOOKS_PID > /dev/null; then
  echo "❌ Erreur lors du lancement des port-forwards"
  cleanup
  exit 1
fi

echo "✅ Port-forwards actifs:"
echo "   - Frontend: http://localhost:8080"
echo "   - API Core: http://localhost:3000"
echo "   - API Books: http://localhost:4000"
echo ""
echo "🌐 Ouvrez votre navigateur: http://localhost:8080"
echo ""
echo "⏹️  Appuyez sur Ctrl+C pour arrêter les port-forwards"
echo ""

# Attendre
wait
