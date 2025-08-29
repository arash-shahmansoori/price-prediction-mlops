# Kubernetes Deployment for House Price Predictor

This directory contains Kubernetes manifests for deploying the House Price Predictor application, which consists of a Streamlit frontend and a FastAPI model backend.

## Architecture Overview

```
┌─────────────┐     ┌──────────────┐
│  Streamlit  │────▶│  Model API   │
│   (UI)      │     │  (FastAPI)   │
└─────────────┘     └──────────────┘
     :30000              :30100
```

## Prerequisites

- **Running Kubernetes cluster** (Kind, Minikube, or any other) - See "Setting Up Kubernetes Cluster" section below
- kubectl CLI installed and configured
- Docker images built and pushed to registry:
  - `<your-docker-registry>/streamlit:latest`
  - `<your-docker-registry>/house-price-pred-model:latest`
  
  **Note**: Replace `<your-docker-registry>` with your actual Docker Hub username or private registry URL (e.g., `johndoe`, `gcr.io/project-id`, `myregistry.com/project`)

## Files Description

- **`kustomization.yaml`** - Kustomize configuration that manages all resources
- **`streamlit-deploy.yaml`** - Deployment manifest for Streamlit frontend
- **`streamlit-svc.yaml`** - NodePort service exposing Streamlit on port 30000
- **`model-deploy.yaml`** - Deployment manifest for Model API backend
- **`model-svc.yaml`** - NodePort service exposing Model API on port 30100

## Before You Deploy

### Update Docker Registry References

Before deploying, you must update the Docker image references in the deployment files:

1. Replace `<your-docker-registry>` in the following files:
   - `model-deploy.yaml` (line 21)
   - `streamlit-deploy.yaml` (line 21)

2. Examples of valid registry values:
   - Docker Hub: `yourusername` (e.g., `johndoe`)
   - Google Container Registry: `gcr.io/your-project-id`
   - Amazon ECR: `123456789.dkr.ecr.region.amazonaws.com`
   - Private Registry: `myregistry.com/project`

## Setting Up Kubernetes Cluster

### Option 1: Using Kind (Kubernetes in Docker)

1. **Install Kind** (if not already installed):
   ```bash
   # macOS
   brew install kind
   
   # Linux
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   ```

2. **Create a 3-node Kind cluster**:
   ```bash
   # Using the provided configuration file
   kind create cluster --name house-price-cluster --config k8s-code/helper/kind/kind-three-node-cluster.yaml
   
   # Or create a simple single-node cluster
   kind create cluster --name house-price-cluster
   ```

3. **Verify cluster is running**:
   ```bash
   kubectl cluster-info --context kind-house-price-cluster
   ```

### Option 2: Using Minikube

1. **Start Minikube**:
   ```bash
   minikube start
   ```

2. **Verify cluster is running**:
   ```bash
   kubectl cluster-info
   ```

### Verifying Kubernetes Cluster Status

Before proceeding with deployment, ensure your cluster is properly configured:

1. **Check current context**:
   ```bash
   kubectl config current-context
   ```

2. **Verify cluster connectivity**:
   ```bash
   kubectl cluster-info
   ```
   
   You should see output similar to:
   ```
   Kubernetes control plane is running at https://127.0.0.1:xxxxx
   CoreDNS is running at https://127.0.0.1:xxxxx/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
   ```

3. **Check cluster nodes**:
   ```bash
   kubectl get nodes
   ```
   
   All nodes should show `Ready` status.

4. **If using Kind, list existing clusters**:
   ```bash
   kind get clusters
   ```

## Deployment Instructions
### Using Kustomize (Recommended)

Deploy all resources with a single command:

```bash
kubectl apply -k deployment/kubernetes
```

### Manual Deployment

If you prefer to deploy resources individually:

```bash
# Create deployments
kubectl apply -f deployment/kubernetes/model-deploy.yaml
kubectl apply -f deployment/kubernetes/streamlit-deploy.yaml

# Create services
kubectl apply -f deployment/kubernetes/model-svc.yaml
kubectl apply -f deployment/kubernetes/streamlit-svc.yaml
```

## Verifying Deployment

Check if all resources are running:

```bash
# Check all resources
kubectl get all -l app=house-price-predictor

# Check pods status
kubectl get pods

# Watch pods in real-time
kubectl get pods -w
```

## Accessing the Application

Once deployed, access the services at:

- **Streamlit UI**: http://localhost:30000
- **Model API**: http://localhost:30100
- **API Health Check**: http://localhost:30100/health
- **API Documentation**: http://localhost:30100/docs
- **Cluster Visualizer**: http://localhost:32100/#scale=2

### Test the endpoints:

```bash
# Test Streamlit
curl -I http://localhost:30000

# Test Model API health
curl http://localhost:30100/health

# Test prediction endpoint (example)
curl -X POST http://localhost:30100/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [...]}'
```

## Port Mappings

| Service        | Internal Port | NodePort | URL                       |
|----------------|---------------|----------|---------------------------|
| Streamlit      | 8501          | 30000    | http://localhost:30000    |
| Model API      | 8000          | 30100    | http://localhost:30100    |
| Model Metrics  | 9100          | 30101    | http://localhost:30101    |
| Prometheus     | 9090          | 30300    | http://localhost:30300    |
| Grafana        | 3000          | 30200    | http://localhost:30200    |
| Kube Ops View  | 8080          | 32100    | http://localhost:32100    |

## Monitoring and Management

### View Logs

```bash
# Streamlit logs
kubectl logs deployment/streamlit -f

# Model API logs
kubectl logs deployment/model -f

# Logs for specific pod
kubectl logs <pod-name>
```

### Scaling

```bash
# Scale deployments
kubectl scale deployment streamlit --replicas=2
kubectl scale deployment model --replicas=3

# Enable autoscaling (requires metrics-server)
kubectl autoscale deployment model --min=1 --max=5 --cpu-percent=80
```

### Updating Deployments

```bash
# Update image
kubectl set image deployment/streamlit streamlit=<your-docker-registry>/streamlit:v2

# Edit deployment directly
kubectl edit deployment streamlit

# Check rollout status
kubectl rollout status deployment/streamlit
```

## Prometheus Monitoring Setup

### Installing Prometheus Stack

Deploy Prometheus and Grafana for monitoring your application:

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus stack with custom values
helm upgrade --install prom \
  -n monitoring \
  --create-namespace \
  prometheus-community/kube-prometheus-stack \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30200 \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30300
```

### Configuring Application Monitoring

Deploy the ServiceMonitor to enable Prometheus scraping:

```bash
# Apply ServiceMonitor configuration
kubectl apply -f deployment/monitoring/servicemonitor.yaml
```

### Accessing Monitoring Services

| Service     | NodePort | URL                        | Default Credentials    |
|-------------|----------|----------------------------|------------------------|
| Prometheus  | 30300    | http://localhost:30300     | No auth required       |
| Grafana     | 30200    | http://localhost:30200     | admin / prom-operator  |

### Verifying Metrics Collection

1. **Check application metrics endpoints**:
   ```bash
   # FastAPI metrics on port 8000
   curl http://localhost:30100/metrics
   
   # Prometheus client metrics on port 9100
   curl http://localhost:30101/
   ```

2. **Query metrics in Prometheus**:
   - Go to http://localhost:30300
   - Try queries like:
     - `http_requests_total`
     - `rate(http_requests_total[5m])`
     - `histogram_quantile(0.95, http_request_duration_seconds_bucket)`

### Available Metrics

The FastAPI application exposes metrics through two endpoints:

1. **Port 8000 `/metrics`** - FastAPI-specific metrics via `prometheus-fastapi-instrumentator`:
   - `http_requests_total` - Total HTTP requests by method, status, and handler
   - `http_request_duration_seconds` - Request latency histogram
   - `http_request_size_bytes` - Size of incoming requests
   - `http_response_size_bytes` - Size of outgoing responses
   - `http_requests_in_progress` - Currently active requests

2. **Port 9100 `/`** - Raw Prometheus client metrics:
   - Python runtime metrics (GC, memory usage)
   - Process metrics (CPU, file descriptors)
   - Custom application metrics (if added)

### Monitoring Troubleshooting

If you encounter issues with metrics not appearing in Prometheus, refer to the comprehensive troubleshooting guide:

📚 **[Prometheus Monitoring Troubleshooting Guide](../monitoring/TROUBLESHOOTING.md)**

This guide covers:
- Common ServiceMonitor configuration issues
- Service label and selector mismatches
- Debugging steps for metric collection
- Essential fixes and verification commands

## Troubleshooting

### Common Issues

1. **Pods stuck in ContainerCreating**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name>
   
   # Check if images can be pulled
   kubectl get events --sort-by='.lastTimestamp'
   ```

2. **Services not accessible**
   ```bash
   # Verify service endpoints
   kubectl get endpoints
   
   # Check service configuration
   kubectl describe service streamlit
   ```

3. **Application errors**
   ```bash
   # Check pod logs
   kubectl logs <pod-name> --previous
   
   # Execute into pod for debugging
   kubectl exec -it <pod-name> -- /bin/bash
   ```

### Useful Debugging Commands

```bash
# Get detailed pod information
kubectl describe pod <pod-name>

# Check resource usage
kubectl top nodes
kubectl top pods

# Port forward for testing
kubectl port-forward deployment/streamlit 8501:8501

# Check cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Configuration with Kustomize

The `kustomization.yaml` file applies common configurations:

- **Common Labels**: `app: house-price-predictor` and `environment: production`
- **Resources**: Manages all 4 YAML files (deployments and services)

To customize for different environments, create overlays:

```bash
# Create staging overlay
mkdir -p overlays/staging
cat > overlays/staging/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../

namePrefix: staging-
namespace: staging

commonLabels:
  environment: staging
EOF
```

## Clean Up

### Quick Cleanup (Remove Everything)

To completely clean up all resources and the Kind cluster:

```bash
# 1. Delete application resources (model & streamlit)
kubectl delete -k deployment/kubernetes

# 2. Delete ServiceMonitor
kubectl delete -f deployment/monitoring/servicemonitor.yaml

# 3. Uninstall Prometheus monitoring stack
helm uninstall prom -n monitoring

# 4. Delete monitoring namespace
kubectl delete namespace monitoring

# 5. Delete Kubernetes Ops View
kubectl delete -f deployment/kubernetes/kube-ops-view.yaml

# 6. Delete Dashboard admin account
kubectl delete -f deployment/kubernetes/dashboard-admin.yaml

# 7. Delete namespaces (this removes all resources within them)
kubectl delete namespace kubernetes-dashboard
kubectl delete namespace monitoring

# 8. Delete the entire Kind cluster
kind delete cluster
```

### Selective Cleanup

If you want to keep the cluster but remove specific components:

#### Remove only the application:
```bash
kubectl delete -k deployment/kubernetes
```

#### Remove only monitoring:
```bash
helm uninstall prom -n monitoring
kubectl delete namespace monitoring
kubectl delete -f deployment/monitoring/servicemonitor.yaml
```

#### Remove only visualization tools:
```bash
# Kube-ops-view
kubectl delete -f deployment/kubernetes/kube-ops-view.yaml

# Kubernetes Dashboard
kubectl delete namespace kubernetes-dashboard
```

### Verify Cleanup

Check remaining resources:
```bash
# Check all resources
kubectl get all --all-namespaces

# Check specific namespaces
kubectl get namespaces

# Check if Kind cluster still exists
kind get clusters
```

### Complete Reset Script

Save this as `cleanup.sh` for easy cleanup:

```bash
#!/bin/bash
echo "Cleaning up Kubernetes resources..."

# Delete application
kubectl delete -k deployment/kubernetes 2>/dev/null

# Delete monitoring
helm uninstall prom -n monitoring 2>/dev/null
kubectl delete -f deployment/monitoring/servicemonitor.yaml 2>/dev/null

# Delete visualization tools
kubectl delete -f deployment/kubernetes/kube-ops-view.yaml 2>/dev/null
kubectl delete -f deployment/kubernetes/dashboard-admin.yaml 2>/dev/null

# Delete namespaces
kubectl delete namespace kubernetes-dashboard 2>/dev/null
kubectl delete namespace monitoring 2>/dev/null

# Wait for namespaces to be fully deleted
echo "Waiting for namespaces to be deleted..."
kubectl wait --for=delete namespace/monitoring --timeout=60s 2>/dev/null
kubectl wait --for=delete namespace/kubernetes-dashboard --timeout=60s 2>/dev/null

# Delete Kind cluster
echo "Deleting Kind cluster..."
kind delete cluster

echo "Cleanup complete!"
```

Make it executable: `chmod +x cleanup.sh`

## Cluster Visualization Tools

### Kubernetes Ops View

For a real-time visual representation of your cluster, we've included Kubernetes Ops View:

**Access**: http://localhost:32100/#scale=2

**Features**:
- Real-time cluster visualization showing nodes and pods
- Color-coded pod states:
  - 🟩 Green: Running pods
  - 🟨 Yellow: Pending/Creating pods
  - 🟥 Red: Failed/Error pods
  - ⬜ Gray: Terminating pods
- Interactive zoom and pan
- Hover for pod details
- Auto-refresh every few seconds

**Installation** (already included):
```bash
kubectl apply -f deployment/kubernetes/kube-ops-view.yaml
```

**URL Parameters**:
- `#scale=2` - Zoom level (0.5 to 5)
- `?namespace=default` - Filter by namespace

This provides a bird's-eye view of your cluster, making it easy to:
- Monitor pod distribution across nodes
- Spot failing or pending pods quickly
- Understand resource utilization visually
- Track deployments and scaling operations

## Kind Cluster Specific Configuration

If using Kind, ensure your cluster configuration includes the NodePort mappings:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30100
    hostPort: 30100
    protocol: TCP
  - containerPort: 32100
    hostPort: 32100
    protocol: TCP
```

Create cluster with: `kind create cluster --config kind-config.yaml`

## Security Considerations

For production deployments:

1. Use proper image tags instead of `latest`
2. Implement resource limits and requests
3. Use Secrets for sensitive data
4. Consider using Ingress instead of NodePort
5. Enable RBAC and Network Policies
6. Use namespaces for isolation

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [Kind Documentation](https://kind.sigs.k8s.io/)