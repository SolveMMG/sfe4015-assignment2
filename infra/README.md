# Staging Environment (Terraform + Docker)

A small staging environment for the SFE4015 case study, described as code in
[`main.tf`](main.tf). It runs an nginx web server in a Docker container named
`scm-staging`, with container port 80 published on host port 8080.

No cloud account is needed: the `kreuzwerker/docker` provider drives the Docker
daemon on the local machine.

## Prerequisites

- Terraform >= 1.5 (`terraform -version`)
- Docker installed and running (`docker ps`)
- Host port 8080 free

## Usage

```bash
cd infra

terraform init       # download the Docker provider
terraform plan       # preview what will be created
terraform apply      # create the image and container

docker ps            # confirm scm-staging is running
curl http://localhost:8080

terraform destroy    # remove the container and the image
```

## What the configuration declares

| Resource | Purpose |
| --- | --- |
| `docker_image.nginx` | Pulls `nginx:1.27-alpine`. `keep_locally = false` so destroy also removes the image. |
| `docker_container.scm_staging` | Runs the container as `scm-staging` and maps `8080 -> 80`. |

Inputs (`container_name`, `nginx_image`, `host_port`) are variables, so the same
configuration can be reused for another environment by overriding them, e.g.
`terraform apply -var host_port=9090 -var container_name=scm-test`.

## Drift experiment

See [`DRIFT.md`](DRIFT.md) for the deliberate drift exercise: stopping the
container by hand outside Terraform, and what `terraform plan` reports.
