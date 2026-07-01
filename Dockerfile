# Use a lightweight official Python runtime
FROM python:3.9-slim

# Set environment paths
ENV PYTHONUNBUFFERED=1 \
    HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Install critical system libraries required for processing video/audio and matrix computing
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root system user for safety (Hugging Face security standard)
RUN useradd -m -u 1000 user
WORKDIR /app

# Copy dependencies first to maximize build caching
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of your system architecture files
COPY --chown=user . .

# Ensure data pipelines have full writing privileges inside the container environment
RUN mkdir -p data/frames data/audio data/transcripts index/vector_store && \
    chmod -R 777 /app/data /app/index

USER user

# Expose the default Hugging Face space tracking port
EXPOSE 7860

# Execute backend server via Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:7860", "--workers", "1", "--timeout", "300", "api:app"]
