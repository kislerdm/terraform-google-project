output "instructions" {
  description = "Instruction to setting up the tf state codebase to manage the newly created project."

  value = {
    "main.tf"        = <<-EOF
Create main.tf with the following configurations:

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.41.0"

    }
  }
  backend "gcs" {
    bucket = "${google_storage_bucket.projects_tf.name}"
  }
}

provider "google" {
  project = "${var.project_id}"
  region  = "us-central1"
  zone    = "us-central1-c"
}

EOF
    "github actions" = <<-EOF
Add the auth step to GitHub Actions workflow definition:

- id: 'auth'
  name: 'Authenticate to Google Cloud'
  uses: 'google-github-actions/auth@v0'
    with:
      workload_identity_provider: '${google_iam_workload_identity_pool.this.name}'
      service_account: '${google_service_account.tf_admin.email}'

EOF
  }
}
