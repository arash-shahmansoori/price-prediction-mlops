# Dual Metrics Endpoint Configuration

This application exposes Prometheus metrics through TWO different endpoints for maximum flexibility.

## Architecture

The application runs two separate metrics endpoints:

1. **Port 8000 - `/metrics` endpoint** (via prometheus-fastapi-instrumentator)
   - Integrated with FastAPI
   - Includes HTTP request metrics specific to FastAPI
   - Accessible at: `http://localhost:30100/metrics`

2. **Port 9100 - Standalone metrics server** (via prometheus_client)
   - Separate HTTP server for metrics only
   - Raw Prometheus client metrics
   - Requires additional port configuration in Kubernetes

## Why Two Metrics Endpoints?

This dual setup provides:
- **Compatibility**: Some monitoring tools expect metrics on a dedicated port
- **Flexibility**: Choose which endpoint to scrape based on your needs
- **Isolation**: Metrics server on 9100 is independent of main app performance
- **Redundancy**: If one endpoint has issues, the other may still work

## Kubernetes Configuration

To expose port 9100 in Kubernetes, you'll need to update the service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: model
  labels:
    monitoring: enabled
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 8000
    nodePort: 30100
  - name: metrics
    port: 9100
    targetPort: 9100
    nodePort: 30101  # Add this NodePort
  selector:
    app: house-price-predictor
    component: model
  type: NodePort
```

## ServiceMonitor Configuration

You can configure Prometheus to scrape either endpoint:

### Option 1: Scrape /metrics on port 8000 (current setup)
```yaml
spec:
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
```

### Option 2: Scrape dedicated metrics port 9100
```yaml
spec:
  endpoints:
    - port: metrics
      path: /metrics
      interval: 15s
```

### Option 3: Scrape both endpoints
```yaml
spec:
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
    - port: metrics
      path: /metrics
      interval: 15s
      honorLabels: true
```

## Testing Both Endpoints

```bash
# Test main app metrics endpoint
curl http://localhost:30100/metrics

# Test dedicated metrics server (after exposing port 9100)
curl http://localhost:30101/metrics

# Compare metrics from both endpoints
diff <(curl -s http://localhost:30100/metrics | sort) \
     <(curl -s http://localhost:30101/metrics | sort)
```

## Important Notes

1. **Memory Usage**: Running two metrics endpoints uses slightly more memory
2. **Port Conflicts**: Ensure port 9100 is not used by other services
3. **Security**: Both ports should be protected in production environments
4. **Metric Names**: The instrumentator adds HTTP-specific metrics not available on port 9100
