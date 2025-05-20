resource "oci_kms_vault" "mushop_vault" {
 compartment_id = var.compartment_ocid
 display_name   = "mushop"
 vault_type     = "DEFAULT"
}

resource "oci_kms_key" "mushop_key" {
 compartment_id      = var.compartment_ocid
 display_name        = "mushop-key"
 management_endpoint = oci_kms_vault.mushop_vault.management_endpoint
 key_shape {
  algorithm = "AES"
  length    = 32
 }
}

resource "oci_vault_secret" "mushop_oci_registry_user" {
 compartment_id = var.compartment_ocid
 key_id         = oci_kms_key.mushop_key.id
 secret_name    = "OCI_REGISTRY_USERNAME"
 vault_id       = oci_kms_vault.mushop_vault.id
 secret_content {
  content_type = "BASE64"
  content      = base64encode(var.oci_registry_username)
 }
}

resource "oci_vault_secret" "mushop_oci_registry_password" {
 compartment_id = var.compartment_ocid
 key_id         = oci_kms_key.mushop_key.id
 secret_name    = "OCI_REGISTRY_PASSWORD"
 vault_id       = oci_kms_vault.mushop_vault.id
 secret_content {
  content_type = "BASE64"
  content      = base64encode(var.oci_registry_password)
  }
 }
