# OSS-Stack-WIN: Integrated Cybersecurity Lab

A production-ready, containerized cybersecurity lab environment featuring **Wazuh** (SIEM), **Suricata** (NIDS), and **Greenbone** (Vulnerability Scanning). This project provides an Ansible-orchestrated deployment stack running on Ubuntu, designed for seamless integration and robust security monitoring.

## 🏗️ Architecture

The stack runs on Docker, managed by Ansible roles, with a `caddy` reverse proxy for unified access.

*   **Wazuh SIEM**:
    *   **Manager**: Ingests logs and alerts.
    *   **Indexer**: Stores security data (OpenSearch based).
    *   **Dashboard**: Web UI for visualization (`https://<IP>:443/wazuh`).
    *   **Agent**: Installed directly on the host (`ServerB`) to monitor system-level events (Auth, Syslog).
*   **Suricata NIDS**:
    *   Runs in `host` network mode.
    *   Inspects traffic on the main interface (`ens33`).
    *   Logs to `eve.json`, which is bind-mounted and ingested by Wazuh.
*   **Greenbone Vulnerability Manager (GVM)**:
    *   **GVMD**: Manages vulnerability data.
    *   **OSPD-OpenVAS**: The scanner component.
    *   **GSA**: Web UI (`https://<IP>:443/greenbone`).
*   **Caddy**:
    *   Reverse proxy handling SSL/TLS.
    *   Provides a landing page at `https://<IP>/`.

## 🚀 Prerequisites

*   **OS**: Ubuntu 24.10 (or compatible Debian-based distro).
*   **RAM**: Minimum 8GB (Strict requirement for Wazuh Indexer & Greenbone).
*   **Root Access**: Scripts require `sudo`.
*   **Ports**: 443 (Web), 1514/1515 (Wazuh Agent), 55000 (Wazuh API).

## 🛠️ Installation

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/TommyKacirek/OSS-Stack-WIN.git
    cd OSS-Stack-WIN
    ```

2.  **Run the Setup Script**:
    The script handles dependency installation (Docker, Ansible), host preparation, and deployment.
    ```bash
    sudo ./setup_lab.sh
    ```
    *   *Note: Takes 10-20 minutes depending on download speeds.*

3.  **Access the Lab**:
    *   **Landing Page**: `https://<YOUR-VM-IP>/`
    *   **Wazuh**: `https://<YOUR-VM-IP>/wazuh` (Creds: `admin` / `SecretPassword123!`)
    *   **Greenbone**: `https://<YOUR-VM-IP>/greenbone` (Creds: `admin` / `admin`)
        *   *See "Known Issues" regarding scanner status.*

## ✅ Verification

Run the included verification script to test the detection pipeline:

```bash
sudo ./verify_lab.sh
```

This will:
*   Trigger a **Suricata Alert** (BlackSun User-Agent).
*   Trigger a **Wazuh Agent Alert** (Suspicious Syslog entry).
*   Attempt a failed SSH login.
*   Check container status.

Check the **Wazuh Dashboard** -> **Security Events** to see these alerts appearing in real-time.

## ⚠️ Known Issues / Troubleshooting

### Greenbone Scanner (OSPD) Initialization
**Status**: Degraded.
The Greenbone scanner containers run, but the `ospd-openvas` service may fail to initialize the scanner socket due to a path mismatch with the NVT feed (Error: `sha256sums not found`).

*   **Context**: The `openvasd` binary expects the vulnerability feed in a specific path that typically requires the exact versioned structure (`25.0/vt-data/nasl`) mixed with a flat structure.
*   **Workaround**: Most of the stack is fully operational. If you need the scanner, refer to `greenbone-docker_vt_data_vol` volume adjustments detailed in `context.md`.
*   **Reference**: See `context.md` in the root of this repo for a detailed debugging log and list of attempted fixes.

---
**Author**: Tommy Kacirek
**License**: MIT / Apache 2.0 (Check individual component licenses)
