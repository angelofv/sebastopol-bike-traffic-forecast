# 1) Builder : wheels offline
FROM python:3.10-slim AS builder
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /opt/app
COPY requirements.txt README.md LICENSE ./
COPY src/ ./src/
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip wheel --wheel-dir /tmp/wheels -r requirements.txt

# 2) Runtime commun
FROM python:3.10-slim AS runtime
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*
RUN useradd -m -u 1000 appuser
ENV PYTHONUNBUFFERED=1 MPLCONFIGDIR=/tmp GIT_PYTHON_REFRESH=quiet \
    GIT_PYTHON_GIT_EXECUTABLE=/usr/bin/git
WORKDIR /opt/app
ENV PYTHONPATH=/opt/app

COPY --from=builder /tmp/wheels /tmp/wheels
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir /tmp/wheels/* && rm -rf /tmp/wheels

COPY --chown=appuser:appuser . .

USER appuser
