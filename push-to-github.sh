#!/bin/bash

# Script pour pousser le projet vers GitHub
# Usage: ./push-to-github.sh

set -e

REPO_URL="https://github.com/NathanDRK/TP-front-back.git"

echo "🚀 Push du projet vers GitHub..."
echo ""

# Vérifier la connectivité
if ! ping -c 1 github.com &> /dev/null; then
  echo "❌ GitHub n'est pas accessible"
  echo "   Vérifiez votre connexion internet"
  exit 1
fi

# Vérifier que nous sommes dans un dépôt Git
if ! git rev-parse --git-dir &> /dev/null; then
  echo "❌ Ce n'est pas un dépôt Git"
  exit 1
fi

# Vérifier s'il y a des changements non commités
if [ -n "$(git status --porcelain)" ]; then
  echo "📦 Changements non commités détectés"
  read -p "Voulez-vous les commiter? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add .
    git commit -m "Mise à jour du projet"
  fi
fi

# Vérifier le remote actuel
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

if [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
  echo "🔄 Configuration du remote..."
  echo "   Remote actuel: $CURRENT_REMOTE"
  echo "   Remote cible: $REPO_URL"
  echo ""
  
  # Essayer de modifier le remote
  if git remote set-url origin "$REPO_URL" 2>/dev/null; then
    echo "✅ Remote configuré"
  else
    echo "⚠️  Impossible de modifier le remote (permissions)"
    echo "   Push direct vers l'URL..."
    git push "$REPO_URL" main
    exit 0
  fi
fi

# Push vers GitHub
echo "📤 Push vers GitHub..."
if git push origin main; then
  echo ""
  echo "✅ Projet poussé avec succès vers:"
  echo "   $REPO_URL"
else
  echo ""
  echo "❌ Erreur lors du push"
  echo ""
  echo "Solutions possibles:"
  echo "1. Vérifiez vos credentials Git"
  echo "2. Utilisez un token d'accès personnel:"
  echo "   git push https://USERNAME:TOKEN@github.com/NathanDRK/TP-front-back.git main"
  echo "3. Configurez SSH:"
  echo "   git remote set-url origin git@github.com:NathanDRK/TP-front-back.git"
  exit 1
fi
