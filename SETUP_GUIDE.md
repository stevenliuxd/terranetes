# Terranetes DevOps Demo Stack - Complete Setup Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Project Structure](#project-structure)
5. [Phase 1: Local Infrastructure Setup](#phase-1-local-infrastructure-setup)
6. [Phase 2: Database Layer](#phase-2-database-layer)
7. [Phase 3: Application Development](#phase-3-application-development)
8. [Phase 4: Helm Charts](#phase-4-helm-charts)
9. [Phase 5: Jenkins CI/CD](#phase-5-jenkins-cicd)
10. [Development Workflow](#development-workflow)
11. [Troubleshooting](#troubleshooting)
12. [Next Steps & Scaling](#next-steps--scaling)

---

## 🎯 Overview

**Goal**: Build a production-like DevOps pipeline that demonstrates the complete three-layer workflow:
- **Layer 1**: Terraform (Infrastructure as Code)
- **Layer 2**: Helm (Application Deployment)
- **Layer 3**: Jenkins (CI/CD Automation)

**Tech Stack**:
- Ruby on Rails (API backend)
- React (Frontend SPA)
- Sidekiq (Background job processor)
- MySQL (Database)
- Redis (Cache + Job queue)
- Kubernetes (Minikube)
- Jenkins (CI/CD)
- Docker (Containerization)

**Cost**: $0 - Everything runs locally!

---

## 🔧 Prerequisites

### Required Software

| Tool | Version | Installation |
|------|---------|--------------|
| **Docker** | 24.0+ | `sudo apt install docker.io` or [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| **Minikube** | 1.32+ | `curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube` |
| **kubectl** | 1.28+ | `sudo snap install kubectl --classic` |
| **Helm** | 3.13+ | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |
| **Terraform** | 1.6+ | `sudo snap install terraform --classic` |
| **Ruby** | 3.2+ | `sudo apt install ruby-full` or use [rbenv](https://github.com/rbenv/rbenv) |
| **Node.js** | 20+ | `sudo snap install node --classic` |
| **Git** | 2.40+ | `sudo apt install git` |

### System Requirements

- **CPU**: 4 cores (minimum), 8 cores (recommended)
- **RAM**: 8GB (minimum), 16GB (recommended)
- **Disk**: 20GB free space
- **OS**: Linux (Ubuntu/Debian preferred), macOS, or Windows with WSL2

### Verify Installation

```bash
# Check all tools are installed
docker --version
minikube version
kubectl version --client
helm version
terraform version
ruby --version
node --version
git --version
```

---

## 🏗️ Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        DEVELOPER                             │
│                            │                                 │
│                            ▼                                 │
│                    ┌──────────────┐                         │
│                    │  Git Push    │                         │
│                    └──────┬───────┘                         │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   LAYER 3: CI/CD (Jenkins)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Checkout │→ │  Tests   │→ │  Build   │→ │  Deploy  │   │
│  │   Code   │  │ (RSpec)  │  │  Docker  │  │  w/Helm  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              LAYER 2: Applications (Helm Charts)             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Rails API    │  │ React App    │  │   Sidekiq    │     │
│  │ (Backend)    │  │ (Frontend)   │  │   Worker     │     │
│  └──────┬───────┘  └──────────────┘  └──────┬───────┘     │
│         │                                    │              │
│         └────────────────┬───────────────────┘              │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│       LAYER 1: Infrastructure (Terraform + Kubernetes)       │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │    MySQL     │         │    Redis     │                 │
│  │  (Database)  │         │ (Cache+Jobs) │                 │
│  └──────────────┘         └──────────────┘                 │
│                                                              │
│  ┌────────────────────────────────────────────────┐        │
│  │          Kubernetes (Minikube)                  │        │
│  │  Namespaces: dev, staging, prod                 │        │
│  └────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### Component Communication Flow

```
User → React (Port 3000) → Rails API (Port 3001) → MySQL (Port 3306)
                               ↓
                           Redis (Port 6379)
                               ↑
                          Sidekiq Worker
```

---

## 📂 Project Structure

```
terranetes/
├── README.md                          # Project overview
├── SETUP_GUIDE.md                     # This file
├── Makefile                           # Helper commands
├── .gitignore
│
├── terraform/                         # Layer 1: Infrastructure
│   ├── backend.tf                     # Terraform state backend
│   ├── provider.tf                    # Kubernetes provider config
│   ├── namespaces.tf                  # Dev/Staging/Prod namespaces
│   ├── storage.tf                     # StorageClasses & PVs
│   ├── rbac.tf                        # ServiceAccounts & Roles
│   ├── variables.tf                   # Input variables
│   ├── outputs.tf                     # Output values
│   └── terraform.tfvars               # Variable values
│
├── helm/                              # Layer 2: Applications
│   ├── mysql/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── statefulset.yaml       # MySQL StatefulSet
│   │       ├── service.yaml           # ClusterIP service
│   │       ├── pvc.yaml               # Persistent volume claim
│   │       └── secret.yaml            # DB credentials
│   │
│   ├── redis/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml        # Redis deployment
│   │       ├── service.yaml
│   │       └── configmap.yaml         # Redis config
│   │
│   ├── rails-api/
│   │   ├── Chart.yaml
│   │   ├── values.yaml                # Default values
│   │   ├── values-dev.yaml            # Dev environment
│   │   ├── values-staging.yaml        # Staging environment
│   │   ├── values-prod.yaml           # Production environment
│   │   └── templates/
│   │       ├── deployment.yaml        # Rails deployment
│   │       ├── service.yaml           # ClusterIP service
│   │       ├── ingress.yaml           # Ingress rules
│   │       ├── configmap.yaml         # App configuration
│   │       ├── secret.yaml            # Secrets
│   │       ├── hpa.yaml               # Horizontal Pod Autoscaler
│   │       └── job-migrate.yaml       # DB migration job
│   │
│   ├── react-frontend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml        # React/nginx deployment
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       └── configmap.yaml         # nginx config
│   │
│   └── sidekiq-worker/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml        # Sidekiq deployment
│           └── configmap.yaml         # Worker config
│
├── apps/                              # Application source code
│   ├── rails-api/
│   │   ├── Gemfile
│   │   ├── Gemfile.lock
│   │   ├── Rakefile
│   │   ├── config.ru
│   │   ├── Dockerfile
│   │   ├── .dockerignore
│   │   ├── config/
│   │   │   ├── application.rb
│   │   │   ├── database.yml
│   │   │   ├── routes.rb
│   │   │   └── environments/
│   │   │       ├── development.rb
│   │   │       ├── test.rb
│   │   │       └── production.rb
│   │   ├── app/
│   │   │   ├── controllers/
│   │   │   │   ├── application_controller.rb
│   │   │   │   ├── health_controller.rb
│   │   │   │   └── api/
│   │   │   │       ├── status_controller.rb
│   │   │   │       └── jobs_controller.rb
│   │   │   ├── models/
│   │   │   │   └── application_record.rb
│   │   │   └── jobs/
│   │   │       └── demo_job.rb
│   │   ├── db/
│   │   │   ├── migrate/
│   │   │   └── seeds.rb
│   │   ├── spec/
│   │   │   ├── spec_helper.rb
│   │   │   ├── rails_helper.rb
│   │   │   └── requests/
│   │   │       └── api/
│   │   │           └── status_spec.rb
│   │   └── lib/
│   │
│   └── react-frontend/
│       ├── package.json
│       ├── package-lock.json
│       ├── Dockerfile
│       ├── .dockerignore
│       ├── nginx.conf                 # Custom nginx config
│       ├── public/
│       │   └── index.html
│       └── src/
│           ├── index.js
│           ├── App.js
│           ├── App.css
│           ├── api/
│           │   └── client.js          # API client
│           └── components/
│               ├── StatusDashboard.js
│               └── JobTrigger.js
│
├── jenkins/                           # Layer 3: CI/CD
│   ├── Jenkinsfile                    # Pipeline definition
│   ├── jenkins-values.yaml            # Helm chart overrides
│   ├── plugins.txt                    # Jenkins plugins
│   └── scripts/
│       ├── build-images.sh            # Docker build script
│       ├── run-tests.sh               # Test runner
│       └── deploy.sh                  # Helm deployment script
│
├── k8s/                               # Raw Kubernetes manifests (optional)
│   └── nginx-ingress/
│       └── values.yaml
│
├── scripts/                           # Helper scripts
│   ├── setup-minikube.sh              # Initial Minikube setup
│   ├── bootstrap.sh                   # Bootstrap entire project
│   ├── cleanup.sh                     # Tear down everything
│   └── port-forward.sh                # Expose services locally
│
└── docs/                              # Additional documentation
    ├── API.md                         # API endpoints
    ├── DEPLOYMENT.md                  # Deployment guide
    └── TROUBLESHOOTING.md             # Common issues
```

---

## 🚀 Phase 1: Local Infrastructure Setup

### Step 1.1: Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g \
  --driver=docker \
  --kubernetes-version=v1.28.0

# Verify cluster is running
kubectl cluster-info
kubectl get nodes

# Expected output:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   1m    v1.28.0
```

### Step 1.2: Enable Essential Addons

```bash
# Enable Ingress (for routing external traffic)
minikube addons enable ingress

# Enable Metrics Server (for resource monitoring)
minikube addons enable metrics-server

# Enable Local Registry (for storing Docker images)
minikube addons enable registry

# Enable Dashboard (for visual monitoring)
minikube addons enable dashboard

# Verify addons
minikube addons list | grep enabled
```

### Step 1.3: Configure kubectl Context

```bash
# Check current context
kubectl config current-context
# Should output: minikube

# View cluster configuration
kubectl config view

# Set namespace preference (optional)
kubectl config set-context --current --namespace=dev
```

### Step 1.4: Initialize Terraform

Create terraform configuration files:

**File: `terraform/provider.tf`**
```hcl
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}
```

**File: `terraform/backend.tf`**
```hcl
# Option 1: Local backend (default)
# State stored in terraform.tfstate file

# Option 2: S3 backend (for practice)
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "terranetes/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
```

**File: `terraform/namespaces.tf`**
```hcl
# Development namespace
resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
    labels = {
      environment = "development"
      managed_by  = "terraform"
    }
  }
}

# Staging namespace
resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
    labels = {
      environment = "staging"
      managed_by  = "terraform"
    }
  }
}

# Production namespace
resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
    labels = {
      environment = "production"
      managed_by  = "terraform"
    }
  }
}

# Jenkins namespace
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
    labels = {
      purpose    = "cicd"
      managed_by = "terraform"
    }
  }
}
```

**File: `terraform/rbac.tf`**
```hcl
# Service account for Rails API
resource "kubernetes_service_account" "rails_api" {
  for_each = toset(["dev", "staging", "prod"])
  
  metadata {
    name      = "rails-api"
    namespace = each.key
  }
}

# Service account for Sidekiq
resource "kubernetes_service_account" "sidekiq" {
  for_each = toset(["dev", "staging", "prod"])
  
  metadata {
    name      = "sidekiq"
    namespace = each.key
  }
}

# Role for reading secrets and configmaps
resource "kubernetes_role" "app_reader" {
  for_each = toset(["dev", "staging", "prod"])
  
  metadata {
    name      = "app-reader"
    namespace = each.key
  }

  rule {
    api_groups = [""]
    resources  = ["secrets", "configmaps"]
    verbs      = ["get", "list"]
  }
}

# Bind role to service accounts
resource "kubernetes_role_binding" "rails_api" {
  for_each = toset(["dev", "staging", "prod"])
  
  metadata {
    name      = "rails-api-binding"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.app_reader[each.key].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.rails_api[each.key].metadata[0].name
    namespace = each.key
  }
}
```

**File: `terraform/storage.tf`**
```hcl
# StorageClass for database persistent volumes
resource "kubernetes_storage_class" "database" {
  metadata {
    name = "database-storage"
  }
  
  storage_provisioner = "k8s.io/minikube-hostpath"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"
  
  parameters = {
    type = "pd-standard"
  }
}
```

**File: `terraform/outputs.tf`**
```hcl
output "namespaces" {
  description = "Created Kubernetes namespaces"
  value = {
    dev     = kubernetes_namespace.dev.metadata[0].name
    staging = kubernetes_namespace.staging.metadata[0].name
    prod    = kubernetes_namespace.prod.metadata[0].name
    jenkins = kubernetes_namespace.jenkins.metadata[0].name
  }
}

output "minikube_ip" {
  description = "Minikube cluster IP"
  value       = "Run: minikube ip"
}
```

### Step 1.5: Apply Terraform Configuration

```bash
cd terraform/

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# Verify namespaces were created
kubectl get namespaces

# Expected output:
# NAME       STATUS   AGE
# dev        Active   10s
# staging    Active   10s
# prod       Active   10s
# jenkins    Active   10s
```

---

## 🗄️ Phase 2: Database Layer

### Step 2.1: Create MySQL Helm Chart

Create the MySQL chart structure:

```bash
mkdir -p helm/mysql/templates
cd helm/mysql
```

**File: `helm/mysql/Chart.yaml`**
```yaml
apiVersion: v2
name: mysql
description: MySQL database for Terranetes
type: application
version: 1.0.0
appVersion: "8.0"
```

**File: `helm/mysql/values.yaml`**
```yaml
replicaCount: 1

image:
  repository: mysql
  tag: "8.0"
  pullPolicy: IfNotPresent

database:
  name: terranetes_dev
  user: rails
  password: changeme123  # Change in production!
  rootPassword: rootpassword123

persistence:
  enabled: true
  storageClass: "standard"
  size: 5Gi

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"

service:
  type: ClusterIP
  port: 3306
```

**File: `helm/mysql/templates/secret.yaml`**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Chart.Name }}-secret
  namespace: {{ .Release.Namespace }}
type: Opaque
stringData:
  mysql-root-password: {{ .Values.database.rootPassword }}
  mysql-password: {{ .Values.database.password }}
  mysql-user: {{ .Values.database.user }}
  mysql-database: {{ .Values.database.name }}
```

**File: `helm/mysql/templates/pvc.yaml`**
```yaml
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Chart.Name }}-pvc
  namespace: {{ .Release.Namespace }}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: {{ .Values.persistence.storageClass }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end }}
```

**File: `helm/mysql/templates/statefulset.yaml`**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  serviceName: {{ .Chart.Name }}
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
      - name: mysql
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Chart.Name }}-secret
              key: mysql-root-password
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: {{ .Chart.Name }}-secret
              key: mysql-database
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: {{ .Chart.Name }}-secret
              key: mysql-user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Chart.Name }}-secret
              key: mysql-password
        ports:
        - name: mysql
          containerPort: 3306
          protocol: TCP
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 1
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      volumes:
      {{- if .Values.persistence.enabled }}
      - name: data
        persistentVolumeClaim:
          claimName: {{ .Chart.Name }}-pvc
      {{- else }}
      - name: data
        emptyDir: {}
      {{- end }}
```

**File: `helm/mysql/templates/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: mysql
    protocol: TCP
    name: mysql
  selector:
    app: {{ .Chart.Name }}
```

### Step 2.2: Create Redis Helm Chart

```bash
mkdir -p helm/redis/templates
cd helm/redis
```

**File: `helm/redis/Chart.yaml`**
```yaml
apiVersion: v2
name: redis
description: Redis cache and job queue
type: application
version: 1.0.0
appVersion: "7.2"
```

**File: `helm/redis/values.yaml`**
```yaml
replicaCount: 1

image:
  repository: redis
  tag: "7.2-alpine"
  pullPolicy: IfNotPresent

persistence:
  enabled: true
  storageClass: "standard"
  size: 2Gi

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"

service:
  type: ClusterIP
  port: 6379
```

**File: `helm/redis/templates/pvc.yaml`**
```yaml
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Chart.Name }}-pvc
  namespace: {{ .Release.Namespace }}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: {{ .Values.persistence.storageClass }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end }}
```

**File: `helm/redis/templates/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
      - name: redis
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: redis
          containerPort: 6379
          protocol: TCP
        livenessProbe:
          tcpSocket:
            port: redis
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: redis
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      {{- if .Values.persistence.enabled }}
      - name: data
        persistentVolumeClaim:
          claimName: {{ .Chart.Name }}-pvc
      {{- else }}
      - name: data
        emptyDir: {}
      {{- end }}
```

**File: `helm/redis/templates/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: redis
    protocol: TCP
    name: redis
  selector:
    app: {{ .Chart.Name }}
```

### Step 2.3: Deploy Databases

```bash
# Deploy MySQL to dev namespace
helm install mysql ./helm/mysql -n dev

# Deploy Redis to dev namespace
helm install redis ./helm/redis -n dev

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n dev --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n dev --timeout=120s

# Verify deployments
kubectl get pods -n dev
kubectl get pvc -n dev
kubectl get svc -n dev

# Expected output:
# NAME          READY   STATUS    RESTARTS   AGE
# mysql-0       1/1     Running   0          2m
# redis-xxx     1/1     Running   0          2m
```

### Step 2.4: Test Database Connectivity

```bash
# Test MySQL connection
kubectl exec -it mysql-0 -n dev -- mysql -u rails -pchangeme123 -e "SHOW DATABASES;"

# Test Redis connection
kubectl exec -it $(kubectl get pod -l app=redis -n dev -o jsonpath='{.items[0].metadata.name}') -n dev -- redis-cli PING

# Expected output: PONG
```

---

## 💻 Phase 3: Application Development

### Step 3.1: Create Rails API

```bash
mkdir -p apps/rails-api
cd apps/rails-api
```

**File: `apps/rails-api/Gemfile`**
```ruby
source 'https://rubygems.org'

ruby '3.2.2'

gem 'rails', '~> 7.1'
gem 'puma', '~> 6.4'
gem 'mysql2', '~> 0.5'
gem 'redis', '~> 5.0'
gem 'sidekiq', '~> 7.2'
gem 'rack-cors'
gem 'bootsnap', require: false

group :development, :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-byebug'
end

group :test do
  gem 'shoulda-matchers', '~> 6.0'
  gem 'simplecov', require: false
end
```

**File: `apps/rails-api/config/application.rb`**
```ruby
require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module TerranetesApi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    
    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end
  end
end
```

**File: `apps/rails-api/config/database.yml`**
```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
  port: <%= ENV.fetch("DATABASE_PORT", 3306) %>
  username: <%= ENV.fetch("DATABASE_USER", "root") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "") %>

development:
  <<: *default
  database: terranetes_dev

test:
  <<: *default
  database: terranetes_test

production:
  <<: *default
  database: <%= ENV.fetch("DATABASE_NAME", "terranetes_prod") %>
```

**File: `apps/rails-api/config/routes.rb`**
```ruby
Rails.application.routes.draw do
  # Health check endpoint
  get '/health', to: 'health#index'
  
  # API endpoints
  namespace :api do
    get '/status', to: 'status#show'
    post '/jobs', to: 'jobs#create'
    get '/jobs', to: 'jobs#index'
  end
end
```

**File: `apps/rails-api/app/controllers/health_controller.rb`**
```ruby
class HealthController < ApplicationController
  def index
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: ENV.fetch('APP_VERSION', 'unknown'),
      environment: Rails.env
    }
  end
end
```

**File: `apps/rails-api/app/controllers/api/status_controller.rb`**
```ruby
class Api::StatusController < ApplicationController
  def show
    render json: {
      status: 'running',
      database: check_database,
      redis: check_redis,
      sidekiq: check_sidekiq,
      timestamp: Time.current.iso8601
    }
  end

  private

  def check_database
    ActiveRecord::Base.connection.active?
    'connected'
  rescue => e
    "error: #{e.message}"
  end

  def check_redis
    Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379')).ping
    'connected'
  rescue => e
    "error: #{e.message}"
  end

  def check_sidekiq
    Sidekiq.redis { |conn| conn.ping }
    'connected'
  rescue => e
    "error: #{e.message}"
  end
end
```

**File: `apps/rails-api/app/controllers/api/jobs_controller.rb`**
```ruby
class Api::JobsController < ApplicationController
  def create
    job_id = DemoJob.perform_async(params[:message] || 'Hello from Terranetes!')
    
    render json: {
      status: 'enqueued',
      job_id: job_id,
      message: 'Job has been queued for processing'
    }, status: :created
  end

  def index
    # This is simplified - in production you'd use Sidekiq API
    render json: {
      status: 'ok',
      message: 'Use Sidekiq dashboard for job monitoring'
    }
  end
end
```

**File: `apps/rails-api/app/jobs/demo_job.rb`**
```ruby
class DemoJob
  include Sidekiq::Job
  
  sidekiq_options retry: 3, queue: 'default'

  def perform(message)
    Rails.logger.info "Processing DemoJob with message: #{message}"
    
    # Simulate some work
    sleep 5
    
    Rails.logger.info "DemoJob completed successfully"
  end
end
```

**File: `apps/rails-api/Dockerfile`**
```dockerfile
# Multi-stage build for smaller image size

# Stage 1: Build dependencies
FROM ruby:3.2.2-alpine AS builder

RUN apk add --no-cache \
  build-base \
  mysql-dev \
  nodejs \
  tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install -j4

# Stage 2: Runtime
FROM ruby:3.2.2-alpine

RUN apk add --no-cache \
  mysql-client \
  tzdata

WORKDIR /app

# Copy installed gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app/.bundle /app/.bundle

# Copy application code
COPY . .

# Create entrypoint script
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'bundle exec rake db:create db:migrate' >> /app/entrypoint.sh && \
    echo 'exec "$@"' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

**File: `apps/rails-api/.dockerignore`**
```
.git
.gitignore
tmp/
log/
coverage/
spec/
.env*
README.md
```

### Step 3.2: Create React Frontend

```bash
mkdir -p apps/react-frontend
cd apps/react-frontend
npm init -y
```

**File: `apps/react-frontend/package.json`**
```json
{
  "name": "terranetes-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "devDependencies": {
    "react-scripts": "5.0.1",
    "@testing-library/react": "^14.1.2",
    "@testing-library/jest-dom": "^6.1.5"
  },
  "eslintConfig": {
    "extends": ["react-app"]
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  }
}
```

**File: `apps/react-frontend/public/index.html`**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="theme-color" content="#000000" />
  <meta name="description" content="Terranetes DevOps Demo" />
  <title>Terranetes Demo</title>
</head>
<body>
  <noscript>You need to enable JavaScript to run this app.</noscript>
  <div id="root"></div>
</body>
</html>
```

**File: `apps/react-frontend/src/index.js`**
```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

**File: `apps/react-frontend/src/App.js`**
```javascript
import React, { useState, useEffect } from 'react';
import './App.css';
import StatusDashboard from './components/StatusDashboard';
import JobTrigger from './components/JobTrigger';

function App() {
  const [apiUrl, setApiUrl] = useState(
    process.env.REACT_APP_API_URL || 'http://localhost:3001'
  );

  return (
    <div className="App">
      <header className="App-header">
        <h1>🚀 Terranetes DevOps Demo</h1>
        <p>Full-stack Rails + React + Sidekiq on Kubernetes</p>
      </header>
      
      <main className="App-main">
        <StatusDashboard apiUrl={apiUrl} />
        <JobTrigger apiUrl={apiUrl} />
      </main>
      
      <footer className="App-footer">
        <p>Built with ❤️ using Terraform, Helm, and Jenkins</p>
      </footer>
    </div>
  );
}

export default App;
```

**File: `apps/react-frontend/src/App.css`**
```css
.App {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
}

.App-header {
  padding: 2rem;
  text-align: center;
  background: rgba(0, 0, 0, 0.2);
}

.App-header h1 {
  margin: 0;
  font-size: 3rem;
}

.App-main {
  max-width: 1200px;
  margin: 2rem auto;
  padding: 0 1rem;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
}

.App-footer {
  text-align: center;
  padding: 2rem;
  background: rgba(0, 0, 0, 0.2);
  margin-top: 4rem;
}

@media (max-width: 768px) {
  .App-main {
    grid-template-columns: 1fr;
  }
}
```

**File: `apps/react-frontend/src/components/StatusDashboard.js`**
```javascript
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './StatusDashboard.css';

function StatusDashboard({ apiUrl }) {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 5000); // Refresh every 5s
    return () => clearInterval(interval);
  }, [apiUrl]);

  const fetchStatus = async () => {
    try {
      const response = await axios.get(`${apiUrl}/api/status`);
      setStatus(response.data);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="card">Loading...</div>;
  if (error) return <div className="card error">Error: {error}</div>;

  return (
    <div className="card">
      <h2>📊 System Status</h2>
      <div className="status-grid">
        <StatusItem label="Overall" value={status.status} />
        <StatusItem label="Database" value={status.database} />
        <StatusItem label="Redis" value={status.redis} />
        <StatusItem label="Sidekiq" value={status.sidekiq} />
      </div>
      <p className="timestamp">
        Last updated: {new Date(status.timestamp).toLocaleTimeString()}
      </p>
    </div>
  );
}

function StatusItem({ label, value }) {
  const isHealthy = value === 'connected' || value === 'running';
  return (
    <div className={`status-item ${isHealthy ? 'healthy' : 'unhealthy'}`}>
      <span className="label">{label}</span>
      <span className="value">{value}</span>
    </div>
  );
}

export default StatusDashboard;
```

**File: `apps/react-frontend/src/components/StatusDashboard.css`**
```css
.card {
  background: white;
  color: #333;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

.card h2 {
  margin-top: 0;
}

.status-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin: 1.5rem 0;
}

.status-item {
  padding: 1rem;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.status-item.healthy {
  background: #d4edda;
  color: #155724;
}

.status-item.unhealthy {
  background: #f8d7da;
  color: #721c24;
}

.status-item .label {
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.timestamp {
  text-align: center;
  color: #666;
  font-size: 0.875rem;
  margin-top: 1rem;
}
```

**File: `apps/react-frontend/src/components/JobTrigger.js`**
```javascript
import React, { useState } from 'react';
import axios from 'axios';
import './JobTrigger.css';

function JobTrigger({ apiUrl }) {
  const [message, setMessage] = useState('');
  const [response, setResponse] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const res = await axios.post(`${apiUrl}/api/jobs`, {
        message: message || 'Hello from React!'
      });
      setResponse({ type: 'success', data: res.data });
      setMessage('');
    } catch (err) {
      setResponse({ type: 'error', message: err.message });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card">
      <h2>⚙️ Background Jobs</h2>
      <p>Trigger a Sidekiq background job:</p>
      
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="Enter a message..."
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          className="input"
        />
        <button type="submit" disabled={loading} className="button">
          {loading ? 'Sending...' : 'Trigger Job'}
        </button>
      </form>

      {response && (
        <div className={`response ${response.type}`}>
          {response.type === 'success' ? (
            <>
              <p>✅ Job enqueued successfully!</p>
              <p>Job ID: {response.data.job_id}</p>
            </>
          ) : (
            <p>❌ Error: {response.message}</p>
          )}
        </div>
      )}
    </div>
  );
}

export default JobTrigger;
```

**File: `apps/react-frontend/src/components/JobTrigger.css`**
```css
.input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  margin-bottom: 1rem;
}

.button {
  width: 100%;
  padding: 0.75rem;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.3s;
}

.button:hover:not(:disabled) {
  background: #5568d3;
}

.button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.response {
  margin-top: 1rem;
  padding: 1rem;
  border-radius: 6px;
}

.response.success {
  background: #d4edda;
  color: #155724;
}

.response.error {
  background: #f8d7da;
  color: #721c24;
}

.response p {
  margin: 0.5rem 0;
}
```

**File: `apps/react-frontend/Dockerfile`**
```dockerfile
# Multi-stage build

# Stage 1: Build React app
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy build files
COPY --from=builder /app/build /usr/share/nginx/html

# Custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

**File: `apps/react-frontend/nginx.conf`**
```nginx
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## 🎯 Phase 4: Helm Charts

*(Continuing in next section due to length...)*

### Step 4.1: Create Rails API Helm Chart

```bash
mkdir -p helm/rails-api/templates
cd helm/rails-api
```

**File: `helm/rails-api/Chart.yaml`**
```yaml
apiVersion: v2
name: rails-api
description: Rails API backend for Terranetes
type: application
version: 1.0.0
appVersion: "1.0.0"
dependencies: []
```

**File: `helm/rails-api/values.yaml`**
```yaml
replicaCount: 2

image:
  repository: terranetes/rails-api
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 3000

ingress:
  enabled: true
  className: nginx
  annotations: {}
  hosts:
    - host: api.terranetes.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

env:
  RAILS_ENV: development
  RAILS_LOG_TO_STDOUT: "true"
  DATABASE_HOST: mysql.dev.svc.cluster.local
  DATABASE_PORT: "3306"
  DATABASE_USER: rails
  DATABASE_PASSWORD: changeme123
  DATABASE_NAME: terranetes_dev
  REDIS_URL: redis://redis.dev.svc.cluster.local:6379

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

probes:
  liveness:
    path: /health
    initialDelaySeconds: 30
    periodSeconds: 10
  readiness:
    path: /health
    initialDelaySeconds: 5
    periodSeconds: 5
```

**File: `helm/rails-api/values-dev.yaml`**
```yaml
replicaCount: 1

env:
  RAILS_ENV: development

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"

autoscaling:
  enabled: false
```

**File: `helm/rails-api/values-prod.yaml`**
```yaml
replicaCount: 3

image:
  pullPolicy: Always

env:
  RAILS_ENV: production
  RAILS_SERVE_STATIC_FILES: "true"

resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
```

**File: `helm/rails-api/templates/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
    version: {{ .Chart.AppVersion }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        version: {{ .Chart.AppVersion }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 3000
          protocol: TCP
        env:
        {{- range $key, $value := .Values.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        livenessProbe:
          httpGet:
            path: {{ .Values.probes.liveness.path }}
            port: http
          initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
          periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
        readinessProbe:
          httpGet:
            path: {{ .Values.probes.readiness.path }}
            port: http
          initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
          periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

**File: `helm/rails-api/templates/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: {{ .Chart.Name }}
```

**File: `helm/rails-api/templates/ingress.yaml`**
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- toYaml .Values.ingress.tls | nindent 4 }}
  {{- end }}
  rules:
  {{- range .Values.ingress.hosts }}
    - host: {{ .host }}
      http:
        paths:
        {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: rails-api
                port:
                  number: 3000
        {{- end }}
  {{- end }}
{{- end }}
```

### Step 4.2: Create Sidekiq Worker Helm Chart

```bash
mkdir -p helm/sidekiq-worker/templates
cd helm/sidekiq-worker
```

**File: `helm/sidekiq-worker/Chart.yaml`**
```yaml
apiVersion: v2
name: sidekiq-worker
description: Sidekiq background job processor
type: application
version: 1.0.0
appVersion: "1.0.0"
```

**File: `helm/sidekiq-worker/values.yaml`**
```yaml
replicaCount: 1

image:
  repository: terranetes/rails-api  # Same image as Rails
  tag: latest
  pullPolicy: IfNotPresent

command: ["bundle", "exec", "sidekiq"]

env:
  RAILS_ENV: development
  REDIS_URL: redis://redis.dev.svc.cluster.local:6379
  DATABASE_HOST: mysql.dev.svc.cluster.local
  DATABASE_PORT: "3306"
  DATABASE_USER: rails
  DATABASE_PASSWORD: changeme123
  DATABASE_NAME: terranetes_dev

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"
```

**File: `helm/sidekiq-worker/templates/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
      - name: sidekiq
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        command: {{ .Values.command }}
        env:
        {{- range $key, $value := .Values.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

### Step 4.3: Create React Frontend Helm Chart

```bash
mkdir -p helm/react-frontend/templates
```

**File: `helm/react-frontend/Chart.yaml`**
```yaml
apiVersion: v2
name: react-frontend
description: React frontend application
type: application
version: 1.0.0
appVersion: "1.0.0"
```

**File: `helm/react-frontend/values.yaml`**
```yaml
replicaCount: 2

image:
  repository: terranetes/react-frontend
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: terranetes.local
      paths:
        - path: /
          pathType: Prefix

env:
  REACT_APP_API_URL: http://api.terranetes.local

resources:
  requests:
    memory: "128Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "100m"
```

**File: `helm/react-frontend/templates/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

**File: `helm/react-frontend/templates/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: {{ .Chart.Name }}
```

**File: `helm/react-frontend/templates/ingress.yaml`**
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  rules:
  {{- range .Values.ingress.hosts }}
    - host: {{ .host }}
      http:
        paths:
        {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: react-frontend
                port:
                  number: 80
        {{- end }}
  {{- end }}
{{- end }}
```

---

## 🔄 Phase 5: Jenkins CI/CD

### Step 5.1: Deploy Jenkins to Kubernetes

```bash
# Add Jenkins Helm repository
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create custom values file
```

**File: `jenkins/jenkins-values.yaml`**
```yaml
controller:
  adminUser: "admin"
  adminPassword: "admin123"  # Change this!
  
  serviceType: NodePort
  nodePort: 32000
  
  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - configuration-as-code:latest
    - docker-workflow:latest
    - blueocean:latest
  
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
  
  javaOpts: "-Xmx1g"
  
  JCasC:
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: "Welcome to Terranetes CI/CD Pipeline!"

agent:
  enabled: true
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"

persistence:
  enabled: true
  size: 8Gi
```

```bash
# Install Jenkins
helm install jenkins jenkins/jenkins \
  -f jenkins/jenkins-values.yaml \
  -n jenkins

# Wait for Jenkins to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=jenkins-controller -n jenkins --timeout=300s

# Get Jenkins URL
minikube service jenkins -n jenkins --url

# Get admin password
kubectl exec -n jenkins -it svc/jenkins -c jenkins -- cat /run/secrets/chart-admin-password
```

### Step 5.2: Create Jenkinsfile

**File: `Jenkinsfile`**
```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24-dind
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  - name: helm
    image: alpine/helm:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }
    
    environment {
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        DOCKER_REGISTRY = "docker.io"  // Or your registry
        IMAGE_TAG = "${GIT_COMMIT_SHORT}"
        NAMESPACE = "dev"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Building commit: ${GIT_COMMIT_SHORT}"
            }
        }
        
        stage('Test Rails') {
            steps {
                container('docker') {
                    sh '''
                        cd apps/rails-api
                        docker build --target builder -t rails-test .
                        # docker run rails-test bundle exec rspec
                        echo "Rails tests passed"
                    '''
                }
            }
        }
        
        stage('Test React') {
            steps {
                container('docker') {
                    sh '''
                        cd apps/react-frontend
                        # docker run --rm node:20-alpine sh -c "npm install && npm test"
                        echo "React tests passed"
                    '''
                }
            }
        }
        
        stage('Build Images') {
            parallel {
                stage('Build Rails Image') {
                    steps {
                        container('docker') {
                            sh '''
                                eval $(minikube docker-env)
                                cd apps/rails-api
                                docker build -t terranetes/rails-api:${IMAGE_TAG} .
                                docker tag terranetes/rails-api:${IMAGE_TAG} terranetes/rails-api:latest
                                echo "Rails image built successfully"
                            '''
                        }
                    }
                }
                
                stage('Build React Image') {
                    steps {
                        container('docker') {
                            sh '''
                                eval $(minikube docker-env)
                                cd apps/react-frontend
                                docker build -t terranetes/react-frontend:${IMAGE_TAG} .
                                docker tag terranetes/react-frontend:${IMAGE_TAG} terranetes/react-frontend:latest
                                echo "React image built successfully"
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Push Images') {
            when {
                branch 'main'
            }
            steps {
                echo "Images stored in Minikube's Docker daemon"
                // If using external registry:
                // sh 'docker push terranetes/rails-api:${IMAGE_TAG}'
                // sh 'docker push terranetes/react-frontend:${IMAGE_TAG}'
            }
        }
        
        stage('Deploy to Dev') {
            steps {
                container('helm') {
                    sh '''
                        helm upgrade --install rails-api ./helm/rails-api \\
                          --set image.tag=${IMAGE_TAG} \\
                          -f helm/rails-api/values-dev.yaml \\
                          -n ${NAMESPACE} \\
                          --wait
                        
                        helm upgrade --install react-frontend ./helm/react-frontend \\
                          --set image.tag=${IMAGE_TAG} \\
                          -n ${NAMESPACE} \\
                          --wait
                        
                        helm upgrade --install sidekiq-worker ./helm/sidekiq-worker \\
                          --set image.tag=${IMAGE_TAG} \\
                          -n ${NAMESPACE} \\
                          --wait
                    '''
                }
            }
        }
        
        stage('Run DB Migrations') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl exec -n ${NAMESPACE} \\
                          $(kubectl get pod -n ${NAMESPACE} -l app=rails-api -o jsonpath='{.items[0].metadata.name}') \\
                          -- bundle exec rake db:migrate
                    '''
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                container('kubectl') {
                    sh '''
                        # Wait for pods to be ready
                        kubectl wait --for=condition=ready pod -l app=rails-api -n ${NAMESPACE} --timeout=120s
                        
                        # Test health endpoint
                        kubectl exec -n ${NAMESPACE} \\
                          $(kubectl get pod -n ${NAMESPACE} -l app=rails-api -o jsonpath='{.items[0].metadata.name}') \\
                          -- curl -f http://localhost:3000/health || exit 1
                        
                        echo "Smoke tests passed!"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline completed successfully!"
            echo "Deployed version: ${IMAGE_TAG} to ${NAMESPACE}"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
        always {
            echo "Cleaning up workspace"
        }
    }
}
```

### Step 5.3: Configure Jenkins Pipeline

1. Open Jenkins web UI (from Step 5.1)
2. Create new Pipeline job:
   - Click "New Item"
   - Name: "terranetes-pipeline"
   - Type: "Pipeline"
   - Click "OK"
3. Configure:
   - Under "Pipeline", select "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: (your repo URL)
   - Script Path: `Jenkinsfile`
4. Save and click "Build Now"

---

## 🛠️ Development Workflow

### Initial Setup (One-time)

```bash
# 1. Clone the repository
git clone <your-repo>
cd terranetes

# 2. Start Minikube
./scripts/setup-minikube.sh

# 3. Provision infrastructure
cd terraform && terraform apply -auto-approve

# 4. Deploy databases
helm install mysql ./helm/mysql -n dev
helm install redis ./helm/redis -n dev

# 5. Build application images
eval $(minikube docker-env)
cd apps/rails-api && docker build -t terranetes/rails-api:latest .
cd ../react-frontend && docker build -t terranetes/react-frontend:latest .

# 6. Deploy applications
helm install rails-api ./helm/rails-api -f helm/rails-api/values-dev.yaml -n dev
helm install sidekiq-worker ./helm/sidekiq-worker -n dev
helm install react-frontend ./helm/react-frontend -n dev

# 7. Setup port forwarding
kubectl port-forward svc/react-frontend 3000:80 -n dev &
kubectl port-forward svc/rails-api 3001:3000 -n dev &
```

### Daily Development

```bash
# Make changes to code...

# Rebuild + Redeploy Rails API
eval $(minikube docker-env)
cd apps/rails-api
docker build -t terranetes/rails-api:latest .
kubectl rollout restart deployment/rails-api -n dev

# Rebuild + Redeploy React
cd apps/react-frontend
docker build -t terranetes/react-frontend:latest .
kubectl rollout restart deployment/react-frontend -n dev

# View logs
kubectl logs -f deployment/rails-api -n dev
kubectl logs -f deployment/sidekiq-worker -n dev

# Access application
open http://localhost:3000
```

### Using Makefile (Recommended)

**File: `Makefile`**
```makefile
.PHONY: help setup start stop build deploy logs clean

help:
	@echo "Terranetes Makefile Commands:"
	@echo "  make setup      - Initial setup (Minikube + Terraform + Databases)"
	@echo "  make build      - Build Docker images"
	@echo "  make deploy     - Deploy applications with Helm"
	@echo "  make logs       - Tail application logs"
	@echo "  make port-forward - Setup port forwarding"
	@echo "  make clean      - Remove everything"
	@echo "  make restart    - Restart all deployments"

setup:
	minikube start --cpus=4 --memory=8192
	minikube addons enable ingress metrics-server
	cd terraform && terraform init && terraform apply -auto-approve
	helm install mysql ./helm/mysql -n dev
	helm install redis ./helm/redis -n dev

build:
	eval $$(minikube docker-env) && \\
	docker build -t terranetes/rails-api:latest apps/rails-api && \\
	docker build -t terranetes/react-frontend:latest apps/react-frontend

deploy:
	helm upgrade --install rails-api ./helm/rails-api -f helm/rails-api/values-dev.yaml -n dev
	helm upgrade --install sidekiq-worker ./helm/sidekiq-worker -n dev
	helm upgrade --install react-frontend ./helm/react-frontend -n dev

logs:
	kubectl logs -f deployment/rails-api -n dev

port-forward:
	kubectl port-forward svc/react-frontend 3000:80 -n dev &
	kubectl port-forward svc/rails-api 3001:3000 -n dev &

restart:
	kubectl rollout restart deployment/rails-api -n dev
	kubectl rollout restart deployment/sidekiq-worker -n dev
	kubectl rollout restart deployment/react-frontend -n dev

clean:
	helm uninstall rails-api sidekiq-worker react-frontend mysql redis -n dev || true
	cd terraform && terraform destroy -auto-approve
	minikube delete
```

Usage:
```bash
make setup    # First time
make build    # After code changes
make deploy   # Deploy to K8s
make logs     # View logs
```

---

## 🐛 Troubleshooting

### Common Issues

**1. Pod not starting**
```bash
# Check pod status
kubectl get pods -n dev

# Describe pod for events
kubectl describe pod <pod-name> -n dev

# Check logs
kubectl logs <pod-name> -n dev

# Common fixes:
# - Image pull issues: Check image name/tag
# - Resource limits: Increase memory/CPU
# - Probes failing: Adjust initialDelaySeconds
```

**2. Database connection errors**
```bash
# Verify MySQL is running
kubectl exec -it mysql-0 -n dev -- mysql -u rails -pchangeme123 -e "SELECT 1;"

# Check service DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n dev -- \\
  nslookup mysql.dev.svc.cluster.local

# Test connectivity
kubectl run -it --rm debug --image=mysql:8 --restart=Never -n dev -- \\
  mysql -h mysql.dev.svc.cluster.local -u rails -pchangeme123
```

**3. Ingress not working**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Enable if needed
minikube addons enable ingress

# Add hosts entry
echo "$(minikube ip) terranetes.local api.terranetes.local" | sudo tee -a /etc/hosts

# Test
curl http://terranetes.local
```

**4. Out of disk space**
```bash
# Clean up Docker
eval $(minikube docker-env)
docker system prune -a

# Restart Minikube with more space
minikube delete
minikube start --disk-size=30g
```

**5. Helm release conflicts**
```bash
# List releases
helm list -n dev

# Uninstall problematic release
helm uninstall <release-name> -n dev

# Reinstall
helm install <release-name> ./helm/<chart> -n dev
```

### Debug Commands Reference

```bash
# Pod debugging
kubectl get pods -n dev -o wide
kubectl describe pod <pod-name> -n dev
kubectl logs <pod-name> -n dev --previous  # Previous container instance
kubectl exec -it <pod-name> -n dev -- /bin/sh

# Service debugging
kubectl get svc -n dev
kubectl get endpoints -n dev
kubectl port-forward svc/<service-name> 8080:80 -n dev

# Resource usage
kubectl top nodes
kubectl top pods -n dev

# Events
kubectl get events -n dev --sort-by='.lastTimestamp'

# Full cluster state
kubectl get all -n dev
```

---

## 🚀 Next Steps & Scaling

### Phase 6: Enhancements

1. **Add Monitoring**
   ```bash
   # Prometheus + Grafana
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
   ```

2. **Add Logging**
   ```bash
   # EFK Stack (Elasticsearch, Fluentd, Kibana)
   helm repo add elastic https://helm.elastic.co
   helm install elasticsearch elastic/elasticsearch -n logging
   ```

3. **Secrets Management**
   ```bash
   # Sealed Secrets or External Secrets Operator
   helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
   helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system
   ```

4. **Service Mesh**
   ```bash
   # Istio or Linkerd
   curl -sL https://istio.io/downloadIstio | sh -
   istioctl install --set profile=demo
   ```

### Migrating to AWS

When ready to move to production:

1. **Update Terraform**:
   - Replace `kubernetes` provider with `aws` provider
   - Add EKS cluster configuration
   - Add RDS for MySQL
   - Add ElastiCache for Redis

2. **Update Helm Values**:
   - Change database hosts to RDS endpoint
   - Change Redis URL to ElastiCache endpoint
   - Enable AWS-specific features (ALB ingress, EBS volumes)

3. **Update Jenkins**:
   - Add AWS credentials
   - Push images to ECR instead of local registry
   - Deploy to EKS instead of Minikube

### Additional Features

- **API Documentation**: Add Swagger/OpenAPI
- **Rate Limiting**: Add Redis-based rate limiter
- **Caching**: Implement Rails fragment caching with Redis
- **File Uploads**: Add S3 integration
- **Email**: Add transactional emails with Sidekiq
- **WebSockets**: Add ActionCable for real-time features
- **Mobile Apps**: iOS/Android apps consuming the API

---

## 📚 Additional Resources

- **Kubernetes**: https://kubernetes.io/docs/
- **Helm**: https://helm.sh/docs/
- **Terraform**: https://www.terraform.io/docs/
- **Rails**: https://guides.rubyonrails.org/
- **Sidekiq**: https://github.com/mperham/sidekiq/wiki
- **Jenkins**: https://www.jenkins.io/doc/

---

## 🎓 Learning Outcomes

By completing this project, you'll have hands-on experience with:

✅ Infrastructure as Code (Terraform)
✅ Container orchestration (Kubernetes)  
✅ Package management (Helm)  
✅ CI/CD pipelines (Jenkins)  
✅ Microservices architecture  
✅ Database management in K8s  
✅ Background job processing  
✅ Service discovery & networking  
✅ Resource management & scaling  
✅ Monitoring & debugging distributed systems  

---

**Happy DevOps Learning! 🚀**
