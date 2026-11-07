# SFE4015 Assignment 2

Case-study repository for SFE4015.

## Infrastructure as Code

[`infra/`](infra/) describes a small staging environment as Terraform code,
using the `kreuzwerker/docker` provider so it runs locally with no cloud
account. It provisions an nginx container named `scm-staging` with host port
8080 mapped to container port 80.

- [`infra/main.tf`](infra/main.tf) — the environment definition
- [`infra/README.md`](infra/README.md) — prerequisites and commands
- [`infra/DRIFT.md`](infra/DRIFT.md) — the deliberate configuration-drift
  experiment, what `terraform plan` reported, and the observation write-up
- [`infra/terraform-run.log`](infra/terraform-run.log) — full transcript of the
  init / plan / apply / drift / destroy run
