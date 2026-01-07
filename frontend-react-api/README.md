# Frontend React (Vite + Nginx)

SPA qui consomme deux APIs :
- `VITE_API_URL` → API core (`tp-mvc-poo-lite`, port 3000) pour Users/Products (in-memory)
- `VITE_BOOKS_URL` → API books/profiles (`bookly-hybrid`, port 4000) pour Books/Profiles (Postgres + Mongo)

## Prérequis
- Node 20+ (dev ou build local)
- Docker si vous voulez construire l’image

## Scripts (dev local)
```bash
npm install
npm run dev         # http://localhost:5173
npm run build       # build prod dans dist/
npm run preview     # sert le build
```
Variables à poser en dev (`.env.local` par exemple) :
```
VITE_API_URL=http://localhost:3000
VITE_BOOKS_URL=http://localhost:4000
```

## Build Docker (utilisé par docker-compose)
Multi-stage :
1) build Vite sur `node:20-alpine`
2) serveur statique `nginx:1.27-alpine` avec fallback SPA (`nginx.conf`)

Commande de build :
```bash
docker build \
  --build-arg VITE_API_URL=http://api-core:3000 \
  --build-arg VITE_BOOKS_URL=http://api-books:4000 \
  -t frontend-react-api .
```

## Routes et pages
- `/` : Users (API core)
- `/products` : Products (API core)
- `/books` : Books (API books)
- `/profiles` : Profiles (API books, Mongo, liés aux users SQL)

## Adapter les URLs d’API
Si les hôtes/ports changent, modifier `VITE_API_URL` / `VITE_BOOKS_URL` (fichier env ou args de build) et re-builder le front si c’est pour Docker/Nginx.
