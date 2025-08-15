# app/Dockerfile
# Use an official lightweight Python image.
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install dependencies
# We will use pip to install FastAPI and Uvicorn
RUN pip install fastapi uvicorn

# Copy the application code into the container
COPY ./main.py /app/

# Create a non-root user and switch to it
RUN useradd --create-home appuser
USER appuser

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application
# Uvicorn is an ASGI server that will run our FastAPI app.
# We bind to 0.0.0.0 to be accessible from outside the container.
# The port is set to 8080, a common practice for Cloud Run.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]