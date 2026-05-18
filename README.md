# codex-dev

本仓库用于通过 GitHub Actions 自动构建 Codex 开发镜像，并推送到 GitHub Container Registry。

## 包含文件

- `Dockerfile`
- `.github/workflows/docker.yml`
- `.dockerignore`

## 使用流程

1. 在 GitHub 创建一个仓库，例如 `codex-dev`。
2. 把当前目录内容推送到仓库。
3. 到 GitHub 仓库设置里开启：
   `Settings -> Actions -> General -> Workflow permissions -> Read and write permissions`
4. 推送到 `main` 后，等待 Actions 自动构建并推送镜像。

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
docker run -it --rm \
  -v $(pwd):/workspace \
  -e OPENAI_API_KEY=xxx \
  ghcr.io/<github-username>/codex-dev:latest
```

## 可选升级

后续如果你的 NAS 是 ARM 平台，可以再把工作流升级为同时构建 `amd64` 和 `arm64` 多架构镜像。
