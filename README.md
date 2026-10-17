# codex-dev

本仓库用于通过 GitHub Actions 自动构建开发镜像，并推送到 GitHub Container Registry。

## 包含文件

- `Dockerfile`
- `entrypoint.sh`
- `docker-compose.yml`
- `.gitignore`
- `.github/workflows/docker.yml`
- `.dockerignore`

## 使用流程

1. 在 GitHub 创建一个仓库，例如 `codex-dev`。
2. 把当前目录内容推送到仓库。
3. 到 GitHub 仓库设置里开启：
   `Settings -> Actions -> General -> Workflow permissions -> Read and write permissions`
4. 推送到 `main` 后，等待 Actions 自动构建并推送镜像。

## 手动触发构建

除了推送代码自动构建外，也可以在 GitHub 仓库的 `Actions -> Build Docker Image -> Run workflow` 手动触发：

- `tag`（可选）：为镜像附加自定义标签，例如工具版本号，生成 `:latest` 和 `:<tag>` 两个标签。
- `no_cache`（可选）：勾选后禁用构建缓存，强制重新安装最新的 agent 工具版本。

手动触发适合在不改动代码的情况下更新镜像内 `codex`、`opencode`、`claude` 等工具的版本。

镜像地址格式：

```text
ghcr.io/<github-username>/codex-dev:latest
```

如果你的仓库名不是 `codex-dev`，镜像路径会变成：

```text
ghcr.io/<github-username>/<repo-name>:latest
```

## 推送仓库示例

```bash
git init
git add .
git commit -m "init"
git branch -M main
git remote add origin https://github.com/<github-username>/codex-dev.git
git push -u origin main
```

## NAS 拉取镜像

先登录 GHCR：

```bash
docker login ghcr.io
```

用户名填写 GitHub 用户名，密码使用带 `read:packages` 权限的 GitHub Personal Access Token。

然后拉取镜像：

```bash
docker pull ghcr.io/<github-username>/codex-dev:latest
```

运行示例：

```bash
docker run -d --name codex-dev \
  -p 10022:22 \
  -v $(pwd):/workspace \
  -v $(pwd)/home/coder:/home/coder \
  -e SSH_PASSWORD=your-password \
  -e SSH_PUBLIC_KEY="ssh-ed25519 AAAA... user@host" \
  -e OPENAI_API_KEY=xxx \
  ghcr.io/<github-username>/codex-dev:latest
```

容器内 `sshd` 监听默认 `22` 端口，通过宿主机端口 `10022` 对外暴露。使用 `ssh` 登录：

```bash
ssh -p 10022 coder@<NAS-IP>
```

如果使用密钥登录，把私钥对应的公钥通过 `SSH_PUBLIC_KEY` 注入即可；也可以直接使用密码登录。

首次启动时，容器会在宿主机的 `./home/coder/.ssh` 目录中自动生成一对 Ed25519 密钥：

```bash
cat home/coder/.ssh/id_ed25519.pub
```

将公钥添加到 GitHub 的 SSH Keys 后，容器内即可使用 `git pull` 和 `git push`。已有密钥不会被覆盖。`SSH_KEY_PASSPHRASE` 默认为空，适合容器无人值守执行 Git 操作；如果设置密码短语，则需要在容器内额外使用 ssh-agent。

从 MacBook 或 Windows 通过 SSH 登录时，可以使用 Agent forwarding：

```bash
ssh -A -p 10022 coder@<NAS-IP>
```

Agent forwarding 可用时优先使用转发的密钥；不可用时，SSH 会使用容器内 `./home/coder/.ssh/id_ed25519` 作为备用密钥。

如需交互式 shell，也可以在启动时覆盖默认命令：

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/home/coder:/home/coder \
  -e OPENAI_API_KEY=xxx \
  ghcr.io/<github-username>/codex-dev:latest bash
```

## 环境变量

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `SSH_USER` | `coder` | SSH 登录用户名 |
| `SSH_PASSWORD` | `coder` | SSH 登录密码，请务必修改 |
| `SSH_PUBLIC_KEY` | 空 | 注入到 `authorized_keys` 的公钥，支持密钥登录 |
| `SSH_KEY_PASSPHRASE` | 空 | 自动生成的 Git SSH 私钥密码短语；留空以支持无人值守 Git 操作 |
| `GIT_USER_NAME` | 空 | Git commit 使用的用户名 |
| `GIT_USER_EMAIL` | 空 | Git commit 使用的邮箱 |

## Docker Compose 示例

仓库内提供了 `docker-compose.yml` 示例，可直接修改后使用：

```bash
docker compose up -d
```

启动后通过宿主机映射端口登录：

```bash
ssh -p 10022 coder@<NAS-IP>
```

如需更新镜像版本：

```bash
docker compose pull && docker compose up -d
```

镜像内可直接使用：

- `codex`
- `opencode`
- `claude`

## 可选升级

后续如果你的 NAS 是 ARM 平台，可以再把工作流升级为同时构建 `amd64` 和 `arm64` 多架构镜像。
