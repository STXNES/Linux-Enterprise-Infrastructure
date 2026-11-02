#!/usr/bin/env bash
# ==============================================================================
# scripts/setup-hardening.sh
# Production Provisioning & CIS Hardening Automation for Debian / RHEL
# Author: Axell Rojas (https://github.com/STXNES)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[ERROR] This provisioning script must be run as root.${NC}" >&2
    exit 1
fi

echo -e "${BLUE}[*] Initializing Enterprise Linux Hardening Setup...${NC}"

# 1. Install Required Packages
echo -e "${BLUE}[1/7] Installing Security Dependencies & Tooling...${NC}"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y ufw fail2ban nginx zstd gpg gnupg libpam-pwquality auditd audispd-plugins unattended-upgrades
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y epel-release
    dnf install -y ufw fail2ban nginx zstd gnupg2 audit
fi

# 2. Deploy Sysctl Kernel Hardening
echo -e "${BLUE}[2/7] Deploying Kernel & Network Hardening (sysctl)...${NC}"
cp "${REPO_ROOT}/configs/sysctl/99-security-hardening.conf" /etc/sysctl.d/99-security-hardening.conf
sysctl --system >/dev/null

# 3. Configure UFW Firewall
echo -e "${BLUE}[3/7] Enforcing UFW Stateful Firewall Rules...${NC}"
bash "${REPO_ROOT}/configs/ufw/ufw-rules.sh"

# 4. OpenSSH Hardening
echo -e "${BLUE}[4/7] Hardening OpenSSH Server (Port 2222, PubKey only)...${NC}"
mkdir -p /etc/ssh/sshd_config.d
cp "${REPO_ROOT}/configs/ssh/sshd_hardening.conf" /etc/ssh/sshd_config.d/99-hardening.conf
if sshd -t; then
    systemctl restart ssh || systemctl restart sshd
else
    echo -e "${RED}[ERROR] SSH configuration test failed. Reverting...${NC}"
    rm -f /etc/ssh/sshd_config.d/99-hardening.conf
    exit 1
fi

# 5. Fail2ban Intrusion Prevention Configuration
echo -e "${BLUE}[5/7] Deploying Fail2ban Jails (sshd, nginx-req-limit, recidive)...${NC}"
mkdir -p /etc/fail2ban/jail.d /etc/fail2ban/filter.d
cp "${REPO_ROOT}/configs/fail2ban/jail.d/custom-jails.local" /etc/fail2ban/jail.d/custom-jails.local
cp "${REPO_ROOT}/configs/fail2ban/filter.d/nginx-req-limit.conf" /etc/fail2ban/filter.d/nginx-req-limit.conf
systemctl restart fail2ban
systemctl enable fail2ban

# 6. Nginx Hardening & Security Headers
echo -e "${BLUE}[6/7] Deploying Nginx TLS 1.3 Baseline & Reverse Proxy...${NC}"
mkdir -p /etc/nginx/snippets /etc/nginx/conf.d
cp "${REPO_ROOT}/configs/nginx/snippets/security-headers.conf" /etc/nginx/snippets/security-headers.conf
cp "${REPO_ROOT}/configs/nginx/snippets/ssl-params.conf" /etc/nginx/snippets/ssl-params.conf
cp "${REPO_ROOT}/configs/nginx/conf.d/hardened-reverse-proxy.conf" /etc/nginx/conf.d/hardened-reverse-proxy.conf
if nginx -t >/dev/null 2>&1; then
    systemctl restart nginx
    systemctl enable nginx
else
    echo -e "${RED}[WARNING] Nginx test had warnings (check SSL certificate paths).${NC}"
fi

# 7. Backup Pipeline Installation & systemd Timer
echo -e "${BLUE}[7/7] Installing Backup Pipeline & Systemd Timer...${NC}"
cp "${REPO_ROOT}/scripts/infra-backup.sh" /usr/local/bin/infra-backup.sh
chmod 700 /usr/local/bin/infra-backup.sh

cp "${REPO_ROOT}/configs/systemd/infra-backup.service" /etc/systemd/system/infra-backup.service
cp "${REPO_ROOT}/configs/systemd/infra-backup.timer" /etc/systemd/system/infra-backup.timer

systemctl daemon-reload
systemctl enable --now infra-backup.timer

echo -e "\n${GREEN}[✔] Enterprise Linux Hardening Setup successfully completed!${NC}"
echo -e "Run '${SCRIPT_DIR}/audit-cis.sh' to verify security compliance.\n"
