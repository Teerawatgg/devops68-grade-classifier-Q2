variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Southeast Asia"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "gradeapi"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1ms"
}

variable "vm_admin_username" {
  description = "Linux VM admin username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string

  validation {
    condition     = length(trimspace(var.ssh_public_key)) > 0
    error_message = "ssh_public_key must not be empty."
  }
}

variable "repo_url" {
  description = "Forked GitHub repository URL"
  type        = string

  validation {
    condition     = can(regex("^https://github.com/.+/.+\\.git$", var.repo_url))
    error_message = "repo_url must be a GitHub HTTPS URL ending with .git"
  }
}

variable "repo_branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3023
}

variable "app_dir" {
  description = "Directory on VM for app"
  type        = string
  default     = "/opt/grade-classifier"
}