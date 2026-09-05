FROM ghcr.io/linuxserver/baseimage-kasmvnc:debianbookworm

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Metatrader Docker:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="gmartin"

ENV TITLE=Metatrader5
ENV WINEPREFIX="/config/.wine"
ENV WINEDEBUG=-all

# Install all packages in a single layer to reduce image size
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    supervisor \
    procps \
    && mkdir -pm755 /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key -o /etc/apt/keyrings/winehq-archive.key \
    && curl -fsSL https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources -o /etc/apt/sources.list.d/winehq-bookworm.sources \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install --install-recommends -y winehq-stable \
    && pip install --break-system-packages --no-cache-dir mt5linux==0.1.9 rpyc==6.0.2 plumbum==1.10.0 numpy==2.0.2 pyxdg==0.28 prometheus_client psutil requests \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


COPY --chmod=755 Metatrader /Metatrader
COPY root/defaults /defaults
COPY --chmod=755 scripts /scripts

# Healthcheck uses the unified validation tool
HEALTHCHECK --interval=30s --timeout=30s --start-period=300s --retries=3 \
  CMD python3 /scripts/validate_connectivity.py --json || exit 1

# Expose VNC (3000), RPyC Bridge (8001), Prometheus Metrics (9100)
EXPOSE 3000 8001 9100
VOLUME /config
