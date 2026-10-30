# Stage 1: Build plan9port on Debian with all required headers
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libx11-dev \
    libxt-dev \
    libxext-dev \
    libfontconfig1-dev \
    x11proto-core-dev

WORKDIR /app
RUN git clone https://github.com/9fans/plan9port.git
WORKDIR /app/plan9port

# Run full installation script (builds binaries and finalizes paths)
RUN ./INSTALL

# Stage 2: Clean Runtime Image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libx11-6 \
    libxt6 \
    libxext6 \
    libfontconfig1 \
    procps \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled plan9port suite from builder
COPY --from=builder /app/plan9port /usr/local/plan9

# Copy and setup entrypoint wrapper script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["rc"]
