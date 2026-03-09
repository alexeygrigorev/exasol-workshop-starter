FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(uname -m) \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" \
       -o /tmp/awscli.zip \
    && unzip -q /tmp/awscli.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscli.zip \
    && aws --version

RUN curl -LsSf https://astral.sh/uv/install.sh \
    | env INSTALLER_NO_MODIFY_PATH=1 UV_INSTALL_DIR=/usr/local/bin sh \
    && uv --version

RUN mkdir -p /home/vscode/bin && chown vscode:vscode /home/vscode/bin
ENV PATH="/home/vscode/bin:${PATH}"

USER vscode
RUN ARCH=$(uname -m) \
    && curl -fSL \
       "https://x-up.s3.eu-west-1.amazonaws.com/releases/exasol-personal/linux/${ARCH}/latest/exasol" \
       -o /home/vscode/bin/exasol \
    && chmod +x /home/vscode/bin/exasol \
    && exasol --version || true
