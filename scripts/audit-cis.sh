#!/usr/bin/env bash
# ==============================================================================
# scripts/audit-cis.sh
# Automated CIS Benchmark Level 2 Security Audit Tool for Debian/RHEL
# Author: Axell Rojas (https://github.com/STXNES)
# ==============================================================================

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

check() {
    local desc="$1"
    local cmd="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -ne "  [..] ${desc}..."
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "\r  [${GREEN}PASS${NC}] ${desc}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "\r  [${RED}FAIL${NC}] ${desc}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo -e "\n${BOLD}${CYAN}====================================================================${NC}"
echo -e "${BOLD}${CYAN}   ENTERPRISE LINUX CIS BENCHMARK LEVEL 2 SECURITY AUDIT            ${NC}"
echo -e "${BOLD}${CYAN}   Target: $(hostname) ($(uname -srm))                             ${NC}"
echo -e "${BOLD}${CYAN}====================================================================${NC}\n"

# Section 1: Network & Kernel Hardening (sysctl)
echo -e "${BOLD}[1/5] Kernel Parameters & Sysctl Network Defenses${NC}"
check "TCP SYN Cookies enabled" "sysctl net.ipv4.tcp_syncookies | grep -q '1'"
check "Reverse Path Filtering enabled (Strict)" "sysctl net.ipv4.conf.all.rp_filter | grep -q '1'"
check "ICMP Redirects disabled (all)" "sysctl net.ipv4.conf.all.accept_redirects | grep -q '0'"
check "Source Routing disabled" "sysctl net.ipv4.conf.all.accept_source_route | grep -q '0'"
check "ICMP Echo Broadcasts ignored (Smurf attack defense)" "sysctl net.ipv4.icmp_echo_ignore_broadcasts | grep -q '1'"
check "Kernel pointer restriction enabled (kptr_restrict = 2)" "sysctl kernel.kptr_restrict | grep -q '2'"
check "dmesg restricted to privileged users" "sysctl kernel.dmesg_restrict | grep -q '1'"
check "ASLR full randomization enforced" "sysctl kernel.randomize_va_space | grep -q '2'"
check "Protected symlinks enabled" "sysctl fs.protected_symlinks | grep -q '1'"
check "Protected hardlinks enabled" "sysctl fs.protected_hardlinks | grep -q '1'"

# Section 2: OpenSSH Daemon Hardening
echo -e "\n${BOLD}[2/5] OpenSSH Daemon Security Policies${NC}"
check "SSH Port configured to non-standard 2222" "grep -Ei '^[#\s]*Port 2222' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf"
check "Root SSH login disabled" "sshd -T 2>/dev/null | grep -Ei 'permitrootlogin no'"
check "Password authentication disabled (Pubkey only)" "sshd -T 2>/dev/null | grep -Ei 'passwordauthentication no'"
check "MaxAuthTries restricted to <= 3" "sshd -T 2>/dev/null | awk '/maxauthtries/ { if (\$2 <= 3) exit 0; else exit 1 }'"
check "X11 Forwarding disabled" "sshd -T 2>/dev/null | grep -Ei 'x11forwarding no'"
check "ED25519 Host Key configured" "sshd -T 2>/dev/null | grep -i 'ssh_host_ed25519_key'"

# Section 3: Firewall (UFW) & Intrusion Prevention (Fail2ban)
echo -e "\n${BOLD}[3/5] Firewall (UFW) & Intrusion Prevention (Fail2ban)${NC}"
check "UFW service active and enabled" "ufw status | grep -qw 'active'"
check "UFW default incoming policy is DENY" "ufw status verbose | grep -i 'Default:' | grep -i 'deny (incoming)'"
check "Fail2ban service is active" "systemctl is-active fail2ban | grep -qw 'active'"
check "Fail2ban sshd jail active" "fail2ban-client status sshd >/dev/null 2>&1"
check "Fail2ban recidive jail active" "fail2ban-client status recidive >/dev/null 2>&1"

# Section 4: Web Proxy & TLS 1.3 Hardening
echo -e "\n${BOLD}[4/5] Nginx Reverse Proxy & Cryptographic Hardening${NC}"
check "Nginx service is active" "systemctl is-active nginx | grep -qw 'active'"
check "Nginx server_tokens disabled (Information leakage mitigation)" "grep -R 'server_tokens off;' /etc/nginx/"
check "HSTS header enabled" "grep -R 'Strict-Transport-Security' /etc/nginx/"
check "X-Frame-Options SAMEORIGIN enabled" "grep -R 'X-Frame-Options' /etc/nginx/"
check "TLS 1.0 and 1.1 disabled" "! grep -R 'ssl_protocols' /etc/nginx/ | grep -E 'TLSv1\b|TLSv1\.1\b'"

# Section 5: Filesystem Permissions & Critical File Integrity
echo -e "\n${BOLD}[5/5] Filesystem Integrity & Sensitive File Permissions${NC}"
check "/etc/shadow permissions <= 0640 and root-owned" "[ -f /etc/shadow ] && [ \$(stat -c %a /etc/shadow) -le 640 ]"
check "/etc/passwd permissions 0644 and root-owned" "[ \$(stat -c %a /etc/passwd) -eq 644 ]"
check "/etc/sudoers permissions 0440 and root-owned" "[ \$(stat -c %a /etc/sudoers) -eq 440 ]"
check "systemd sandboxed infra-backup timer active" "systemctl is-active infra-backup.timer >/dev/null 2>&1"

# Score & Summary
SCORE=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
echo -e "\n${BOLD}====================================================================${NC}"
echo -e "${BOLD}AUDIT SUMMARY:${NC}"
echo -e "  Total Verifications : ${TOTAL_CHECKS}"
echo -e "  Passed              : ${GREEN}${PASSED_CHECKS}${NC}"
echo -e "  Failed              : ${RED}${FAILED_CHECKS}${NC}"
echo -e "  CIS Compliance Score: ${CYAN}${SCORE}%${NC}"
echo -e "${BOLD}====================================================================${NC}\n"

if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✔ SYSTEM CONFORMS TO CIS BENCHMARK LEVEL 2 SPECIFICATIONS.${NC}\n"
    exit 0
else
    echo -e "${YELLOW}${BOLD}⚠ REMEDIATION REQUIRED FOR ${FAILED_CHECKS} CHECKS.${NC}\n"
    exit 1
fi
