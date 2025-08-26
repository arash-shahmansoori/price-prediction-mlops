# Use the official Python 3.9 slim image as a parent image
FROM python:3.9-slim

# Set environment variables for best practices
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a non-root user and group
RUN addgroup --system app && adduser --system --group app

# Set the working directory in the container
WORKDIR /app

# Copy only the requirements file to leverage Docker layer caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application source code
COPY app.py .

# Change ownership of the application directory to the non-root user
RUN chown -R app:app /app

# Switch to the non-root user
USER app

# Expose the port the app runs on
EXPOSE 8501

# Run the Streamlit application
CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0"]
