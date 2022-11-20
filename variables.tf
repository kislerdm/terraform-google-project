variable "root_project" {
  type        = string
  description = "Parent project_id."
}

variable "root_sa_email" {
  type        = string
  description = "Parent project SA's email."
}

variable "project_id" {
  type        = string
  description = "Name of the project to create."
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix of the gcs bucket to store tf state within the provisioned project."
  default     = "sys"
}

variable "org_id" {
  type        = string
  description = "Organisation ID."
}

variable "billing_account" {
  type        = string
  description = "Billing account."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository to keep tf codebase defining resources in the provisioned project. The format: {{owner}}/{{repoName}}"
  validation {
    condition     = length(split("/", var.github_repo)) == 2
    error_message = "The github_repo value must satisfy the template {{owner}}/{{repoName}}, e.g. kislerdm/gcp-projects"
  }
}
