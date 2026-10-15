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
