# Greenbone Debugging Context (Session Handover)

## 🏗️ Status Overview
- **Wazuh**: ✅ Fully Operational (Agents connected, Alerts piping from Suricata).
- **Suricata**: ✅ Fully Operational (Verified via "Live Fire").
- **Greenbone**: ⚠️ **Degraded**. Containers running, but scanner is dormant.

## 🔴 The Problem
The Greenbone Scanner container (`ospd-openvas`) loops with the following error and fails to connect to the socket:
```
WARN openvasd::vts::orchestrator: Unable to check feed error=Unable to calculate hash: Unable to load file: sha256sums not found.
WARN openvasd::scans::scheduling: OSPD socket /var/run/ospd/ospd-openvas.sock does not exist.
```

The scanner binary (`openvasd`) cannot locate the critical `sha256sums` file in the mounted volume, preventing it from loading the Vulnerability Tests (NVTs).

## 🕵️ What We Know
1. **The File Exists**: Verified multiple times via `ls -la` in the container. The `sha256sums` file IS present in the mounted volume.
2. **Permissions**: The file is accessible (chmod 755/644 tried, owned by root/1001).
3. **Mount Point**: The volume `greenbone-docker_vt_data_vol` is mounted. We have tried mounting it to:
    - `/etc/openvas/plugins` (Original config)
    - `/var/lib/openvas/plugins` (Standard Linux layout)
4. **Source Data**: The data was manually extracted from the `vulnerability-tests` docker image, confirming it is valid data.

## 🛠️ Attempted Fixes (All Failed)
1. **Automated Restore**: Failed due to missing paths in the restore image script.
2. **Manual Copy**: Successfully copied data, but scanner ignored it.
3. **Path Flattener**: Moved all files to the root of the volume.
4. **Deep Nesting**: Replicated the `25.0/vt-data/nasl/` structure found in the image.
5. **Shotgun Method**: Copied `sha256sums` to `nasl/`, `plugins/`, `vt-data/` simultaneously.
6. **Symlinking**: Linked `/var/lib/openvas` to `/usr/share/openvas` and `/opt/gvm`.
7. **Environment Override**: Tried setting `OPENVAS_PLUGINS` and `NASL_SEARCH_PATH` env vars.

## ⏭️ Next Steps (Tomorrow)
1. **Binary Inspection**: We need to know EXACTLY where `openvasd` is looking. Since `strings` is not available, we might need to `strace` the process or copy the binary out to analyze it.
2. **Config File**: Review `/etc/openvas/openvas.conf` explicitly for a `plugins_folder` directive.
3. **Log Level**: Increase log level in `openvas_log.conf` to TRACE to see the specific path being accessed.
4. **Different Image**: Consider switching the scanner image tag if this one (stable) has a broken path definition.
