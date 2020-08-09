#### Creating Consul Server on Ubuntu Server
resource "aws_instance" "consul-server" {
  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.micro"
  associate_public_ip_address = "false"
  key_name = var.ssh_key
  security_groups = var.security_groups
  subnet_id     = var.subnet_id

  user_data = <<-_EOF
    #!/bin/bash
    apt install -y unzip curl
    echo "Determining local IP address"
    LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
    echo "Installing Consul"
    curl "https://releases.hashicorp.com/consul/1.7.4/consul_1.7.4_linux_amd64.zip" -o consul.zip
    sleep 5
    unzip consul.zip
    chmod +x consul
    cp consul /usr/local/bin/consul

    echo "Configuring Consul Server"
    useradd --system --home /etc/consul.d --shell /bin/false consul
    mkdir -p /var/lib/consul /etc/consul.d

    echo "Creating Consul server config file"
    cat >/etc/consul.d/consul.hcl <<-_EOCCF
    {
        "client_addr" : "0.0.0.0",
        "bootstrap" : true,
        "server" : true,
        "datacenter" : "AWS_DATACENTER_ONE",
        "node_name" : "SERVER-$LOCAL_IPV4",
        "data_dir" : "/var/lib/consul",
        "bootstrap_expect" : 1,
        "enable_script_checks" : false,
        "enable_local_script_checks" : false,
        "ui" : true
    }
    _EOCCF

    echo "Creating Consul systemd file"
    cat >/etc/systemd/system/consul.service <<-_EOCSU
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
    chown --recursive consul:consul /var/lib/consul
    chown --recursive consul:consul /etc/consul.d

    echo "Starting Consul server"
    systemctl enable consul
    systemctl start consul
    systemctl status consul

    _EOF

  tags = {
    Name = "consule-server"
  }

  lifecycle {
    create_before_destroy = true
  }
}



#### Creating Consul Client on Ubuntu Server
resource "aws_instance" "consul-client" {
  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.micro"
  associate_public_ip_address = "false"
  key_name = var.ssh_key
  security_groups = var.security_groups
  subnet_id     = var.subnet_id

  user_data = <<-_EOF
    #!/bin/bash
    apt install -y unzip curl
    echo "Determining local IP address"
    LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
    echo "Installing Consul"
    curl "https://releases.hashicorp.com/consul/1.7.4/consul_1.7.4_linux_amd64.zip" -o consul.zip
    unzip consul.zip
    chmod +x consul
    cp consul /usr/local/bin/consul

    echo "Configuring Consul Client"
    useradd --system --home /etc/consul.d --shell /bin/false consul
    mkdir -p /var/lib/consul /etc/consul.d

    echo "Creating Consul client config file"
    cat >/etc/consul.d/consul.hcl <<-_EOCCF
    {
        "datacenter" : "AWS_DATACENTER_ONE",
        "node_name" : "CLIENT-$LOCAL_IPV4",
        "data_dir" : "/var/lib/consul",
        "enable_script_checks" : false,
        "enable_local_script_checks" : false,
        "retry_join" : ["${aws_instance.consul-server.private_ip}"]
    }
    _EOCCF

    echo "Creating Consul systemd file"
    cat >/etc/systemd/system/consul.service <<-_EOCSU
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
    chown --recursive consul:consul /var/lib/consul
    chown --recursive consul:consul /etc/consul.d
    chmod 640 /etc/consul.d/consul.hcl

    echo "Starting Consul server"
    systemctl enable consul
    systemctl start consul
    systemctl status consul

    _EOF

  tags = {
    Name = "consul-client"
  }

  lifecycle {
    create_before_destroy = true
  }
}
