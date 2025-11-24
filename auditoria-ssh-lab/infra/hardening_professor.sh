#!/bin/bash
# infra/hardeningh_professor.sh — execute dentro do container professor como root



#cria usuário "professor" com senha fraca (simulação)
if ! id "professor" &>/dev/null; then
    useradd -m -s /bin/bash professor
fi
echo "professor:123456789" | chpasswd

# instala ssh server
DEBIAN_FRONTEND=noninteractive apt update & install -y openssh-server

# garante diretórios
mkdir -p /var/run/sshd

# configura sshd para permitir password (intencionalmente vulnerável para simulação)
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat >/etc/ssh/sshd_config <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PermitEmptyPasswords no
MaxAuthTries 6
AllowUsers professor
EOF

echo "Setup victim completo. Usuário: professor / senha: 123456789"

# --- MITIGAÇÃO V#1: HARDENING SSH ---
echo "--- 1. Protegendo a configuração SSH ---"
# Secure SSH configuration
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
# Adicionar outras diretivas de segurança de forma idempotente
grep -q '^PermitRootLogin no' /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
grep -q '^PubkeyAuthentication yes' /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
grep -q '^MaxAuthTries' /etc/ssh/sshd_config || echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
echo "SSH seguro!."

# --- MITIGAÇÃO V#2: POLÍTICA DE SENHAS ---
echo "--- 2. Implementar uma política de senhas fortes ---"
apt-get install -y libpam-pwquality > /dev/null 2>&1 || true
cat > /etc/security/pwquality.conf <<EOF
minlen = 12
minclass = 3
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
EOF

#tamanho mínimo 12, pelo menos 3 classes de caracteres (maiúsculas, minúsculas, dígitos, especiais)

chage -d 0 professor
echo "Política de senhas fortes em vigor e senha do usuário 'professor' expirada."

# --- MITIGAÇÃO V#3: REMOVER PRIVILÉGIOS EXCESSIVOS ---
echo "--- 3. Removendo Privilegios Excessivos ---"
sed -i '/professor.*NOPASSWD/d' /etc/sudoers || true
echo "Sudo sem senha para 'professor' removido."

# --- MITIGAÇÃO V#4: REMOÇÃO DE CREDENCIAIS EXPOSTAS ---
echo "--- 4. Removendo Credenciais Expostas ---"
rm -f /home/professor/anotacoes.txt || true
echo "Arquivo com credenciais removido."

# --- MITIGAÇÃO V#5: HARDENING DO SO ---
echo "--- 5. Aplicando Hardening no Sistema Operacional ---"
cat > /etc/sysctl.d/99-hardening.conf <<EOF
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_syncookies = 1
kernel.randomize_va_space = 2
EOF
if [ "$SKIP_NET" != "1" ]; then
	sysctl -p || echo "sysctl falhou." 
else
	echo "Pulando aplicação de sysctl durante o build."
fi
echo "Parametros de hardening aplicados no SO."
echo "--- Script de Hardening completo. ---"