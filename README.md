# Microservices Demo — Local → Kubernetes → GCP

A 3-microservice project built the way it's actually done in production:
independent services, a real Postgres database per service, container
images, Kubernetes manifests, a cloud deployment target (GCP/GKE), and a
CI/CD pipeline.

## Architecture

```
   browser
      │
      ▼
   ┌───────────────────┐
   │   frontend (nginx)  │  static console UI + /api/* reverse proxy
   │   (port 80/8080)     │  (also acts as a lightweight API gateway)
   └─────────┬─────────┘
             │
             ▼
   ┌────────────────┐
   │  order-service  │ ───▶ calls user-service (validate user)
   │   (port 3003)    │ ───▶ calls product-service (check/decrement stock)
   └────────┬───────┘
            │ writes to orders_db
            ▼
   ┌──────────────────┐          ┌─────────────────────┐
   │   user-service     │          │   product-service     │
   │   (port 3001)       │          │   (port 3002)           │
   │   → users_db        │          │   → products_db         │
   └──────────────────┘          └─────────────────────┘
```

Each backend service is standalone: own codebase, own Dockerfile, **own
Postgres database** (`users_db`, `products_db`, `orders_db` —
database-per-service, running on one shared Postgres instance to keep cost
down). `order-service` demonstrates real service-to-service communication: it
calls the other two over HTTP, then atomically decrements stock via
`product-service` (rejecting with `409` if that would oversell) before
persisting the order.

The **frontend** is a static console UI (plain HTML/CSS/JS, no build step)
served by nginx. Nginx also acts as a small API gateway: the browser only
ever calls `/api/users`, `/api/products`, `/api/orders` on the frontend's own
origin, and nginx routes each to the right backend service. That means the
browser never needs to know 3 different ports/hostnames, and the exact same
`nginx.conf` works unchanged in docker-compose and in Kubernetes (both
resolve `user-service`, `product-service`, `order-service` by DNS name). The
console shows a live topology diagram — when you place an order, you'll see
the actual request pulse from `order-service` to `user-service` and
`product-service` in real time, plus a request log with real response
times, so the architecture is visible instead of hidden behind a form.

## Project layout

```
microservices-project/
├── frontend/                  # nginx static console UI + /api/* reverse proxy
├── services/
│   ├── user-service/       # Express + Postgres — users
│   ├── product-service/    # Express + Postgres — products/stock
│   └── order-service/      # Express + Postgres — orders, calls the two above
├── db-init/                  # creates the 3 databases on first Postgres boot (local only)
├── docker-compose.yml         # run frontend + all 3 services + Postgres locally, one command
├── k8s/                       # Deployment/Service/Ingress manifests + Cloud SQL Auth Proxy sidecars
├── gcp/                       # numbered shell scripts: provision GCP, DB, CI/CD auth, deploy
└── .github/workflows/         # CI/CD pipeline (GitHub Actions → GKE)
```

## 1. Run it locally right now

Requires Docker + Docker Compose.

```bash
cd microservices-project
docker compose up --build
```

This starts Postgres (with `users_db`, `products_db`, `orders_db` created
automatically), all three backend services, and the frontend console:

| Service          | URL                     |
|-------------------|--------------------------|
| **frontend (open this)** | **http://localhost:8080** |
| user-service      | http://localhost:3001    |
| product-service   | http://localhost:3002    |
| order-service      | http://localhost:3003    |

Open **http://localhost:8080** — you'll see the console: live status lights
for each service, the request topology diagram, and panels to browse
users/products/orders and place a new order. Watch the topology when you
submit an order.

Or drive it from the command line the same way the UI does, straight
through the frontend's API gateway:

```bash
curl http://localhost:8080/api/users
curl http://localhost:8080/api/products

curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "productId": 2, "quantity": 2}'

curl http://localhost:8080/api/products/2   # stock dropped by 2
curl http://localhost:8080/api/orders        # the order is now persisted in Postgres
```

I ran this exact flow — schema creation, seed data, the cross-service order
call routed through nginx exactly as the browser sends it, stock decrement,
and an oversell attempt correctly rejected with `409` — against a live
Postgres instance while building it, all verified working end to end.

If you restart the containers, data persists (it's in the `pgdata` Docker
volume). To fully reset: `docker compose down -v`.

No Docker? Run each service against a local Postgres:
```bash
export DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=postgres
cd services/user-service && npm install && PORT=3001 DB_NAME=users_db npm start
cd services/product-service && npm install && PORT=3002 DB_NAME=products_db npm start
cd services/order-service && npm install && PORT=3003 DB_NAME=orders_db \
  USER_SERVICE_URL=http://localhost:3001 PRODUCT_SERVICE_URL=http://localhost:3002 npm start
```

## Frontend design notes

The console is deliberately a plain HTML/CSS/JS file (no React/build step) —
for a project this size that keeps the Dockerfile to two lines and there's
nothing to compile. It's styled as an internal ops console rather than a
marketing page: dark slate background, amber signal-light accent, IBM Plex
Sans/Mono for a technical feel. If you outgrow a single file (more views,
client-side routing), it's a natural candidate to rebuild in React — say the
word and I'll convert it.

## 2. Deploy to GCP (GKE + Cloud SQL + Artifact Registry)

Everything below is in `gcp/`, meant to be run **in numeric order**. Requires
the `gcloud` CLI installed and `gcloud auth login` already done.

```bash
cd gcp
export PROJECT_ID=your-gcp-project-id
export REGION=asia-south1        # change to your preferred region

./01-setup-project.sh              # enables required GCP APIs
./02-create-artifact-registry.sh   # creates a Docker image repo
./03-build-and-push.sh             # builds & pushes all 3 images
./04-create-gke-cluster.sh         # creates a GKE Autopilot cluster

DB_PASSWORD='pick-a-strong-password' ./05-create-cloudsql.sh
# ^ prints an INSTANCE_CONNECTION_NAME - copy it, you need it next

./06-setup-workload-identity.sh    # lets GKE pods reach Cloud SQL, no key files
```

Now create the real DB secret from the template and fill in the values from
the step above:

```bash
cp ../k8s/db-secret.yaml.example ../k8s/db-secret.yaml
# edit db-secret.yaml: set DB_PASSWORD and INSTANCE_CONNECTION_NAME
```

`k8s/db-secret.yaml` is in `.gitignore` — never commit real credentials.

```bash
./07-deploy-to-gke.sh              # applies everything with real image paths + secret
```

Each pod runs your service **plus a Cloud SQL Auth Proxy sidecar container**
— the standard, secure way GKE workloads reach Cloud SQL (no public IP
allowlisting, no TLS cert management in app code).

Check status:
```bash
kubectl get pods -n microservices-demo
kubectl get ingress -n microservices-demo   # external IP appears after a few minutes
```

GKE **Autopilot** is used deliberately — Google manages nodes, patching, and
scaling. Swap in Standard GKE if you need custom node types (e.g. GPUs).

## 3. CI/CD (GitHub Actions)

One more one-time setup step so GitHub Actions can deploy without a JSON key
file (uses Workload Identity Federation instead):

```bash
cd gcp
PROJECT_ID=your-gcp-project-id GITHUB_REPO="your-username/your-repo" \
  ./00-setup-github-actions-auth.sh
```

It prints 3 values — add them as **GitHub repo secrets**
(Settings → Secrets and variables → Actions):
- `GCP_PROJECT_ID`
- `WIF_PROVIDER`
- `WIF_SERVICE_ACCOUNT`

From then on, `.github/workflows/deploy.yml` runs on every push to `main`:
1. Builds each service's Docker image
2. Pushes it to Artifact Registry, tagged with the git SHA (traceability) and `latest`
3. Authenticates to GCP via Workload Identity Federation
4. Rolls out the new image to the GKE deployment and waits for
   `kubectl rollout status` to confirm health before finishing

If you'd rather use **Google Cloud Build** instead of GitHub Actions, the
same 4 steps translate directly into a `cloudbuild.yaml` — ask and I'll
generate one.

## What's intentionally simplified (and how to harden it further)

| Area | Demo version | Production upgrade |
|---|---|---|
| Data storage | ✅ Real Postgres (Cloud SQL), one DB per service | Add read replicas / connection pooling (PgBouncer) at higher scale |
| Auth | None | OAuth2/JWT via an API gateway or Identity-Aware Proxy |
| Service-to-service calls | Plain HTTP | mTLS via a service mesh (Istio/Anthos Service Mesh), retries/circuit breakers |
| Secrets | K8s Secret (base setup) | Secret Manager + External Secrets Operator for rotation |
| Observability | `console.log` | Cloud Logging/Monitoring, or Prometheus + Grafana |
| Ingress | Basic GCE ingress | Cloud Armor (WAF/DDoS) in front of it |

Happy to build out any of these next — auth/API gateway is usually the
highest-value next step.
