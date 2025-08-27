# MLOps Pipeline Improvements

## Overview
The modular pipeline (`mlops-pipeline.yml`) improves upon the original workflow (`mlops-ci-workflow.yaml`) by introducing job separation, artifact passing, and better error handling.

## Key Improvements

### 1. Modular Job Structure
- **data-processing**: Handles data cleaning and feature engineering
- **model-training**: Trains the model using processed data
- **build-and-publish**: Builds and publishes Docker images
- **cleanup**: Removes artifacts after pipeline completion

### 2. Artifact Management
- Uses GitHub Actions artifacts to pass data between jobs
- Includes retention policies (1 day) to manage storage
- Automatic cleanup job to remove artifacts

### 3. Enhanced Features

#### Version Consistency
- Uses consistent action versions (v3/v5) throughout
- Maintains Python version 3.11.11 from original

#### MLflow Improvements
- Added health check with retry logic
- Proper cleanup in `always()` condition
- Consistent port mapping (5555:5000)

#### Docker Tagging Strategy
- Supports semantic versioning (v*.*.*)
- Branch-based tags
- PR tags for testing
- Latest tag for main branch

#### Build Optimizations
- Docker Buildx for multi-platform builds
- GitHub Actions cache for faster builds
- Metadata extraction for proper labeling

### 4. Conditional Execution
- Build and publish only runs on main branch or version tags
- Cleanup runs regardless of previous job status

### 5. Error Handling
- Graceful MLflow container cleanup
- Artifact deletion with error suppression
- Health check retries for MLflow startup

## Usage

### For Development
```bash
# Push to feature branch - runs data processing and training only
git push origin feature/my-feature
```

### For Release
```bash
# Tag and push for full pipeline including Docker publish
git tag v1.0.0
git push origin v1.0.0
```

### Environment Variables Required
- `DOCKER_USERNAME` (repository variable)
- `DOCKER_PASSWORD` (repository secret)

## Benefits
1. **Parallelization**: Jobs can run on different runners
2. **Reusability**: Failed jobs can be rerun independently
3. **Visibility**: Clear separation of concerns
4. **Efficiency**: Artifacts reduce redundant processing
5. **Scalability**: Easy to add new jobs or modify existing ones
