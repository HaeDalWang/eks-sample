terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.21"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
    bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = ">= 0.1.2"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "~> 1.0.4"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}
