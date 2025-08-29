# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables to prevent Python from writing .pyc files and to buffer output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a non-root user and group
RUN addgroup --system app && adduser --system --group app

# Set the working directory in the container
WORKDIR /app

# Copy only the requirements file to leverage Docker cache
COPY src/api/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application source code
COPY src/api/ .
COPY models/trained/*.pkl models/trained/

# Change ownership of the application directory
RUN chown -R app:app /app

# Switch to the non-root user
USER app

# Expose the ports the app runs on
# Port 8000: Main FastAPI application with /metrics endpoint
# Port 9100: Separate Prometheus metrics server
EXPOSE 8000 9100

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
