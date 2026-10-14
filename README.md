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

