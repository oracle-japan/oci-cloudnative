### Terraform OCI Provider
variable "region" {
}

variable "tenancy_ocid" {
}

variable "current_user_ocid" {
}

variable "compartment_ocid" {
}

### OCI Vault & Secrets
variable "oci_registry_username" {
}

variable "oci_registry_password" {
}

### Email Delivery
variable "email_address" {
  description = "Email address for Email Delivery"
}
