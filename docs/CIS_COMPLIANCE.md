# CIS Benchmark Level 2 Compliance Checklist

This document details the configuration controls aligned with the **Center for Internet Security (CIS) Debian 12 / RHEL 9 Benchmark Level 2 Server**.

---

## 1. Initial Setup & Filesystem Controls

| CIS Item | Control Description | Status | Implementation File |
| :--- | :--- | :---: | :--- |
| **1.1.1.1** | Restrict unprivileged eBPF execution | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **1.1.1.2** | Ensure ASLR is enabled (`randomize_va_space = 2`) | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **1.1.1.3** | Enforce protected symlinks and hardlinks | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **1.1.1.4** | Restrict dmesg access (`kernel.dmesg_restrict = 1`) | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **1.1.1.5** | Hide exposed kernel pointers (`kptr_restrict = 2`) | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |

---

## 2. Network Configuration & Perimeter Defense

| CIS Item | Control Description | Status | Implementation File |
| :--- | :--- | :---: | :--- |
| **3.1.1** | Disable packet forwarding (`ip_forward = 0`) | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.2.1** | Disable source routed packet acceptance | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.2.2** | Disable ICMP redirect acceptance | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.2.3** | Disable secure ICMP redirect acceptance | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.2.4** | Log suspicious / Martian packets | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.2.5** | Ignore ICMP broadcast ping requests | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.2.7** | Enforce Reverse Path Filtering (RFC 3704) | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.2.8** | Enable TCP SYN Cookies | `COMPLIANT` | `configs/sysctl/99-security-hardening.conf` |
| **3.5.1.1**| Enforce UFW default deny incoming policy | `COMPLIANT` | `configs/ufw/ufw-rules.sh` |
| **3.5.1.2**| Enforce rate limiting on SSH ingress port | `COMPLIANT` | `configs/ufw/ufw-rules.sh` |

---

## 3. Access Control & OpenSSH Hardening

| CIS Item | Control Description | Status | Implementation File |
| :--- | :--- | :---: | :--- |
| **5.2.1** | Restrict OpenSSH port to dedicated non-default (2222) | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.4** | Disable SSH root login (`PermitRootLogin no`) | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.5** | Enforce Public Key Authentication only | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.7** | Restrict authentication retries (`MaxAuthTries <= 3`) | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.8** | Restrict SSH MaxSessions (`MaxSessions 4`) | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.10**| Disable SSH password authentication | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.11**| Disable empty password usage | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.14**| Disable X11 forwarding | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |
| **5.2.15**| Enforce strong ciphers and key exchange algorithms | `COMPLIANT` | `configs/ssh/sshd_hardening.conf` |

---

## 4. Service Hardening & Sandboxing

| CIS Item | Control Description | Status | Implementation File |
| :--- | :--- | :---: | :--- |
| **6.1.1** | Read-only OS mounts in systemd (`ProtectSystem=full`) | `COMPLIANT` | `configs/systemd/*.service` |
| **6.1.2** | Isolate home directory access (`ProtectHome=true`) | `COMPLIANT` | `configs/systemd/*.service` |
| **6.1.3** | Prevent execution of new privileges (`NoNewPrivileges=true`) | `COMPLIANT` | `configs/systemd/*.service` |
| **6.1.4** | Isolated `/tmp` filesystem namespace (`PrivateTmp=true`) | `COMPLIANT` | `configs/systemd/*.service` |
| **6.1.5** | Memory W^X execution denial (`MemoryDenyWriteExecute=true`) | `COMPLIANT` | `configs/systemd/*.service` |
| **6.2.1** | Intrusion prevention automated ban (Fail2ban jails) | `COMPLIANT` | `configs/fail2ban/jail.d/custom-jails.local` |
