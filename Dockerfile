FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    gnupg \
    git \
    curl \
    gcc \
    build-essential \
    ripgrep \
    python3 \
    python3-pip \
    openssh-client \
    openssh-server \
    gosu \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @openai/codex opencode-ai@latest @anthropic-ai/claude-code

RUN useradd -ms /bin/bash coder \
    && mkdir -p /home/coder/.ssh /var/run/sshd /workspace \
    && chown -R coder:coder /home/coder/.ssh /workspace \
    && printf '%s\n' \
        'PasswordAuthentication yes' \
        'PubkeyAuthentication yes' \
        'AllowAgentForwarding yes' \
        'PermitRootLogin no' \
        > /etc/ssh/sshd_config.d/00-ssh-dev.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
