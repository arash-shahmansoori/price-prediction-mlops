# MLflow Permission Error Fix

## Problem
The pipeline was failing with:
```
PermissionError: [Errno 13] Permission denied: '/mlflow'
```

This occurred because:
1. MLflow was running in Docker with `/mlflow` as the artifact root
2. The Python training script was trying to write to `/mlflow` on the host system
3. GitHub Actions runner didn't have permission to create `/mlflow` at the root

## Solution
Changed from Docker-based MLflow to native installation:

### Before (Docker):
```yaml
docker run -d \
  -v $(pwd)/mlflow:/mlflow \
  -e MLFLOW_DEFAULT_ARTIFACT_ROOT=/mlflow/artifacts \
  ghcr.io/mlflow/mlflow:v2.9.2 \
  mlflow server --host 0.0.0.0 --port 5000
```

### After (Native):
```yaml
# Install MLflow
pip install mlflow==2.9.2

# Start MLflow server
mlflow server \
  --backend-store-uri sqlite:///$(pwd)/mlflow/mlflow.db \
  --default-artifact-root file://$(pwd)/mlflow/artifacts \
  --host 0.0.0.0 \
  --port 5555 \
  --serve-artifacts &
```

## Key Changes

1. **Native MLflow Installation**: Runs directly on the runner, avoiding Docker permission issues
2. **Local Paths**: Uses `$(pwd)/mlflow/artifacts` instead of `/mlflow/artifacts`
3. **Artifact Serving**: Added `--serve-artifacts` flag for proper HTTP artifact handling
4. **Version Format**: Changed from `v2.9.2` to `2.9.2` for pip installation
5. **Process Management**: Uses PID file instead of Docker commands for cleanup

## Benefits

- No permission issues as MLflow runs with runner's permissions
- Simpler setup without Docker overhead
- Faster startup time
- Same functionality with better compatibility

## Testing

To test locally:
```bash
# Create directories
mkdir -p mlflow/artifacts mlruns

# Start MLflow
mlflow server \
  --backend-store-uri sqlite:///$(pwd)/mlflow/mlflow.db \
  --default-artifact-root file://$(pwd)/mlflow/artifacts \
  --host 0.0.0.0 \
  --port 5555 \
  --serve-artifacts
```

Then run your training script with:
```bash
export MLFLOW_TRACKING_URI=http://localhost:5555
python src/models/train_model.py --config configs/model_config.yaml ...
```
