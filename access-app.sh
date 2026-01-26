#!/bin/bash

# Script pour accéder à l'application via port-forward
# Usage: ./access-app.sh

set -e

echo "🌐 Configuration de l'accès à l'application..."
echo ""

# Vérifier que les pods sont prêts
echo "⏳ Vérification que les pods sont prêts..."
kubectl wait --for=condition=ready pod --all -n bookly-app --timeout=60s || echo "⚠️  Certains pods ne sont pas encore prêts"

echo ""
echo "✅ Configuration du port-forward..."
echo ""
echo "📝 Instructions:"
echo ""
echo "1. Ouvrez 3 terminaux séparés et exécutez dans chacun:"
echo ""
echo "   Terminal 1 (Frontend):"
echo "   kubectl port-forward svc/frontend 8080:80 -n bookly-app"
echo ""
echo "   Terminal 2 (API Core):"
echo "   kubectl port-forward svc/api-core 3000:3000 -n bookly-app"
echo ""
echo "   Terminal 3 (API Books):"
echo "   kubectl port-forward svc/api-books 4000:4000 -n bookly-app"
echo ""
echo "2. Une fois les 3 port-forwards actifs, ouvrez:"
echo "   http://localhost:8080"
echo ""
echo "3. Pour arrêter, appuyez sur Ctrl+C dans chaque terminal"
echo ""

# Option: Lancer automatiquement (en arrière-plan)
read -p "Voulez-vous lancer les port-forwards automatiquement? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  echo "🚀 Lancement des port-forwards en arrière-plan..."
  echo "⚠️  Note: Ils s'arrêteront si vous fermez ce terminal"
  echo ""
  
  # Lancer en arrière-plan
  kubectl port-forward svc/frontend 8080:80 -n bookly-app &
  kubectl port-forward svc/api-core 3000:3000 -n bookly-app &
  kubectl port-forward svc/api-books 4000:4000 -n bookly-app &
  
  echo "✅ Port-forwards lancés"
  echo ""
  echo "🌐 Accédez à l'application: http://localhost:8080"
  echo ""
  echo "⏹️  Pour arrêter, appuyez sur Ctrl+C"
  
  # Attendre
  wait
fi
