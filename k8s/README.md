# Déploiement Kubernetes - Application Bookly

Ce dossier contient tous les manifestes Kubernetes nécessaires pour déployer l'application Bookly sur un cluster Kubernetes.

## 📋 Table des matières

1. [Architecture](#architecture)
2. [Prérequis](#prérequis)
3. [Build des images Docker](#build-des-images-docker)
4. [Déploiement](#déploiement)
5. [Auto-scaling](#auto-scaling)
6. [Rolling Updates](#rolling-updates)
7. [Externalisation des bases de données](#externalisation-des-bases-de-données)
8. [Accès à l'application](#accès-à-lapplication)
9. [Commandes utiles](#commandes-utiles)

---

## 🏗️ Architecture

L'application est déployée dans un namespace Kubernetes `bookly-app` avec les composants suivants :

- **PostgreSQL** : Base de données relationnelle (1 replica, PVC pour persistance)
- **MongoDB** : Base de données NoSQL (1 replica, PVC pour persistance)
- **API Core** : API REST pour users/products (2+ replicas, HPA activé)
- **API Books** : API REST hybride pour books/profiles (2+ replicas, HPA activé)
- **Frontend** : Application React servie par Nginx (2+ replicas, HPA activé)
- **Ingress** : Point d'entrée HTTP/HTTPS pour exposer l'application

### Choix d'architecture

**Bases de données dans le cluster** : Les bases de données PostgreSQL et MongoDB sont déployées dans le cluster Kubernetes pour :
- ✅ Simplicité de déploiement (tout dans un seul namespace)
- ✅ Cohérence avec l'environnement Docker Compose
- ✅ Facilite les tests et le développement
- ✅ Coût réduit pour les petits déploiements

**Externalisation recommandée en production** : Pour un environnement de production, il est recommandé d'utiliser des services managés :
- **PostgreSQL** : Cloud SQL (GCP), RDS (AWS), Azure Database
- **MongoDB** : MongoDB Atlas, DocumentDB (AWS)
- Avantages : haute disponibilité, sauvegardes automatiques, scaling indépendant, sécurité renforcée

---

## 📦 Prérequis

- Cluster Kubernetes fonctionnel (minikube, kind, GKE, EKS, AKS, etc.)
- `kubectl` configuré et connecté au cluster
- Ingress Controller installé (ex: NGINX Ingress Controller)
- Accès à un registry Docker (Docker Hub, GCR, ECR, etc.) OU images buildées localement

### Installation de l'Ingress Controller (si nécessaire)

**Minikube :**
```bash
minikube addons enable ingress
```

**Kind ou cluster standard :**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

---

## 🐳 Build des images Docker

### Option 1 : Build local et push vers un registry

```bash
# Depuis la racine du projet
docker build -t votre-registry/api-core:latest ./tp-mvc-poo-lite
docker build -t votre-registry/api-books:latest ./bookly-hybrid
docker build -t votre-registry/frontend:latest ./frontend-react-api

# Push vers le registry
docker push votre-registry/api-core:latest
docker push votre-registry/api-books:latest
docker push votre-registry/frontend:latest
```

Puis modifiez les Deployments pour utiliser vos images :
```yaml
image: votre-registry/api-core:latest
imagePullPolicy: Always
```

### Option 2 : Build local avec minikube (pour tests)

```bash
# Configurer Docker pour utiliser le daemon de minikube
eval $(minikube docker-env)

# Build les images
docker build -t tpfront-back-api-core:latest ./tp-mvc-poo-lite
docker build -t tpfront-back-api-books:latest ./bookly-hybrid
docker build -t tpfront-back-frontend:latest ./frontend-react-api

# Les images sont maintenant disponibles dans minikube
# Utilisez imagePullPolicy: Never dans les Deployments
```

---

## 🚀 Déploiement

### Déploiement complet (recommandé)

```bash
# Depuis la racine du projet
kubectl apply -k k8s/
```

### Déploiement étape par étape

```bash
# 1. Namespace
kubectl apply -f k8s/namespace.yaml

# 2. ConfigMaps et Secrets
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/configmap-postgres-init.yaml
kubectl apply -f k8s/secret.yaml

# 3. PersistentVolumeClaims
kubectl apply -f k8s/pvc-postgres.yaml
kubectl apply -f k8s/pvc-mongo.yaml

# 4. Bases de données
kubectl apply -f k8s/deployment-postgres.yaml
kubectl apply -f k8s/deployment-mongo.yaml
kubectl apply -f k8s/service-postgres.yaml
kubectl apply -f k8s/service-mongo.yaml

# 5. APIs
kubectl apply -f k8s/deployment-api-core.yaml
kubectl apply -f k8s/deployment-api-books.yaml
kubectl apply -f k8s/service-api-core.yaml
kubectl apply -f k8s/service-api-books.yaml

# 6. Frontend
kubectl apply -f k8s/deployment-frontend.yaml
kubectl apply -f k8s/service-frontend.yaml

# 7. Ingress
kubectl apply -f k8s/ingress.yaml

# 8. Auto-scaling (HPA)
kubectl apply -f k8s/hpa-api-core.yaml
kubectl apply -f k8s/hpa-api-books.yaml
kubectl apply -f k8s/hpa-frontend.yaml
```

### Vérification du déploiement

```bash
# Vérifier les pods
kubectl get pods -n bookly-app

# Vérifier les services
kubectl get svc -n bookly-app

# Vérifier les HPA
kubectl get hpa -n bookly-app

# Vérifier l'Ingress
kubectl get ingress -n bookly-app
```

---

## 📈 Auto-scaling

L'application utilise des **HorizontalPodAutoscalers (HPA)** pour ajuster automatiquement le nombre de replicas selon la charge :

- **API Core** : 2-10 replicas (CPU 70%, Memory 80%)
- **API Books** : 2-10 replicas (CPU 70%, Memory 80%)
- **Frontend** : 2-5 replicas (CPU 70%, Memory 80%)

### Vérifier l'auto-scaling

```bash
# Voir les métriques HPA
kubectl describe hpa api-core-hpa -n bookly-app
kubectl describe hpa api-books-hpa -n bookly-app
kubectl describe hpa frontend-hpa -n bookly-app

# Voir le nombre de replicas actuels
kubectl get deployment -n bookly-app
```

### Tester l'auto-scaling

Pour tester, vous pouvez générer de la charge :

```bash
# Installer hey (outil de load testing)
# macOS: brew install hey
# Linux: wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64

# Générer de la charge sur l'API
hey -n 10000 -c 50 http://bookly.local/api/core/api/users
```

Observez le scaling avec :
```bash
watch kubectl get hpa -n bookly-app
```

---

## 🔄 Rolling Updates

Kubernetes effectue automatiquement des **rolling updates** lors des mises à jour :

### Mettre à jour une image

```bash
# Méthode 1 : Modifier le Deployment
kubectl set image deployment/api-core api-core=votre-registry/api-core:v2 -n bookly-app

# Méthode 2 : Modifier le fichier YAML et appliquer
kubectl apply -f k8s/deployment-api-core.yaml
```

### Contrôler le rolling update

```bash
# Voir le statut du rollout
kubectl rollout status deployment/api-core -n bookly-app

# Rollback en cas de problème
kubectl rollout undo deployment/api-core -n bookly-app

# Voir l'historique des rollouts
kubectl rollout history deployment/api-core -n bookly-app
```

### Configuration du rolling update

Par défaut, Kubernetes utilise :
- **maxSurge** : 25% (peut dépasser le nombre de replicas souhaités)
- **maxUnavailable** : 25% (peut avoir moins de replicas disponibles)

Pour personnaliser, ajoutez dans le Deployment :

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero-downtime deployment
```

---

## 🗄️ Externalisation des bases de données

### Pourquoi externaliser ?

En production, il est recommandé d'utiliser des services managés pour :
- ✅ Haute disponibilité (multi-AZ)
- ✅ Sauvegardes automatiques
- ✅ Scaling indépendant
- ✅ Maintenance gérée par le provider
- ✅ Sécurité renforcée (chiffrement, réseau privé)

### Exemple : Externaliser PostgreSQL vers Cloud SQL (GCP)

1. **Créer une instance Cloud SQL**
2. **Modifier le ConfigMap** pour pointer vers l'instance externe :

```yaml
# k8s/configmap.yaml
data:
  PGHOST: "10.0.0.5"  # IP privée de Cloud SQL
  PGPORT: "5432"
```

3. **Créer un Secret** avec les credentials Cloud SQL
4. **Supprimer les Deployments PostgreSQL** du cluster :

```bash
kubectl delete deployment postgres -n bookly-app
kubectl delete service postgres -n bookly-app
kubectl delete pvc postgres-pvc -n bookly-app
```

### Exemple : Externaliser MongoDB vers MongoDB Atlas

1. **Créer un cluster MongoDB Atlas**
2. **Modifier le ConfigMap** :

```yaml
# k8s/configmap.yaml
data:
  MONGO_URI: "mongodb+srv://username:password@cluster.mongodb.net/bookly?retryWrites=true&w=majority"
```

3. **Supprimer les ressources MongoDB du cluster**

---

## 🌐 Accès à l'application

### Avec Ingress (recommandé)

1. **Obtenir l'adresse IP de l'Ingress** :

```bash
kubectl get ingress -n bookly-app
```

2. **Configurer /etc/hosts** (pour développement) :

```bash
# Sur macOS/Linux
echo "INGRESS_IP bookly.local" | sudo tee -a /etc/hosts

# Sur Windows : C:\Windows\System32\drivers\etc\hosts
```

3. **Accéder à l'application** :

- Frontend : `http://bookly.local`
- API Core : `http://bookly.local/api/core`
- API Books : `http://bookly.local/api/books`

### Avec Port-Forward (pour tests rapides)

```bash
# Frontend
kubectl port-forward svc/frontend 8080:80 -n bookly-app
# Accès : http://localhost:8080

# API Core
kubectl port-forward svc/api-core 3000:3000 -n bookly-app
# Accès : http://localhost:3000

# API Books
kubectl port-forward svc/api-books 4000:4000 -n bookly-app
# Accès : http://localhost:4000
```

### Avec NodePort (non recommandé en production)

Modifiez les Services pour utiliser `type: NodePort` et accédez via `<NODE_IP>:<NODE_PORT>`.

---

## 🛠️ Commandes utiles

### Monitoring

```bash
# Logs d'un pod
kubectl logs -f deployment/api-core -n bookly-app

# Logs de tous les pods d'un service
kubectl logs -f -l app=api-core -n bookly-app

# Décrire un pod pour voir les événements
kubectl describe pod <pod-name> -n bookly-app

# Top des ressources
kubectl top pods -n bookly-app
kubectl top nodes
```

### Debugging

```bash
# Exécuter une commande dans un pod
kubectl exec -it deployment/postgres -n bookly-app -- psql -U bookly -d bookly

# Accéder à un shell
kubectl exec -it deployment/api-core -n bookly-app -- sh

# Voir les événements du namespace
kubectl get events -n bookly-app --sort-by='.lastTimestamp'
```

### Maintenance

```bash
# Redémarrer un deployment
kubectl rollout restart deployment/api-core -n bookly-app

# Mettre à l'échelle manuellement
kubectl scale deployment/api-core --replicas=5 -n bookly-app

# Supprimer tout le namespace (ATTENTION : supprime toutes les données)
kubectl delete namespace bookly-app
```

---

## 📝 Notes importantes

1. **Secrets** : Les secrets sont stockés en base64 (non chiffrés). En production, utilisez :
   - Sealed Secrets
   - External Secrets Operator
   - Services cloud (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)

2. **Storage** : Les PVC utilisent `storageClassName: standard`. Adaptez selon votre cluster.

3. **Ressources** : Les limites CPU/Memory sont définies dans les Deployments. Ajustez selon vos besoins.

4. **Ingress** : L'Ingress utilise `ingressClassName: nginx`. Adaptez si vous utilisez un autre Ingress Controller.

5. **Images** : Remplacez les noms d'images par vos propres images dans un registry accessible.

---

## 🔗 Liens utiles

- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Rolling Updates](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment)
