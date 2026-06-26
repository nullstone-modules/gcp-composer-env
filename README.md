# gcp-composer-env

Nullstone app module that provisions a [Google Cloud Composer](https://cloud.google.com/composer)
(managed Apache Airflow) environment.

- **Contract:** `app:serverless/gcp/composer`
- **Tool:** OpenTofu

## What it creates

- A **Cloud Composer 3 environment** (`google_composer_environment`), private by
  default, with configurable size, Airflow image version, PyPI packages, and
  Airflow config overrides.
- An **app runtime service account** that the environment runs as. Capability
  bindings (e.g. `secretmanager.secretAccessor`, `bigquery.dataEditor`) target
  this SA so DAGs inherit those grants. Granted `roles/composer.worker`.
- A **deployer service account** (impersonated by the Nullstone agent) with
  `roles/composer.environmentAndStorageObjectAdmin` to manage the environment and
  read its config.
- A **pusher service account** (impersonated by the Nullstone agent) with
  `roles/storage.objectAdmin` on the environment's DAG bucket, used to sync DAG
  files to `gs://<bucket>/dags`.
- A **log reader service account** with `roles/logging.viewer`.
- IAM for the Cloud Composer service agent (`roles/composer.ServiceAgentV2Ext`),
  required for environments that run as a user-managed service account.

## Networking & internal access

The environment is **private by default** (`enable_private_environment = true`)
and reaches the connected VPC through a Composer 3 Private Service Connect
network attachment, auto-created from the network connection's VPC and private
subnetwork. Because the environment sits on the private network, DAGs can reach:

- **Internal Kubernetes services** on the cluster — via internal load balancers /
  internal ingress published on the same VPC.
- **A Cloud SQL Postgres instance** — via its private IP / the network's Private
  Service Access range. The app runtime SA is granted `roles/cloudsql.client` so
  DAGs can open connections through the Cloud SQL connector / IAM auth; database
  credentials are injected by an attached `gcp-postgres-access` capability.

Internet egress (e.g. for `pip` installs of `pypi_packages`) flows through the
network's Cloud NAT.

> Note: this gives DAGs network access to internal *service endpoints*. Driving
> the Kubernetes API itself (e.g. `KubernetesPodOperator` against the cluster)
> additionally requires a cluster connection and `container`-level IAM — open an
> issue / extend the module if you need that.

## Environment variables & secrets

- `env_vars` are injected as Airflow environment variables
  (`software_config.env_variables`).
- `secrets` (and capability secrets) are stored in **GCP Secret Manager** and the
  Airflow **Secret Manager backend** is configured automatically. A secret named
  `KEY` is stored as `<environment_name>-KEY`; a DAG resolves it with
  `Variable.get("KEY")`.
- Standard `NULLSTONE_*` and `GOOGLE_CLOUD_*` variables are injected automatically.

## Deployment model

Composer apps are deployed by syncing DAG files to the environment's GCS bucket
(`dag_gcs_prefix`, e.g. `gs://<bucket>/dags`). The `pusher` service account has
`storage.objectAdmin` on that bucket to perform the sync, and the `deployer`
service account manages the environment itself.

## Connections

| Name    | Contract          | Purpose                                      |
|---------|-------------------|----------------------------------------------|
| network | `network/gcp/vpc` | VPC + private subnetwork for the environment |
