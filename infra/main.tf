# SFE4015 Assignment 2 - Infrastructure as Code
# A small staging environment described declaratively with Terraform.
# The Docker provider runs it locally, so no cloud account is required.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Talk to the local Docker daemon over its Unix socket.
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "container_name" {
  description = "Name of the staging container."
  type        = string
  default     = "scm-staging"
}

variable "nginx_image" {
  description = "Nginx image to pull for the staging environment."
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "host_port" {
  description = "Port on the host machine that maps to port 80 in the container."
  type        = number
  default     = 8080
}

# ---------------------------------------------------------------------------
# Resources
# ---------------------------------------------------------------------------

# Pull the nginx image. keep_locally = false means `terraform destroy`
# also removes the image, leaving the machine as it was found.
resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = false
}

# Run the staging web server, publishing container port 80 on host port 8080.
resource "docker_container" "scm_staging" {
  name    = var.container_name
  image   = docker_image.nginx.image_id
  restart = "no"

  ports {
    internal = 80
    external = var.host_port
  }

  # Labels make the managed resource easy to identify with `docker ps`.
  labels {
    label = "project"
    value = "sfe4015-assignment2"
  }

  labels {
    label = "environment"
    value = "staging"
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "container_name" {
  description = "Name of the running staging container."
  value       = docker_container.scm_staging.name
}

output "container_id" {
  description = "Docker ID of the staging container."
  value       = docker_container.scm_staging.id
}

output "staging_url" {
  description = "URL where the staging environment is reachable."
  value       = "http://localhost:${var.host_port}"
}
