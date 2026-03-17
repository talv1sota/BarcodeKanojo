FROM python:3.12-slim

# System dependencies for Pillow
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libjpeg62-turbo-dev \
        zlib1g-dev \
        libpng-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server code
COPY . .

# Create required directories
RUN mkdir -p static/profile_images/kanojo \
             static/profile_images/user \
             static/avatar \
             static/product_images \
             static/resource

# Default avatar_data path inside the container (mounted via volume)
ENV AVATAR_DATA_DIR=/data/avatar_data
ENV DATABASE_URL=sqlite+aiosqlite:////data/barcode_kanojo.db
ENV UPLOAD_DIR=/app/static
ENV SECRET_KEY=change-me-in-production
ENV HOST=0.0.0.0
ENV PORT=8000

# Persist database and avatar data on a volume
VOLUME ["/data"]

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
