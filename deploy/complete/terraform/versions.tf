terraform {
  required_version = "~> 1.2.0"
  required_providers {
    name = {
      source  = "oracle/oci"
      version = "6.27.0"
    }
  }
}
