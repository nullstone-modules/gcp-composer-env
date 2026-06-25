terraform {
  required_providers {
    ns = {
      source  = "nullstone-io/ns"
      version = "~> 0.11.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.29.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
