#!/bin/bash
set -e

SSH_USER="${SSH_USER:-coder}"
SSH_PASSWORD="${SSH_PASSWORD:-coder}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"

if ! id "$SSH_USER" >/dev/null 2>&1; then
  useradd -ms /bin/bash "$SSH_USER"
fi

mkdir -p "/home/$SSH_USER/.ssh"
chmod 700 "/home/$SSH_USER/.ssh"

if [ -n "$SSH_PUBLIC_KEY" ]; then
  printf '%s\n' "$SSH_PUBLIC_KEY" > "/home/$SSH_USER/.ssh/authorized_keys"
  chmod 600 "/home/$SSH_USER/.ssh/authorized_keys"
fi

chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.ssh"

echo "$SSH_USER:$SSH_PASSWORD" | chpasswd

ssh-keygen -A
mkdir -p /run/sshd

/usr/sbin/sshd

echo "sshd started for user '$SSH_USER' (password auth + pubkey auth enabled)"

if [ "$#" -eq 0 ]; then
  set -- bash
fi

exec gosu "$SSH_USER" "$@"
