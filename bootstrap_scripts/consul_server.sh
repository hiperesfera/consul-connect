#!/bin/bash
sudo sudo apt-get update
sudo apt install -y unzip curl jq
echo "Determining local IP address"
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
echo "Installing Consul"
CONSUL_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/consul | jq .current_version | tr -d '"')
curl "https://releases.hashicorp.com/consul/1.8.0/consul_1.8.0_linux_amd64.zip" -o consul.zip
unzip consul.zip
chmod +x consul
sudo cp consul /usr/local/bin/consul

echo "Configuring Consul Server"
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /var/lib/consul /etc/consul.d
ID=$(echo "$LOCAL_IPV4" | md5sum | cut -d' ' -f1)

echo "Creating Consul server config file"
sudo cat >/etc/consul.d/consul.hcl <<-_EOCF
{
    "client_addr" : "0.0.0.0",
    "bootstrap" : true,
    "server" : true,
    "datacenter" : "AWS_DATACENTER_ONE",
    "node_name" : "SERVER-$ID",
    "data_dir" : "/var/lib/consul",
    "bootstrap_expect" : 1,
    "enable_script_checks" : false,
    "enable_local_script_checks" : false,
    "retry_join" : ["$LOCAL_IPV4"],
    "encrypt" : "${PSK}",
    "ui" : true
}
_EOCF

sudo cat >/etc/consul.d/connect.hcl <<-_EOCCF
connect {
  enabled = true
}
_EOCCF

echo "Creating Consul systemd file"
sudo cat >/etc/systemd/system/consul.service <<-_EOCSU
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl
[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
ExecStop=/usr/local/bin/consul leave
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
_EOCSU

echo "Adding permissions"
sudo chown --recursive consul:consul /var/lib/consul
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

echo "Starting Consul server"
sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl status consul
