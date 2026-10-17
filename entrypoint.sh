#!/bin/bash
set -e

SSH_USER="${SSH_USER:-coder}"
SSH_PASSWORD="${SSH_PASSWORD:-coder}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"
SSH_KEY_PASSPHRASE="${SSH_KEY_PASSPHRASE:-}"
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

if ! id "$SSH_USER" >/dev/null 2>&1; then
  useradd -ms /bin/bash "$SSH_USER"
fi

mkdir -p "/home/$SSH_USER/.ssh"
chmod 700 "/home/$SSH_USER/.ssh"

if [ -n "$SSH_PUBLIC_KEY" ]; then
  printf '%s\n' "$SSH_PUBLIC_KEY" > "/home/$SSH_USER/.ssh/authorized_keys"
  chmod 600 "/home/$SSH_USER/.ssh/authorized_keys"
fi

PRIVATE_KEY="/home/$SSH_USER/.ssh/id_ed25519"
PUBLIC_KEY="${PRIVATE_KEY}.pub"

if [ ! -f "$PRIVATE_KEY" ]; then
  ssh-keygen -q -t ed25519 -N "$SSH_KEY_PASSPHRASE" \
    -f "$PRIVATE_KEY" -C "$SSH_USER@codex-dev"
fi

if [ ! -f "$PUBLIC_KEY" ]; then
  ssh-keygen -y -f "$PRIVATE_KEY" > "$PUBLIC_KEY"
fi

chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

if [ ! -f "/home/$SSH_USER/.ssh/known_hosts" ]; then
  ssh-keyscan -H github.com > "/home/$SSH_USER/.ssh/known_hosts" 2>/dev/null || true
  chmod 644 "/home/$SSH_USER/.ssh/known_hosts"
fi

chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.ssh"

if [ -n "$GIT_USER_NAME" ]; then
  gosu "$SSH_USER" git config --global user.name "$GIT_USER_NAME"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
  gosu "$SSH_USER" git config --global user.email "$GIT_USER_EMAIL"
fi

echo "$SSH_USER:$SSH_PASSWORD" | chpasswd

ssh-keygen -A
mkdir -p /run/sshd

/usr/sbin/sshd

echo "sshd started for user '$SSH_USER' (password auth + pubkey auth enabled)"
echo "Git SSH public key:"
ssh-keygen -lf "$PUBLIC_KEY"

if [ "$#" -eq 0 ]; then
  set -- bash
fi

exec gosu "$SSH_USER" "$@"
