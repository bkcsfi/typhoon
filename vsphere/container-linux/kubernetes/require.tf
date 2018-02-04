# Terraform version and plugin versions

terraform {
  required_version = ">= 0.11.3"
}

provider "vsphere" {
  version = "~> 1.3.1"
}

provider "local" {
  version = "~> 1.0"
}

provider "null" {
  version = "~> 1.0"
}

provider "template" {
  version = "~> 1.0"
}

provider "tls" {
  version = "~> 1.0"
}
