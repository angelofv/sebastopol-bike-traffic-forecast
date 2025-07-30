# 1) Builder stage: build wheels for all dependencies offline
FROM python:3.10-slim AS builder

# Install git (needed by some Python packages) and clean up apt cache
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app

# Copy only what’s needed to build wheels
COPY requirements.txt README.md LICENSE pyproject.toml ./
COPY src/ ./src/

# Upgrade pip and build wheels into /tmp/wheels cache
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip \
    && pip wheel --wheel-dir /tmp/wheels -r requirements.txt


# 2) Runtime stage: install the built wheels + your package in editable mode
FROM python:3.10-slim AS runtime

# Again install git and clean up apt cache
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for running the app
RUN useradd -m -u 1000 appuser

# Set environment variables for Python behavior and ML tools
ENV PYTHONUNBUFFERED=1 \
    MPLCONFIGDIR=/tmp \
    GIT_PYTHON_REFRESH=quiet \
    GIT_PYTHON_GIT_EXECUTABLE=/usr/bin/git

WORKDIR /opt/app
ENV PYTHONPATH=/opt/app

# 2.1) Install all dependencies from the pre-built wheels
COPY --from=builder /tmp/wheels /tmp/wheels
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir /tmp/wheels/* \
    && rm -rf /tmp/wheels

# 2.2) Copy the full project and install it in editable mode
COPY --chown=appuser:appuser . .

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -e .

# Switch to the non-root user for safety
USER appuser