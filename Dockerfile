# Use a lightweight official Python runtime
FROM python:3.9-slim

# Set environment paths
ENV PYTHONUNBUFFERED=1 \
    HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Install critical system libraries (with modern GLX dependencies)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1 \
    libglx-mesa0 \
    libglib2.0-0 \
    build-essential \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root system user for safety
RUN useradd -m -u 1000 user

# ── ADJUSTED WORKING DIRECTORY ──────────────────────────────────────────────
# If your files are nested under smart_lecturer, this forces the engine there.
# If they are already at the root, /app works seamlessly.
WORKDIR /app/smart_lecturer

# Copy dependencies first to maximize build caching
# (Looks up one directory to capture requirements if it sits outside)
COPY --chown=user requirements.txt /app/smart_lecturer/requirements.txt
COPY --chown=user requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/smart_lecturer/requirements.txt

# Copy everything into the container
WORKDIR /app
COPY --chown=user . .

# Move back down into the execution root context
WORKDIR /app/smart_lecturer

# Ensure data pipelines have full writing privileges inside the target runtime environments
RUN mkdir -p data/frames data/audio data/transcripts index/vector_store && \
    chmod -R 777 /app/smart_lecturer/data /app/smart_lecturer/index

USER user

# Expose the default Hugging Face space tracking port
EXPOSE 7860

# Execute backend server with clean runtime environmental perspective
CMD ["gunicorn", "--bind", "0.0.0.0:7860", "--workers", "1", "--timeout", "300", "api:app"]
