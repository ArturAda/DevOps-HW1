# STEP I: Ansible
1. **Create the inventory file**
&emsp; First of all, we need to create an inventory.ini (where all names of groups and servers belonging to those groups will be defined).
2. **Create the host_vars and .yaml files**
&emsp; Then we need to create a folder host_vars (and if you want, you can create another folder group_vars). In this folder you create files with .yaml extension, using the server names you specified in the .ini file.

---

### Examples:
—— **How the directory structure look right now**
```text
ansible/
├── inventory.ini
└── host_vars/
    └── example.yaml
```

—— **Example .ini and .yaml file in host_vars**

———**1. .ini file**
```ini
# ./ansible/inventory.ini
[wonderful_server]
fairy-server
```
———**2. .yaml file**
```yaml
# ./ansible/host_vars/fairy-server.yaml
---
ansible_host: 0.47.0.0
ansible_user: agent
ansible_ssh_private_key_file: /blood/money/contract
```

**3. Create the Ansible Playbook**

&emsp; We created a `setup_host.yaml` playbook that connects to the servers, creates a non-root `deployer` user with passwordless sudo access, and installs Docker along with the Docker Compose plugin.

**4. How to run**

&emsp; To prepare the server, run the following command from the `ansible/` directory:
```bash
ansible-playbook -i inventory.ini setup_host.yaml
```

**5. Idempotency Check**

&emsp; Next, we need to check idempotency. If we run the playbook a second time, it will not change anything on the server. You can see the result on the screenshot below.

![Ansible Idempotency Check](images/ansible.png)

---

## STEP II: Terraform

**1. Create the Terraform directory**

&emsp; First of all, we need to create a separate folder for our Terraform project (for example, `terraform/`).

**2. Create the main.tf file**

&emsp; Then we need to create a `main.tf` file in this folder. In this file, we configure the Docker provider, download the Nginx image, and create a custom network, a volume, and the container itself (running on a non-standard port 6767).

---

### Examples:
—— **How the directory structure looks right now**

```text
terraform/
└── main.tf
```

—— Example main.tf file

```tf
# ./terraform/main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}
provider "docker" {
  host = "unix:///var/run/docker.sock"
}
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}
resource "docker_network" "custom_nginx_network" {
  name = "nginx_net"
}
resource "docker_volume" "nginx_data" {
  name = "nginx_volume"
}
resource "docker_container" "nginx_web" {
  name  = "nginx_terraform"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.custom_nginx_network.name
  }

  volumes {
    volume_name    = docker_volume.nginx_data.name
    container_path = "/usr/share/nginx/html"
  }

  ports {
    internal = 80
    external = 6767
  }
}
```

**3. How to run**

&emsp; To deploy the container and all resources, run the following commands from the `terraform/` directory one by one:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**4. Verification Check**

&emsp; Next, we need to check if everything works correctly. First, we use the `terraform state list` command to see all created objects. Then, we check if Nginx answers on our custom port using `curl -i http://localhost:6767`. You can see both results on the screenshots below.

**Terraform State:**  
![Terraform State List](images/terraform_state_list.png)

**Nginx HTTP Response:**  
![Nginx Curl Result](images/curl.png)

---

## STEP III: Bash Monitoring Script

**1. Create the script file**

&emsp; First of all, we need to create a `monitor.sh` file on our VM.

**2. Write the monitoring logic**

&emsp; In this file, we write a Bash script that takes a service name as an argument. It checks if the service is active using `systemctl`. If the service is not running, the script shows the last 10 lines of its logs using `journalctl`. After that, it counts the number of errors in `/var/log/syslog` for the last hour using `grep` and `awk`.

---

### Examples:
—— **How the directory structure looks right now**

```text
scripts/
└── monitor.sh
```

—— **Example monitor.sh file**

```bash
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./monitor.sh <service_name>"
    exit
fi

SERVICE=$1

echo "Checking $SERVICE"

STATE=$(systemctl is-active "$SERVICE")

if [ "$STATE" = "active" ]; then
    echo "Service $SERVICE is running"
else
    echo "Service $SERVICE isn't running"
    echo "The last 10 lines of the log for $SERVICE"
    journalctl -u "$SERVICE" -n 10 --no-pager
fi

echo "Checking the number of errors"

if [ -f /var/log/syslog ]; then
    TIME_HOUR_AGO=$(date -d "-1 hour" '+%Y-%m-%dT%H:%M:%S')
    ERRORS=$(grep -i "error" /var/log/syslog | awk -v iso="$TIME_HOUR_AGO" '$1 >= iso {count++} END {print count+0}')
    echo "Found $ERRORS error(s) in /var/log/syslog in the last hour"
else
    echo "Couldn't find file /var/log/syslog"
fi
```

**3. How to run**

&emsp; First, we need to make the script executable, and then we can run it by passing any service name as an argument:

```bash
chmod +x monitor.sh
./monitor.sh docker
./monitor.sh agent_p
```

**4. Verification Check**

&emsp; Next, we need to check if our script works correctly in both situations. First, we test it with a running service (`docker`), and then we test it with a non-existing service (`agent_p`) to see the log output. You can see both results on the screenshots below.

**Active Service Check (docker):**
![Docker Active Check](images/docker_active.png)

**Inactive Service Check (agent_p):**  
![Agent P Inactive Check](images/agent_p_active.png)