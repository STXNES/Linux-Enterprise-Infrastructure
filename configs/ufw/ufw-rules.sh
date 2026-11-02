#!/usr/bin/env bash
# ==============================================================================
# configs/ufw/ufw-rules.sh
# Enterprise UFW (Uncomplicated Firewall) Hardening Script
# Author: Axell Rojas (https://github.com/STXNES)
# ==============================================================================

set -euo pipefail

echo "[*] Configuring Enterprise UFW rules according to CIS Level 2..."

# 1. Reset rules to clean baseline (unattended)
ufw --force reset

# 2. Enforce strict default policies
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

# 3. Harden SSH on custom port 2222 with connection rate-limiting
# Limit mitigates brute force attempts: denies connections from an IP that attempts 6+ connections in 30s
ufw limit 2222/tcp comment 'SSH Hardened Port (Rate Limited)'

# 4. Allow HTTP (Port 80) exclusively for ACME challenges and TLS 1.3 redirection
ufw allow 80/tcp comment 'HTTP 80 - 301 Permanent Redirect to HTTPS'

# 5. Allow HTTPS (Port 443) for encrypted production traffic
ufw allow 443/tcp comment 'HTTPS 443 - TLS 1.3 Production Traffic'

# 6. Enable logging for security monitoring and SIEM integration
ufw logging medium

# 7. Enable firewall
echo "[*] Enabling UFW firewall..."
ufw --force enable

echo "[+] UFW Configuration completed successfully."
ufw status verbose
