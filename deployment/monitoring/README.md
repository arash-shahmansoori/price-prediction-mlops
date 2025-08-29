# Monitoring Configuration

This directory contains monitoring configuration files for the House Price Predictor application.

## Files

- **servicemonitor.yaml** - Kubernetes ServiceMonitor configuration that tells Prometheus how to scrape metrics from the FastAPI application
- **TROUBLESHOOTING.md** - Comprehensive troubleshooting guide for common Prometheus monitoring issues

## Overview

The monitoring setup uses:
- **Prometheus** - For metrics collection and storage
- **Grafana** - For visualization and dashboards
- **prometheus-fastapi-instrumentator** - Python library that adds Prometheus metrics to FastAPI

## Quick Setup

1. Deploy the application first:
   ```bash
   kubectl apply -k deployment/kubernetes
   ```

2. Install Prometheus stack:
   ```bash
   helm upgrade --install prom \
     -n monitoring \
     --create-namespace \
     prometheus-community/kube-prometheus-stack \
     --set grafana.service.type=NodePort \
     --set grafana.service.nodePort=30200 \
     --set prometheus.service.type=NodePort \
     --set prometheus.service.nodePort=30300
   ```

3. Apply ServiceMonitor:
   ```bash
   kubectl apply -f deployment/monitoring/servicemonitor.yaml
   ```

## Access Points

- **Prometheus**: http://localhost:30300
- **Grafana**: http://localhost:30200 (admin / prom-operator)

## Metrics Available

The FastAPI application exposes standard HTTP metrics:
- `http_requests_total` - Request counts
- `http_request_duration_seconds` - Latency metrics
- `http_request_size_bytes` - Request sizes
- `http_response_size_bytes` - Response sizes

## Troubleshooting

If metrics don't appear in Prometheus, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed debugging steps.
