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
