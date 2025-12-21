#!/bin/bash

set -e

# LOCALE FIX FOR ANSIBLE
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

################################################################################
# CYBERSECURITY LAB SETUP SCRIPT (Senior DevOps/Security Edition)
################################################################################

# RAM CHECK
MIN_RAM_GB=8
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))

if [ "$TOTAL_RAM_GB" -lt "$MIN_RAM_GB" ]; then
    echo "[!] WARNING: System has only ${TOTAL_RAM_GB}GB of RAM. Wazuh Indexer requires at least 8GB for stable operation."
    read -p "Continue anyway? (y/N) " confirm
    [[ "$confirm" == [yY] ]] || exit 1
fi

echo "--- [1/5] System Optimization & Persistence ---"
# Wazuh Indexer (OpenSearch) requires high vm.max_map_count
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

echo "--- [2/5] Installing Dependencies & Host Agent ---"
sudo apt-get update
sudo apt-get install -y python3 python3-pip ansible git jq curl gnupg apt-transport-https docker.io

# Install Wazuh Agent on Host
echo "Installing Wazuh Agent on Host..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt-get update
sudo apt-get install -y wazuh-agent

# Configure Agent
echo "Configuring Wazuh Agent..."
sudo sed -i 's/<address>.*<\/address>/<address>127.0.0.1<\/address>/' /var/ossec/etc/ossec.conf
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Install Python SDK for Docker
sudo apt-get install -y python3-docker python3-requests || pip3 install docker --break-system-packages

echo "--- [3/5] Smart Extract: Fetching Default Configs ---"
mkdir -p /home/kaca/cybersecurity-serverB/roles/wazuh/files
mkdir -p /home/kaca/cybersecurity-serverB/roles/suricata/files

# Extract configs using create/cp (more reliable)
echo "Extracting ossec.conf from image..."
docker create --name wazuh_tmp wazuh/wazuh-manager:4.7.2
docker cp wazuh_tmp:/var/ossec/etc/ossec.conf /home/kaca/cybersecurity-serverB/roles/wazuh/files/ossec.conf.default || echo "Warning: ossec.conf extraction failed, using template."
docker rm wazuh_tmp

echo "Extracting suricata.yaml from image..."
docker create --name suricata_tmp jasonish/suricata:latest
docker cp suricata_tmp:/etc/suricata/suricata.yaml /home/kaca/cybersecurity-serverB/roles/suricata/files/suricata.yaml.default || echo "Warning: suricata.yaml extraction failed, using template."
docker rm suricata_tmp

echo "--- [4/5] Deploying Stack via Ansible ---"
docker volume create suricata_logs || true
export ANSIBLE_ROLES_PATH=/home/kaca/cybersecurity-serverB/roles
ansible-galaxy collection install community.docker --force
ansible-playbook -i inventory/hosts playbooks/deploy_lab.yml

echo "================================================================================"
echo "   DEPLOYMENT COMPLETE"
echo "================================================================================"
