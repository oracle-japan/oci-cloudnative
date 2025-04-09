resource "oci_apm_apm_domain" "mushop_domain" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop"
  is_free_tier   = true
}
