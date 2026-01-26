# 🔧 Solutions pour le Rate Limit Docker Hub

## Problème
Docker Hub limite les pulls d'images pour les utilisateurs non authentifiés :
- **100 pulls toutes les 6 heures** pour les utilisateurs anonymes
- **200 pulls toutes les 6 heures** pour les utilisateurs authentifiés gratuits

## ✅ Solutions

### Solution 1: S'authentifier à Docker Hub (Recommandé)

```bash
# Se connecter à Docker Hub
docker login

# Entrer vos identifiants Docker Hub
# Si vous n'avez pas de compte: https://hub.docker.com/signup
```

**Avantages:**
- 200 pulls toutes les 6 heures au lieu de 100
- Accès aux images privées si vous en avez

### Solution 2: Utiliser les images en cache

Si vous avez déjà buildé les images précédemment, elles sont en cache :

```bash
# Vérifier les images en cache
docker images | grep -E "node|nginx"

# Si elles sont présentes, le build les utilisera automatiquement
```

### Solution 3: Attendre et réessayer

Le rate limit se réinitialise toutes les 6 heures. Vous pouvez :

```bash
# Utiliser le script avec retry automatique
./build-with-retry.sh
```

Ce script attend 60 secondes entre chaque tentative.

### Solution 4: Utiliser des registries alternatifs

Modifier les Dockerfiles pour utiliser des registries alternatifs :

**Option A: GitHub Container Registry (ghcr.io)**
```dockerfile
FROM ghcr.io/node:20-alpine
```

**Option B: Quay.io**
```dockerfile
FROM quay.io/node:20-alpine
```

**Option C: Utiliser des images déjà téléchargées**
Si vous avez déjà `node:20-alpine` en cache, Docker l'utilisera automatiquement.

### Solution 5: Build progressif (une image à la fois)

Au lieu de tout builder d'un coup, builder une image à la fois avec des pauses :

```bash
# Builder API Core
docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite
sleep 60

# Builder API Books
docker build -t tpfront-back-api-books:latest ./bookly-hybrid
sleep 60

# Builder Frontend
docker build \
  --build-arg VITE_API_URL=http://api-core:3000 \
  --build-arg VITE_BOOKS_URL=http://api-books:4000 \
  -t tpfront-back-frontend:latest ./frontend-react-api
```

### Solution 6: Utiliser Docker Compose avec cache

Docker Compose peut utiliser le cache plus efficacement :

```bash
# Builder avec cache
docker compose build --no-cache=false

# Ou builder une seule image à la fois
docker compose build api-core
docker compose build api-books
docker compose build frontend
```

## 🚀 Solution rapide (recommandée)

1. **S'authentifier à Docker Hub:**
```bash
docker login
```

2. **Utiliser le script de build avec retry:**
```bash
./build-with-retry.sh
```

3. **Si ça échoue encore, attendre 1-2 heures et réessayer**

## 📝 Vérification

Pour vérifier combien de pulls il vous reste :

```bash
# Vérifier votre limite (nécessite curl et jq)
curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/node:pull" | jq .
```

## 🔄 Pour Kubernetes

Si vous déployez sur Kubernetes, les images doivent être disponibles. Options :

1. **Utiliser les images buildées localement** (minikube/kind)
2. **Pusher vers un registry privé** (GitHub Container Registry, Docker Hub avec compte)
3. **Utiliser un registry public alternatif**

### Exemple avec GitHub Container Registry

```bash
# Tag les images
docker tag tpfront-back-api-core:latest ghcr.io/votre-username/api-core:latest
docker tag tpfront-back-api-books:latest ghcr.io/votre-username/api-books:latest
docker tag tpfront-back-frontend:latest ghcr.io/votre-username/frontend:latest

# Login à GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u votre-username --password-stdin

# Push
docker push ghcr.io/votre-username/api-core:latest
docker push ghcr.io/votre-username/api-books:latest
docker push ghcr.io/votre-username/frontend:latest

# Mettre à jour les Deployments Kubernetes pour utiliser ces images
```

## 💡 Astuce

Pour éviter le rate limit à l'avenir :
- Gardez les images en cache (ne pas faire `docker system prune` trop souvent)
- Utilisez un registry privé pour vos images
- Authentifiez-vous à Docker Hub
- Utilisez des images alternatives (ghcr.io, quay.io)
