terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.41.0"

    }
  }
}

resource "google_project" "this" {
  name            = var.project_id
  project_id      = var.project_id
  org_id          = var.org_id
  billing_account = var.billing_account
}

resource "google_project_iam_member" "admin" {
  project    = var.project_id
  role       = "roles/owner"
  member     = "serviceAccount:${var.root_sa_email}"
  depends_on = [google_project.this]
}

resource "google_service_account_iam_member" "admin" {
  service_account_id = "projects/${var.root_project}/serviceAccounts/${var.root_sa_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.root_sa_email}"
  depends_on         = [google_project.this]
}

resource "google_storage_bucket" "projects_tf" {
  location = "us-central1"
  project  = var.project_id

  name = "${var.bucket_prefix}-${var.project_id}"

  force_destroy = true
  versioning {
    enabled = false
  }

  depends_on = [google_project.this]
}

resource "google_service_account" "tf_admin" {
  account_id   = "terraform"
  display_name = "Terraform Admin"
  description  = "Role to provision project's resources"
  project      = var.project_id
  depends_on   = [google_project.this]
}

resource "google_service_account_iam_member" "tf_admin" {
  service_account_id = google_service_account.tf_admin.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.tf_admin.email}"
  depends_on         = [google_project.this]
}

resource "google_project_iam_member" "tf_admin" {
  project    = google_service_account.tf_admin.project
  role       = "roles/owner"
  member     = "serviceAccount:${google_service_account.tf_admin.email}"
  depends_on = [google_project.this]
}

resource "google_project_service" "this" {
  project = var.project_id
  service = "iamcredentials.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
  disable_on_destroy         = true

  depends_on = [google_project.this]
}

resource "google_iam_workload_identity_pool" "this" {
  project                   = var.project_id
  workload_identity_pool_id = "github-access-pool"
  display_name              = "Github Access Pool"
  description               = "Pool to authorize terraform SA"
  disabled                  = false
  depends_on                = [google_project.this]
}

resource "google_iam_workload_identity_pool_provider" "this" {
  project = var.project_id

  workload_identity_pool_provider_id = "github-oidc"
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id

  display_name = "Github OIDC"
  description  = "OIDC to AuthN/Z project terraform SA to provision resourced during Github Action job"

  attribute_mapping = {
    "google.subject"       = "assertion.sub",
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  disabled = true
}

resource "google_service_account_iam_binding" "this" {
  service_account_id = google_service_account.tf_admin.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/attribute.repository/${var.github_repo}"
  ]
}
