#!/bin/bash

echo "--- [Red Team] Lab Verification Script ---"

# 1. Network Test (Triggers Suricata via User-Agent)
echo "[1/3] Triggering Suricata alert (BlackSun)..."
curl -A "BlackSun" http://testmyids.com -m 5 || echo "Network test triggered (Expected status/connection log)."

# 2. Host Test (Triggers Wazuh Agent via logger)
echo "[2/3] Triggering Wazuh Agent alert (Syslog)..."
logger "Wazuh-Test: Highly suspicious activity detected on host"

# 3. Failed SSH Test (Triggers Wazuh Agent)
echo "[3/3] Triggering failed SSH login..."
ssh -o BatchMode=yes -o ConnectTimeout=1 invalid_user@localhost 2>/dev/null || true

echo ""
echo "--- Status Check ---"
echo ">> Docker Containers:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo ">> Wazuh Agent:"
sudo systemctl status wazuh-agent | grep "Active:"

echo ""
echo ">> Verification Instructions:"
echo "1. Log into Wazuh Dashboard: https://100.114.205.29:5601"
echo "2. Check 'Security Events' for alerts related to 'BlackSun' or 'invalid_user'."
echo "3. Confirm 'Host' (ServerB) is visible in the Agents tab."
