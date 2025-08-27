# GitHub Workflows

This directory contains CI workflows for the House Price Predictor project.

## Workflows

### 1. MLOps Pipeline (`mlops-pipeline.yml`)
Main machine learning pipeline with flexible job execution modes.

**Triggers:**
- Push to main branch or version tags
- Pull requests to main
- Manual dispatch with job selection

**Features:**
- Data processing and feature engineering
- Model training with MLflow
- Docker image building and publishing
- Flexible run modes for individual job execution

### 2. MLOps CI Workflow (`mlops-ci-workflow.yaml`)
Original CI workflow (legacy - consider migrating to mlops-pipeline.yml)

### 3. Streamlit CI (`streamlit-ci.yml`)
Comprehensive CI pipeline for the Streamlit application.

**Triggers:**
- Push to streamlit_app/ directory
- Pull requests affecting Streamlit code
- Manual dispatch with environment selection

**Features:**
- Multi-platform Docker builds (amd64/arm64)
- Vulnerability scanning with Trivy
- Environment-based tagging
- Build caching for performance

### 4. Streamlit CI Simple (`streamlit-ci-simple.yml`)
Minimal Streamlit CI pipeline for basic needs.

**Triggers:**
- Push to streamlit_app/ directory
- Manual dispatch

## Required Secrets and Variables

### Repository Secrets
- `DOCKER_PASSWORD`: Docker Hub access token or password

### Repository Variables
- `DOCKER_USERNAME`: Docker Hub username

## Setting Up Secrets and Variables

1. Go to Settings → Secrets and variables → Actions
2. Add the following:
   - Under "Secrets": New repository secret → Name: `DOCKER_PASSWORD`
   - Under "Variables": New repository variable → Name: `DOCKER_USERNAME`

## Usage Examples

### MLOps Pipeline - Manual Run
```
Actions → MLOps Pipeline → Run workflow
Select run mode:
- all: Complete pipeline
- data-processing-only: Just data processing
- model-training-only: Just model training
- build-only: Just Docker build
```

### Streamlit CI - Manual Deployment
```
Actions → Streamlit CI → Run workflow
Select environment:
- development
- staging  
- production
```

## Docker Image Tags

### MLOps Model Images
- `latest`: Latest from main branch
- `{version}`: Semantic version tags (e.g., 1.2.3)
- `{environment}-{sha}`: Environment-specific builds

### Streamlit Images
- `latest`: Latest from main branch
- `{environment}-latest`: Environment-specific latest
- `{environment}-{sha}`: Environment-specific with commit SHA
- `pr-{number}`: Pull request builds (not pushed)

## Best Practices

1. Use semantic versioning for production releases
2. Test changes in PRs before merging
3. Use manual dispatch for emergency deployments
4. Monitor vulnerability scan results
5. Keep Docker credentials secure and rotate regularly
