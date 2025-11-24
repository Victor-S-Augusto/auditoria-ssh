#!/bin/bash
# infra/setup_aluno.sh — execute no container aluno

set -e
apt update
DEBIAN_FRONTEND=noninteractive apt install -y sshpass nmap whois netcat

# Cria wordlist simples (somente para laboratório)
cat > /tmp/wordlist_small.txt <<'WL'
password
aluno1234
Aluno1234
senha
Senha
12345
123456789
Prof1234
WL

echo "Setup attacker completo. Wordlist em /tmp/wordlist_small.txt"