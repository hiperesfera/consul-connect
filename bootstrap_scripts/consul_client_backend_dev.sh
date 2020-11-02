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

echo "Configuring Consul Client"
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /var/lib/consul /etc/consul.d
ID=$(echo "$LOCAL_IPV4" | md5sum | cut -d' ' -f1)

echo "Creating Consul client config file"
sudo cat >/etc/consul.d/consul.hcl <<-_EOCCF
{
    "datacenter" : "AWS_DATACENTER_ONE",
    "node_name" : "CLIENT-$ID-DEV",
    "data_dir" : "/var/lib/consul",
    "enable_script_checks" : false,
    "enable_local_script_checks" : false,
    "encrypt" : "${PSK}",
    "retry_join" : ["${consul_server_address}"]
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

echo "Creating Consul sidecar systemd file"
sudo cat >/etc/systemd/system/sidecard.service <<-_EOCSCU
[Unit]
Description="Consul sidecar Proxy"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul connect proxy -sidecar-for counting-dev
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
_EOCSCU

echo "Adding permissions"
sudo chown --recursive consul:consul /var/lib/consul
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

echo "Starting Consul server"
sudo systemctl enable consul
sudo systemctl enable sidecar


echo "Creating Dashboard Service definition"
sudo cat >/etc/consul.d/counting.hcl <<-_EOSCF
  service {
    name = "counting-dev"
    id = "counting-dev"
    port = 9003

    connect {
      sidecar_service {}
    }

    check {
      id       = "counting-check-dev"
      http     = "http://localhost:9003/health"
      method   = "GET"
      interval = "1s"
      timeout  = "1s"
    }
  }
_EOSCF

#Restart consul client load new configuration
sudo systemctl restart consul
sudo systemctl start sidecard

echo "Deploying new service"
curl  -LJO https://github.com/hashicorp/demo-consul-101/releases/download/0.0.3/counting-service_linux_amd64.zip
unzip counting-service_linux_amd64.zip
chmod +x counting-service_linux_amd64

PORT=9003 ./counting-service_linux_amd64 &
