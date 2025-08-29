# Prometheus Monitoring Troubleshooting Guide

This guide documents the troubleshooting steps and solutions for common Prometheus monitoring issues with the House Price Predictor application.

## Table of Contents
- [Overview](#overview)
- [Common Issues and Solutions](#common-issues-and-solutions)
- [Debugging Steps](#debugging-steps)
- [Essential Fixes Applied](#essential-fixes-applied)
- [Verification Commands](#verification-commands)
- [Architecture Diagram](#architecture-diagram)

## Overview

When setting up Prometheus monitoring for a FastAPI application in Kubernetes, several configuration issues can prevent metrics from appearing in Prometheus, even when the application is correctly instrumented.

### Key Components
- **FastAPI Application**: Exposes metrics at `/metrics` endpoint using `prometheus-fastapi-instrumentator`
- **Kubernetes Service**: Exposes the application with proper labels and port names
- **ServiceMonitor**: Tells Prometheus where to find and how to scrape the metrics
- **Prometheus**: Scrapes metrics based on ServiceMonitor configuration

## Common Issues and Solutions

### 1. ServiceMonitor Configuration Issues

**Problem**: ServiceMonitor exists but Prometheus doesn't discover the targets.

**Symptoms**:
- No metrics appear in Prometheus UI
- ServiceMonitor shows in `kubectl get servicemonitor` but not in Prometheus targets

**Solutions**:
```yaml
# Ensure ServiceMonitor has correct labels for Prometheus to discover it
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: house-price-app  # Fix any typos in the name
  namespace: default
  labels:
    release: prom  # Must match Prometheus serviceMonitorSelector
spec:
  selector:
    matchLabels:
      monitoring: enabled  # Service must have this label
  endpoints:
    - port: http  # Use port name, not number
      path: /metrics
      interval: 15s
```

### 2. Service Label and Selector Mismatches

**Problem**: Service doesn't have the labels that ServiceMonitor is looking for, or service selector doesn't match pods.

**Symptoms**:
- `kubectl get endpoints <service-name>` shows no endpoints or wrong endpoints
- Prometheus shows the target as "down" or doesn't show it at all

**Solutions**:
```yaml
# Add monitoring label to service
apiVersion: v1
kind: Service
metadata:
  labels:
    app: model
    monitoring: enabled  # Required by ServiceMonitor
  name: model
spec:
  ports:
  - name: http  # Named port (not just "8000")
    port: 8000
    targetPort: 8000
  selector:
    app: house-price-predictor  # Must match pod labels
    component: model  # Be specific if multiple deployments share labels
```

### 3. Kustomize Label Override Issues

**Problem**: When using Kustomize with `commonLabels`, it overrides all labels including selectors, causing mismatches.

**Symptoms**:
- Service endpoints show pods from multiple deployments
- Service selector doesn't match what you expect

**Solutions**:
1. Check actual labels on pods:
   ```bash
   kubectl get pod <pod-name> -o yaml | grep -A5 "labels:"
   ```

2. Update service selector to match actual pod labels:
   ```bash
   kubectl patch service model --type='json' -p='[
     {"op": "replace", "path": "/spec/selector", 
      "value": {"app": "house-price-predictor", "environment": "production"}}
   ]'
   ```

3. Add unique labels to distinguish pods:
   ```bash
   kubectl patch deployment model --type='json' -p='[
     {"op": "add", "path": "/spec/template/metadata/labels/component", 
      "value": "model"}
   ]'
   ```

### 4. Port Configuration Issues

**Problem**: Service port is not properly named or NodePort is not accessible.

**Symptoms**:
- Connection refused when accessing NodePort
- Port-forward fails with connection errors

**Solutions**:
- Use named ports in service definition (e.g., `name: http` instead of `name: "8000"`)
- Verify Kind cluster has port mappings for NodePorts
- Use port-forwarding for testing: `kubectl port-forward service/model 8080:8000`

## Debugging Steps

### Step 1: Verify Application Metrics Endpoint

Check if the FastAPI application is correctly exposing metrics:

```bash
# Port-forward to the pod directly
kubectl port-forward pod/<pod-name> 8080:8000

# Test metrics endpoint
curl http://localhost:8080/metrics

# Should see Prometheus metrics format output
```

### Step 2: Check Service Endpoints

Verify the service has discovered the correct pods:

```bash
# Check service endpoints
kubectl get endpoints model

# Should show IP addresses of pods
# If shows <none>, service selector doesn't match pod labels
```

### Step 3: Verify ServiceMonitor Discovery

Check if Prometheus is configured to discover ServiceMonitors:

```bash
# Check Prometheus configuration
kubectl get prometheus -n monitoring -o yaml | grep -A10 serviceMonitorSelector

# Should show:
# serviceMonitorSelector:
#   matchLabels:
#     release: prom
```

### Step 4: Check Pod Logs for Scraping

Verify Prometheus is attempting to scrape metrics:

```bash
# Check application logs for metrics requests
kubectl logs <pod-name> | grep "/metrics"

# Should see entries like:
# INFO:     10.244.2.8:xxxxx - "GET /metrics HTTP/1.1" 200 OK
```

### Step 5: Use Prometheus API to Check Targets

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring service/prom-kube-prometheus-stack-prometheus 9090:9090

# Check targets via API
curl http://localhost:9090/api/v1/targets | grep -i "house-price"
```

## Essential Fixes Applied

### 1. Fixed ServiceMonitor Configuration

**Before**:
```yaml
metadata:
  name: teution o  # Typo in name
spec:
  endpoints:
    - port: "8000"  # String port number
```

**After**:
```yaml
metadata:
  name: house-price-app
spec:
  endpoints:
    - port: http  # Named port
```

### 2. Added Monitoring Label to Service

```bash
kubectl patch service model --type='merge' -p='{"metadata":{"labels":{"monitoring":"enabled"}}}'
```

### 3. Fixed Service Port Naming

Changed from unnamed port "8000" to named port "http" in service definition.

### 4. Resolved Selector Issues

Added component-specific labels to avoid selecting multiple pod types:

```bash
# Add component label to deployment
kubectl patch deployment model --type='json' -p='[
  {"op": "add", "path": "/spec/template/metadata/labels/component", "value": "model"}
]'

# Update service selector
kubectl patch service model --type='json' -p='[
  {"op": "add", "path": "/spec/selector/component", "value": "model"}
]'
```

## Verification Commands

### Quick Health Check Script

```bash
#!/bin/bash
echo "=== Checking Monitoring Setup ==="

echo -e "\n1. Checking ServiceMonitor:"
kubectl get servicemonitor house-price-app -o yaml | grep -E "name:|release:|monitoring:"

echo -e "\n2. Checking Service Labels and Endpoints:"
kubectl get service model -o yaml | grep -E "monitoring:|app:|component:"
kubectl get endpoints model

echo -e "\n3. Checking Pod Labels:"
kubectl get pods -l component=model -o yaml | grep -A5 "labels:"

echo -e "\n4. Checking Recent Metrics Scrapes:"
kubectl logs -l component=model --tail=50 | grep "/metrics" | tail -5

echo -e "\n5. Testing Metrics Endpoint:"
kubectl port-forward service/model 8080:8000 &
PF_PID=$!
sleep 3
curl -s http://localhost:8080/metrics | grep "http_requests_total" | head -3
kill $PF_PID 2>/dev/null
```

### Prometheus Query Examples

Once everything is working, use these queries in Prometheus:

```promql
# All metrics from your app
{job="serviceMonitor/default/house-price-app/0"}

# HTTP requests total
http_requests_total{handler="/predict"}

# Request rate (requests per second)
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
)

# Error rate
sum(rate(http_requests_total{status=~"4..|5.."}[5m])) / 
sum(rate(http_requests_total[5m]))
```

## Architecture Diagram

```
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   FastAPI App       │────▶│ Service (model)  │────▶│ ServiceMonitor  │
│ Port: 8000         │     │ NodePort: 30100  │     │ house-price-app │
│ /metrics endpoint  │     │ Labels:          │     │                 │
└─────────────────────┘     │ - monitoring:    │     └────────┬────────┘
                           │   enabled        │              │
                           └──────────────────┘              │
                                                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Prometheus (Port: 30300)                      │
│  - Scrapes /metrics every 15s                                      │
│  - Discovers targets via ServiceMonitor with release: prom label   │
└─────────────────────────────────────────────────────────────────────┘
```

## Additional Tips

### 1. Use Port-Forwarding for Testing
When NodePorts aren't working, use port-forwarding:
```bash
kubectl port-forward service/model 8080:8000
```

### 2. Check Prometheus Targets Page
Always verify in Prometheus UI:
- Go to http://localhost:30300/targets
- Look for your ServiceMonitor job
- Check if target shows as "UP"

### 3. Common Metric Names
The `prometheus-fastapi-instrumentator` exposes these metrics:
- `http_requests_total` - Total requests counter
- `http_request_duration_seconds` - Request latency histogram
- `http_request_size_bytes` - Request size
- `http_response_size_bytes` - Response size
- `http_requests_in_progress` - Currently active requests

### 4. Debugging No Data in Prometheus

If metrics endpoint works but Prometheus shows no data:
1. Check time range in Prometheus (use "Last 5 minutes")
2. Try querying without any filters first: `http_requests_total`
3. Check dropped targets: `curl http://localhost:9090/api/v1/targets`
4. Verify ServiceMonitor namespace matches where your app is deployed

### 5. Generate Test Traffic

To create metrics for testing:
```bash
# Single request
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"sqft": 2000, "bedrooms": 3, "bathrooms": 2.5, 
       "location": "suburban", "year_built": 2010, 
       "condition": "Good"}'

# Multiple requests
for i in {1..10}; do
  curl -X POST http://localhost:8080/predict \
    -H "Content-Type: application/json" \
    -d '{"sqft": '$((1500 + i * 100))', "bedrooms": 3, 
         "bathrooms": 2, "location": "urban", 
         "year_built": 2010, "condition": "Good"}' \
    -s > /dev/null
done
```

## Conclusion

The key to successful Prometheus monitoring setup is ensuring proper label matching throughout the chain: Pod Labels → Service Selector → Service Labels → ServiceMonitor Selector → Prometheus Configuration. When debugging, work backwards from Prometheus to verify each component in the chain.
