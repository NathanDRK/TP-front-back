## Déploiement de l’application avec Docker / Docker Compose

Ce dépôt regroupe une application web complète, lançable via Docker / Docker Compose :  
- API « core » (utilisateurs & produits en mémoire)  
- API « hybride » (utilisateurs & livres en PostgreSQL + profils en MongoDB)  
- Front-end React (SPA Vite servie par Nginx)  
- Bases de données PostgreSQL et MongoDB

Objectif : faire tourner tout l’ensemble sur n’importe quelle machine équipée de Docker, sans autre dépendance.

---

## 1. Services

- **api-core** (`tp-mvc-poo-lite`)  
  - API REST Node/Express, port interne `3000`  
  - Données en mémoire : utilisateurs + produits

- **api-books** (`bookly-hybrid`)  
  - API REST Node/Express, port interne `4000`  
  - Utilisateurs + livres en **PostgreSQL**  
  - Profils (préférences / historique) en **MongoDB**

- **frontend** (`frontend-react-api`)  
  - SPA React (Vite) servie par **Nginx**, exposée sur `8080`  
  - Consomme les deux APIs via des URLs de build

- **postgres**  
  - Image `postgres:16-alpine`, base `bookly`, user `bookly` / password `booklypwd`  
  - Volume `pg_data` pour la persistance  
  - Init auto avec `bookly-hybrid/db/init.sql` (tables + seed)

- **mongo**  
  - Image `mongo:7.0`, base logique `bookly`  
  - Volume `mongo_data` pour la persistance

---

## 2. Prérequis

- Docker 24+ et Docker Compose v2  
- OS : Linux, macOS ou Windows (Docker Desktop)  
- Ports libres : `8080` (front), `3000` (api-core), `4000` (api-books), `5432` (Postgres), `27017` (Mongo)

---

## 3. Démarrage rapide

Depuis la racine `TP front-back` :

```bash
docker compose build
docker compose up -d
```

Accès :
- Front : http://localhost:8080  
- API core : http://localhost:3000/api/...  
- API books/profiles : http://localhost:4000/api/...

Arrêt (sans supprimer les données) :
```bash
docker compose down
```

Arrêt + suppression des volumes (efface Postgres/Mongo) :
```bash
docker compose down -v
```

---

## 4. Variables d’environnement (définies dans `docker-compose.yml`)

- **PostgreSQL**  
  - `POSTGRES_USER=bookly`  
  - `POSTGRES_PASSWORD=booklypwd`  
  - `POSTGRES_DB=bookly`

- **API books (`bookly-hybrid`)**  
  - `PGHOST=postgres`, `PGPORT=5432`, `PGDATABASE=bookly`, `PGUSER=bookly`, `PGPASSWORD=booklypwd`  
  - `MONGO_URI=mongodb://mongo:27017/bookly`  
  - `PORT=4000`

- **API core (`tp-mvc-poo-lite`)**  
  - `PORT=3000`

- **Front-end (build Vite)**  
  - `VITE_API_URL=http://api-core:3000`  
  - `VITE_BOOKS_URL=http://api-books:4000`

Si vous changez les URLs des APIs, re-build du front requis :
```bash
docker compose build frontend
docker compose up -d frontend
```

---

## 5. Conteneurisation (résumé)

- **APIs Node** : base `node:20-alpine`, `npm ci --omit=dev`, exécution sous l’utilisateur `node`, ports 3000/4000.  
- **Front** : multi-stage `node:20-alpine` (build Vite) → `nginx:1.27-alpine` (serve statique, fallback SPA).  
- **BDD** : Postgres init par `db/init.sql`; Mongo base `bookly`; volumes `pg_data` / `mongo_data`.  
- **Réseau** : bridge par défaut, résolution par nom de service (`api-core`, `api-books`, `postgres`, `mongo`, `frontend`).  
- **Healthchecks** : `pg_isready` pour Postgres, `mongosh ping` pour Mongo, dépendances configurées dans Compose.

---

## 6. Tests rapides

### Bases
```bash
docker compose exec postgres psql -U bookly -d bookly -c "\dt"
docker compose exec mongo mongosh --eval "db.adminCommand('ping')"
```

### API core (users/products en mémoire)
```bash
curl http://localhost:3000/api/status
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","age":20}'
curl http://localhost:3000/api/products
```

### API books/profiles (Postgres + Mongo)
```bash
curl -X POST http://localhost:4000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob","email":"bob@test.fr"}'
curl -X POST http://localhost:4000/api/books \
  -H "Content-Type: application/json" \
  -d '{"title":"Dune","author":"Herbert","available":true}'
curl -X POST http://localhost:4000/api/profiles \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"preferences":["scifi","fantasy"]}'
```

### Front
- Ouvrir `http://localhost:8080`, onglets Users / Products / Books / Profiles.  
- Vérifier création/édition/suppression et absence d’erreurs console.

### Persistance
```bash
docker compose restart postgres mongo
```
Après redémarrage, les données Postgres/Mongo doivent rester présentes.

---

## 7. Bonnes pratiques appliquées

- Images légères (`*-alpine`), `npm ci` pour un build reproductible.  
- Conteneurs Node lancés en utilisateur non-root.  
- Secrets non codés en dur : variables dans Compose, externalisables en prod.  
- Volumes nommés pour la persistance.  
- Healthchecks pour séquencer le démarrage des services dépendants.

---

## 8. Déploiement Kubernetes

L'application peut également être déployée sur un cluster Kubernetes avec auto-scaling, rolling updates et Ingress.

### 📦 Manifestes Kubernetes

Tous les manifestes sont disponibles dans le dossier `k8s/` :
- **Deployments** : postgres, mongo, api-core, api-books, frontend
- **Services** : ClusterIP pour chaque service
- **Ingress** : Point d'entrée HTTP/HTTPS
- **HPA** : Auto-scaling horizontal (2-10 replicas pour les APIs, 2-5 pour le frontend)
- **PVC** : Volumes persistants pour PostgreSQL et MongoDB
- **ConfigMaps & Secrets** : Configuration et credentials

### 🚀 Déploiement rapide

```bash
# Depuis la racine du projet
cd k8s
kubectl apply -k .
```

### 📚 Documentation complète

Consultez **[k8s/README.md](k8s/README.md)** pour :
- Instructions détaillées de déploiement
- Configuration de l'auto-scaling (HPA)
- Rolling updates
- Externalisation des bases de données (recommandé en production)
- Accès via Ingress ou Port-Forward
- Commandes utiles pour le monitoring et le debugging

### 🔗 Lien GitHub

Projet disponible sur : **https://github.com/NathanDRK/Docker**

---

## 9. Schéma d'architecture

Voir `docs/architecture.md` (diagramme mermaid) pour les conteneurs, réseaux, volumes et flux principaux.


