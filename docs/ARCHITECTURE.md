# Architecture Blueprint & Security Specifications

## 1. Overview & Objective

This repository implements an enterprise-grade hardened reference architecture for mission-critical Linux nodes running **Debian 12 (Bookworm)** and **RHEL 9**. 

Designed under the **Center for Internet Security (CIS) Level 2 Server Benchmark**, it provides defense-in-depth across the kernel, network perimeter, service execution layers, and cryptographic automated recovery routines.

```
                           +--------------------------------------+
                           |          UNTRUSTED INTERNET          |
                           +-------------------+------------------+
                                               |
                                     Traffic on 80/443 & 2222
                                               v
                     +--------------------------------------------------+
                     |            UFW FIREWALL / IPTABLES               |
                     |  - Default Deny Incoming                         |
                     |  - Port 2222: SSH (Rate Limited)                 |
                     |  - Port 80: HTTP (Redirect to 443)               |
                     |  - Port 443: HTTPS (TLS 1.3 only)                |
                     +---------+--------------------+-------------------+
                               |                    |
             Port 2222         |                    | Port 80 & 443
                               v                    v
    +--------------------------------+   +------------------------------------+
    |      OPENSSH HARDENED          |   |     NGINX REVERSE PROXY            |
    | - Port 2222 / ED25519 only     |   | - TLS 1.3 / HSTS 2-Yr / HTTP/2     |
    | - Root & Password Auth: NO     |   | - CSP, X-Frame-Options, no-sniff   |
    | - MaxAuthTries 3 / Grace 30s   |   | - Rate Limiting: 10r/s (zone)      |
    +---------------+----------------+   +------------------+-----------------+
                    |                                       |
                    | Log Auth Events                       | Log 4xx/5xx Errors
                    v                                       v
    +-------------------------------------------------------------------------+
    |                       FAIL2BAN INTRUSION PREVENTION                     |
    |  - sshd jail (3 attempts -> 24h ban)                                    |
    |  - nginx-req-limit jail (Rate limit abuse -> 2h ban)                    |
    |  - recidive jail (Repeat offenders -> 1 week ban)                       |
    +-------------------------------------------------------------------------+
                                        |
                                        v
    +-------------------------------------------------------------------------+
    |                     SYSTEMD SANDBOXING LAYER                            |
    |  - ProtectSystem=full, ProtectHome=read-only, PrivateTmp=true           |
    |  - NoNewPrivileges=true, MemoryDenyWriteExecute=true                    |
    |  - Socket run isolation: /run/enterprise-app                            |
    +-----------------------------------+-------------------------------------+
                                        |
                                        v
    +-------------------------------------------------------------------------+
    |             AUTOMATED BACKUP PIPELINE (infra-backup.sh)                 |
    |  - Systemd Timer: daily at 02:00:00 UTC                                 |
    |  - LVM Atomic Snapshot: /dev/vg0/snap_data                              |
    |  - Multithreaded Zstd Compression (Level 19)                            |
    |  - Asymmetric GPG Encryption (STXNES-INFRA-KEY)                         |
    |  - Cryptographic Verification: SHA256 integrity hash -> Syslog (local0) |
    |  - Offsite Encrypted Replication over Hardened SSH                      |
    +-------------------------------------------------------------------------+
```

---

## 2. Threat Model & Mitigations

| Threat Vector | Mitigation Strategy | Implemented Component |
| :--- | :--- | :--- |
| **Network IP Spoofing & TCP SYN Flood** | Enforce RFC 3704 strict reverse path filtering and kernel syncookies. | `configs/sysctl/99-security-hardening.conf` |
| **SSH Brute-Force & Credential Stuffing** | Move port to 2222, disable password auth, enforce ED25519 keys, and limit auth attempts to 3. | `configs/ssh/sshd_hardening.conf` + UFW rate limit |
| **Layer 7 HTTP Flooding & Scanners** | Zone rate-limiting in Nginx (10 req/sec) with automated IP bans via Fail2ban filter. | `configs/nginx/nginx.conf` + `nginx-req-limit.conf` |
| **Privilege Escalation & Binary Exploit** | Sandboxed systemd execution (`ProtectSystem=full`, `NoNewPrivileges=true`, `MemoryDenyWriteExecute=true`). | `configs/systemd/sample-sandboxed-app.service` |
| **Ransomware / Data Destruction** | Atomic read-only LVM snapshots, multithreaded zstd compression, and offsite GPG-encrypted replication. | `scripts/infra-backup.sh` + `infra-backup.timer` |
| **Man-in-the-Middle (MitM) Attacks** | TLS 1.3 only, modern elliptic-curve ciphers, HSTS preloaded (2 years), and OCSP stapling. | `configs/nginx/snippets/ssl-params.conf` |

---

## 3. Engineering Decisions & Architecture Tradeoffs

### 3.1 Ed25519 Cryptography vs Traditional RSA
- **Decision:** OpenSSH is restricted exclusively to Ed25519 elliptic-curve keys (with fallback to 4096-bit RSA).
- **Rationale:** Ed25519 offers faster signature calculation, resistance to cache/side-channel attacks, and immune to padding oracle vulnerabilities present in legacy RSA formats.

### 3.2 Systemd Sandboxing vs Containerization
- **Decision:** Native systemd process sandboxing (`ProtectSystem=full`, `PrivateTmp=true`, `RestrictAddressFamilies`).
- **Rationale:** Allows defense-in-depth on bare metal or virtualized instances without the overhead, bridge network latency, or daemon vulnerability surface of Docker/container runtimes.

### 3.3 Zstandard (zstd -19) vs gzip / bzip2
- **Decision:** Zstandard level 19 multithreaded (`-T0`).
- **Rationale:** Achieves up to 3.5x faster decompression and higher compression ratio compared to gzip, drastically decreasing backup window time and network replication payload sizes.
