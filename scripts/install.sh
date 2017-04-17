#!/usr/bin/env bash
set -e
echo "Installing dependencies..."

if [ -x "$(command -v apt-get)" ]; then
  sudo apt-get update -y
  sudo apt-get install -y unzip jq python-pip
else
  sudo yum update -y
  sudo yum install -y unzip wget jq python-pip
fi
echo "Fetching Consul..."
CONSUL=0.7.0
cd /tmp
wget https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_linux_amd64.zip -O consul.zip --quiet

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /opt/consul/data

echo "Installing Systemd service..."
sudo mkdir -p /etc/systemd/system/consul.d
sudo chown root:root /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service
sudo chmod 0644 /etc/systemd/system/consul.service
sudo mkdir -p /etc/sysconfig/consul
sudo chown root:root /etc/sysconfig/consul
sudo chmod 00644 /etc/sysconfig/consul
sudo mkdir -p /etc/consul
sudo chown root:root /etc/consul
sudo chmod 0644 /etc/consul
