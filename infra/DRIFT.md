# Configuration Drift Experiment

Deliberate drift was introduced into the staging environment defined in
[`main.tf`](main.tf), to observe how Terraform detects and reports it.

## Method

```bash
cd infra
terraform init
terraform plan
terraform apply          # 2 added: docker_image.nginx, docker_container.scm_staging
docker ps                # scm-staging  Up  0.0.0.0:8080->80/tcp
curl http://localhost:8080   # HTTP 200

docker stop scm-staging  # <-- the manual change, made outside Terraform
terraform plan           # <-- the observation
```

## What `terraform plan` reported

```text
docker_image.nginx: Refreshing state... [id=sha256:6769dc3a703c...nginx:1.27-alpine]
docker_container.scm_staging: Refreshing state... [id=af7a83afc39b...]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # docker_container.scm_staging has been deleted
  - resource "docker_container" "scm_staging" {
      - id   = "af7a83afc39b40f1626468d15ea53603df45f2e7d29041d807f43b1c315685a2" -> null
        name = "scm-staging"
        # (42 unchanged attributes hidden)
        # (3 unchanged blocks hidden)
    }

Terraform will perform the following actions:

  # docker_container.scm_staging will be created
  + resource "docker_container" "scm_staging" {
      + name  = "scm-staging"
      + image = "sha256:6769dc3a703c..."
      + ports {
          + external = 8080
          + internal = 80
        }
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ container_id = "af7a83afc39b..." -> (known after apply)
```

Running `terraform apply` afterwards reconciled the environment: the provider
discarded the stale stopped container and created a replacement with a new ID
(`14c40e3b1ac5...`), port 8080 served HTTP 200 again, and the next
`terraform plan` returned *"No changes. Your infrastructure matches the
configuration."*

Note that `docker_image.nginx` was refreshed and reported no change. Drift is
detected per resource, so only the resource that was actually tampered with
appeared in the plan.

## Observation paragraph

Configuration drift is the gap that opens up between the infrastructure a
project has declared in code and the infrastructure that actually exists,
arising whenever the real environment is changed by some route other than the
tool that owns it. Here I caused it deliberately with `docker stop
scm-staging`, a manual, out-of-band action that Terraform knew nothing about
and that left its state file still claiming a running container on port 8080.
Terraform found the discrepancy on the next `terraform plan`: during the
refresh phase it queried the Docker daemon about every resource it tracks,
compared the answers against its recorded state, and printed the banner
*"Objects have changed outside of Terraform"* followed by
`# docker_container.scm_staging has been deleted`. It reported a deletion
rather than a mere status change because the `kreuzwerker/docker` provider
treats a container that is not running as absent while `must_run` is true, so
a stopped container is read as no container at all. Terraform then proposed
the correction needed to close the gap — `Plan: 1 to add, 0 to change, 0 to
destroy`, recreating `scm-staging` with the same image, name, labels and
`8080 -> 80` mapping, with `container_id` marked `(known after apply)` because
the replacement would carry a new Docker ID. The important point is that
Terraform did not simply report a problem; it worked out the specific action
that would restore the declared state, which is what makes the configuration
the single source of truth rather than just documentation. Drift detection
matters because undetected drift is how environments quietly stop matching
each other: a hotfix applied by hand to staging and never written back into
code makes staging an unreproducible snowflake, so the next `apply` silently
reverts somebody's undocumented fix, a rebuild from code produces a subtly
different environment, and "it works in staging" stops being evidence of
anything. Routinely running `plan` in CI turns that invisible divergence into
a visible, reviewable diff before it becomes an outage or an unreproducible
deployment.

## Teardown

```bash
terraform destroy        # 2 destroyed: container and image
docker ps -a             # no scm-staging
```

Because `docker_image.nginx` sets `keep_locally = false`, destroy removes the
pulled image as well as the container, returning the machine to its original
state.
