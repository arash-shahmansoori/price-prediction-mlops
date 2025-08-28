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

- Kubernetes cluster (Kind, Minikube, or any other)
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

| Service   | Internal Port | NodePort | URL                     |
|-----------|---------------|----------|-------------------------|
| Streamlit | 8501          | 30000    | http://localhost:30000  |
| Model API | 8000          | 30100    | http://localhost:30100  |

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

Remove all deployed resources:

```bash
# Using Kustomize
kubectl delete -k deployment/kubernetes

# Or manually
kubectl delete deployment streamlit model
kubectl delete service streamlit model
```

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