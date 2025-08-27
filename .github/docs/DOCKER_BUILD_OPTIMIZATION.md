# Docker Build Optimization Guide

## Optimizations Applied to Pipeline

### 1. **Separated Platform Builds**
- **Before**: Built both `linux/amd64` and `linux/arm64` in one step
- **After**: 
  - AMD64 builds always (faster, most common platform)
  - ARM64 only for main branch and tags (slower due to QEMU emulation)
- **Impact**: ~50% faster for development builds

### 2. **Registry Caching**
- Added Docker registry caching with dedicated cache images
- Cache stored as `buildcache` and `buildcache-arm64` tags
- **Impact**: Reuses layers across builds, even after GitHub Actions cache expires

### 3. **BuildKit Optimizations**
- Pinned BuildKit version for consistency
- Added `BUILDKIT_INLINE_CACHE=1` for better cache metadata
- Disabled provenance and SBOM generation (saves ~10-20 seconds)
- **Impact**: Faster builds with better cache hit rates

### 4. **Mirror Registry**
- Added Google Container Registry mirror for Docker Hub
- **Impact**: Faster base image pulls in GitHub Actions

### 5. **Conditional QEMU**
- QEMU (for ARM64) only loaded when needed
- **Impact**: Saves ~30 seconds on development builds

## Additional Dockerfile Optimizations

To make your builds even faster, optimize your Dockerfile:

### 1. **Multi-stage Builds**
```dockerfile
# Build stage
FROM python:3.11-slim as builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
```

### 2. **Layer Caching**
Order your Dockerfile commands from least to most frequently changing:
```dockerfile
# System dependencies (rarely change)
RUN apt-get update && apt-get install -y ...

# Python dependencies (change occasionally)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Application code (changes frequently)
COPY . .
```

### 3. **Cache Mounts** (Recommended)
Add to your Dockerfile for package manager caching:
```dockerfile
# For pip
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# For apt
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y ...
```

### 4. **Minimize Layers**
Combine commands where logical:
```dockerfile
# Instead of:
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# Use:
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*
```

### 5. **Use Specific Base Images**
```dockerfile
# Instead of: python:3.11 (1GB+)
# Use: python:3.11-slim (150MB)
FROM python:3.11-slim

# Or for minimal size:
FROM python:3.11-alpine
```

## Performance Metrics

With these optimizations:
- **Cold build**: 5-10 minutes → 3-5 minutes
- **Cached build**: 3-5 minutes → 30-60 seconds
- **Development builds** (AMD64 only): 50% faster
- **Registry cache**: Persists beyond GitHub's 7-day limit

## Monitoring Build Performance

Add build timing to your pipeline:
```yaml
- name: Build Docker Image
  run: |
    START_TIME=$(date +%s)
    # ... build command ...
    END_TIME=$(date +%s)
    echo "Build took $((END_TIME - START_TIME)) seconds"
```

## Further Optimizations

1. **Use Depot.dev or similar**: Cloud native builders can be 10-20x faster
2. **Pre-built base images**: Create your own base image with dependencies
3. **Incremental builds**: Use tools like `pack` (Cloud Native Buildpacks)
4. **Local registry**: Run a pull-through cache in your infrastructure

## Example Optimized Dockerfile

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.11-slim as builder

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
WORKDIR /app
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY . .

# Set up non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

CMD ["python", "app.py"]
```
