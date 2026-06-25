# gcp-composer-env

Nullstone app module that provisions a [Google Cloud Composer](https://cloud.google.com/composer)
(managed Apache Airflow) environment.

- **Contract:** `app:serverless/gcp:composer`
- **Tool:** OpenTofu

## What it creates

- A **Cloud Composer 2 environment** (`google_composer_environment`) wired into the
  connected VPC/subnetwork, with configurable size, Airflow image version, PyPI
  packages, and Airflow config overrides.
- An **app runtime service account** that the environment runs as. Capability
  bindings (e.g. `secretmanager.secretAccessor`, `bigquery.dataEditor`) target
  this SA so DAGs inherit those grants. Granted `roles/composer.worker`.
- A **deployer service account** (impersonated by the Nullstone agent) with
  `roles/composer.environmentAndStorageObjectAdmin` to upload DAGs to the
  environment's GCS bucket and read environment config.
- A **log reader service account** with `roles/logging.viewer`.
- IAM for the Cloud Composer service agent (`roles/composer.ServiceAgentV2Ext`),
  required for environments that run as a user-managed service account.

## Environment variables & secrets

- `env_vars` are injected as Airflow environment variables
  (`software_config.env_variables`).
- `secrets` (and capability secrets) are stored in **GCP Secret Manager** and the
  Airflow **Secret Manager backend** is configured automatically. A secret named
  `KEY` is stored as `<environment_name>-KEY`; a DAG resolves it with
  `Variable.get("KEY")`.
- Standard `NULLSTONE_*` and `GOOGLE_CLOUD_*` variables are injected automatically.

## Deployment model

Composer apps are deployed by uploading DAG files to the environment's GCS bucket
(`dag_gcs_prefix`, e.g. `gs://<bucket>/dags`). The `deployer` service account has
the permissions required to do this.

## Connections

| Name    | Contract          | Purpose                                   |
|---------|-------------------|-------------------------------------------|
| network | `network/gcp/vpc` | VPC + private subnetwork for the environment |
