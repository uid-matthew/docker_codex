FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    python3-pip \
    build-essential \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @openai/codex opencode-ai@latest @anthropic-ai/claude-code

RUN useradd -ms /bin/bash coder

USER coder

WORKDIR /workspace

CMD ["bash"]
