# Terraform module to provision a child GCP project managed with CI

The module provisions a GCP project and assigns a billing account to it.

The following resources are also provisioned in the newly created account:

- the service account to provision project specific resources using terraform;
- the bucket to be used as the terraform backend to keep state of project specific resources;
- the workload identity pool to authenticate and authorise the created service account for CI jobs.

The module supports the following CI:

- GitHub Actions.

## Architecture Diagram

![diagram](https://raw.githubusercontent.com/kislerdm/terraform-google-child-project/master/module-diagram.svg)

## Prerequisites

1. The [GCP Account](https://console.cloud.google.com/).
2. Activated [billing](https://console.cloud.google.com/billing).
3. The root GCP project -> `{{.rootProjectID}}`.
4. The service account (SA) to be assumed to provision child projects using terraform -> `{{.serviceAccountEmail}}`.
5. The following roles attached to the SA on the _organisation level_:
    - roles/axt.admin
    - roles/billing.user
    - roles/resourcemanager.projectCreator
    - roles/resourcemanager.projectIamAdmin
    - roles/resourcemanager.projectDeleter
6. Follow [the steps](https://github.com/google-github-actions/auth#setting-up-workload-identity-federation) to setup
   workload ID federation
7. Configure the GitHub action authN/Z step:

```yaml
- id: 'auth'
  name: 'Authenticate to Google Cloud'
  uses: 'google-github-actions/auth@v0'
  with:
    workload_identity_provider: '{{.outputOfStep6}}'
    service_account: '{{.serviceAccountEmail}}'
```

where

- `serviceAccountEmail` is the email of the terraform root's SA, output from the step 4;
- `outputOfStep6` provider's ID output from the step 6.

8. Export `ORG_ID` and `BILLING_ACCOUNT`
   as [GitHub secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

### How to create a new project

Add the configuration to the [main.tf](main.tf) of the terraform project:

```terraform
module "{{.projectName}}" {
  source          = "kislerdm/child-project/google"
  root_project    = "{{.rootProjectID}}"
  root_sa_email   = "{{.serviceAccountEmail}}"
  project_id      = "{{.projectName}}"
  github_repo     = "{{.githubOwner}}/{{.githubRepoName}}"
  bucket_prefix   = "sys"
  org_id          = var.org_id
  billing_account = var.billing_account
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.41.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 4.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_iam_workload_identity_pool.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_iam_member.admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.tf_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.tf_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_binding.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_binding) | resource |
| [google_service_account_iam_member.admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_account_iam_member.tf_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.projects_tf](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_billing_account"></a> [billing\_account](#input\_billing\_account) | Billing account. | `string` | n/a | yes |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | Prefix of the gcs bucket to store tf state within the provisioned project. | `string` | `"sys"` | no |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repository to keep tf codebase defining resources in the provisioned project. The format: {{owner}}/{{repoName}} | `string` | n/a | yes |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | Organisation ID. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Name of the project to create. | `string` | n/a | yes |
| <a name="input_root_project"></a> [root\_project](#input\_root\_project) | Parent project\_id. | `string` | n/a | yes |
| <a name="input_root_sa_email"></a> [root\_sa\_email](#input\_root\_sa\_email) | Parent project SA's email. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instructions"></a> [instructions](#output\_instructions) | Instruction to setting up the tf state codebase to manage the newly created project. |
<!-- END_TF_DOCS -->
