# Operational Runbook & Disaster Recovery SOP

## 1. Quick Verification & Health Check

### 1.1 Service Status Check
Verify that all core daemons are active and healthy:
```bash
systemctl is-active nginx sshd fail2ban infra-backup.timer
```

### 1.2 Firewall & Intrusion Prevention Inspection
```bash
# Check UFW state
sudo ufw status verbose

# Inspect Fail2ban banned IP list
sudo fail2ban-client status sshd
sudo fail2ban-client status nginx-req-limit
sudo fail2ban-client status recidive
```

### 1.3 Unbanning an Accidentally Blocked IP
If a legitimate administrator IP is blocked by Fail2ban:
```bash
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>
sudo fail2ban-client set recidive unbanip <IP_ADDRESS>
```

---

## 2. Backup Execution & Disaster Recovery

### 2.1 Triggering an On-Demand Backup
Run the automated pipeline manually with GPG encryption and cryptographic verification:
```bash
sudo /usr/local/bin/infra-backup.sh --full --gpg --verify
```

### 2.2 Restoring from an Encrypted Backup Archive
To restore data on a fresh or recovered host:

```bash
# Step 1: Transfer the encrypted archive
scp -P 2222 backup-storage:/srv/cold-storage/srv01/srv01_20261102_020001.tar.zst.gpg /tmp/

# Step 2: Decrypt the archive using the private GPG key
gpg --decrypt /tmp/srv01_20261102_020001.tar.zst.gpg > /tmp/srv01_recovered.tar.zst

# Step 3: Verify cryptographic SHA256 integrity hash
sha256sum /tmp/srv01_recovered.tar.zst

# Step 4: Decompress and unpack payload
sudo tar -I zstd -xvf /tmp/srv01_recovered.tar.zst -C /
```

---

## 3. Incident Response & Troubleshooting

### 3.1 Investigating Malicious SSH Activity
```bash
# View live journal logs for SSH failures
sudo journalctl -u ssh -u sshd -f -o cat | grep -i "Failed password"

# Check Fail2ban log entries
sudo grep -i "Ban" /var/log/fail2ban.log
```

### 3.2 Resolving systemd Sandboxing Socket Permissions
When deploying a custom daemon under `ProtectSystem=full`:
1. Ensure the daemon does not attempt to write directly to `/usr` or `/etc`.
2. Configure `RuntimeDirectory=your-daemon-name` in the `.service` unit to grant access to `/run/your-daemon-name`.
3. If temporary IPC socket communication is required, define `ReadWritePaths=/run/your-socket-dir`.
