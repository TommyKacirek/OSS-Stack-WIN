# Mission Handover: integrated Cybersecurity Lab

## 🌍 Current System State (As of 2025-12-29)

### 1. Greenbone Vulnerability Management
- **Status**: ✅ **Fully Operational**.
- **Critical Fix Applied**: The scanner (`ospd-openvas`) was failing due to missing checksums and path mismatches. We performed a "Tabula Rasa" reset and **manually injected Feed Version 25.0** into the `vt_data_vol`.
- **Infrastructure**:
  - `docker-compose.yml` (and Ansible template) now explicitly points `FEED_PATH` to `/var/lib/openvas/plugins/25.0/vt-data/nasl`.
  - Notus scanner is configured and volume mounted correctly.
- **Access**: `https://<LAB-IP>/greenbone` (Credentials: `admin` / `admin`).

### 2. Wazuh SIEM
- **Status**: ✅ **Running**.
- **Components**: Manager, Indexer, Dashboard are up.
- **Access**: `https://<LAB-IP>/wazuh` (Credentials: `admin` / `SecretPassword123!`).

### 3. Suricata NIDS
- **Status**: ✅ **Running**.
- **Integration**: Logs are writing to `eve.json` which is bind-mounted to Wazuh Agent/Manager for ingestion.

### 4. Caddy (Reverse Proxy)
- **Status**: ✅ **Running**.
- **Role**: Handles SSL and routing for Wazuh and Greenbone on port 443.

---

## 🛠️ Maintenance & Troubleshooting

### Greenbone Feed Updates
**WARNING**: The current feed data (v25.0) was manually injected because the automated sync container was pulling an incomplete/older version (21.04).
- If you run `clean_slate_greenbone.sh`, it might revert to a broken state unless the `vulnerability-tests` image is updated upstream.
- **To fix volume manually (if needed)**:
  ```bash
  docker run --rm -v greenbone-docker_vt_data_vol:/mnt \
    registry.community.greenbone.net/community/vulnerability-tests \
    sh -c "rm -rf /mnt/* && cp -r /var/lib/openvas/25.0 /mnt/ && chown -R 1001:1001 /mnt"
  ```

### Ansible Synchronization
The file `roles/greenbone/templates/docker-compose.j2` has been updated to reflect the production fixes. If you intend to redeploy using Ansible, it is safe to do so.

### Restarting the Stack
Use the standard Docker Compose commands in the respective directories (`/home/kaca/*-docker/`) or use the utility scripts in `/home/kaca/cybersecurity-serverB/`.
